# Ada Research → s&box VR Test Scene

A minimal [s&box](https://sbox.game/) (Source 2, C#) project that rebuilds an Ada
Research map for VR — driven by the **same `map_data.json`** the Godot project uses.
`AdaMapBuilder` parses the 3-layer grid (structure / utilities / interactables) at
runtime and constructs the world, so the map stays data and the engine is swappable.

The bundled map is **Tutorial_Start** ("the absolute beginning — just one cube and
an exit"): a 3×3 plate, spawn pad, pulsing teleporter, and the animated trio
(`rotating_cube`, `oscillation_cube`, `rotation_oscillation_cube`).

## What's here

```
AdaVRTest.sbproj                     s&box project (VR + Keyboard control modes)
Assets/scenes/ada_vr_test.scene      VR rig: VRAnchor player, Both-eye camera with
                                     Head pose, Left/Right hand tracked objects
Assets/maps/tutorial_start.map_data.json   verbatim copy from commons/maps/Tutorial_Start
Code/AdaMapBuilder.cs                map_data.json → world (grid columns, lighting,
                                     spawn, teleporter, artifacts)
Code/AdaVRPlayer.cs                  locomotion: VR smooth-move + snap turn,
                                     desktop WASD fallback, ground clamp
Code/AdaAnimatedCube.cs              the three tutorial artifacts (rotate/oscillate/both)
Code/AdaTeleporter.cs                `t` utility — proximity pad, loops to spawn
Code/AdaMapData.cs                   embedded map fallback
```

## Running it

1. Install **s&box** from Steam (it's free in dev preview) and SteamVR / an OpenXR
   runtime for your headset (Quest via Link/Steam Link works).
2. Launch s&box → **Open Project** → select `AdaVRTest.sbproj`
   (copy this folder OUT of the Godot repo first if you prefer; it's self-contained).
3. The editor compiles `Code/` automatically. Open `Assets/scenes/ada_vr_test.scene`
   and press **Play**.
4. **With a headset connected** s&box renders to it (camera `TargetEye: Both` +
   `VR Anchor` on the player). **Without one**, you get a desktop fallback.

### Controls

| Mode | Input | Action |
|---|---|---|
| VR | Left stick | Smooth locomotion (gaze-relative) |
| VR | Right stick | 30° snap turn |
| VR | Walk into green pad | Teleporter (loops to spawn) |
| Desktop | WASD | Move |
| Desktop | Hold RMB + mouse | Look |

## Mapping notes (Godot ↔ s&box)

- Ada grid: 1 cell = 1 m, Y-up. Source 2: inches, **Z-up**. `MetersToUnits = 39.3701`;
  grid col → +X, grid row → −Y, height → +Z.
- Structure heights render as scaled `models/dev/box.vmdl` columns with colliders
  (checkerboard greys — the grid is the aesthetic in sequences 1–6).
- `lighting` block → `DirectionalLight`; `settings.background.color` is the camera
  clear color set in the scene.
- Utilities: `s`/`sp` → spawn pad, `t` → teleporter. Everything else logs
  "not implemented" and is skipped.
- Interactables: the three tutorial cubes are ported; **any other artifact token
  becomes a magenta placeholder cube** — the 750+ Godot artifacts are code, not data,
  so each needs its own C# port.

## Trying another map

Copy any `commons/maps/<Name>/map_data.json` into `Assets/maps/` and point the
`Ada Map` GameObject's **MapFile** property at it (or edit the default in
`AdaMapBuilder.cs`). Structure, spawn, teleporters and lighting will build;
unported artifacts show as placeholders.

## Caveats

- Scene/API surface checked against Facepunch's `sbox-scenestaging` `test.vr.scene`
  (VRAnchor / VRTrackedObject / TargetEye) as of mid-2026 — s&box is pre-release and
  APIs churn; if a component fails to compile, the editor's error list will point at
  it and the fix is usually a rename (e.g. joystick input access in `AdaVRPlayer`).
- Hands are simple tracked cubes, not the cloud `vr_hand` models, to keep the
  project dependency-free.
- No physics-based character: locomotion is anchor translation + a downward trace
  ground clamp. Fine for a 3×3 test plate; a real port would use a proper controller.

## Sources

- https://sbox.game/dev/doc/systems/vr/ — official VR doc (VR Anchor, VR Tracked Object, eye targets)
- https://github.com/Facepunch/sbox-scenestaging — `Assets/Scenes/Tests/test.vr.scene` reference rig
- https://sbox.game/news/scene-system — scene system announcement
