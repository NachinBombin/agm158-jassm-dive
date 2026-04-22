if not SERVER then return end

util.AddNetworkString("BombinJassm_ManualSpawn")

net.Receive("BombinJassm_ManualSpawn", function(len, ply)
    if not IsValid(ply) then return end

    local tr = util.TraceLine({
        start  = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 3000,
        filter = ply,
    })

    local centerPos = tr.Hit and tr.HitPos or (ply:GetPos() + Vector(0, 0, 100))
    local callDir   = ply:EyeAngles():Forward()
    callDir.z = 0
    if callDir:LengthSqr() <= 1 then callDir = Vector(1, 0, 0) end
    callDir:Normalize()

    if not scripted_ents.GetStored("ent_bombin_jassm") then
        ply:PrintMessage(HUD_PRINTCENTER, "[Bombin JASSM] Entity not registered!")
        return
    end

    local ent = ents.Create("ent_bombin_jassm")
    if not IsValid(ent) then
        ply:PrintMessage(HUD_PRINTCENTER, "[Bombin JASSM] Spawn failed!")
        return
    end

    ent:SetPos(centerPos)
    ent:SetAngles(callDir:Angle())
    ent:SetVar("CenterPos",            centerPos)
    ent:SetVar("CallDir",              callDir)
    ent:SetVar("Lifetime",             GetConVar("npc_bombinjassm_lifetime"):GetFloat())
    ent:SetVar("Speed",                GetConVar("npc_bombinjassm_speed"):GetFloat())
    ent:SetVar("OrbitRadius",          GetConVar("npc_bombinjassm_radius"):GetFloat())
    ent:SetVar("SkyHeightAdd",         GetConVar("npc_bombinjassm_height"):GetFloat())
    ent:SetVar("DIVE_ExplosionDamage", GetConVar("npc_bombinjassm_dive_damage"):GetFloat())
    ent:SetVar("DIVE_ExplosionRadius", GetConVar("npc_bombinjassm_dive_radius"):GetFloat())
    ent:Spawn()
    ent:Activate()

    ply:PrintMessage(HUD_PRINTCENTER, "[Bombin JASSM] Missile inbound!")
end)
