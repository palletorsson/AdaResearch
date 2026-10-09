# Melencolia platform archaeology

The user's remembered structure is present exactly in commit `8feb9c91329d416908f86ca811f09bbb0b65b1da` (2026-07-07), and still present in `40e15987f^` / `4beaa29b89ea1fe297fab7d747a6c44624d01bb1`, the parent of the July 19 promenade adoption. Both saved JSONs are identical. The immediate pre-museum map is already a rearranged promenade; simply restoring the museum conversion's parent would miss the intended composition.

Coordinates below are grid `(x,z)`, zero based. Grid spacing is one metre, no gutter. Structure values are cube counts, not museum wall types.

## First raised court

- 5 x 5 cells, x=1..5, z=1..5, structure `2` throughout.
- Four equal `pyramid:0:-0.5` at (1,1), (5,1), (1,5), (5,5).
- `pyramidlong:0:-0.5` at (3,3).
- Four `cube_scene:0:-0.5:0.5` in a cross around it: (3,2), (2,3), (4,3), (3,4).
- `snap_pyramid_puzzle:180` at (3,1), between the two leading corner pyramids.
- Height-2 approach cell (0,4); `wp` utility at (0,3), over height-1 floor.
- A one-cell-wide height-2 spine runs x=3, z=6..9 out of the court toward the second platform.

## Durer platform

- Main deck x=2..4, z=10..11, structure `3` (3 x 2 cells).
- One-cell tongue at (3,12), also structure `3`, carries `durer_scene:180:0:0.5`.
- `diamondtoruscollection:0:4` at (3,10), over the same raised deck.
- `wp` at (3,9), on the height-2 connecting spine, approaches this higher deck.
- `code_display:180:4#tutorial:melencolia_axioms` at (3,13) is beyond the platform, over a row of zero structure.
- Twin next teleporters at (1,8) and (5,8), both deliberately over void cells; big frames at (0,8), (6,8). These are context, not required to reconstruct the two platforms.

At that revision `GridCommon.surface_world_y()` used centre-origin cubes: structure 1 top is y=0.5, structure 2 top y=1.5, structure 3 top y=2.5. Thus the court stands 1m above its surrounding floor, and Durer's deck stands 2m above the surrounding floor / 1m above the connecting spine. The old explicit -0.5 offsets predate current placement details; restore spatial seating with the present museum's support rules rather than copying those offsets blindly. Fourth numeric token field is uniform scale, so the old Durer and cross cubes were half scale.

## Drift chronology

- July 19, `40e15987f`: the promenade adoption moved artifacts away from their repeated/corner arrangement; later immediate pre-museum `8c45017e8` has only one pyramid and one cube, with Durer at (3,0), even while stale `documentation.key_elements` still describes four corners and the southern platform.
- August 24, `f839f244c`: museum conversion replaces that 7 x 14 multi-tier plaza with a 20 x 22 hall and round southern chamber. The five-pyramid composition becomes one pyramid in the first gallery plus three differently scaled pyramids and a long one in the southern chamber; Durer moves to (5,17). A separate little 2 x 2 `p` platform existed x=2..3,z=14..15 for the small pyramids.
- The current map is 13 x 22, the small `p` corner platform has become ordinary `1` floor, and the Durer token has no half-scale field or platform. The old museum layer is also a stale 17-column matrix. Parent task is inspecting which current layer generates museum supports.

## Restoration implication

Restore the recognizable relationships: four same-sized corner pyramids around a centred long pyramid on a single walkable raised court, then an approach to a separate higher Durer platform. Preserve the current museum room's connected entry/exit and current other exhibits. Half-scale Durer is historical evidence; present scale can be adapted only if the restored support is sized to its actual current bounds. These archaeological findings establish intended arrangement; collision and sightline verification must use the current museum renderer.

All extracted source JSONs and a machine-readable artifact coordinate inventory are in this directory. No live source file was modified during archaeology.
