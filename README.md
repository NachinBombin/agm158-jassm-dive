# agm158-jassm-dive

Garry's Mod addon — **AGM-158 JASSM Loitering-Mode Missile**.

Part of the **Bombin Support** family. A re-skin of the Tomahawk with a **3D model flame trail** instead of particle effects.

## Visuals

- **3D flame model** attached to exhaust — `models/roycombat/shared/trail_f22.mdl`, parented to the missile, follows and rotates with it
- **Dynamic orange glow** — DynamicLight at exhaust position, size 280–380
- No particle emitters — no smoke, no flamelets, no sparks

## Flight personality

| Property | JASSM | Tomahawk | Shahed-136 |
|---|---|---|---|
| **Damage** | **1200** | 1200 | 700 |
| **Blast radius** | **1200 HU** | 1200 HU | 900 HU |
| **Dive speed** | **2200 HU/s** | 2200 | 1800 |
| **Track interval** | 0.1 s | 0.1 s | 0.1 s |
| **Aim error** | ±400 HU | ±400 HU | ±400 HU |
| **Blast effects** | 5 layers | 5 | 4 |
| **Trail** | **3D model flame** | particles | none |

## Required content

```
models/sw/avia/agm158/sw_rocket_agm158_v3.mdl
models/roycombat/shared/trail_f22.mdl
sound/jet/luxor/external.wav
```

## ConVars

| ConVar | Default | Description |
|---|---|---|
| `npc_bombinjassm_enabled` | 1 | Enable NPC calls |
| `npc_bombinjassm_chance` | 0.12 | Probability per check |
| `npc_bombinjassm_interval` | 12 | Seconds between checks |
| `npc_bombinjassm_cooldown` | 50 | Per-NPC cooldown |
| `npc_bombinjassm_min_dist` | 400 | Min call distance |
| `npc_bombinjassm_max_dist` | 3000 | Max call distance |
| `npc_bombinjassm_delay` | 5 | Flare → arrival delay |
| `npc_bombinjassm_lifetime` | 40 | Munition lifetime (s) |
| `npc_bombinjassm_speed` | 250 | Orbit speed HU/s |
| `npc_bombinjassm_radius` | 2500 | Orbit radius HU |
| `npc_bombinjassm_height` | 2500 | Altitude above ground HU |
| `npc_bombinjassm_dive_damage` | 1200 | Explosion damage |
| `npc_bombinjassm_dive_radius` | 1200 | Explosion radius HU |
| `npc_bombinjassm_announce` | 0 | Debug prints |

## Menu

Spawnmenu → **Bombin Support** → **JASSM**

Or run `bombin_spawnjassm` in console for a manual test spawn.

## Credits

NachinBombin
