# Coloured lines and light dots

Open `draw_lines.tscn` and run the current scene (F6). The dedicated download starts in this scene automatically; the source project's normal main scene remains the six-construction gallery.

The same drawing has two forms: a thin coloured tube follows each stroke, or separate luminous spheres mark distance samples along it. A single click is retained as one point in either mode. Strokes keep their positions and colours when the representation changes.

## Draw

- **C** clears the example. **Left-drag** draws; release to lift the pen. **Click** leaves a single point.
- **B** switches between coloured lines and light dots; **1 / 2** select them directly.
- **X** changes the next stroke's colour. **[ / ]** change line thickness and dot size.
- **Right-drag** orbits. **Wheel** changes camera distance. **Shift + wheel** moves the drawing plane in depth, including during a stroke.
- **S** switches between 0.085 m and 0.16 m rendering intervals. The retained input path is unchanged.
- **G** toggles screen glow. The luminous spheres remain when glow is off; they do not illuminate other objects in this study.
- **Z** undoes the last stroke, clear, preset switch or load. **P** cycles the authored examples; **R** restores the current one.
- **F5 / F9** save and load positions and colours in `user://line-dot-drawing.json`. This is separate from the six-construction gallery's save. Brush size, camera and drawing mode are viewing choices and are not saved in that file.

The starting portrait is an authored example. Drawings made in this scene use the mouse and a camera-facing plane; orbiting or moving that plane introduces depth. A tracked hand could supply positions in another way, but that input is not implemented here.

The view deliberately omits the plinths and wider gallery. Input storage and rendered geometry retain the parent study's limits: 1,600 recorded positions, 24 strokes, 512 distance samples per stroke and 4,096 across the drawing. The display announces reduced detail for very long paths. Narrower detail cannot restore a bend that was never recorded.

The colour of each line is unshaded, so it stays legible without scene lighting. The dots use a luminous surface and optional screen glow. Neither construction is a mathematical point or a zero-width line: each needs finite geometry to become visible.
