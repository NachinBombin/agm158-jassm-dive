ENT.Type           = "anim"
ENT.Base           = "base_entity"
ENT.PrintName      = "Bombin JASSM"
ENT.Author         = "NachinBombin"
ENT.Information    = "AGM-158 JASSM loitering-mode missile. 3D model flame trail, full AN-71 positional audio."
ENT.Category       = "Bombin Support"

ENT.Spawnable      = false
ENT.AdminSpawnable = false

-- RENDERGROUP_OPAQUE is client-only; guard it so shared.lua doesn't crash on the server
if CLIENT then
	ENT.RenderGroup = RENDERGROUP_OPAQUE
end
