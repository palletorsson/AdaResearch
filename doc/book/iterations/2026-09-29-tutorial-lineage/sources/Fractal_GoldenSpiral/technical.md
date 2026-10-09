# Numerical recurrence, height and geometric remainder

Two primary artifacts now have compact physical desks. `fibonacci_sequences` uses the existing live script at `algorithms/fractals/fibonacci_sequences/FibonacciSequences.gd`. The scene's text path previously named an inactive copy under stringalgorithms while its UID loaded the fractals copy; path and UID now agree. The inactive file is preserved exactly as archived. Both artifacts opt in with `#lesson:true`; ordinary scenes retain their automatic behavior.

## Fibonacci values and height

The source starts at [1,1] and generates twenty values by appending the preceding pair's sum. The teaching desk reveals two through ten terms, ending at 55. No automatic step advances this teaching view. NEXT/BACK change only the number of visible terms. HEIGHT switches between `h = 0.05 * value` and the existing logarithmic rule `h = 0.5 * log(value) + 0.5`. Indices, values, spacing and colour assignments remain consistent across the comparison. These are mathematical mappings into metres, not physical growth models.

SUM shows the last available addition as two matching stacks at a fixed 0.05 m per unit: the left stack joins the two summands in separate colours; the right is their sum. It is independent of the tower-height mapping. With fewer than three terms there is no addition to display. At ten terms, both stacks contain 55 units and are 2.75 m high. RESET restores two logarithmic towers and hides SUM/RULE. Ten terms bound the size and draw work of this encounter.

The original helix, natural-pattern panels and branching diagram are built once from their existing source functions and retained on supports. Their process-driven CSG rebuilding is disabled in the opted-in teaching instance. Their dimensions and construction rules remain. The downward branching diagram is raised so its last generation meets its display rather than being buried below the museum floor. The legacy Godot 3 material property `flags_transparent` is replaced by Godot 4's transparency enum in the live source.

The source helix uses `r = 0.1 * phi ** (angle / TAU)`, with a vertical term; this multiplies radius by phi per full revolution. It is not the conventional golden logarithmic spiral, whose radial multiplier is phi per quarter revolution. The 144 seed points use `r = 0.1 * sqrt(i)` and `angle = i * TAU / phi²`. The pinecone-like construction has 8 pieces in each of 13 layers with a 0.3-radian turn between layers. Shell-like chambers and the branching diagram introduce other explicit rules. These are constructed resemblances, not validated biological explanations.

## Golden rectangle and arcs

The second source computes `phi = (1 + sqrt(5)) / 2`. The initial rectangle is 5 by 5/phi metres. A cut removes a square of side `min(width,height)` and retains a rectangle with one dimension reduced by that side. The remainder alternates orientation and retains the long/short ratio phi, up to floating-point error. Squares plus the current remainder partition the original area; historical remainder records must not be summed again as additional material.

The desk permits zero through eight cuts. It presents the existing generated geometry upright, with shallow 0.01 m extrusion. MEASURE labels the actual square side in metres and the cut index. Legacy Fibonacci number labels do not measure these shrinking squares. NEXT/BACK/RESET regenerate bounded geometry and detach old nodes before queueing deletion.

ARC adds quarter-circle segments through the squares. Corrected arc centres in directions 1 and 3 make adjacent endpoints meet; each complete arc has 20 straight segments and both endpoints. The displayed curve is a polygonal rendering of piecewise circular arcs, not an exact logarithmic spiral. The arc is kept slightly in front of the squares. View toggles do not change the rectangle data. Ordinary source modes retain their auto-generation with the endpoint repair.

## Retained room and limits

The original 17×15 structure is preserved at offset (3,24) in a 23×39 hall. Its five other placements stay at that offset. The two primaries move into the added approach so controls and their studies have space. The old raised sphere cell, gaps and walls remain. This wider hall exceeds the automatic 13–19-cell width recommendation because it stages the retained full-sized diagrams; the authored placement and walking route are checked explicitly.

The existing recursion cabinet had no map-ready registry flags and was omitted at runtime. Its existing scene is now available. Romanesco's source was trying to add already-parented buds a second time. Reparenting without preserving the global transform now gives each bud its intended local offset under its actual parent: 13, 169 and 2,197 descendants at depths 1–3. This bug repair affects other instances using the same source. The 0.382 scale is approximately 1/phi², not 1/phi. DLA and the Fibonacci terrain retain their own automatic rules; neither receives a new controlled comparison.

The same six full-size push targets and small transparent tilted screen used in preceding halls serve each desk. The rendered acceptance runner uses synthetic input through the real DesktopPlayer pointer pipeline. Native mouse interaction, human headset reach/comfort/readability and Quest frame time remain separate pending checks. Archive and receipts: `doc/space/golden-mapping-2026-09-14/`.
