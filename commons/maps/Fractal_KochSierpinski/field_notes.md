# Fractal_KochSierpinski — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Read before written

Written 2026-09-02 from an agent's reading of every placed script and scene,
with a skeptic pass behind it. Nothing in the text predates the sheet.

- **The spawn is inside solid geometry**: 5 cm inside the pyramid's base slab,
  which occupies y 1.0 to 2.0 at the floor centroid.
- **`sierpinski_pyramid` builds 1296 leaves, not the 625 the registry states** —
  `_recursive_build` makes six calls, so depth 4 is 6^4. It is the only solid
  object in the room, with 1296 StaticBody3D pairs.
- **`sierpinski_triangle` is 10 m wide in a 13 m room**, out through two walls and
  3.8 m under the floor, with zero collision.
- **`fractal_koch_curve` at depth 4 measures the same bounding box as depth 0**,
  because the spikes are built pointing inward. The text uses this as the honest
  demonstration of infinite perimeter in a finite box.
- **`koch_curve_3d` draws 2304 cylinders of radius 0.20 m on a 4.712 m curve**;
  the registry's own note says iterations 3 to 6 are one photograph.
- `cube_cabin` and `cube_bookshelf` are 31 and 12 hard-coded boxes, with no
  subdivision and no recursion despite both descriptions.
- `box_counting_dimension` measures 1.585 off 8000 points and agrees with the
  arithmetic. It is the room's one genuine measurement.
- The teleporter is in a hole.

## Open

- Two artifacts are 5.9 m and 10.25 m taller than the walls. Either the room grows or they shrink; the text describes them going through the roofline, which is true and probably not intended.
