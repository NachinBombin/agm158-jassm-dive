include("shared.lua")

-- ================================================================
-- AGM-158 JASSM -- CLIENT
-- ================================================================

local FLAME_MODEL = "models/roycombat/shared/trail_f22.mdl"
local BACK_OFFSET = 55
local FLAME_SCALE = 0.55

function ENT:Initialize()
	self:SetModelScale(1.6, 0)
	self:SetBodygroup(1, 1)

	timer.Simple(0, function()
		if not IsValid(self) then return end
		self._flameProp = ClientsideModel(FLAME_MODEL)
		if IsValid(self._flameProp) then
			self._flameProp:SetModelScale(FLAME_SCALE, 0)
			self._flameProp:SetNoDraw(true)
		end
	end)
end

function ENT:Draw()
	self:DrawModel()

	if not IsValid(self._flameProp) then return end

	local exhaustPos = self:GetPos() + (-self:GetForward()) * BACK_OFFSET
	local ang = self:GetAngles()
	ang.y = ang.y + 180

	self._flameProp:SetPos(exhaustPos)
	self._flameProp:SetAngles(ang)
	self._flameProp:DrawModel()

	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.pos        = exhaustPos
		dlight.r          = 255
		dlight.g          = 120
		dlight.b          = 20
		dlight.brightness = 4
		dlight.Decay      = 1200
		dlight.Size       = math.Rand(280, 380)
		dlight.DieTime    = CurTime() + 0.05
	end
end

function ENT:OnRemove()
	if IsValid(self._flameProp) then
		self._flameProp:Remove()
	end
end

-- ============================================================
-- PRECACHE
-- ============================================================
game.AddParticles( "particles/fire_01.pcf" )
PrecacheParticleSystem( "fire_medium_02" )

-- ============================================================
-- DAMAGE TIER VISUAL SYSTEM
--
-- Tier 0: no damage effects
-- Tier 1: light smoke + 1 fire point  (66% -> 33% HP)
-- Tier 2: 2 fires along fuselage      (33% ->  0% HP)
-- Tier 3: 4 fires + violent bursts    (destroyed / <=0 HP)
--
-- Offsets are in local-entity space, tuned for the AGM-158
-- fuselage (slender body, ~200 units long at scale 1.6).
-- ============================================================

local TIER_OFFSETS = {
	[1] = {
		Vector( 0, 0, 8 ),             -- mid-body smoke
	},
	[2] = {
		Vector(  30,  0, 8 ),          -- forward section
		Vector( -30,  0, 8 ),          -- rear section
	},
	[3] = {
		Vector(  40,  0, 10 ),
		Vector(   0,  0,  8 ),
		Vector( -40,  0,  8 ),
		Vector( -60,  0,  5 ),         -- near exhaust
	},
}

-- How often (seconds) between periodic burst FX per tier
local TIER_BURST_DELAY = { [1] = 5.0, [2] = 2.5, [3] = 0.9 }
-- How many burst positions to spray per interval
local TIER_BURST_COUNT = { [1] = 1,   [2] = 2,   [3] = 4   }

-- Per-entity particle state:  JassmStates[entIndex] = { tier, particles, nextBurst }
local JassmStates = {}

-- ============================================================
-- BURST FX  (sparks / small explosions along fuselage)
-- ============================================================
local function BurstAt( wPos, tier )
	local ed = EffectData()
	ed:SetOrigin( wPos )
	ed:SetScale( tier == 3 and math.Rand( 0.6, 1.2 ) or math.Rand( 0.3, 0.7 ) )
	ed:SetMagnitude( 1 )
	ed:SetRadius( tier * 15 )
	util.Effect( "Explosion", ed )

	local ed2 = EffectData()
	ed2:SetOrigin( wPos )
	ed2:SetNormal( Vector( 0, 0, 1 ) )
	ed2:SetScale( tier * 0.25 )
	ed2:SetMagnitude( tier * 0.35 )
	ed2:SetRadius( 14 )
	util.Effect( "ManhackSparks", ed2 )

	if tier >= 2 then
		local ed3 = EffectData()
		ed3:SetOrigin( wPos )
		ed3:SetNormal( VectorRand() )
		ed3:SetScale( 0.5 )
		util.Effect( "ElectricSpark", ed3 )
	end
