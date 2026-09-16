# Point_Line_Grid — walked

> R-021, amended: the considered critical tutorial for a walked, working map.
> The ghost drafts from what the map IS; Palle rules the voice. Two trajectories
> woven: the walk (tutorial) and the turn (critical).
>
> PILOT (ruling pending): the dwell register. The walk keeps its walking tempo;
> at three stations it stops, and an inset long-take opens — distilled from the
> map's own thinking files, provenance shown. The page is paced like the map:
> walk → dwell → walk. Each dwell carries its computed reading time (P-6).

## What this map holds (seed)

The grid quantizes. Continuous movement snaps to discrete positions. Your trace, once fluid, becomes a sequence of cells. This is how space becomes computable — and how the body's path becomes data.

`grid_lines` provides the fixed frame you did not choose. `player_trace` writes your position into the cell it falls inside, not where it actually was. `grab_sphere_point_snap` makes the constraint legible: you reach, the sphere jumps to the nearest cell, agency negotiating with imposed structure. Quantization is never neutral. Foucault already wrote this; the grid here is his disciplinary diagram rendered in Vector3.

## Why it was built (seed)

Concept: The grid quantises continuous movement into discrete positions. Traces snap to cells; the learner's fluid path is disciplined into a sequence of addresses.
Sequence role: Fourth map. Synthesises Point_Lines' grid and Point_Trace's duration — the fluid trace disciplined by structure so deviation becomes measurable.
Critical angle: The grid as political technology — quantisation is always a choice about what resolution of difference matters. Foucault's disciplinary grid; the panopticon as spatial sampling.

## The cast

grid_lines · player_trace · grab_sphere_point_snap · room_grammar · floating_sphere_field

## The walk

You bring two things into this room that the last maps gave you: a grid (from Point_Lines) and a trace (from Point_Trace). The map's whole move is to make them collide. `grid_lines` lays down a fixed frame — you did not choose it, it was here — and now when `player_trace` records your motion it no longer keeps where you *were*. It keeps the **cell you fell inside**. Walk a smooth curve and watch it come back to you as a staircase: your continuous path, quantized, snapped to the nearest addresses. The body moved through real numbers; the record holds integers.

> **Dwell — `grid_lines` · ~55s**
>
> Look down at the lines and count what defines them: two numbers. Cells per
> axis, meters between lines — `grid_size` and `cell_spacing`, nothing else.
> The whole apparatus is drawn as independent segments, pure edges, no
> triangles, no filled surface: the grid has no interior at all, only
> relationships between positions. Walk from one intersection to the next and
> you have walked exactly one meter — it is a ruler built into the floor.
> Every intersection has an integer address; every position between
> intersections has no name the grid recognizes. Now look at the center of
> the room, where the floor is missing — and notice that the lines cross the
> void anyway. Nothing is there, and it is addressed. That is the grid's
> confession: it does not need anything to occupy a cell for the cell to have
> a name, which means indexing claims space as legible and governable
> regardless of whether a body can stand there. And once laid down, the grid
> forgets it was laid down — it presents itself as how space simply is, the
> way a surveyed section line comes to look like nature. Two exported
> variables, and territory appears. The word for that register is cadastral,
> and it was invented for collecting tax.
>
> *distilled from critical.md · technical.md*

> **Dwell — `player_trace` · ~55s**
>
> Stand still and watch your own wake. The trail behind you is being rebuilt
> from scratch every frame — the visible line is not the record; an array of
> positions is, and the mesh is merely derived from it. Read the array's
> honest constraints: a new point only when you have moved at least a
> centimeter, so your stillness does not exist here; at most 1024 positions
> kept, so when memory fills, the oldest point is dropped for each new one —
> the trace forgets, from the far end, as you go. And every position it holds
> is relative. The trail stores your location in the coordinate frame of the
> trace node itself: move that node and every recorded coordinate changes,
> though you never moved differently. Absolute position does not exist in
> this engine — only positions relative to some frame, composed all the way
> up to the root, and "the world" is just the frame everyone agreed to stop
> at. Meanwhile the headset is doing this to you ninety times a second
> whether you look at the trail or not. You cannot use this system without
> being indexed by it. The trail just makes visible what the infrastructure
> was already writing.
>
> *distilled from technical.md · critical.md*

`grab_sphere_point_snap` is the map's honest instrument — reach for the sphere and feel it *jump*, refusing to sit where your hand actually is, sitting instead where the grid permits. That small tug is the entire lesson in your muscles: **agency negotiating with imposed structure.** You can feel the fit when your intention lands on a cell, and the misfit when it lands between two and the grid decides for you. `room_grammar` frames the whole space as a set of rules you're inside rather than a neutral floor.

> **Dwell — `grab_sphere_point_snap` · ~55s**
>
> Hold the sphere and feel the argument. During the drag, two things are true
> at once: the sphere follows your hand, and the trail follows the grid —
> they diverge, and the moment you let go, the sphere jumps to the nearest
> node, a small discontinuity you feel in space. The operation deciding all
> of this is three arithmetic steps: divide by the cell size, round, multiply
> back. That is quantization entire — the same three steps that make pixels
> out of images, samples out of sound, voxels out of volumes, tiles out of
> maps. The data table beside you shows the transaction in two columns: where
> you measurably were, and the cell that will stand for it. (2.37, 0.0,
> −1.83) becomes (2, 0, −2). The decimals are erased; where you precisely
> were is replaced by the name of the cell you were in — information
> discarded, because that is what addressing requires. And the staircase your
> diagonal becomes has a technical name: aliasing. The grid is a sampling
> frequency, and your movement changes faster than it samples. Shrink the
> cells and the staircase leans toward your curve; it never becomes it. Ask,
> before you put the sphere down, what falls below this grid's resolution —
> and who set the resolution.
>
> *distilled from technical.md · critical.md*

## The turn (critical)

This is the map where Ada says the word out loud: **quantization is never neutral.** A grid is a decision about which differences count and which fall below resolution — and once you've made that decision, everything finer than a cell simply *does not exist* to the system, not as a value but as a fact. Foucault's disciplinary grid is not a metaphor the map reaches for; it is the mechanism the map implements. The panopticon is a sampling scheme. The census, the timetable, the cell block, the pixel — all of them are this room: a continuous body made legible, governable, comparable, by being snapped to a frame it did not author. "Whose grid? Whose resolution?" is the political question, and the map hands it to you as a felt tug rather than a slogan.

But — and this is the map's real sophistication — it does not let you off with pure critique either. The snap is also what makes the trace *comparable*: a gridded path can be replayed, diffed against another, measured for deviation. The discipline that erases your sub-cell body is the same discipline that lets two bodies' paths be laid side by side and learned from. The grid is the condition of both surveillance and science, and the map makes you hold both in one gesture — the loss of the continuous self, and the birth of the shareable record. That doubled feeling, fit *and* misfit at once, is the thing to protect.

## Room for improvement

*(Palle: the snap-tug is the load-bearing sensation here. Note whether it reads
in the body as agency-vs-structure, or just as a UI convenience.)*
