# A movement that exposes a decision

17 October 2026 · Reverse design trial · **Build instructions, not implemented changes**

Palle supplied the glass painting wall, selected-point correspondence and skull substitution. The Animated Cube proposal below is the assistant's contribution. It is grounded in the current map placements, museum plan and active scripts, rather than the older map summaries. No map, artifact, canonical tutorial or final text is changed by this brief.

The working principle is: **give an ordinary action somewhere clear to happen; let one changed condition produce a consequence; let that consequence make the next encounter useful.** It should produce different rooms, not a repeated sequence of control panels. A successful encounter can produce a good question or an unexpected construction, not only the intended answer.

## Point_Trace — surface marks and spatial traces

**Palle's clarification.** Keep both drawing on glass and tracing in three-dimensional space. The pen belongs to the glass, where its nib meets a surface. The problem with air drawing is the pen metaphor, not the existence of the spatial trace. The earlier instruction to replace air drawing with the glass wall was a misunderstanding and is superseded here.

**Build instruction.** Give the painting more space and a transparent glass wall. Keep pens on a small tray attached to its frame. These pens make marks only near the glass, inside its bounds; lifting the nib starts a gap. Keep a separate open area for three-dimensional tracing, with a tool or gesture that makes sense without a surface. A small held point or bead that leaves a trail is one candidate to test, not an agreed final design. Its start, stop and release behaviour needs to be understandable through use.

Start with a 3 m wide pane, a writing band approximately 0.75–1.85 m above the floor, and at least 1.5 m of clear approach and circulation on either side. These are prototype dimensions to test at seated and standing reach, not established comfort measurements. Give the pane a visible frame and restrained edge reflections. Ink should remain legible against the room, without an opaque sheet pretending to be glass. Allow walking around an end to see the drawing from behind. The same marks should read in reverse there, rather than becoming a second unrelated canvas.

Keep the ball ramp in its own clear bay. A proposed sequence is a pen marking glass, a held point leaving a spatial trace, then a released ball whose movement continues through gravity and contact. The sampling monitor belongs beside the tracing area, not across the route or in front of the pane. Retain the different grid spacings, with one short label explaining what changes. Compare recordings of the **same accepted gesture** when claiming that only recording resolution changed; separate hand-drawn repetitions vary the gesture as well.

**The necessary bridge.** The current air pens send position arrays to `TraceData` on release. Preserve that connection when changing the spatial tool: a new appearance or gesture must not lose the trace carried into Grid. Adapt the sampling monitor if its source interface changes. The current glass/whiteboard painting system keeps a separate image. Carrying glass drawings onward would be an additional proposal, not a prerequisite for keeping spatial tracing. If added, it must record glass-local positions, order, stroke breaks and the placement transform, preserve gaps, and account for erased marks rather than silently exporting them.

The current archive holds arrays in memory for the running session, without stroke metadata or disk persistence. Any extension must remain compatible; do not describe crossing a hall as saving a drawing across application restarts.

**Observation test.** With a glass pen, draw a loop, lift, and add a separate short stroke. Walk behind the pane and recognise the same marks. Then use the spatial tool to make a trace with depth and carry that trace into Grid. Can someone understand why the pen needs contact while the spatial tool does not? Does the latter invite shaping a line in space without looking for a missing page? A lost carried trace, an invisible pane or glass-pen ink appearing away from the surface is a failed implementation. The usefulness of the new spatial gesture remains a research question.

**Tutorial seed:** compare recording contact with a plane and recording a point moving in three dimensions. **Final seed:** a surface supports one kind of mark; open space permits a line with depth. Keep the same room/text order. Neither encounter should be presented as a failed version of the other. The tool's form should make the difference understandable.

## Point_Line_Grid — find the same point twice

**Build instruction.** Selecting a point in the coordinate record must identify that exact point in the displayed line. Selecting it on the line must identify the same row. Use a numbered halo and a short segment highlight as well as colour; selection should stay until another point is chosen.

