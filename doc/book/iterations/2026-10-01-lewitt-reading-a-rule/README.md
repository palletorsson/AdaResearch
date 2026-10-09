# Open structures — reading a rule

A standalone Godot study after three photographs of Sol LeWitt structures supplied by Palle. Made on 1 October 2026. The purpose is to discover a small vocabulary that can produce a complicated arrangement, then change that vocabulary deliberately.

Open `project.godot` in the Godot 4.6 environment prepared in Day Zero. The main scene is `study.tscn`. Read `TUTORIAL.md` for the short investigation. This project has no plugins, external textures or museum dependencies.

## Four views

1. **Five forms:** a cube, square-based pyramid, narrow box, truncated pyramid and sheared box, all described by positions and connections.
2. **Twenty-five places:** compare a cyclic choice of form with five identical rows. The addresses stay fixed.
3. **Stacked modules:** compare five bounded height rules on one cross-shaped footprint. Change the footprint to a full square without changing the height rules.
4. **Between the forms:** seven samples between a pyramid and a cube, obtained by changing the size of the upper square.

Right-drag to orbit; use the wheel to move closer. The bottom slider reveals bars in construction order. **Change array rule** operates in views 2 and 3. The numbered view buttons select a study; they are not keyboard shortcuts. Reset view restores the camera.

## What belongs to the learner

Start in `rules.gd`: `shape()`, `form_at()`, `height_at()` and `occupied()` are the small decisions under investigation. The rest assembles and displays their answers. In `open_structure.gd`, `corners()` is the next layer to read: it makes the relation between a number and a corner explicit.

The camera, lighting, interface, square-section bar renderer and MultiMesh batching are supplied apparatus. They reuse the Line lesson's operation of joining two positions, but understanding rendering optimization is not a prerequisite here. There are no invisible solid faces inside the frames and no collision shapes or XR player. These are desktop observations, not a walkable museum installation.

## Attribution and limits

The five-form vocabulary responds to LeWitt's **Five Open Geometric Structures (1979)**, documented by [Lisson Gallery](https://www.lissongallery.com/artists/sol-lewitt/artworks/five-open-geometric-structures?image_id=3605). The stepped structures respond to **Five Modular Structures (Sequential Permutations on the Number Five), 1972**, documented by the [National Galleries of Scotland](https://www.nationalgalleries.org/art-and-artists/313/five-modular-structures-sequential-permutations-number-five). MCA Chicago also catalogues the 1979 artist's book [Open Geometric Structures: Five Geometric Structures and their Combinations](https://mcachicago.org/art-artists/collection/open-geometric-structures-five-geometric-structures-and-their-combinations/).

These are Ada's studies after the images. Dimensions, member thickness, joints, the cyclic 5×5 arrangement and exact height functions are our choices, not recovered historical instructions. One photograph cannot establish concealed connections or uniquely identify the rule that generated an arrangement. The cross-shaped footprint is a working interpretation, not a measured plan of the photographed work. The combination photograph's exact work title and arrangement have not been independently established.

## Evidence and replay

From a terminal with Godot available, run `godot --path . --xr-mode off --script res://capture.gd`. This needs a rendering window. It writes eight native screenshots and `captures/report.json`, checks geometry, repeated addresses and two changes of rule, then exits with a failure code if a check fails. Do not use `--headless` for screenshots.

The recorded Godot 4.6 run passed 27 checks. Screenshots were inspected. These checks establish the specified software behavior, not exact fidelity to LeWitt's objects, a beginner's learning outcome or headset performance.

The most useful curricular home is Arrays: one frame → a row → a choice at each address → a three-dimensional occupancy rule. The current Chessboard study supplies a concrete bridge from `colour_of(x, z)` to `form_at(column, row)`. Individual open forms can appear earlier, after Lines and the cube's corners, with the renderer supplied. Taper and shear need a short explicit bridge; whole-object translation, rotation and scale do not teach them by themselves.


## Museum placement, 2 October 2026

The study now has an installed museum adapter and an application passage in the book. See the [current spine integration](../2026-10-02-studies-in-the-spine/index.html). This page preserves the earlier companion evidence.
