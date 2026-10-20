# Matrix size in your hands

Both matrices start at **8 × 8**. The new **MATRIX slider selects 2 × 2 through 16 × 16**. Each panel keeps its footprint; more cells make a finer matrix. There are fifteen integer choices.

## In the museum

The installed Seed Replay console now has a separate resolution slider beside its existing seed and replay controls. Drag MATRIX to change both grids together. The seed, selected extra draw and random-seed generator are retained. Returning to an earlier size reproduces its colours. The selected size also returns with the artifact's saved visit state.

The control itself survives the grid rebuild, so the hand can continue moving it. The original seed slider still controls the seed; its behaviour is unchanged.

## In the tutorial

The printed reconstruction also starts at eight by eight and includes a pink grab handle on a rail. Every mesh, collision and label is built in code. `matrix_slider.gd` is printed in full beside `01_seed_picture.gd` and the unchanged `point_body.gd`; XR Tools remains the declared Day Zero dependency.

Resizing changes the number of requests: 192 RGB draws at 8 × 8, 768 at 16 × 16, with one extra when the right grid discards a value. It preserves the prefix of the colour list, but changes the row width. This is a new arrangement of the same stream, not a zoom into the old picture.

The reflection now names the difference between the two handles: changing a seed varies the colours; changing MATRIX varies how many places can receive them. The tutorial keeps seed, request order and assignment as its focus; the rail is supplied interaction code.

## Checked

- Printed reconstruction passes **36** native Godot checks; grayscale and swapped-channel edits pass **37 each**, including every slider choice, bounds, seed retention, replay and returning to the original picture.
- The track's hand-displacement calculation is checked in a rotated study, including a stationary hand not advancing the handle again.
- Both deliberately broken random-stream variants are still rejected.
- **24 checks pass in the actual museum**, including the live slider driver's signals, fixed panel width/height, saved resolution, draw counts, and agreement between the printed study and installed colours. Five of these are capture-camera checks.

Native screenshots were inspected. These checks supply control movements; they do not certify headset comfort or a physical hand/controller session. The museum log retains its existing UID and renderer warnings. No map layout or other Randomness lesson was changed.

[Tutorial and reflection](parallel.html) · [Tutorial source](tutorial.md) · [Reflection source](final.md) · [Before/after](changes.html) · [Code evidence](tests.json) · [Museum evidence](museum/report.json)
