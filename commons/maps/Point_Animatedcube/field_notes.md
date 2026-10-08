> Historical document. The 2026-09-16 source and room review is recorded in intent.md, tutorial.md and artifacts.md. This earlier text is retained as written; its former inventory and flexible-quad claims are not the current setup.

# Point_Animatedcube — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The ruling (Palle, 2026-09-02)

The cube shown as triangles (twelve of them) and as its net, unfolded. The map
is about the cube "but should really have a lot more cube, like classic game
crates; it's what the whole museum is made of, but we have a world without
composition yet." The last clause is to be **said in the text**, as the room's
own admission.

## What is here and what is not

Placed: `animatedcubebuilder`, `polyhedron_nets_cube` (the net), `first_phosphor`,
`first_shadow`. Not placed, though they exist: `crate`, `tech_crate`,
`station_crates`. The triage judged the room SPLIT because blurb, tutorial and
artifacts argued deformation, interpolation and assembly respectively and never
met. The ruling settles it: the cube as the museum's own material, in quantity.

## Written (2026-09-02)

- **The tutorial's tween register was kept, not rewritten.** The map is the
  *animated* cube; keyframes plus interpolation is Point_Trace's "the lines
  invent the between" applied to a solid, so it earns one section, "Given
  time," and hands the rest to transformation ("what changes is where it is,
  and the next chapter is about that and nothing else").
- **The admission is said in full**, once, in bold: *A world without
  composition yet.* The crates carry it split across their stencils (pallet:
  A WORLD / WITHOUT / COMPOSITION; pile: WITHOUT COMPOSITION / YET; crate:
  YET) via the `stencil_words` knob added the same day.
- **Exact counts only.** Eight, twelve, six; Euler two (proven in the corner
  probe); twelve triangles and six seams; 720 spent eight ways; **eleven**
  distinct cube nets (the artifact's own description; the room shows four).
- **The props' names are DNA-gallery variant names**, not tokens:
  `glove_box_1_single_glove` is `glove_box#glove_count:1`, and so on.
- `first_shadow` and `first_phosphor` stand in the east bay behind the c8
  wall column; the text calls them "across the room" and claims nothing about
  reaching them.

## For the writer

- The museum is a voxel grid; the hall you stand in is cubes. The room can say
  that the floor under the visitor is the same object as the crate on the plinth.
- Twelve triangles, six seams. After the triangle room, the visitor knows why.
- The net is the cube admitting it was flat all along: six squares, five folds.
- Cube props need placing before the text can point at them. This is a
  curator task (`/map-curator`), not a writing task, and it comes first.


## Interface pass: 22 September 2026

Both configured builders keep their own experiment and remain available for
comparison. The floating side panel is replaced by a compact, inclined console
in front of each cube, supported from the hall floor. Both plinths are lowered
to 55 cm; the cube keeps its one-metre size, while visible grips grow inside
the unchanged grab colliders. Console height is independent of plinth height.
Four physical buttons sit
on a shared backplate; captions are baked flat textures, and the smaller readout
uses the shared 2D data surface. The console is excluded from specimen seating.

Replay retains the current vertices. Restore returns the initial positions.
While a corner is held, these two actions dim and the readout asks the visitor
to release it first; the builder's existing guards enforce that boundary.
Pause becomes a lit RESUME button. Diagonals become available after assembly.
The manuscript's argument and the room's artifact selection remain intact;
references to the side instrument now point to the front instrument.

Actual-hall desktop measurements and images:
`doc/book/iterations/2026-09-22-interface-spine-cube-review/index.html`.
Headset reach, visual comfort, seated access and Quest performance need a later
in-headset pass. The console's standing pose does not promise every corner is
reachable from that same spot: moving around the cube remains part of the work.

## 2026-10-04 — Fold, fall, again

Upgraded the existing `polyhedron_nets_cube` at (4,10), with no new placement. Six numbered faces, dark outlines and one pink face let the eye follow the fold. A completed 0.7 m cube falls onto the museum floor, settles, pauses for 2.2 seconds with changing dots, then rises and unfolds. The six face nodes survive the entire cycle.

The net's plinth is disabled. Hinge animation hands the closed object to a rigid body; the collider switches off for the authored return and reopening. Existing fold-only and static configurations remain available. The book passage and museum companion describe the new behavior, while the student tutorial keeps its position/connection lesson.

Native museum evidence: `doc/book/iterations/2026-10-04-cube-fold-fall-again/`. Two complete cycles, floor contact, still pause, continuity, reset and four legacy net layouts pass 24 checks. Reproduce with `python tools/capture_cube_net_cycle.py`. Physical headset behavior remains untested.

## 2026-10-04 — Another cube each cycle

Follow-up: shrink the finished cube to 45 percent, then leave a physical copy on the floor. The working net grows and unfolds above it. Copies collide and can nudge one another; the collection retains up to 24 bodies before retiring the oldest. This replaces the earlier rise of the fallen cube.

Native two-cycle recording and 29 checks: `doc/book/iterations/2026-10-04-cube-another-one/`. The first two cubes remain visible below the next open net. The student lesson stays focused on positions and connections.
