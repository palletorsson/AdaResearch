from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/GT_Flow';S=R/'doc/book/studies/graphs-through-the-hands/GT_Flow'
def code(n):return '<!-- student-code:'+n+' -->\n```gdscript\n'+(S/n).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Flow — room for another

**Learning elements**

- Directed capacity and allocated flow
- Reusing breadth-first pathfinding on residual connections
- The bottleneck of a route
- Reversing an earlier allocation
- Conservation, completion and a limiting cut

The tree connected everyone cheaply. It did not tell us how much could pass through a connection. We keep our point and seven vertex IDs, but give the links a new meaning: **crate slots available during one planning interval**. A capacity is not the build cost from Spanning Trees.

The small harbour is a fictional logistics model. Its buildings are stock, two depots, two transfer yards, a dock and a destination. The boxes on its links are allocation markers. We are planning deliveries before dispatch, not simulating trucks, queues or moving water. One marker means the link is used; the numeric label gives its assigned amount.

**Carry:** PointBody, the queue and the complete route finder from Pathfinding. **New:** a capacity table and a flow table. **Supplied:** the existing museum/XRTools and the complete harbour drawing below. Keep earlier lesson folders intact.

## First see the obstruction

The museum's existing push/relabel display fills source connections, then tries to pass excess onward. Its height is an algorithm label, not physical altitude. The implementation follows only original forward edges. It can stop with excess left at a junction, and its label explicitly says that a maximum has not been established. Keep that comparison: an early allocation may need revision.

Our smaller reconstruction uses complete source-to-destination paths. Every completed step conserves flow at intermediate vertices. It does **not** reproduce the comparison's temporary excess or height procedure.

## Give the route finder a different set of neighbours

Make a `GT_Flow` folder beside the earlier studies. Copy `point_body.gd` and `traversal.gd` unchanged from Spanning Trees, and `route.gd` unchanged from Pathfinding. Save this as `flow_model.gd`.

'''+code('flow_model.gd')+'''
`capacity[a][b]` is the declared limit. Each row is a separate array. `flow[a][b]` is the amount assigned in that direction, and the opposite entry records its negative. The example has no original pair of opposite links; the negative entry records permission to cancel an allocation, not a second physical road.

`residual(a, b)` subtracts what is assigned from what is available. After assigning one unit from 1 to 3, the forward residual is zero. The reverse entry is `0 - (-1)`, giving one unit of permission to revise that choice.

`search()` builds neighbours only where residual capacity is positive. Then it calls the **same** breadth-first route finder we already used. It finds a path with the fewest residual edges, not the shortest physical journey. We replace its old neighbours explicitly, so the old reciprocal detour does not leak into this model.

`step()` takes the smallest residual capacity along that path: its bottleneck. It adds that amount in each forward traversal and subtracts it in the opposite entry. A path that traverses a reverse residual edge cancels part of an earlier allocation. Each successful step increases the total reaching the destination.

This is Edmonds–Karp on a small integer network. Capacity and reverse-flow conventions can also be inspected in the [NetworkX maximum-flow documentation](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.flow.maximum_flow.html). Our code is implemented here; NetworkX is not a runtime dependency.

## Predict two allocations

| Action | Residual path | Result |
|---|---|---|
| First step | 0 → 1 → 3 → 5 → 6 | Allocate one crate slot |
| Second step | 0 → 2 → 3 → **1** → 4 → 5 → 6 | Cancel 1 → 3; total becomes two |
| Third step | No residual source-to-destination path | Mark the allocation complete |

On the second step, 3 → 1 is a revision. Final deliveries can follow 0 → 1 → 4 → 5 → 6 and 0 → 2 → 3 → 5 → 6. No delivered crate is magically retrieved. The final link 5 → 6 has capacity two. So do the two source links together: no allocation can exceed two, and our allocation achieves two. Here that gives a simple independent certificate of the maximum.

The two final routes share the dock. A route existing does not mean it owns all that capacity. Intermediate inflow must equal outflow after each complete augmentation; the source and destination are the exceptions.

## Put the plan in the museum

