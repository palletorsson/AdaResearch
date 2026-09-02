# Fractal_MandelbrotSet — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Read before written

Written 2026-09-02 from an agent's reading of every placed script and scene,
with a skeptic pass behind it. Nothing in the text predates the sheet.

- **The field is 9.584 m square, 6% wider than the entire floor**, hanging at
  3.96 m: 10,000 boxes, 100 iterations each.
- **Auto-ground lifts it 3.50 m, driven by two decorative CSG props** at local
  y -3.5 that control nothing; they end up 5.5 m and 1.5 m beyond the floor edges.
- **Jumping re-rolls the fractal.** `_input` fires on `ui_accept`, which is Space,
  which is jump.
- **Walking pans the dive table.** `mandelbrot_dive._input` binds W/A/S/D to
  centre_x and centre_y, the same physical keycodes as movement.
- `mandelbrot_dive` has two grab sliders, four buttons and eleven key bindings;
  the registry says "observe".
- The 100-iteration cap is real and is the room's closing argument: the black
  region is slightly too big, by an amount somebody chose.
- **summary.md, technical.md and critical.md describe Fractals_9.** eye_shot.md is
  six weeks stale.

## Open

- Two input collisions (jump re-rolls, walking pans) are genuine bugs the text turns into warnings. Both are one keybinding away from fixed.
