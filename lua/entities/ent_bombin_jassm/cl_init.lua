include("shared.lua")

-- ================================================================
--  AGM-158 JASSM — CLIENT
--  3D flame model, free-floating (no parent), repositioned every Draw.
-- ================================================================

local FLAME_MODEL  = "models/roycombat/shared/trail_f22.mdl"
local BACK_OFFSET  = 55    -- HU behind missile origin
local FLAME_SCALE  = 0.55

function ENT:Initialize()
    -- Create flame as a standalone clientside prop — NO SetParent.
    -- Parenting + manual repositioning fight each other and cause spin/jitter.
    self._flameProp = ClientsideModel(FLAME_MODEL)
    if IsValid(self._flameProp) then
        self._flameProp:SetPos(self:GetPos())
        self._flameProp:SetAngles(self:GetAngles())
        self._flameProp:SetModelScale(FLAME_SCALE, 0)
        -- Render normally; we position it ourselves every frame.
        self._flameProp:SetNoDraw(false)
    end
end

function ENT:Draw()
    -- Draw the missile model
    self:DrawModel()

    if not IsValid(self._flameProp) then return end

    -- Place flame at exhaust: behind the missile along its -forward axis
    local exhaustPos = self:GetPos() + (-self:GetForward()) * BACK_OFFSET
    -- Face flame rearward (180° yaw flip so trail streams behind)
    local ang  = self:GetAngles()
    ang.y      = ang.y + 180

    self._flameProp:SetPos(exhaustPos)
    self._flameProp:SetAngles(ang)
    self._flameProp:DrawModel()

    -- Orange glow at exhaust
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