Save `study.gd` below on a single Node3D named `Study`, and save that node as `study.tscn`. All displayed objects and controls are created by the script. Place your study in the Flow hall at map-local `(9, 0, 3.8)`, yaw 180 degrees, scale 1. In the isolated hall wrapper, whose map starts four metres along Z, the equivalent local position is `(9, 0, 7.8)`.

The existing museum provides the player, camera, lighting and pickup function. This study adds the familiar black point, buildings, directed links, allocation markers and two nearby controls. The primary programming subject remains the small flow model; this full host makes it runnable.

<details open>
<summary>Complete harbour host — study.gd</summary>

'''+code('study.gd')+'''
</details>

Hold the black point above yard 4 to move that building across the plan. As in Layout, a change of coordinates leaves the represented connections unchanged. We now project onto local XZ because this is a tabletop. Capacities remain fixed. Its trigger or `1` plans the next allocation; the nearby PLAN NEXT control does the same. Release before `R` or RESET.

Labels show **assigned / capacity**. A pink raised connection identifies a cancelled allocation on the latest step. It is separate from the original directed roads. The final empty search clears the latest path display; the assigned totals stay visible.

## Make a different limit

Change only the final link, 5 → 6, from capacity 2 to **1**. Reset and predict the result before stepping. One crate slot reaches the destination; no second residual path can pass its full final link. The network is still connected by routes. Its capacity is smaller.

Now restore that capacity to 2 and set 1 → 4 to **0**. Predict the same total of one for a different reason: both depots must compete for the single slot on 3 → 5. A zero-capacity link can remain in the drawing while being unavailable to the search.

The tests reconstruct the printed code, check conservation and capacities, compare many small inputs with independently enumerated cuts, and reject a version that cannot cancel earlier choices. Passing a single demonstration is not enough.

## Carried code, unchanged

These files are printed so the lesson can be reconstructed without an undisclosed dependency. They are not new lessons.

'''
for n in ['point_body.gd','traversal.gd','route.gd']:
 t+='<details>\n<summary>'+n+' — unchanged</summary>\n\n'+code(n)+'\n</details>\n\n'
t+='''The next hall is Matching. One early pair can prevent two later pairs; an alternating path will give revision another concrete job.
'''
(M/'tutorial.md').write_text(t,encoding='utf8')
(M/'final.md').write_text('''# Room for another

Two depots have something to send. The first route is open, so you use it. Then the second delivery waits.

<!-- @graph_worlds -->

The little harbour makes the problem look familiar: buildings, roads, boxes, a dock. Each connection has a number. It counts available crate slots during the interval we chose. It says nothing about what is inside a crate, who needs it, or how long they have already waited.

Follow the first allocation through yard 3. There is room at the destination, but the route you chose has taken a connection the other depot needs. An acceptable decision has made another decision harder.

Press again. A pink connection appears above the plan. It takes back one part of the earlier allocation. The first delivery can use yard 4; the second can use yard 3. Both now fit.

Nothing has travelled backwards through time. These are commitments being revised before departure. Once a ship has sailed, a model's reverse arrow is not enough to recall it. The ability to revise has conditions: time, information, permission, and something not yet made irreversible.

<!-- @push_relabel_algorithm -->

Across the room, the older display begins by sending as much as it can out of its source. Excess gathers at junctions. Local labels change; another push becomes possible. Its forward-only procedure can also reach a point where it cannot pass the remainder onward. The excess stays visible. This is where that procedure stopped, not proof that no other arrangement could work.

Keep those two experiences beside one another: the accumulation that cannot proceed, and the allocation that becomes possible when a previous choice can change.

It is tempting to call every obstruction a bottleneck and every revision an improvement. But a harbour, a conversation, a flock and an infection do not carry the same thing. Crates are conserved in this plan. A message can be copied. Infection requires more than a connection. A person's need does not become a capacity because we have put a number beside it.

The models let us ask precise questions. Their precision also makes their omissions available to us. Who chose the interval? Which route was never recorded? Who is being asked to wait while we celebrate a larger total?

<!-- @ -->

At the next table, each person can take one tool. The first reasonable pairing may have to change so that another person can make something too.
''',encoding='utf8')
print('Flow tutorial/reflection written; five complete scripts.')