end

local function SpawnBurstFX( ent, count, tier )
	if not IsValid( ent ) then return end
	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	for _ = 1, count do
		-- Scatter burst points along the missile body (local X is forward)
		local localOff = Vector(
			math.Rand( -70, 70 ),   -- along fuselage
			math.Rand( -15, 15 ),   -- side
			math.Rand(  -8, 18 )    -- vertical
		)
		local wPos = LocalToWorld( localOff, Angle(0,0,0), pos, ang )
		BurstAt( wPos, tier )
	end
end

-- ============================================================
-- PARTICLE MANAGEMENT
-- ============================================================
local function StopParticles( state )
	if not state.particles then return end
	for _, p in ipairs( state.particles ) do
		if IsValid( p ) then p:StopEmission() end
	end
	state.particles = {}
end

local function ApplyFlameParticles( ent, state, tier )
	StopParticles( state )
	state.tier = tier
	if not IsValid( ent ) or tier == 0 then return end

	for _, off in ipairs( TIER_OFFSETS[tier] ) do
		local p = ent:CreateParticleEffect( "fire_medium_02", PATTACH_ABSORIGIN_FOLLOW, 0 )
		if IsValid( p ) then
			p:SetControlPoint( 0, ent:LocalToWorld( off ) )
			table.insert( state.particles, p )
		end
	end

	state.nextBurst = CurTime() + ( TIER_BURST_DELAY[tier] or 4 )
end

-- ============================================================
-- NET  --  server notifies clients whenever tier changes
-- ============================================================
net.Receive( "bombin_jassm_damage_tier", function()
	local entIndex = net.ReadUInt( 16 )
	local tier     = net.ReadUInt( 2 )
	local ent      = Entity( entIndex )

	local state = JassmStates[entIndex]
	if not state then
		state = { tier = 0, particles = {}, nextBurst = 0 }
		JassmStates[entIndex] = state
	end

	if state.tier == tier then return end

	if IsValid( ent ) then
		ApplyFlameParticles( ent, state, tier )
		if tier > 0 then SpawnBurstFX( ent, TIER_BURST_COUNT[tier] or 1, tier ) end
	else
		-- Entity not yet available on client; defer to Think hook
		state.tier         = tier
		state.pendingApply = true
	end
end )

-- ============================================================
-- THINK HOOK  --  keep particle control points glued to missile
-- and fire periodic burst FX
-- ============================================================
hook.Add( "Think", "bombin_jassm_damage_fx", function()
	local ct = CurTime()
	for entIndex, state in pairs( JassmStates ) do
		local ent = Entity( entIndex )
		if not IsValid( ent ) then
			-- Missile is gone: clean up particles and table entry
			StopParticles( state )
			JassmStates[entIndex] = nil
		else
			-- Deferred apply: entity has arrived on the client
			if state.pendingApply then
				state.pendingApply = false
				ApplyFlameParticles( ent, state, state.tier )
			end

			if state.tier > 0 then
				-- Track particle control points to the moving missile
				local pos     = ent:GetPos()
				local ang     = ent:GetAngles()
				local offsets = TIER_OFFSETS[state.tier]
				for i, p in ipairs( state.particles ) do
					if IsValid( p ) and offsets[i] then
						p:SetControlPoint( 0, LocalToWorld( offsets[i], Angle(0,0,0), pos, ang ) )
					end
				end

				-- Periodic burst sparks / explosions
				if ct >= state.nextBurst then
					SpawnBurstFX( ent, TIER_BURST_COUNT[state.tier] or 1, state.tier )
					state.nextBurst = ct + ( TIER_BURST_DELAY[state.tier] or 4 )
				end
			end
		end
	end
end )
