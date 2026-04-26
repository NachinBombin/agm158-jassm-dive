-- ================================================================
--  ENT_BOMBIN_JASSM_CHUTE  (server)
--  Parachute that rides above the JASSM during freefall.
--  Detaches when the missile engine ignites (NWBool "EngineOn" true).
-- ================================================================

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local CHUTE_MODEL   = "models/v92/parachutez/flying.mdl"
local ABOVE_OFFSET  = Vector( 0, 0, 105 )
local SWAY_AMP      = 2.5
local SWAY_RATE     = 1.2

function ENT:Initialize()
	self:SetModel( CHUTE_MODEL )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	self:DrawShadow( false )

	self.SwayClock = math.Rand( 0, math.pi * 2 )

	self:EmitSound( "npc/combine_soldier/zipline_clip1.wav", 75, 110, 0.9 )
end

function ENT:Think()
	local missile = self:GetOwner()

	if not IsValid( missile ) then
		self:Remove()
		return
	end

	-- Engine ignited: detach and fall away
	if missile:GetNWBool( "EngineOn", false ) then
		self:Detach()
		return
	end

	-- Follow missile position every tick
	self.SwayClock = self.SwayClock + SWAY_RATE * FrameTime()
	local sway = math.sin( self.SwayClock ) * SWAY_AMP

	local missileAng = missile:GetAngles()
	self:SetPos( missile:GetPos() + ABOVE_OFFSET )
	self:SetAngles( Angle( sway, missileAng.y, 0 ) )

	self:NextThink( CurTime() )
	return true
end

function ENT:Detach()
	local pos = self:GetPos()
	local ang = self:GetAngles()

	local abandon = ents.Create( "prop_physics" )
	if IsValid( abandon ) then
		abandon:SetModel( CHUTE_MODEL )
		abandon:SetPos( pos )
		abandon:SetAngles( ang )
		abandon:Spawn()
		abandon:Activate()

		local phys = abandon:GetPhysicsObject()
		if IsValid( phys ) then
			phys:Wake()
			phys:SetVelocity( Vector(
				math.Rand( -80, 80 ),
				math.Rand( -80, 80 ),
				math.Rand( -40, 20 )
			) )
			phys:AddAngleVelocity( Vector(
				math.Rand( -60, 60 ),
				math.Rand( -60, 60 ),
				math.Rand( -30, 30 )
			) )
		end

		sound.Play( "npc/combine_soldier/zipline_clip2.wav", pos, 80, math.random(95,108), 1.0 )

		timer.Simple( 12, function()
			if IsValid( abandon ) then abandon:Remove() end
		end )
	end

	self:Remove()
end

function ENT:OnRemove()
end
