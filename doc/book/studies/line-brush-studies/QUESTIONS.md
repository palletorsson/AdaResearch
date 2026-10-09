# One gesture, six constructions

These are proposed comparisons for the standalone study, not observations from a completed learner trial. Keep one stored freehand centreline and derive six views: fine round line, flat opaque ribbon, tapered loaded stroke, twisted ribbon, transparent wash and dry brush with shader gaps. Record each view's construction and changed parameters.

## Questions to carry into the build

- **What belongs to the gesture?** Keep position order and stroke breaks fixed when switching views. Which apparent changes in speed, force or hesitation come entirely from width, orientation or opacity? A tapered ending can suggest lift without recording any lift or pressure.
- **When does a line acquire a face?** Compare the fine round section with the flat ribbon. Inspect the same bend from the front and from its edge. Width, section and triangle count are separate choices; a ribbon can have width while retaining zero geometric thickness.
- **What does “loaded” mean here?** Name the rule that varies width or coverage along the stroke. Unless explicitly simulated, there is no reservoir losing pigment, bristle deformation, liquid transport, drying or absorption into a support. Which visual cues remain convincing once that rule is exposed?
- **What turns with the hand?** Twist the ribbon's local section while retaining its centreline. Does a dark edge follow geometric orientation, lighting or a painted colour rule? A procedural twist is not a measurement of wrist rotation.
- **Where is the opening?** Compare wash opacity with dry-brush masking. Alpha blending and shader discard change visible coverage; neither removes mesh triangles or opens a collision shape. Mesh connectivity, rendered coverage and collision must be inspected separately.
- **What did sampling leave out?** Increase the spacing between accepted positions. Where do tight turns straighten or small loops disappear? Interpolating between retained positions can fill intervals but cannot recover an unrecorded movement.

## Four proposed visual tests

1. **Side view:** capture the same straight section and bend front-on, at 45 degrees and nearly edge-on. Pair round, flat and twisted sections at fixed width, camera distance and lighting. Show that a two-sided ribbon can remain visible from behind without gaining thickness.
2. **Same gesture, material switch:** lock camera and stored points; capture opaque, wash and dry versions of the same ribbon geometry. Show the centreline/sample count beside each. Separately label the round, tapered and twisted variants as geometry changes.
3. **Sample spacing:** derive three spacings from one dense recorded input; keep the original untouched. Overlay accepted points and report their counts. Use a tight loop plus a sharp bend so lost detail is visible at one fixed camera pose.
4. **Overlapping coverage:** cross two strokes of different colours at distinct depths. Compare wash and dry coverage from both sides, then reverse creation order. Inspect overlap colour, visible background and any transparency sorting changes; do not describe compositing as pigment mixing.

## Student lineage and bodily stakes

[Trace](../../../../commons/maps/Point_Trace/tutorial.md) supplies ordered positions and a distance gate; [Triangle](../../../../commons/maps/Point_Triangle_Context/tutorial.md) separates boundary from face; [Primitives](../../../../commons/maps/Primitives_Ignorance/tutorial.md) separates generated positions from their display; [Color](../../../../commons/maps/Color_Paint/tutorial.md) asks where a mark is received; [Shaders](../shader-skin/README.md) computes surface appearance. [Painting space](../painting-space/README.md) and [Borrowed outlines](../glyph-form-atlas/README.md) supply the neighbouring comparisons.

The desktop brush records a constrained pointer gesture, not pressure input or tracked XR motion. Ask whose small movements the spacing threshold preserves, and whether a default taper assigns expressive force the person never supplied. The QFEP question stays operational: which variation is retained, suppressed or introduced by each rule? Headset use, learner interpretation and physical paint fidelity remain separate investigations.
