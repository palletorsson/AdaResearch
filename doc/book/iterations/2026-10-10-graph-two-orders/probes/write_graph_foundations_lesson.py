from pathlib import Path
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/graphs-through-the-hands/GT_Foundations'
M=R/'commons/maps/GT_Foundations'
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```'
text='''# Two orders, the same connections

## Learning elements

- Vertex identifiers.
- Adjacency lists: which vertices are neighbours.
- Queue and stack: which pending entry comes next.
- Visited state: a vertex is visited once.
- Breadth-first and depth-first visit order.

**Carry:** the grabbable PointBody, arrays, loops, conditions and signals. **New work:** a record of connections and a procedure that visits it. **Supplied:** the museum, XR hands, and the small numbered lamp display printed below.

## Encounter

Find the fifteen lamps of *Two Travellers* in GT_Foundations. The blue tide spreads through a layer; the orange diver follows a branch. Choose a lamp and watch how long it waits under each rule. These are visits being replayed, not a body walking continuously along the rods.

We will reconstruct that choice with seven lamps, small enough to follow by hand. The installed exhibit records children in a fifteen-vertex tree. Our seven-vertex tree records each connection in both directions. The visiting rule is the same; the graph is deliberately smaller.

## Record what can follow

In Trace, an array kept positions. Here an array keeps **neighbours**. A vertex's ID is its row number, starting at zero. Row 1 contains `[0, 3, 4]`: from vertex 1, these three vertices are connected. No distance calculation decides this. The display keeps its positions separately.

Create `traversal.gd`. This is the complete new operation:

'''+code('traversal.gd')+'''

`restart()` puts vertex 0 in `pending` and clears the visit record. `next_visit()` removes one candidate. A queue takes the first entry with `pop_front()`; a stack takes the last with `pop_back()`. Both add new candidates at the end with `append()`.

The selected vertex enters `visited`, and its unvisited neighbours enter `pending`. The function returns its ID so the display can light that lamp. For the stack we reverse a **copy** of the neighbours: adding 2 before 1 lets 1 come off the stack first. The stored connections stay unchanged.

Because connections go both ways, the procedure must recognise a vertex it has already visited. On a graph with a cycle, a candidate can also reach `pending` more than once. The `while` and `continue` skip those repeats before returning the next new visit. An empty list returns `-1`, meaning there is no reachable vertex left to visit from this start.

## Put it in the museum

Keep these three scripts together. Attach `study.gd` to one empty Node3D, or instance the supplied `study.tscn`, under the GT_Foundations hall. Use the study bay on the opposite side from the travellers: map-local position `(3.5, 0, 4.5)`, rotation Y `180°`, scale 1. In an isolated museum run, the hall root includes a four-metre entrance vestibule: the corresponding position relative to that root is `(3.5, 0, 8.5)`. The downloaded study contains no camera, light or player; the existing Endless Museum supplies them. The native review capture tests this placement.

The host builds seven numbered lamps and six rods from the supplied drawing positions. It connects the carried point's trigger to `advance()`. All scene objects and the label are initialized here; there are no hidden child-node references.

<details>
<summary>Complete display and input host — study.gd</summary>

'''+code('study.gd')+'''

</details>

<details>
<summary>Carried unchanged — point_body.gd</summary>

This is the same small PointBody used through Soft Bodies. It provides pickup, release and the inherited action signal. It controls the study; moving the point does not change an edge or a vertex position.

'''+code('point_body.gd')+'''

</details>

Hold the black point and press its trigger once. One lamp is visited. Release returns the point to its place and keeps the current visit record. The desktop equivalent is **1**. After the seventh visit, another press prepares the other order; the following press starts its visits. **2** switches and restarts immediately; **R** restarts the current order.

Predict the third visit before advancing. Compare the pending list with the lamps:

| Rule | Visit order from 0 |
| --- | --- |
| Queue / breadth-first | 0, 1, 2, 3, 4, 5, 6 |
| Stack / depth-first | 0, 1, 3, 4, 2, 5, 6 |

Both reach the same seven vertices. Breadth-first visits them in layers of edge distance from 0 in this unweighted graph. Depth-first follows the first available branch before taking the waiting alternative. Neither rule consults the lamps' coordinates.

## Change one decision

In `neighbours`, change **only row 0** from `[1, 2]` to `[2, 1]`. Predict both orders before running. The same two neighbours remain connected, but their consideration order changes. The queue should begin `0, 2, 1`; the stack should begin `0, 2, 5, 6`. Explain why both now favour the right branch without moving a lamp or adding an edge.

Restore `[1, 2]` before the next hall. Keep `neighbours`, `pending` and `visited` distinct. In Layout we will move the drawing while keeping the vertex IDs and connections: a shorter-looking rod need not be a new connection.

The bridge model is a separate encounter. Crossing every **edge** once is a different question from visiting every reachable **vertex** once; we do not combine those lessons here.

## Check the reconstruction

Run `python tools/test_graph_foundations.py` from the AdaResearch project. It extracts the exact printed scripts, checks the two predicted orders, the independent row edit, cycles and disconnected vertices, then exercises keyboard and XRTools pickup/action/release. The review report contains its receipt. This is an executable author-operated reconstruction; headset comfort and a new reader's understanding still require people.

API reference: [Godot Array](https://docs.godotengine.org/en/stable/classes/class_array.html) for the three list operations; [Godot Quaternion](https://docs.godotengine.org/en/stable/classes/class_quaternion.html) for the supplied rod orientation. The host's drawing code is available to inspect, but the lesson's new work is choosing the next pending vertex.
'''
(M/'tutorial.md').write_text(text,encoding='utf8')
(M/'final.md').write_text('''# Two travellers, one graph

Can two travellers obey the same connections and encounter the graph in different orders?

<!-- @two_travelers -->

Choose a lamp several connections away from the start. Keep it in mind as the blue tide spreads across the graph. Then watch the orange diver. The lamp stays where it was. Its turn comes at another moment.

The tide visits a layer before moving further out. The diver follows a branch while the alternatives wait. Nothing has cut those waiting branches away. They remain in the graph, and in the procedure's unfinished work.

You have already made lists of positions, joined points into faces, and watched connected bodies pull on one another. Here a connection becomes an explicit permission: from this vertex, these others can follow. The line records a relation. Its length on the wall does not decide when the lamp will light.

What does decide is a small arrangement of memory. A queue takes the oldest pending entry. A stack takes the newest. The same connections become two different orders of attention.

Choose your lamp again. The tide reaches it by layers of connection from the start; the diver may go deep elsewhere first. Being close in the drawing does not guarantee an early turn. Nor does reaching every lamp eventually make the waiting equivalent.

Suppose one of these lamps stood for someone waiting for help. Give it an urgency that the graph does not record. Count how many other lamps are visited before it. The procedure has done what it was asked to do. What we needed from it has changed.

We can inspect the order and alter it. We still have to decide what deserves attention, and what our record has left out.

<!-- @ -->

In the next room the drawing begins to move. Keep hold of the distinction: a position can change while a connection remains.
''',encoding='utf8')
print('Wrote first hall tutorial and reflection; three complete printed learner scripts.')
