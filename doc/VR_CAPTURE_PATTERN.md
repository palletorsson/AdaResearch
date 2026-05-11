# VR Capture Pattern

> *How to mock a VR scene in headless Godot so the chamber/DNA auto-research pattern works on gestures, hand-interactions, and other XR-only systems.*

The chamber and DNA galleries were built around artifacts that exist in **world space** — drop them in a scene, capture from a fixed camera. **VR-only systems were a blind spot** until 2026-05-11: gestures, two-handed interactions, controller-relative behaviours, anything that requires a player rig to produce. They were essentially un-evaluable from remote.

This doc captures what we learned in the orb gesture slice (commits `7229816`, `9ceee83`) about making VR-only systems still-captureable — and where the limits of the technique are.

---

## When to use this pattern

Use the VR capture rig when:

- The artifact under review *only exists when the player rig is present* (gestures, hand-tracked interactions, controller poses, body-relative spawn points)
- You want a side-by-side DNA-style comparison of variants (mode A vs mode B, before vs after, foe vs friend at-contact)
- The reviewer is remote, or you want to iterate faster than a VR session allows
- The visual is needed for a blog post, documentation, or proposal

Do **not** use this pattern when:

- The system's truth is in *felt presence* (haptics, gestural timing, body-knowledge) — the headset is irreducible
- The interaction is multi-modal in ways the still can't capture (audio cues, sustained engagement, peer-to-peer in multiplayer)
- The bug under investigation is *kinetic* — frame timing, latency, jitter

The rig produces stills, not felt experience. The headset remains the source of truth.

---

## The six lessons

### 1. The player rig is fakeable

A small sphere + cylinder + two posed hands + camera mimic the spatial relationships of a real XR rig well enough for evaluation. The headset never has to plug in.

```gdscript
VRCaptureRig.build_player_figure(root)
# head sphere at (0, 1.62, 0), torso cylinder at (0, 1.20, 0)
```

The figure faces -Z. Hands you pose separately at controller positions.

### 2. Hand meshes load if you skip the scripts

The XR Tools full hand scenes carry `hand.gd`, which depends on `XRToolsUserSettings` autoload. The project's custom hands at `commons/body/hands/*.tscn` depend further on `GameManager`. Neither will initialise in headless capture.

**Load the `.gltf` directly:**

```gdscript
const LEFT_HAND_GLTF := preload("res://addons/godot-xr-tools/hands/model/Hand_Nails_low_L.gltf")
const RIGHT_HAND_GLTF := preload("res://addons/godot-xr-tools/hands/model/Hand_Nails_low_R.gltf")
```

You get the skinned mesh + skeleton in rest pose. No scripts, no autoload chain. Same mesh the player sees in VR.

### 3. Mirrored meshes need mirrored bases

The right-hand mesh is intrinsically mirrored from the left. If you apply the same basis to both, the right's geometry mirrors back to look like a second left hand — they overlap visually.

The fix in `hand_basis`:

```gdscript
# Mirror right hand 180° around Y so its natural-side palm faces inward.
if not is_left:
    b = b.rotated(Vector3.UP, PI)
```

For a two-handed cupping gesture, the LEFT hand's palm should face +X and the RIGHT hand's palm should face -X. Use `roll = +1.0` for left, `roll = -1.0` for right.

### 4. Animation players must be stopped

Hand models default to a mid-grip blend animation. If you don't stop the AnimationPlayer, the skeleton will be mid-pose when you capture.

```gdscript
static func stop_animation_players(node: Node) -> void:
    if node is AnimationPlayer:
        (node as AnimationPlayer).stop()
        (node as AnimationPlayer).process_mode = Node.PROCESS_MODE_DISABLED
    for c in node.get_children():
        stop_animation_players(c)
```

`pose_hand()` calls this on every instantiation.

### 5. Elevated 3/4 separates what front-on collapses

When two hands flank an orb, a front-on camera puts them along the same line of sight — the orb occludes one. An **elevated 3/4 view from above and to the side** maps the X-axis stance into vertical screen offset, separating the hands visually.

```gdscript
var cam := VRCaptureRig.default_elevated_camera()
# camera at (1.30, 2.10, 0.35) looking at (-0.05, 0.85, -1.40)
```

Use `build_camera(pos, target, fov)` for custom angles.

### 6. Capture-only visual aids are honest

The orb's production design has an *invisible* cone of effect — only the sphere + OmniLight + per-creature visual response. For the still, the cone needs to be legible.

**Solution: a translucent cone mesh added in the capture rig, not in production.**

