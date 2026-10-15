# Random Touch: ink wall and one replay button

Palle requested a better-looking abacus with transparent filled circles registering its movement, then clarified: **just a big REPLAY button**. The final interface has exactly one large rectangular replay button. It keeps the hand-only movement and resets the paths and paper after release.

The frame is charcoal, the rods warm metal, and the recording surface pale. Circles use low-opacity filled discs. The first four rows share X positions at different speeds; the fifth records X and Y. Each movement step contributes twelve evenly spaced phase samples. Equal numbers of steps therefore produce identical X marks despite different speeds. Waiting, pausing and the return to centre contribute no ink. Each row retains its latest 576 marks, bounding geometry at five MultiMeshes rather than thousands of nodes.

The installed target source is still uniform. A dense centre in smoothed-path samples does not establish a Gaussian source. A bounded Gaussian comparison is supported in reconstruction code using `Motion.make_record(seed, "gaussian_bounded")`; it uses sigma = range/3 and rejection beyond the range. There is no source selector in the room. [Godot's method documentation](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html#class-randomnumbergenerator-method-randfn) distinguishes range draws from normally distributed `randfn` draws.

Research helpers retain paths, distribution, individual phases and ink in `random-touch/4`, saved separately from previous versions. Full-precision JSON and restoration to the renderer's vector precision preserve the visible circles. These helpers do not add controls to the exhibit.

## Evidence

- [Ink tests](ink-test.log): PASS. Four-speed mark equivalence, X projection in row 5, frame-rate independence, bounded storage, no idle/return stamps, Gaussian bounds and repeatability, record round trips, one large public button and its reset callback.
- [Hand tests](hand-test.log): PASS. Actual XR Tools hand nodes; unchanged body, head, tracked controller and other hand; withdrawal and cleanup.
- [Hall-seed tests](hall-seed-test.log): PASS. Seed propagation, retained records, replay and active-interaction guards.
- Native Godot previews inspected: [installed uniform version](uniform.png), [empty paper](empty.png), [Gaussian reconstruction comparison](gaussian.png). The renderer uses direct script calls to construct the comparison; the room exposes only REPLAY.

The test runtime reports existing Jolt solver-bias and missing-environment warnings. No headset session or independent reconstruction is claimed. The current tutorial, final opening, wall notes, artifact card and plans reflect the changed apparatus. Current tutorial: 1,316 words, 449 nonblank code lines. Rebuild with this directory's `build-tutorial.mjs`.
