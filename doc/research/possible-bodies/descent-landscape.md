# Where does downhill take you?

[Working route](index.html#FormFinding_Descent) · [Book primary](/necklace/thread?map=FormFinding_Descent&role=primary) · [Previous: Force as Place](force-as-place.html)

**Form Finding opens with a controlled landscape.** One primary experiment compares two surfaces, three beginnings, four step sizes and three stopping tolerances. The five older exhibits remain behind it as comparisons. The book now follows the experiment before explaining its rule.

![The two-valley surface in the actual museum, with controls and the local path](descent_valleys.png)

## Try it

1. Predict the next address. Press STEP a few times on the bowl, then RUN.
2. Reveal PARTS and RULE. Compare the pink local direction with the gold history.
3. Change SURFACE to two valleys. Keep RATE at 0.7 and STOP at 0.01; compare the first and second START.
4. Note the cost when each says SMALL SLOPE. The recorded endpoints are about -0.304 and 0.295. Both meet the same tolerance.
5. Return to the bowl. Compare loose and tight STOP settings, then increase RATE. A long step can raise cost or leave the frame.

Changing a setting resets the run; RESET preserves the settings. The presentation clock paces updates but is absent from the optimisation equation. This marker has no momentum. The retained marble toy does, and it periodically receives programmed kicks: a comparison to inspect, rather than proof that the two processes are identical.

![The opening bowl after five steps, before the code is revealed](descent_bowl.png)

## What the experiment establishes

| Display | What happened | What it does not establish |
|---|---|---|
| SMALL SLOPE | Local sampled gradient fell below the chosen tolerance | A global minimum |
| LEFT FRAME | The proposed address left the six-metre domain; the last valid point is retained | Convergence |
| STEP LIMIT | The budget of 160 moves was spent | A sufficiently good answer |

The surface draws cost at height 0.40 + 0.22 × cost. Its 48 by 48 cells do not determine the gradient: the update samples the analytic function at offsets of 0.03. This is a plot on a solid pedestal, with clear circulation around it; the blue surface is not walkable physical terrain. Its local direction arrow is capped at one metre.

The room gains sixteen rows for this experiment. All five original placements shift together into the rear gallery; its former front wall opens into the extension. The old twenty-metre noise terrain is reduced to 0.14 scale as a supporting exhibit. No old artifact identity is removed.

## The thread into Form Finding

| Hall | New question | Next concrete work |
|---|---|---|
| Descent | Where does a local rule take us, and why does it stop? | Implemented and desktop checked; learner and headset visit remain |
| Catenary | What can change between held endpoints? | Inspect supports, length, load and the cable's actual update |
| Relaxation | How can local constraints change a connected shape? | Compare the mass-spring and Verlet implementations |
| Equilibrium | What balances, and is the balance stable? | Test a perturbation; do not infer stability from one still frame |
| Annealing | What can accepting an uphill proposal make accessible? | Inspect the acceptance rule, schedule and repeated trials |
| Forge | Which measure and constraints will you author? | Establish actual controls before promising freely authored models |

These are working questions for the remaining halls, not claims that their existing scenes already demonstrate them. The sequence description now avoids equating every objective with physical or biological free energy.

## Evidence

36 checks pass in the actual desktop museum, including pointer presses, analytic bowl comparison, distinct valley endpoints, all stopping conditions, capped history, nine reachable controls, clear approaches and all five retained exhibits. Captures were inspected. Headset comfort, stereo legibility and a learner walkthrough remain open.

[Check report](descent-landscape-check.json) · [Placement ledger](descent-landscape-placements.json) · [Page and book source](descent-landscape.md)

**Next: Catenary.** A point searched a landscape we supplied. Now ask how a connected shape can change when its endpoints are held.

## Book passage

# Where does downhill take you?

<!-- @descent_landscape_lab -->

The last room let a field carry you across a gap. You brought motion into it; the field changed that motion; something of the journey remained when you left. Here a gold point waits above a blue surface. There is no gap to jump. There is a button marked STEP.

Before pressing it, choose where you think the point will go.

One press leaves a short line behind. Another extends it. The number called cost changes. Try a few more presses before RUN. What repeats? What gets smaller? Does the point travel the same distance each time?

RUN lends the operation a rhythm. It repeats the same step, with a pause between updates so you can follow it. The pause helps us watch; it is not time inside the equation. Stop the run and take over with STEP again. The line remembers where the point has been, but that memory does not propel it.

This is already a departure from Forces. There is no stored velocity here.

## A direction without a destination

Press PARTS. The pink arrow offers a local direction. It lies horizontally, above the drawing; its length is capped at one metre. It does not point at a destination that the program has found elsewhere. The program has looked a little to either side of the current address.

In the x direction it asks how much cost changes between x minus 0.03 and x plus 0.03. It divides that difference by the distance between the samples. It does the same along z. Two comparisons make a vector: the sampled gradient. Its negative gives the direction the point will try.

Now reveal RULE. The moving point becomes a short instruction:

```gdscript
proposed = point - rate * gradient(point)
```

The subtraction is familiar. We have carried vectors, combined them and used them to cross space. Here subtraction changes an address in a search. RATE decides how far to trust the local direction. It does not name speed in metres per second. No mass is divided out; no acceleration is accumulated.

On the opening bowl, the cost is one quarter of x squared plus z squared. At the usual rate, the steps shrink as the point approaches the centre. The program does not need to know the centre's address to make those steps. We can see the whole bowl; the update uses nearby samples.

Eventually the display says SMALL SLOPE. Look at that wording before calling the run solved.

## Two beginnings

Switch SURFACE. The blue drawing now has two unequal valleys. Changing a setting starts a fresh run, so the next trail belongs to that setting alone. Keep RATE at 0.7 and STOP at 0.01. Run from the first START, note the final cost, then select the second START and repeat.

Both runs can stop at a small slope. They do not arrive at the same cost.

In the recorded desktop comparison, the first run finishes near -0.304 and the second near 0.295. The rule, tolerance and surface are shared. The beginning differs. One valley is lower, but the point in the other valley has no instruction to cross the intervening rise in search of it.

The surface makes this difference visible all at once. The moving point encounters it locally, one update at a time. You can walk around the plot and see the other valley. That knowledge has not entered the algorithm merely because it has entered your view.

What would have to change for the point to search there? Keep the question. Annealing will give us one way of approaching it later.

## How much is enough?

Try a looser STOP setting. A larger tolerance accepts a larger remaining slope. The run can finish earlier, at a different address and cost. Nothing in the surface has announced that this much unfinished movement is acceptable. We supplied that threshold.

Then return to the bowl and increase RATE. A downhill direction is a local statement; a long step can pass the useful part of it. Cost can rise. At the largest setting, a proposed step can leave the six-metre frame. The display says LEFT FRAME and keeps the last valid point. It does not silently push the point back against an edge and congratulate itself.

A third ending, STEP LIMIT, means the budget of 160 moves was spent. These endings answer different questions. Small slope describes a local measurement. Leaving the frame describes a boundary. Spending the budget describes how long we agreed to search.

Even a zero gradient would not by itself prove a global minimum. A maximum or a saddle can have one too. Here we can inspect the authored surface and compare runs. Elsewhere that overview may be unavailable.

## The surface we agreed to search

The plot is drawn with 48 by 48 cells, each split into two triangles. The gradient samples the cost function directly, at offsets of 0.03. It does not read the rendered triangles. What you see and what the point measures are related representations with different resolutions.

Its displayed height is another choice:

```gdscript
height = 0.40 + 0.22 * cost(point)
```

The height makes cost legible across a table. It is not gravitational potential energy, and the blue mesh is not a floor for your body to climb. The point's apparent descent comes from changing an address and drawing the result. Behind this experiment, the retained marble toy carries velocity and receives periodic programmed kicks. Its motion may resemble searching, but it uses another update. The resemblance gives us a comparison to investigate.

There is room for a different body in these small changes. One beginning inhabits a valley another beginning misses. A threshold admits one endpoint and rejects the next. Yet lowering cost only means improving according to the cost we wrote. Nothing in the arithmetic establishes that this measure contains everything worth keeping.

For now the landscape is authored and the point searches it. We have not yet let a connected shape emerge under load. In the next hall, hold two ends of a cable and let the space between them become the question. What can change when some things must remain fixed?

<!-- @ -->
