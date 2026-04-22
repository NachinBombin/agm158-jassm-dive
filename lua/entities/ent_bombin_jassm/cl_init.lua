include("shared.lua")

-- ================================================================
--  AGM-158 JASSM — CLIENT
--  3D flame model attached to the exhaust — no particle emitters.
-- ================================================================

local FLAME_MODEL    = "models/roycombat/shared/trail_f22.mdl"
local BACK_OFFSET    = 55    -- HU behind origin to place the flame prop
local FLAME_SCALE    = 0.55  -- SetModelScale on the prop

function ENT:Initialize()
    -- Spawn the 3D flame as a client-side prop parented to this entity.
    self._flameProp = ClientsideModel(FLAME_MODEL)
    if IsValid(self._flameProp) then
        self._flameProp:SetPos(self:GetPos())
        self._flameProp:SetAngles(self:GetAngles())
        self._flameProp:SetParent(self)
        self._flameProp:SetModelScale(FLAME_SCALE, 0)
        -- Place it at the exhaust (behind local origin along -X which is forward in Valve coords)
        -- We use a local attachment offset via SetRenderOrigin override in Draw().
        self._flameProp:SetNoDraw(true)   -- we'll position & draw manually
    end
    self._spawnTime = CurTime()
end

function ENT:Draw()
    self:DrawModel()

    if not IsValid(self._flameProp) then return end

    -- Position flame prop at exhaust
    local backDir    = -self:GetForward()
    local exhaustPos = self:GetPos() + backDir * BACK_OFFSET
    local ang        = self:GetAngles()
    -- Flame faces rearward: rotate 180° on yaw so the trail points back
    ang.y = ang.y + 180

    self._flameProp:SetPos(exhaustPos)
    self._flameProp:SetAngles(ang)
    self._flameProp:DrawModel()

    -- Dynamic orange glow at exhaust
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

function ENT:Think()
    -- Nothing needed — flame prop is repositioned every Draw().
end

function ENT:OnRemove()
    if IsValid(self._flameProp) then
        self._flameProp:Remove()
    end
end
