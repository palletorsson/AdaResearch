# Five rooms after an image

Five original, editable Godot studies responding to the supplied Hatoum, Bałka, McLeod, Hart and Peaches & Pussykrew references. These are independent chapter companions. They have not been placed in the main museum spine, and they are not reconstructions of the artists' works.

Open `project.godot` in Godot 4.6 and run. Day Zero is assumed: this project supplies the room, camera, lights and desktop visitor. It needs no plugins, downloads, accounts, remote textures or museum autoloads.

## Try a room

Choose a room along the bottom. Drag its single slider. Right-drag to move the comparison view; use the wheel to approach. **Walk inside** enables WASD and mouse look. **Esc** returns to the comparison view. **H** hides or reveals the controls. Reset restores the room's first state and camera. Only the pattern garden has automatic movement; it starts paused.

The visitor is a 1.75 m-high capsule, 0.56 m in diameter, with its eye 1.62 m above the floor. This is a declared test body, not a universal human body or an accessibility standard. The passage and room shell have collision. The sculptures, flowers, landscape and platform are visual studies, not climbable or grabbable objects. There is no physical headset integration in this kit.

| Study | Chapter companion | What changes | What stays fixed |
|---|---|---|---|
| A place still held | Array → Tutorial_3D | Corner variation of fragments | 75 positions, 25 rods, seed |
| Who fits through? | Trans_Scale → Trans_Body | Opening, 0.48–1.68 m | Visitor diameter, 2.05 m headroom |
| A world from a cone | Colour / composition | Height of repeated cones | 48 sites, three cones per tree, seed |
| The pattern crosses over | Shader_05_Patterns | Half-cell phase; optional slow drift | Geometry, density, view |
| A body in the plural | Shader_11_QueerRubber → Shader_12_PinkExtravaganza | Six arms unfolding; three heads spreading | Part count, surface rule |

## Where to edit

The five scores are in `artifacts/suspension.gd`, `passage.gd`, `landscape.gd`, `pattern_garden.gd` and `plural_body.gd`. `build.gd` is supplied fabrication apparatus: it makes meshes, tubes and materials. `gallery.gd` supplies viewing and movement. Start with the small experiment in `MAKING.md`; understanding every helper is not the entry requirement.

Each artifact can also be instantiated independently from its `.tscn`. It has an exported `amount` in 0–1 and methods `set_amount(value)` and `set_clock(seconds)`. It does not take over the camera or input. Live `set_amount` rebuilds its children; this is appropriate for deliberate slider changes, not animation at headset frame rate. The pattern clock only updates shader uniforms.

Canonical source is `commons/artifacts/reference_studies/` in AdaResearch. The `artifacts/` folder here is a generated, byte-identical copy prepared by `prepare.py`; the source manifest records that relationship. The downloadable ZIP is independent and editable.

## Representation choices

Lighting is supplied studio apparatus: the room shell receives light but does not cast directional shadows. The artworks do cast shadows. A generated sky supplies metal reflections; it is not a reflection of the actual room. No imported material textures are used. The concrete-like grain is a shader and the fragments are perturbed hexahedra, not fracture physics. The lake is an opaque glossy plane, not simulated water or refraction. The body is a geometric assemblage, not a scan, rig, soft-body simulation or representation of the performers' bodies.

The flower shader projects patterns using world coordinates and blends three projections according to the surface normal. At oblique surfaces those projections blend. Moving the phase changes sampled colour without moving geometry. It is an explicit experiment with coordinates; it is not Hart's production technique reconstructed from a photograph.

## Evidence

`capture.gd` runs the five scenes in the native renderer, saves fixed-camera comparisons and tests the passage with the actual visitor capsule. It checks fixed addresses, counts, restoration, parameter effects and pattern-clock effects. Rebuilt geometry and state must match exactly. Restored rendered images allow less than 0.01 mean error in 8-bit channel units because resource recreation changes a few shadow-edge pixels on this GPU. The numerical error is recorded per room.

Run the capture with Godot using `--path <this project> --script res://capture.gd --xr-mode off`. The report goes in `captures/report.json`. This is software and rendered evidence, not a learner study or headset performance result.

## References

- Mona Hatoum, *Remains to be Seen* (2019): [White Cube](https://www.whitecube.com/gallery-exhibitions/remains-to-be-seen). Concrete-like fragments and rebar in a suspended, aligned structure. Their architectural and political associations matter to the reference.
- Mirosław Bałka: the user's supplied installation photograph. Its exact title, date, dimensions and materials remain unverified. Our passage is an original response to what is visible in that photograph.
- Alex McLeod: the supplied CGI landscape and [MOMENTA's artist page](https://momentabiennale.com/en/artist/alex-mcleod/). The exact supplied work is unverified. Our primitive landscape does not claim to reproduce its production method.
- Claudia Hart, *Inside the Flower Matrix* (2016): [artist's page](https://claudiahart.com/Inside-the-Flower-Matrix-XR-2016). Her pattern-covered flowers and architecture are part of a virtual labyrinth with a specific critique of commercial digital space.
- Peaches & Pussykrew, *Fill the Whole*, CTM 2021: [CTM Cyberia](https://www.ctm-festival.de/festival-2021/programme/exhibition/ctm-cyberia), [FACT presentation and credits](https://www.factmag.com/2021/02/21/ctm-2021-peaches-pussykrew-fill-the-whole/). Our assemblage examines attachment and surface; it does not reproduce their game, likenesses, scans, voice or music.


## Museum placement, 2 October 2026

The study now has an installed museum adapter and an application passage in the book. See the [current spine integration](../2026-10-02-studies-in-the-spine/index.html). This page preserves the earlier companion evidence.
