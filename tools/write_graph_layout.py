from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/GT_Layout';S=R/'doc/book/studies/graphs-through-the-hands/GT_Layout'
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Layout — move the drawing, keep the graph

## Learning elements

- Vertex identity and adjacency, separate from position
- Springs along edges; repulsion between every pair
- Velocity, damping and a shared simulation step
- A held point pins one vertex; release resumes its motion

## In this hall

Watch the existing blue graph move. Choose an edge and follow both ends. It can stretch without connecting different vertices. The museum exhibit has eight vertices and twelve edges, the connectivity of a cube. Our smaller reconstruction continues the **seven-vertex graph from Foundations**, with exactly the same neighbour lists and the same PointBody. We change its drawing.

The point was a step control. Here it becomes vertex 0. Hold it and move your hand: its connected neighbours respond. Release it and the point joins the motion. Nearness alone never adds an edge.

## Continue the student's object

Work inside the existing Endless Museum project, with the supplied desktop or XR player. Keep `traversal.gd` and `point_body.gd` unchanged from Foundations. Restore the original neighbour order if you changed it for that lesson's exercise. Add `layout.gd` beside them and replace the learner's `study.gd` with the complete host below. These are separate files, each with one responsibility.

Attach `study.gd` to one empty Node3D in GT_Layout's left learner bay. The saved `study.tscn` does only this. For the reviewed placement use map-local position **(4.5, -0.45, 4.5)** and Y rotation **180 degrees**. The small downward offset puts the initial point within reach. In the isolated museum the hall root starts four metres before map zero: its equivalent root-local position is (4.5, -0.45, 8.5). Keep scale at 1. The hall supplies camera, lighting and hands; the script creates its own graph, labels and point.

The new operation is `layout.gd`. The complete display and input host follows it. The two carried files are included at the end so the example can be reconstructed without hidden scene children.

## One graph, another record

`neighbours[0]` still contains `[1, 2]`. A second list, `positions`, says where to draw each ID. Entry 0 can move while the two neighbour IDs stay the same. `velocities` is another parallel list: entry 0 records how that drawn vertex is moving.

Every pair repels. Only a listed edge acts as a spring. The spring compares its present length with `rest_length`: a stretched spring pulls; a compressed one pushes. `a < b` counts a reciprocal connection once, and equal opposite forces go to its two ends. These are forces chosen to arrange a diagram. An edge in another kind of network need not describe a physical spring.

'''+block('layout.gd')+'''
`forces()` reads all positions and returns a fresh force list. Only then does `step()` change velocities and positions. Updating positions inside the force calculation would let later vertices react to an already changed world.

The model uses unit mass. Force changes velocity by `force * delta`; velocity changes position by `velocity * delta`. Damping multiplies velocity by `exp(-damping * delta)`, so its strength is expressed per second. The force calculation still advances in discrete physics steps: this is not a guarantee of an exact or unique equilibrium. The speed limit and minimum repulsion distance keep this small study manageable. At exact coincidence a zero direction cannot push two vertices apart; start them at distinct positions.

A pinned vertex skips the integration and has zero velocity. Its position still participates in every force calculation, so its neighbours feel the move. No neighbour list is written by the layout.

## Give the drawing a body

The host keeps the earlier spheres, numbers and thin cylinders. Now `redraw()` updates **both** ends of each cylinder every physics step. Its `ends` list stores IDs, not copied coordinates. The display can therefore follow the motion without guessing which vertices should be connected.

'''+block('study.gd')+'''
The hand arrives in world coordinates. `to_local()` brings it into this study's frame. Setting Z to zero projects the movement onto the drawing's XY plane. While you hold the point, a blue marker shows that projected vertex; your black point can be in front of the plane. On release the black point returns to the projected position and continues with the simulation. This is a planar layout, not a new three-dimensional graph.

Trigger or keyboard **1** pauses/resumes the simulation. You can still reposition vertex 0 while paused. **R** resets only the drawing and its velocities; release the point first if you want to see the initial arrangement. The queue and stack readouts use the previous lesson's traversal. Their orders remain unchanged as the drawing moves.

## Try, predict, explain

1. Follow edge 0–1 while pulling the point sideways. Predict which two vertices have direct springs to 0. Check the unchanged list `[1, 2]`; every other vertex can still respond through repulsion or through the rest of the graph.
2. Pause, move the point, and inspect the stretched cylinders. Explain why an unconnected neighbour on the screen has not gained an edge. Resume and release.
3. Change only `rest_length` from **0.65 to 0.9** in `layout.gd` and restart from the same positions. A longer rest length reduces a stretched spring's pull at the same separation, or increases its push if compressed. Expect a more spread-out drawing in this example. It is not an instruction to make every edge exactly 0.9: repulsion also acts. Predict that both visit orders remain identical, then check them.

You should still read queue **0,1,2,3,4,5,6** and stack **0,1,3,4,2,5,6**. The runnable checks also compare average edge length after the same number of simulation steps, so the independent edit tests a visible consequence rather than merely compiling.

## Carried files — unchanged

`traversal.gd` retains vertex identities, adjacency and the queue/stack procedure. It never reads `positions`.

'''+block('traversal.gd')+'''
`point_body.gd` is the same pickable point. XRTools supplies grabbing; the museum supplies the pickup function. This lesson connects the inherited action signal and reads `held()` rather than rebuilding that interaction.

'''+block('point_body.gd')+'''
## What travels onward

Carry the point, the neighbour lists and this distinction: **a drawing can change while its routes remain available**. In Pathfinding, making a vertex or connection unavailable can change the route itself. A new position alone did not do that here.
'''
(M/'tutorial.md').write_text(t,encoding='utf8')
(M/'final.md').write_text('''# A connection is not a coordinate

Choose an edge. Keep its two ends in view while the drawing moves.

<!-- @force_directed_layout -->

The edge lengthens. One end slips past another point. The arrangement becomes unfamiliar, but the connection you chose remains. Left and right were temporary ways of finding it.

The blue graph has eight vertices joined in a cube's pattern. Each has three neighbours. Springs along its edges and repulsion between every pair give that pattern a changing shape. Damping wears down the motion. Someone chose those forces, their strengths, the starting positions and the bounds within which the drawing may move.

It can look as though the graph has found its natural form. Stay with that impression for a moment. Then find the point that seems most important. Is it larger in your view, nearer the middle, or easier to see? Count its connections: three, like every other point here. The drawing has offered a hierarchy that this count does not support.

Move around it. One edge hides behind another; a gap opens. The relationship remains, yet your access to it changes. Making a network visible is already a choice about what another body will be able to notice.

The travellers in the last room could follow only the neighbours their record supplied. Two unrelated points might pass close enough here to look intimate. No new connection follows from that appearance. Nor does a stretched edge tell us that a relationship has weakened: this drawing has no such measure.

In the small study, your hand can pull the black point out of place. Its neighbours follow; the shape answers. Release it and watch the arrangement continue without you. You have altered the position from which the point is seen, while keeping the record of whom it can reach.

Some relationships persist through a change of place. Others need a change in the record before they can appear at all. Which kind of change are you asking this picture to show?

<!-- @ -->

In the next hall a stone can become unavailable. The traveller will need more than a different drawing to find a way across.
''',encoding='utf8')
print('Complete Layout tutorial and reflective text written; four printed scripts, two carried unchanged.')
