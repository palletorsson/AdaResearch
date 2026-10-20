from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/GT_Matching';S=R/'doc/book/studies/graphs-through-the-hands/GT_Matching'
def code(name):return f'<!-- student-code:{name} -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Matching — room for two

**Learning elements**

- Two sets and permitted pairings
- One partner per vertex
- Maximal versus maximum matching
- Reusing pathfinding along alternating edges
- Revising an earlier choice

At the workshop table, two people need tools for their declared tasks. Maker A can use either the drill or the saw. Maker B needs the drill. These are task requirements for this example, not judgments about the people. Each person gets at most one tool; each tool serves at most one person during this session.

The first listed pairing gives A the drill. It is permitted. It also leaves B waiting while the saw remains free. No further pair can simply be added. Press NEXT again: A releases the drill and takes the saw; B gets the drill. The revised collection has two pairs.

Flow taught us to revise a commitment. Here the commitment is a pairing. We carry the same PointBody class and unchanged route finder. We declare **four new vertex roles**, rather than quietly turning the harbour's seven places into people. Keep the previous lesson folder intact.

## Store the pairing

Create a `GT_Matching` folder beside Flow. Copy `point_body.gd`, `route.gd` and `traversal.gd` unchanged. Save the following as `matching_model.gd`.

`links` contains permitted pairs, always `[person, tool]`. The two sets use consecutive IDs from zero, with no overlap. `mate[id]` stores the chosen partner, or `-1` when free. A selected pair is recorded at both endpoints. The input here contains no same-set links.

'''+code('matching_model.gd')+'''
The listed greedy scan chooses `0–2`. It cannot then choose `0–3` or `1–2`: each touches an occupied endpoint. This is **maximal**—no edge can be added without disturbing an existing choice. It is not **maximum**, because two pairs are possible.

Reverse the scan order. It chooses `1–2`, then `0–3`. Changing the order exposes the earlier loss, but a fresh scan is not the same as repairing the first result.

## Make revision a path

The temporary search graph gives unused links the direction **person → tool**, and chosen links **tool → person**. Our unchanged BFS route finder can now find a path from a free person to a free tool.

After the first greedy scan, that path is `[1, 2, 0, 3]`: B → drill → A → saw. Its edges alternate unused, chosen, unused. We remove the old `2–0` pair first, then choose `1–2` and `0–3`. This complete update increases the count by one and leaves every endpoint in at most one pair. The temporary direction is a search device; a task-compatible pairing is not itself a one-way journey.

`augment()` searches and flips one path. Call it again until no path remains. For a valid bipartite matching, absence of an augmenting path characterises a maximum-cardinality matching. In this tiny case, two pairs already reach the simpler upper bound: there are only two people and two tools. We are maximising the **number of pairs**, not preference, benefit, consent or fairness.

## The complete workshop

The workshop already stands in Endless Museum. Reconstruct a second instance in the clear front-right bay: map-local `(10, 0, 5)`, Y rotation `180°`, scale `1`. In the isolated hall-root coordinate frame used by the capture tool, the same location is `(10, 0, 9)`. The museum supplies the player, camera, lighting and XRTools.

Make a one-node `Node3D` scene with this `study.gd` attached. The script creates its figures, tools, table, cylinder links, labels and controls. No prebuilt mesh nodes or dollar references are required. The small human/tool geometry is supplied display construction; the new algorithm is the model above.

<details open>
<summary>Complete study.gd</summary>

'''+code('study.gd')+'''
</details>

NEXT or `1` first runs the greedy scan, then searches for one augmentation per press. ORDER or `O` changes the scan order and resets. RESET or `R` clears the pairing after the point is released. The displayed history is only the pair count after changes: `[0, 1, 2]`; it is not a recording of the whole workshop state.

The familiar black sphere is a handle above maker A. Grab it to move that figure in the table's local XZ plane. Its place changes; permitted pairs do not. The held trigger calls NEXT. On release, the same point stays with the same figure. We reuse pickup/release rather than teaching it again.

<details>
<summary>Unchanged files carried from Flow — complete dependencies</summary>

'''+''.join(code(n)+'\n' for n in ['point_body.gd','route.gd','traversal.gd'])+'''
</details>

## Change one condition yourself

