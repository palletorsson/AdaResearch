# Which points get a say?

<!-- @space_colonization_algorithm -->

Three pink points wait above a small root. Two sit apart at the same height; the third is higher, between them. Before pressing anything, follow a line from the root towards each point. Which way would you go if all three asked at once?

The gold lines show those requests. The short white segment proposes a step. Press STEP and watch a pale branch take its place. The root has moved nowhere. It has acquired a child, half a metre above it. Neither side point has been reached. Something useful happened between their demands.

In the last room, an evaluator compared whole bodies with a target number. Here the target has become a distribution of positions. We call them attraction points. They do not exert a simulated force, and they are not light sensors. They are coordinates that a rule consults while adding segments.

Start with one request. Subtract the site's position from the point's position. This gives a vector pointing from here to there. We have met that subtraction before. Now normalize it: keep its direction, give it length one. A distant point will not get a longer vote merely because it is farther away.

These are the lines in the running program:

```gdscript
var direction = (attr_point - closest_node.position).normalized()
closest_node.growth_direction += direction
```

The opening root receives three unit directions. The leftward and rightward components cancel; the upward components add. The program normalizes their sum and takes a fixed step:

```gdscript
var growth_dir = node.growth_direction.normalized()
var new_position = node.position + growth_dir * segment_length
```

Here `segment_length` is 0.5. The two side requests are at (-2, 3, 0) and (2, 3, 0); the upper request is at (0, 5, 0), measured from the model's root. The first new position is therefore (0, 0.5, 0). The geometry you predicted is the geometry the code builds. The gold construction now shows a decision for the next generation, not a replay of the previous one.

Press FIELD once. Eight known points replace the three, and growth starts again. Their arrangement is uneven. Press STEP several times and follow the strand. Some points pull it sideways; others remain behind. You can keep advancing, one generation at a time. A reached point becomes small and dark. It leaves the active calculation but stays visible, so the encounter does not erase every trace of what mattered.

There is a restriction easy to miss in the name of this artifact. Under TIPS, a growing end can produce one successor. That successor replaces it in the eligible set. From this single root, the rule makes a strand. A sufficiently crooked strand may suggest a tree in silhouette, but it has not made a fork.

Press HOLD when you have a specimen worth comparing. It appears on the side plinth at 0.45 times the display scale; its proportions and parent relations are kept. This is a small witness, not evidence that the algorithm shrank its body. Now press POLICY. The same eight points and the same root return at generation zero, with NETWORK on the readout. Press STEP again.

Watch for a site that has already produced a child and later produces another. The new policy lets earlier sites remain eligible to receive requests. Each active point chooses its nearest eligible site within eight metres. Requests assigned to one site are still summed; each site can add at most one child per generation. A fork becomes possible across generations because an earlier site can act again. Changing who may respond changes what this construction can become.

The held strand remains beside the growing tree. Compare a local fork before comparing their overall outlines. NETWORK is the control's name; this implementation still attaches each new node to one parent. It builds a rooted tree, without joining existing branches into loops. Another topology will require another operation.

FIELD once more opens a canopy of 96 fixed points. Its asymmetry is authored through sine offsets, using a tool we already know. It is not fresh randomness at each step. The field helps make the form; calling the result organic does not remove that authorship. A perfectly balanced field can cancel sideways directions and leave a stem. More points alone do not promise more branches.

Some requests may remain when growth stops. RULE names the operations and the budgets: this study permits at most 192 nodes and 60 generations. A limit reached by the computer is not a tree's natural maturity. RESET restores the three-point opening and TIPS, while keeping the held witness. You can return without pretending that nothing has happened.

Walk around the specimen and onto the rear deck by its side ramp. The museum supports your body. The drawn branches do not have collision surfaces. A connected parent record, a visible shape and a place you can inhabit are three relations we must learn to build together.

We have changed eligibility while keeping the points. In Branching Growth, next, we will change what a site listens to: one nearest invitation, rather than the sum of several. Before admiring another tree, find that smaller difference.

<!-- @ -->
