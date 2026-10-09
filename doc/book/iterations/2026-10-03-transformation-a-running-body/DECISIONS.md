# Trans_Pre — a running body

The previous tutorial placed three copies. This tutorial keeps one copy and changes its transform over time. It follows the museum's cumulative still / slide / turn / pulse progression, using one code-created cube with a face mark so that its orientation can be followed.

The author changes `stage` and restarts. No new switch, input handler or interface is needed to teach the operation. The local teaching contract records prerequisites, what the learner owns, what is supplied and what is deferred. The early Coordinates starter revision remains pending; these local lessons do not certify the old numeric taxonomy.

## Source and reduction

- `commons/maps/Trans_Pre/map_data.json` sets the pickup artifacts to `motion_curve:lerp`.
- `commons/scenes/mapobjects/pick_up_cube.gd` uses `pingpong(time / duration + 0.5, 1.0)` for height and size, and adds rotation at a rate multiplied by delta.
- The student version uses local positions in one unscaled study frame. The height range, turn rate and scale factor are declared separately. Writing a scale from Vector3.ONE each frame prevents unintended compounding.
- The production cube's DNA, material effects, rewards, player detection and collection are excluded from this first motion lesson. The code-created marker adds a visible orientation reference. There is no implicit collision or pickup in this study.
- `marked_cube.gd` supplies the mesh and material; `motion_readout.gd` observes the values without driving them. The source is included. The scene provides the existing room, player, backdrop and plinth.

The original tutorial is preserved exactly in `tutorial-museum.md`. The critical `final.md` and live museum configuration have not changed.

## Sine comes in as a small comparison

The 3 October subject register explicitly permits a first usable sine example here, before the Wave Functions sequence. The older map intent proposed deferring it. The newer teaching decision is implemented as a separate, short `tutorial-sine.md`, linked after the main study. It replaces only the normalized progress expression at stage 1. The position range, starting midpoint, endpoint times and full period remain fixed. The difference is the velocity between them.

The comparison does not claim that the museum changed to sine. It establishes two controls the student can use now: duration and extent. Circle derivation, phase and wave combinations remain for the later return.

## Technical references

The native runs check the actual printed substitutions, endpoint timing, uniform scale, rotation periods, frame partition independence, unchanged mesh data and the bounds of the sine comparison. A cold extraction tests the ZIP's dependencies. The room images and eight-second movie are rendered in Godot from those lesson objects. The film uses fixed simulation steps at 30 Hz; it is not a headset recording or a performance benchmark.

Godot's versioned references: [global functions, including pingpong, lerp and sin](https://docs.godotengine.org/en/4.6/classes/class_@globalscope.html), [Node3D rotation](https://docs.godotengine.org/en/4.6/classes/class_node3d.html#class-node3d-method-rotate-y). In this study the parent has no rotation, so its vertical Y axis also matches the room's. General frame and rotation composition are deliberately deferred.

Physical headset use and beginner comprehension remain untested. The browser policy blocks inspection of local file pages; the generated review's local links and anchors are checked programmatically, and the native Godot images are inspected separately.

Next: Trans_Introduction, keeping the distinction between an animated visible surface and one that carries a body across a gap.
