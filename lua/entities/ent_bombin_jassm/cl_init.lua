include("shared.lua")

-- ================================================================
-- AGM-158 JASSM -- CLIENT
-- Missile body drawn via DrawModel().
-- 3D flame prop (trail_f22) floated at the exhaust, created after
-- a one-frame defer so a bad model path can never abort Initialize.
-- ================================================================

local FLAME_MODEL = "models/roycombat/shared/trail_f22.mdl"
local BACK_OFFSET = 55
local FLAME_SCALE = 0.55

function ENT:Initialize()
	-- Apply bodygroup locally -- custom Draw() / DrawModel() bypasses
	-- networked bodygroup state, so we must set it on the client too.
	self:SetBodygroup(0, 1)

	-- Defer flame prop creation by one frame.
	-- If the model is missing this errors in the timer, not here,
	-- so the entity Initialize always completes and DrawModel works.
	timer.Simple(0, function()
		if not IsValid(self) then return end
		self._flameProp = ClientsideModel(FLAME_MODEL)
		if IsValid(self._flameProp) then
			self._flameProp:SetModelScale(FLAME_SCALE, 0)
			self._flameProp:SetNoDraw(true) -- we manually call DrawModel in ENT:Draw
		end
	end)
end

function ENT:Draw()
	-- Always draw the missile body first.
	self:DrawModel()

	-- Draw flame prop if it loaded.
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
