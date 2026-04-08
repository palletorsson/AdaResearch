# Making Algorithms Visible

You are improving the visual quality of algorithm artifacts in Ada Research — a VR project where learners stand inside mathematical ideas and watch them run.

There are ~600 artifacts. Most are algorithmically correct but visually dead. Your job is to make them alive.

---

## What You're Working With

Each artifact is a Godot 4 scene (`.tscn` + `.gd`). It extends Node3D, builds itself procedurally in `_ready()`, and runs its algorithm in `_process()`. The learner stands at arm's length in VR and watches.

The code works. The algorithms are right. What's missing is the layer between "correct simulation" and "thing you can understand by looking at it."

## What "Alive" Means

An alive artifact answers five questions without the learner having to think:

1. **What moves?** — One thing should be obviously the protagonist. It glows brighter, it's a different color, it leaves a trail. Your eye goes there first.

2. **What holds?** — The structure, frame, or constraint that shapes the motion. It should be visible but quieter — present without competing. A warm muted tone, subtle emission.

3. **What connects?** — The invisible relationships. Joints, forces, springs, constraints. These are the *reason* the motion looks the way it does. They must become visible — glowing markers, drawn lines, color-coded endpoints.

4. **Where has it been?** — Algorithms unfold over time. A trail is not decoration — it IS the algorithm made visible. A pendulum without a trail is just a ball. A pendulum with a trail is a diagram of harmonic decay.

5. **What does the number say?** — Every algorithm has a critical parameter. Show it. A velocity, an angle, a distance, a force magnitude. The learner should be able to read the number and connect it to what they see.

## How to Think About Each Artifact

Don't start with "what code pattern do I apply." Start with:

**What is the story this algorithm tells?**

A chain swing tells the story of resonance — small periodic inputs creating large oscillations through a chain of constraints. The visual should make resonance *obvious*: the trail gets wider when the driving frequency matches the natural frequency. The joint markers pulse. The info label shows amplitude growing.

A drawbridge tells the story of a motor fighting gravity through a single hinge. The visual should make the constraint *architectural* — warm stone, mechanical precision, the satisfying arc of the bridge tip traced in space.

A ragdoll tells the story of intention emerging from pure mechanics. The visual should make it slightly uncanny — the leg moves "like a leg" even though nothing is trying to be a leg. The color should be warm, organic, almost fleshy.

**Every artifact has a story. Find it. Then make it visible.**

## The Palette

Not a rigid rulebook — a starting vocabulary:

| Role | Color | Why |
|------|-------|-----|
| Primary mover | Cyan-teal | Cool, electric, draws the eye |
| Constraint/joint | Orange | Warm complement to cyan, reads as "mechanism" |
| Anchor/fixed | Yellow-gold | Suggests solidity, warmth, ground truth |
| Frame/structure | Cool gray or warm amber | Recedes but present |
| Trail | Mover color at 30% alpha | Ghost of the mover's history |

Use emission on everything the learner should notice. The energy scale communicates hierarchy:
- Structural frame: 0.5 (barely glows)
- Active bodies: 1.0-1.5 (alive)
- The protagonist: 2.0 (unmistakable)
- Markers and indicators: 2.5+ (read as annotation)

## The Trail Is The Algorithm

This deserves its own section because it's the single most important visual element.

A screenshot of a physics simulation without trails shows you nothing. You see objects at one moment in time. You have no idea what they were doing a second ago or what they'll do next.

A trail turns time into space. The pendulum's trail IS the harmonic function. The orbit trail IS the gravitational relationship. The crank rod's trail IS the Fourier component.

**Trail the interesting position.** Not the center of mass — the foot of the ragdoll, the seat of the swing, the tip of the rod, the outer edge of the bridge. The position that moves most, that traces the most expressive curve.

## What To Do With Each Artifact

1. Read the code. Understand the algorithm. What moves, what's fixed, what's the critical parameter?
2. Read the `@identity` block. It contains the poetic truth. If there's no identity block, write one.
3. Decide: what's the story? What should the learner see first, second, third?
4. Replace flat materials with emissive ones. Assign colors by role.
5. Add a trail on the most expressive position.
6. Add markers at invisible constraint points.
7. Add a Label3D showing the critical number.
8. Capture a screenshot. Does the screenshot tell the story? If not, iterate.

## Screenshot Pipeline

The project has a full capture pipeline that outputs to the encyclopedia's `scene-catalog/` directory.

### Batch (all scenes)
```bash
python commons/testing/batch_capture_all_scenes.py
```
Reads `scene-catalog.json`, captures every scene to `ada_encyclopedia/public/scene-catalog/`. Skips existing PNGs. Auto-restarts on crashes. This is the authoritative pipeline — run it after visual improvements to update the catalog.

### Per-artifact (3 zoom levels + 4 angles)
```bash
godot --path . --xr-mode off --no-window \
  --script res://commons/testing/capture_multi_angle.gd \
  -- --mode=artifact --target=LOOKUP_NAME
```
Outputs to `user://multi_shots/<target>/`. For each of 4 angles (front, left, right, top), captures 3 zoom levels: `_far` (1.4x), `_mid` (1.0x), `_close` (0.65x). Default image uses the wide shot. Disables any cameras the artifact creates to ensure the capture camera controls framing. Skips ground plane for scenes with their own `WorldEnvironment`.

### Single shot
```bash
godot --path . --xr-mode off --no-window \
  --script res://commons/testing/capture_tscn_shot.gd \
  -- --scene=res://PATH.tscn --ground=false --wait=4.0 \
  --out=OUTPUT_PATH.png
```

### Key details
- Scenes with `CaptureCamera` child nodes use their artist-placed angle
- AABB-based framing at 1.0x max dimension (fills the frame)
- Wait 3-4 seconds before capture so trails have time to build
- Artifact cameras are disabled so the capture camera controls the shot

## What "Done" Looks Like

A done artifact tells its story in a screenshot. You look at it and you know:
- What's the protagonist (brightest, trailing)
- What's the structure (quieter, framing)
- What's the constraint (orange markers at invisible joints)
- What happened over time (the trail's shape)
- What the critical number is (the readout)

And in VR, you stand in front of it and the algorithm *teaches itself to you* because the visual hierarchy matches the conceptual hierarchy.

## The Registry

After visual improvements, update `commons/artifacts/registry/*.json` with proper metadata:
- `description`: 5-layer description from @identity
- `qfep_connection`: where in E = F + lambda * phi * dE
- `capacity`: "VERB what_learner_can_do_after"
- `interactions`: what the learner can trigger
- `tags`: 5-10 keywords
- `footprint`: real AABB from capture output

Use `/ada-artifact-improver auto` for batch metadata work.

## Current State

| Sequence | Avg Score | Status |
|----------|-----------|--------|
| joints | 7.0/8 | visually upgraded + metadata done |
| foundationscrisis | 4.5/8 | gold standard template |
| physicssimulation | 4.5/8 | partially done |
| forces | 3.7/8 | 15 improved |
| graphtheory | 5.3/8 | metadata done |

Run `python tools/heat_map_generator.py` for the full priority list. Lowest-scoring sequences with the fewest artifacts are the quickest wins.