Show the selected source point in pink and its snapped counterpart in green, with a thin connector between them and a compact original/displayed coordinate readout. Highlight the incoming and outgoing recorded segments, where they exist. Keep the rest of the line quiet. The comparison belongs next to the sculpture, within one glance, rather than on a distant information board.

Selection must use **trace identity and source index**, not coordinates or row number on the current page. Revisited positions can have different positions in the sequence. The existing renderer recentres and rescales the trace, while its panel lists source coordinates. Apply exactly that display transform to the halo. The green renderer also removes consecutive duplicate snapped positions: preserve the many-to-one correspondence, so several selected source points can correctly identify the same green location. Never pretend that one surviving green vertex represents only one source sample.

Start still, as the current map already specifies. Add large, reachable previous/next-point targets to the existing reading surface and allow direct selection with the desktop/VR pointer. Do not require precise contact with a millimetre-thin line. Keep page navigation distinct from point navigation. Arrive without a drawing and show an honest empty state with the route back to Trace; any demonstration trace must be labelled as a demonstration.

**Observation test.** Select two distinct source positions that snap to one address. The pink halo moves; the green halo stays. Change pages and return: the selected point remains the same. Test a repeated position and a stroke boundary too. The next question is now concrete: *when can several different positions count as one place?*

**Tutorial seed:** one record, one index, two display transforms. **Final seed:** the line and the table become mutually findable. Selection foregrounds one point; it must leave enough of the surrounding gesture visible to understand its place.

## Point_Animatedcube — the surface was also a decision

The current room already contains two builders with movable corners, replay, pause, restoration and diagonal visibility. It also contains a folding net, a box library, a conveyor, additional solids and several supporting studies. Adding basic grab or replay again would not improve its core.

**Build instruction.** Make a paired study of two one-metre cubes the first main encounter. Give them the same eight corner positions and the same materials, lighting and orientation. Change only the diagonal dividing their front face. Leave room to approach and see both from an oblique angle. Use low, unobtrusive supports with no raised floor to climb.

Start with both cubes complete and still. Make the upper front corner, `v6`, visibly graspable. Moving it on the first cube moves the corresponding corner on the second by the same local displacement; show this link plainly. The other seven positions stay fixed during the comparison. The first face uses triangles `4–5–7` and `5–6–7`; the second uses `4–5–6` and `4–6–7`, with rendering winding checked during implementation.

At first the faces coincide geometrically. Pull the corner forward. One face bends along one diagonal, the other along the opposite diagonal. **Identical corner positions can describe different surfaces when the connections differ.** A regular cube's shape has been lost; the vertex identities and face connectivity in each version remain. Do not call every deformation a cube or use unchanged counts as proof of geometric validity.

Use quiet, mostly opaque front faces and consistent side lighting so the crease is visible before its explanation. Mark the two triangles subtly. Thin diagonal lines can appear during the drag and remain for comparison after release. Put one short question on the support: *Same corners. Why a different fold?* Keep restore and optional assembly replay on a small reachable edge strip, outside the sightline. Restoration resets positions; replay reveals the current geometry again. They remain different operations. Free editing of all eight corners can follow the controlled trial.

**Give the rest a sequence.** Follow the paired study with the folding net: now faces remain rigid and hinges move. Then reach the box library and conveyor: a completed object becomes a copy that can be placed, sorted or left to accumulate. Keep the crate/sculpture studies in a side bay and the shadow/phosphor studies as optional stops. They should not conceal the first pair or compete with its motion. This is a proposed hierarchy, not an instruction to delete existing artifacts.

The main route and final should agree: **same corners / different surface → rigid faces / moving hinges → made object / different arrangements of copies.** The existing cube tutorial already compares opposite diagonals; extend it with the same controlled displacement, rather than introducing an unrelated lesson.

**Observation test.** Before dragging, ask for a prediction. After dragging, ask where the surfaces differ and which data changed. For a one-metre front face with `v6` displaced 0.25 m forward, the two surfaces differ by 0.125 m at the centre of their front-view projection. This is a geometric calculation, not a verified Godot capture. Check it in the implementation, then check whether a person can see and investigate the difference without first reading the explanation. Finally let them choose another corner or a different face and propose the next trial.

