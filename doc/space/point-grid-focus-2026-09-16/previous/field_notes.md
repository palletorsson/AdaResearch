# Point_Line_Grid — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## What the room decided

Point_Trace ended on a fork: two losses, and which one you can live with. This
room answers for the grid: it lives with losing everything below a cell and
keeps the address forever. The differentiator from the trace is one `if`:
`visited_cells` never overwrites, so the grid counts places and not time, where
the trace kept duration and dropped from the far end.

## Two lines from one walk (Palle, 2026-09-02)

"It follows the player and writes a trace behind her as she moves. But since
this is the grid, can we write both the grid line with high resolution and the
current trace line." Both already existed inside `player_trace`:
`show_discarded` (the walk as walked, every frame) and `seam_grid` (the kept
trail snapped into the staircase). They were unreachable: `apply_grid_config`
read only `retention`, and the museum's stamp hands a *string* to a typed
float, which is refused in silence. Now coerced. The placement is
`player_trace:0:0.5#seam_grid:1.0#show_discarded:1`, a metre to match the
sphere (`grab_sphere_point_snap.grid_size = 1.0`) and the floor grid
(`grid_lines.cell_spacing = 1.0`). The tutorial's `CELL_SIZE 0.5` is the
tutorial's; the text says the sphere snaps at a metre "where the tutorial's cell
is half that," on purpose.

## The trace was invisible in the museum

Not the drawing, and not the hall offset: the trail already converts to local
space. Under the shipped game loop there are two `XROrigin3D` in the tree, the
staging's menu rig that never moves and the loaded scene's that the visitor
drives, and `player_trace` took the first it met and cached it forever. Same bug
the museum fixed in itself on 2026-08-18 (`_vr_eye`). Now it mirrors that
resolver, re-checks every half second, and restarts the trail on a rig switch
so no phantom segment spans the room. `probe_trace_live_rig.gd`, seven checks.

## Where the loss happens

Worth keeping straight across the three rooms, because the reviewer of
Point_Trace caught it there: the trace loses at *sampling* and its lines then
*invent* what lay between. The grid loses at the *write*, and the write is
idempotent. The staircase is aliasing, not a rendering artefact.

## Open

- The room is one cell narrower than the corridor the plan assumes
  (`line_demo` sits at x = 8, the corridor middle is 9). Cosmetic, noted.
- `room_grammar` is a table-top plan generator, a guest. The text gives it one
  honest beat ("not this room's plan, but the same hand") rather than pretending
  it built the hall.
