# Noise Inside Noise — borrow an address

Accepted 13 September 2026. Illustrated review: `/research/possible-bodies/noise-inside-noise.html`. Next development target: **Noise_Space_10**. This review covers one hall.

## The preserved work and the new comparison

The original hall has two placements: dark_sphere at (3,3) and noisesphere at (5,5). Both remain; the sphere moves to (6,5) and selects `noisesphere:180#stand:warp`. The large legacy scene and its value-noise shader are unchanged. A baseline capture in an isolated museum plan showed the old offset dome extending far outside the hall. That shader did not implement coordinate warping. The optional stage retains its original sphere node as the direct member of a matched pair, using a private copy of its mesh resolution; the second sphere, plates and grid belong to this artifact.

The stage declares a FastNoiseLite Value base (seed 4, frequency 1.2) and two Perlin displacement components (seeds 19 and 47, frequency .45), all FRACTAL_NONE. The same CPU sampler evaluates images, witness coordinates and sphere vertices. q = p + amount × displacement(p); the result is base(q). This is a new declared realization, not the legacy shader's field. Strengths are 0/.35/.8/1.4, and the state stays still between actions. WARP changes strength, SAMPLE changes witness only, RELIEF changes output mapping, ZERO returns strength to zero. No clock-stop control is invented.

Each image has 9,216 cell-centre samples in [-4,4]², top row positive z. The coordinate witness draws nine lines per axis in the central [-2,2]² region, 32 segments each, alongside their displaced versions and a selected link: 2,306 line vertices. Five sphere directions provide numerical witnesses. Sphere direction x/z × 3 is the 2D input, omitting y. The authored 128 radial segments and 64 rings produce 8,514 rebuilt vertices. SKIN radius is .94 m; RELIEF radius is .94 + .16 × value. Mesh colours and normals are rebuilt; the flat images keep their values through RELIEF. These sphere surfaces have no collision. Their floor and plinths do.

The low instrument case is tilted 55 degrees. Its shared readout prints p, q and both samples, with yellow/pink witnesses on the images and yellow points on the bodies. The independent orb remains unchanged, including its elapsed-time pulse. Material and state ownership stay local to the study.

## A missing hall and a route around its history

The sequence JSON and book included this hall after Noise_6_Wall, but map_authored and both live/shipped museum plans skipped it. The acceptance run uses an isolated plan containing the new row; the exact accepted row is then installed in both plans. Only this hall is inserted. Noise_Space_10 remains the next development target; it is not yet in the live museum plan.

Every old structure cell and utility is preserved. An east wall column brings the cropped map to its declared 13 m width; the optional stage floor and museum-only aprons provide access. A new ground row at z=13 links x=7..11 around the original wall at (8,12), retaining the elevated landing and t at (7,12). The map now uses its declared 14 m depth. The hall's museum artifact placement follows its map coordinates.

Earlier route failures exposed a height-sensitive gap: a graph flood without heights could reach the exit while the actual walk model could not descend from the old raised landing. The last failed run and cell-by-cell reachable/height record are preserved in route-diagnostic/. The accepted route is level around that structure. No global traversal rule was relaxed.

## Evidence

Runner: ada_run/review_inside.py. Acceptance: ada_run/inside_full_acceptance.gd. Latest receipt: ada_run/inside-review-2026-09-13/run.json. PID **11036**, 2026-09-13T14:56:26+02:00 to 2026-09-13T14:56:50+02:00, exit 0, **42 checks, zero failures**. Fingerprinted sources and original saved necklace hand unchanged. This was an owned hidden/offscreen rendered Compatibility run with XR disabled; the prelaunch inventory contained no other Godot processes.

At zero, all 9,216 image samples and image bytes match. At each nonzero preset, all 9,216 samples differ beyond 1e-5 while the direct baseline stays unchanged. SKIN meshes are equal at every strength. RELIEF retains image bytes and computes every actual output vertex from its sampled value; maximum geometric error is 4.10e-7 m. ZERO restores equal relief meshes. SurfaceTool can reorder vertices while regenerating normals: the verifier derives direction from each actual output vertex rather than assuming the input index order. An earlier test's index assumption was corrected, not hidden by loosening the tolerance.

All four controls pass through the real desktop pointer using synthetic mouse events. SAMPLE retains field values, marker p/q positions agree, and local controls leave an unconfigured legacy instance unchanged. The body walks the side apron from local z=6.1 to 11.93335 at x=1.5 (including the 4 m vestibule). It then follows the east passage to z=17.49999 and turns west to x=8.225273 while remaining at ground height. The museum's height-aware route is connected. This checks the local passage plus route graph, not a headset session through the entire sequence.

Captures: skin_0..3, relief, instrument, readout, orb, plan; direct_0..3 and warped_0..3 are the exact generated 96×96 images. The skin_2/relief photographs have the same camera and amount .8. The web sample viewer uses recorded data and overlays exact coordinates; it does not simulate Godot or read interpolated screenshot colours as numerical samples. The overhead view resets to .8/SKIN/sample 1 after controls.

before/ preserves old texts, sources and shared data. baseline/ preserves the rendered legacy hall. Browser, publication and static verification receipts live beside this README. Headset comfort, reach, legibility and Quest performance remain deferred.

## Book and further work

final.md, tutorial, technical, critical, summary, blurb, intent and artifact inventory are aligned with the implemented controls. Old claims of recursive warp controls and organic guarantees are replaced with an inspectable one-pass coordinate composition. Two primaries and anchors: noisesphere, dark_sphere. Old walked/eye-shot records are marked historical.

The reusable principle is a shared sampler with separate interventions on input address and output use. Return-to-zero exposes a reference state; one numerical witness connects the image and body without claiming their sampling grids coincide. Keep engine defaults and omitted coordinates inspectable. Future iterations, time animation, editable seeds and collision deformation remain proposals.