This foregrounds triangulation by temporarily linking two objects and restricting seven corners. It gives up independent sculpture-making during that first comparison; free editing afterward returns that possibility.

## Primitives_Melencolia — a skull among the instruments

**Build instruction.** Replace the main seated figure in the Dürer installation with a skull. The intended target in the active source is `_main_figure()` and its `Melencolia` group; the smaller figure is a separate construction. Treat this as a deliberate Ada variation of the tableau, not a claim that the altered scene reproduces the print.

Place a recognisable skull on a modest stone support within the former figure's footprint, at a height from which its eye sockets, jaw and hollow spaces can be inspected. Start around 0.28 m tall, then judge recognition from the actual approach. Prefer a restrained bone finish and believable cavities over luminous eyes or a spherical head with painted black spots. A dedicated skull asset was not found in the inspected registry; making or sourcing and validating it is a real task, not a completed substitution.

Keep the large polyhedron, sphere, tools and numbered square in the composition. Let the skull face slightly towards the stone. Preserve the frontal encounter and a side route where occlusion changes. Do not turn every object into a control. This room can make its difference through looking and walking.

**Observation test.** Is the skull recognisable before reading its label? Does moving sideways expose different relations among skull, stone and tools? Does removing the seated body sharpen an interesting question, or merely make the tableau less specific? That last possibility is a valid reason to revise the proposal.

**Text consequence:** rewrite the passages about the seated figure's fist, compass, lap, skirt and gaze. They cannot remain as descriptions of the installed scene. Name the substitution briefly and let the encounter establish its significance. The existing reading of a skilled person hesitating is lost; the new reading is not automatically stronger. Keep the preceding court and later encounters in their existing sequence unless the spatial test supplies a reason to change them.

## Build and judge one pilot first

1. Build only the paired cube comparison first. Retain its source and capture the baseline and one controlled displacement from the same camera.
2. Test actual selection, hand/controller reach, restoration, triangle winding and the measured surface difference. Keep technical verification separate from a visitor's interpretation.
3. Ask for a prediction, watch one manipulation, and ask what they would investigate next. Record what actually happened; do not mark a question answered because the intended explanation was displayed.
4. If the encounter holds attention, give its result space in the room and revise the corresponding tutorial/final in that order. If it does not, change the apparatus or its staging before adding more explanation.
5. Build the glass wall, trial the spatial tracing tool, and add Grid correspondence. Test the spatial trace across halls; treat carrying the glass image as a separate extension. Then stage the skull variation and compare its reading with the current tableau.

The criterion is not “more features.” It is whether an action produces a legible difference, whether that difference matters to the subject, and whether it gives us a reason to reconstruct or continue the experiment.

## Source anchors inspected

- `commons/maps/{Point_Trace,Point_Line_Grid,Point_Animatedcube,Primitives_Melencolia}/map_data.json` and their corresponding rows in `commons/data/museum/em_plan.json`.
- `commons/primitives/animatedcubebuilder/animatedcubebuilder.gd`: vertices/triangles, handle updates, discovery controls; `commons/maps/Point_Animatedcube/tutorial.md`: alternative diagonal construction.
- `commons/primitives/line/grid_lines.gd`: display frame, pink and snapped traces, duplicate filtering and paged source coordinates.
- `commons/primitives/point/draw_dot.gd`: export on release; `commons/globals/trace_data.gd`: shared archive entry point.
- `commons/artifacts/whiteboard/whiteboard_drawing.gd` and `whiteboard_canvas.gd`: bounded surface contact and opaque painted image, currently separate from the carried trace.
- `commons/scenes/demos/durer/EngravingScene.gd`: current sculptural groups; `commons/maps/Primitives_Melencolia/final.md`: figure-dependent prose.

Source inspection and the cube calculation support this brief. No new Godot or headset behaviour is claimed as tested. Existing work in the maps is preserved. No commit or push requested.
