# Aurora Blade: Roblox sword with VFX

A procedural sword with no asset dependencies. It has a glowing fuller, a 3-hit combo, a swing trail, ember and aura particles, a pulsing light, hit bursts, a slam shockwave and camera shake.

## Install (no Rojo)
1. In Studio, create a **Script** in `ServerScriptService` and paste `src/server/AuroraBlade.server.luau`.
2. Optional: create a **LocalScript** in `StarterPlayer > StarterPlayerScripts` and paste `src/client/AuroraBladeClient.client.luau` for camera shake.
3. Press Play. Everyone spawns with the sword in their hotbar.

## Install (Rojo)
`rojo serve` in this folder, then connect from Studio.

## Controls
Left click to swing. Chain clicks for chop, side slash, then a ground slam with AOE shockwave. The combo resets after 1.2s idle.

## Tuning
Everything is in the `CONFIG` table at the top of the server script: damage, knockback, range, colors and sound ids. Paste `rbxassetid://` ids into `Sounds` for audio. If a swing looks mirrored on your rig, flip the angle signs in `POSES`.