In a separate copy, replace the link `[0, 3]` with `[1, 3]`. Predict both scan orders before running them. The listed order now finds two pairs directly. The reversed order first takes `1–2` and leaves A waiting; augmentation follows `[0, 2, 1, 3]` and restores two pairs. Explain why moving a figure would not have changed this requirement. Only editing the relation changes the available partnerships.

The workshop's fixed four-role drawing is not a general graph editor. The model can accept larger consecutive disjoint sets, but a larger scene needs corresponding figures and links. We test that distinction instead of promising a display that automatically adapts to every input.

## Compare the other things in the room

The larger ring-and-spokes exhibit uses an odd cycle and a greedy scan. CYCLE FIRST gives three pairs; SPOKES FIRST gives five on the same ten vertices and ten edges. Its order button restarts the scan. It does not implement the alternating-path repair above, and its general graph cannot be fed unchanged into our bipartite model. Full blossom handling, weighted assignment and preference-based matching are further subjects.

The **Ada relations** model is a companion for reading the project. VIEW separates the spine's recommended order, declared dependencies, concept returns, shared artifact tokens and selected dated review milestones. PREVIOUS/NEXT selects a sequence; HALLS/ALL shows its rooms. These relationships are many-to-many. A sequence may depend on several others; a concept may return repeatedly. They are not pairings with an exclusivity rule.

Read the source ledger beside that model. Plan declarations are not evidence that a learner has mastered a subject. Shared tokens do not establish shared live state. Dates name selected saved review folders, not the first invention of an idea. The graph lets us inspect our chosen account of Ada; it does not complete that account.

The next sequence, Foundations Crisis, asks what a procedure's success entitles us to claim. Carry this distinction: a valid pairing, a largest collection and a good arrangement for the people are three different questions.

Algorithm reference: [Princeton Algorithms: bipartite matching](https://algs4.cs.princeton.edu/code/javadoc/edu/princeton/cs/algs4/BipartiteMatching.html). The GDScript above uses the route finder already built in Ada; it is not Princeton's implementation.
'''
(M/'tutorial.md').write_text(t,encoding='utf8')
(M/'final.md').write_text('''# Room for two

One person takes the drill. The other waits. There is still a saw on the table.

<!-- @matching_workshop -->

The first choice was allowed. That is what the pale connection told us. It did not promise that accepting this choice would leave a useful choice for someone else.

Follow the waiting person's line to the drill, then back to the person holding it. From there another line reaches the saw. No new tool arrives. Someone changes their arrangement, and both can work.

The model makes that change easy. A pair is an entry that can be cleared. A person can release a tool without losing time, face, trust or the work already begun. We have supplied a willingness to reconsider by leaving all those costs outside the table.

There is something worth keeping in the movement nevertheless: what looked like a shortage was partly the consequence of an earlier allocation. Looking again changed what the room could offer.

<!-- @edmonds_algorithm -->

Across the room, five points form a ring, each with another point waiting outside it. Let the ring's edges go first: three pairs form. Let the spokes go first: five. The connections have not changed. The rule against pairing an endpoint twice has been obeyed both times.

A rule can be followed while its promise remains unmet. Here we can count the gap and demonstrate another arrangement. Elsewhere the thing we hope an arrangement will provide may not have an agreed measure.

The people at the little table have declared tasks. Their lines record which tools those tasks permit. They do not tell us whom to trust, what someone wants to become, or whether a more efficient allocation is welcome. Two selected edges cannot settle those questions.

<!-- @ada_relations -->

Now look at Ada itself. The rooms become small buildings; the walk becomes a line. Change the view. Connections reach back across the route: a concept returns, a lesson names an earlier dependency, an artifact appears again.

The chronology beside them keeps dates from selected saved reviews. A date tells us where an account was kept. It cannot tell us when an idea first began to trouble us. Nor does the tidy line erase the returns, revisions and arguments that made the work possible.

These are different relations. We have drawn them separately so that one cannot quietly stand for another. Going next is not depending on. Sharing a name is not carrying the same object. Being connected is not being paired.

<!-- @ -->

The drawing is useful because we can return to the files that support it. It remains open because those files can change. Before the next room asks what a proof can hold, keep the saw in view: the unused possibility was there all along, but the first arrangement did not make it available.
''',encoding='utf8')
print('Matching tutorial/final: complete operation, carried files, concrete workshop, separate project relations.')