```gdscript
var cone := VRCaptureRig.build_cone_visual(
    orb_origin, orb_dir, length, mode_color)
root.add_child(cone)
```

This is the keep-honest principle: visual aids live in the capture rig, never creep into the production substrate. The slice's design rule (no UI, no toasts, audiotactile + creature-visual change only) stays intact. The capture is *about* the design, not a vote on it.

---

## Minimal usage

A complete capture script following the pattern:

```gdscript
@tool
extends SceneTree

const MY_ARTIFACT := preload("res://commons/...my_artifact.tscn")

func _init() -> void:
    DirAccess.open("user://").make_dir_recursive("my_runs")
    await _capture("variant_a")
    await _capture("variant_b")
    quit()

func _capture(variant: String) -> void:
    var root := Node3D.new()
    VRCaptureRig.build_environment(root)
    VRCaptureRig.build_player_figure(root)

    # Pose hands (example: two-handed gesture)
    var left_pos := Vector3(-0.20, 1.30, -0.50)
    var right_pos := Vector3(0.20, 1.30, -0.50)
    var forward := Vector3(0, -0.55, -1).normalized()
    VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF,
        left_pos, VRCaptureRig.hand_basis(forward, +1.0, true))
    VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF,
        right_pos, VRCaptureRig.hand_basis(forward, -1.0, false))

    # Place artifact under test
    var artifact: Node3D = MY_ARTIFACT.instantiate()
    artifact.position = (left_pos + right_pos) * 0.5
    root.add_child(artifact)

    # Camera
    root.add_child(VRCaptureRig.default_elevated_camera())

    # Replace scene + settle
    var prev := current_scene
    get_root().add_child(root)
    current_scene = root
    if prev != null:
        prev.queue_free()
    for _i in range(60):
        await process_frame

    # Capture
    var img: Image = root.get_viewport().get_texture().get_image()
    img.save_png("user://my_runs/%s.png" % variant)
```

---

## What this pattern CAN'T do

The rig produces stills, not VR. Out of scope:

- **Felt presence.** The body-knowledge of holding palms together far from the head is gone. No haptic, no proprioception.
- **Gestural timing.** Capture is one frame. The 0.3 s sustain that gates orb formation is invisible in a still; the 1.2 s cooldown after a one-handed burst is invisible.
- **Audio cues.** The orb's mode-keyed hum, the chord shift on contact — all gone. Audiotactile feedback can't be captured in PNG.
- **Multiplayer or peer-to-peer.** No support for showing two players' gestures interacting.
- **Real lighting balance.** Headset rendering has different exposure/tonemapping than headless RGB. Production light energies may need to be dimmed for capture (the orb rig does this).

For these, the headset remains the truth source. The rig's job is to make the cheap iterations cheap — *most* of the design work can happen on stills, *some* must wait for VR.

---

## How this fits the project's auto-research pattern

The cognitive-water sieve applied to the VR capture pattern:

- **Thickens?** Yes. Turns a one-off into a reusable capability for the DNA/chamber pattern. VR-only systems can now be evaluated by the same review loop as any other artifact.
- **What is foreclosed?** The temptation to evaluate VR systems purely from stills. The doc above is explicit about what can't be captured; without that caution, the rig would erode toward "good-enough-for-shipping" and the felt-truth would atrophy.
- **What lives in the dark spot?** The felt experience itself. The rig deliberately can't reach it, and *that's the design.* The headset is the dark spot — the place where the design either lives or doesn't, in a way no still can confirm.

The pattern passes the sieve cleanly *as long as it's used with this discipline*: stills accelerate the cheap loop, the headset closes the loop.

---

## Future extensions

Captures we could now build easily:

- **`capture_bracelet_rotation.gd`** — three stones cycling, mode-color shifting
- **`capture_voxel_placement.gd`** — cube spawned at cardinal neighbour
- **`capture_wedge_placer.gd`** — walkable prism ghost + placed wedge
- **`capture_pylon_interaction.gd`** — when pylons exist, the gesture-against-pylon
- **`capture_cord_trails.gd`** — when trails exist, the tapestry-on-floor

Each in 30–50 lines instead of 200, by extending the rig where needed (new helpers in `vr_capture_rig.gd`) and keeping the per-artifact script thin.

---

## Pointers

- Rig: `commons/testing/vr_capture_rig.gd`
- Reference usage: `commons/testing/capture_orb_gesture.gd`
- Worked example output: `/orb-gesture/two_handed.png`, `/orb-gesture/one_handed.png` (encyclopedia)
- Slice context: `doc/ORB_GESTURE_SLICE.md`
- Philosophical context: `/blog/2026-05-11-cognitive-water` and the trilogy
