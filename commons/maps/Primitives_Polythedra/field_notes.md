> Historical development draft. The current route and placed inventory are described in [final.md](final.md), [tutorial.md](tutorial.md) and [artifacts.md](artifacts.md), revised 16 September 2026. The original record follows unchanged; its former placements and claims are not current validation.

# Primitives_Polythedra — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The ruling (Palle, 2026-09-02)

"The first most basic 3D form with just three sides; we should practise that
artifact, it face-shifts." Confirmed as the **trihedron**: three faces meeting
at a point, open, the corner before any container. The room holds
`grab_trihedron` (wedge / corner / regular / inverted) and `pyramid_edit`
(grab handles on base and apex), so "face-shift" is dragging those faces.

## What the triage found

Five of ten placements are another layer: `path_watchdog`,
`path_game_controller` and `becoming_catalyst` are the path-and-block playtest
(2026-05-29); `tentacle_placer` drops pyramids from a seven-metre sky
(2026-07-07); `interactive_point_origin_force#mode:transformation` is a
force-field toy. `walked.md` already asked whether the catalyst "reads as
integral to the volume beat or as a guest." `snap_tetrahedron_puzzle`, named in
the intent as the closing station, is not placed; `grab_tetrahedron` is, with a
one-word registry description.

Ruling implied for the writer: the corner stations are the room; the game layer
is untagged, like the catalysts in the triangle room.

## The tutorial belongs to a later room

It enumerates the five Platonic solids and their volumes. Palle's thread puts
the Platonic set in Primitives_Ignorance. What belongs *here* is the corner:
the angle sum at a vertex under 360° ("six equilateral triangles collapse into
a plane; five or fewer rise into a point" is the KEEP line and it is a corner
fact), a trihedron built from three faces, the tetrahedron as a corner closed
by one more face, Euler's V − E + F = 2 as the first count of a solid.

## An observation, offered not pressed

The tetrahedron is the only Platonic solid with no centre of symmetry. The odd
one was in the ideal set from the start. That may belong to Ignorance's capsule
argument rather than here, but it is the corner's own property, so it is noted
where the corner lives.

## The expansion (2026-09-05): the prism, twice

Palle: *"I want to expand the map ... add this kind of set up"* - the prism ring
round `dark_sphere` and `diamonds:0:-1:0.8` (Primitives_Fiver's rows, the 2025
repo's Primitives_4) - *"with rock_spawner#rock_count:30#spawn_height:3.5
#spawn_area_x:3#spawn_area_y:2#spawn_area_z:3, also want 2 structures with
wedges. It shows how a prism can work as a blocker and something you can walk up
on."* The hall grew from 13x10 to 13x28; rows 0-8 are as they were, the old
bottom wall (row 9, with its `p` cell) is row 27 now, and the exit `t` moved from
(6,8) to (6,26) so the new rooms are walked before it.

**What stands.** Rows 10-14 the ring: twelve `prism_block` (three at 90 across
the top and bottom rows, two down each side), `dark_sphere` at (4,11),
`diamonds:0:-1:0.8` at (4,12). Rows 16-18 the wedges: a bar of two `p:2` cells at
(1,17),(2,17) with `wp` north of it and `wp:180` south; a single `p:2` at (5,17)
with `wp` (5,16), `wp:180` (5,18), `wp:90` (4,17), `wp:270` (6,17). Rows 20-24
the pen: Primitives_Irregular's, height-3 walls with the gap at (4,24), the
spawner at (4,21) and `rock_scanner` at (4,22). Captions at (1,9), (7,15), (1,20).

**Exactness decisions.**
- **The wedge grammar.** `wp:ROT` climbs from one neighbour onto the other: 0
  rises south (+z), 90 east, 180 north, 270 west - the museum's own
  `_stamp_wedge` reads the yaw that way ("north: climbs from the entrance
  side, smaller z"), and the grid's `walkableprism.tscn` is a 2 x 1 x 1 right
  prism whose low half lies in the approach cell. So the platform is the
  neighbour in the rise direction, and the approach cell must be free floor;
  the generator asserts both.
- **`p:2`, not `2`.** A numeric 2 is a wall to the museum's door hall
  (`h>=2 wall`); `p:N` is an explicit PLATFORM in both engines (GridStructure
  Component.parse_cell_height, em_map_halls tile "p2"). The wedge structures
  are `p:2`; the pen's walls are plain 3.
- **diamonds**: `unit_count` 12, `unit_height` 2.0, `rotation_offset` 15,
  `twist_rule` linear, `unit` octahedron, sunk 1 m at scale 0.8 (the token).
- **rock_spawner**: exports rock_count, spawn_area (3,2,3), spawn_height 3.5 -
  the token's config names them. **rock_scanner**: scan_range 0..3 m, speed 0.5,
  auto_scan, display 2 x 2 m.
- The walkable prism is `PrismMesh` size (2, 1, 1) with `left_to_right` 0: a
  right triangle two metres long and a metre high.

**Museum.** This is a map-authored primitives hall: its plan row was re-derived
from the map alone (a full apply would have re-derived Point_One and the other
rows other sessions are editing) and its pearl re-baked after dropping the stale
segment: 29 bodies placed, nothing refused. The wedges are utilities and go
through the museum's own wedge stamp.

**Open.** Nobody has walked it. The east strip (x9-12) is floor beyond the wall
as it always was. The working tree carried two uncommitted interactable lines
(row 0's prism, row 5's grain prisms) from another hand; they are kept in the
file and not in this commit.
