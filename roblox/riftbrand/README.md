# Riftbrand — Roblox sword kit

A drop-in Roblox `Tool`: a blade built as a tear in space, with chromatic crescent slashes, a hanging
rift that detonates, afterimage dashes and a crystal-shard ground slam. It needs no uploaded meshes,
decals or animations.

| Input | Move | What it does |
|---|---|---|
| M1 / tap / R2 (hold to chain) | **Prism Cascade** | 3-hit combo: diagonal, reverse, 360° spin finisher. 16 · 16 · 28 dmg |
| Q / ButtonX | **Phase Step** | 26-stud dash in 0.2 s with 6 neon afterimages. Cancels slash recovery. 2.5 s cooldown |
| E / ButtonY | **Rift Tear** | Overhead cleave opens a rift that pulls enemies in for 0.6 s, then detonates (r 14, 38 dmg). 6 s cooldown |
| R / ButtonB | **Prism Nova** | Leap, corkscrew and slam. 8 crystal shards, r 20, 55 dmg. 14 s cooldown |

## Import (1:1)

1. In Studio, right-click **StarterPack › Insert from File…** and pick `Riftbrand.rbxmx` (or `Riftbrand.rbxm`).
2. Press Play. On first run the Tool's `RiftInstaller` puts `RiftbrandShared` in ReplicatedStorage and
   `RiftbrandServer` in ServerScriptService, and the server gives every player the FX listener.
   Nothing else needs wiring.
3. Use R15 avatars. R6 characters get all VFX and damage but no procedural animation.

## How it works

- **RiftAnim**: procedural keyframe animation. It writes `Motor6D.Transform` every `PreSimulation`,
  layered over the default Animator, so legs keep running under slashes. Every client runs the same
  keyframes for every wielder, so everyone sees the animation without any uploaded AnimationIds.
- **RiftFX**: all transient VFX, built at runtime from Beams, Parts, ParticleEmitters, PointLights and a
  ColorCorrection. Everything uses `LightEmission 1` / `LightInfluence 0`.
- **RiftClient**: input, combo buffering, dash-cancel, movement and the cooldown HUD. Moves play locally
  the instant you press.
- **RiftbrandServer**: validation (equipped, alive, cooldowns, rate limits), hitboxes via
  `GetPartBoundsInBox` / `GetPartBoundsInRadius`, damage via `Humanoid:TakeDamage`, team check,
  knockback, and a rebroadcast to other clients.
- **Config**: every number in one place: damage, timings, cooldowns, palette, textures, sounds,
  and the toggles for camera shake, screen flash, bloom, friendly fire and damage numbers.

## Assets

Textures and sounds are `rbxasset://` engine built-ins (`sparkles_main.dds`, `forcefield_glow_main.dds`,
`explosion01_shockwave_main.dds`, `swordslash.wav`, `swordlunge.wav`, `unsheath.wav`), so there's nothing
to upload. If one doesn't show up in your Studio version, swap it for your own `rbxassetid://` in
`Config.Textures` or `Config.Sounds`. `Config.Sounds.Detonate` and `Slam` are empty slots for your own impact sounds.

## Rebuild

`src/` is the source of truth. Build with [Lune](https://github.com/lune-org/lune) 0.10+:

```
cd roblox/riftbrand
lune run build.luau
```

The build checks every property against Roblox's reflection database and writes both model files.
