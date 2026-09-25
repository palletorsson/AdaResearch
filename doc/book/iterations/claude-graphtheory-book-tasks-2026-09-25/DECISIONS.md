# graphtheory — the 24 Sept book tasks applied, 25 September 2026

Tasks `book_graphtheory.001`–`.018`: twelve applied and closed, six left open with a note. Walking the spine from its far end (forum 260925-tvljg). A prose-only pass: no scene, map or code was changed; two captures were copied into `doc/book/figures/graphtheory/`.

| task | hall | what landed |
|---|---|---|
| .001 | GT_Spanning_Trees | the chapter says what the display does: the considered edge turns yellow, an accepted one gets a green line, a rejected one is left yellow and unmarked, so the tracing is the visitor's; "yellow edge" replaces "rejected edge" at the later mentions; footnote `[^red]` cites the registry description (line 5357) against the commented-out call |
| .002 | GT_Network_Analysis | paragraph 1 names what is visible (large red vertices orbit slowly and pulse harder, small green ones circle faster and glow less; NetworkAnalysis.gd:150-182, :436, :452); "a size or a glow" for "an animated number"; the two computed numbers follow a clock and are never shown; "its two meters, a ball on a bar at either side, do not move" |
| .003 | GT_Pathfinding | the spark's crossing and hops in place of a displayed route (four phrases); the readout's stone count; "If the readout says NO ROUTE" (impatient_river.gd:133) |
| .005 | GT_Layout | "Its positions are not fixed: connected vertices pull together as if on springs, every pair pushes apart, and damping wears the motion down" |
| .006 | GT_Matching | both stills placed under one caption, after the spokes-first paragraph rather than the cycle-first one, so the prediction the chapter asks for ("predict what will happen to the point you chose") is not answered by the second still before it is made |
| .007 | GT_Layout | "Count: every vertex in this graph has exactly three neighbours" (the shipped adjacency is Q3, ForceDirectedLayout.gd:121-124) |
| .008 | GT_Connectivity | yellow when visited, orange when finished but waiting on the stack, a back edge red at the moment the low-link is lowered (tarjan_algorithm.gd:89-99, :595-603, :628) |
| .009 | GT_Flow | "The source shows a negative excess: it is the total it has sent out and will not receive back" (push_relabel.gd:891, :1017-1022) |
| .010 | GT_Foundations | "the hall calls it the tide" / "the diver", as the readout names them |
| .011 | four halls | the backlog paragraph folded into a question the visitor can already ask: Foundations (make one lamp urgent: under which traveller does it wait longer?), Layout (walk to the far side: is the central vertex still central?), Pathfinding (which stones did the search pass over before it settled on these?), Spanning Trees (one extra edge to spend: which yellow one?); kept as the honest confession in Network Analysis and Flow, as the task proposes |
| .013 | GT_Matching | the file name moved to footnote `[^name]`; the prose keeps the greedy / Edmonds distinction |
| .014 | GT_Matching | the exit names the plaque of the next hall: five sentences, one coloured gold before it is read (Euclid_Parallel §2) |

Left open, with a note on each:

- .004 (GT_Connectivity) and .012 (GT_Layout) ask for scene changes (a lesson_controls panel for tarjan / mst / push_relabel; a push button wired to reset_simulation). Prose-only pass; both are small and their models exist (edmonds_algorithm's panel, impatient_river's button). Recommended as one follow-up commit with a map token gate.
- .015–.018 (GT_Foundations) wait on a placement decision for Königsberg and the two graph cities, then a walk from the seam. The edges-pilot candidate (`doc/book/iterations/claude-graphtheory-gt-foundations-edges-pilot/final.candidate.md`) stays uninstalled; the two sentences applied to the installed chapter here (.010, .011) are already in the candidate word for word, so a later install is a straight replace.

Verification: every replacement matched exactly once; footnotes defined; fences balanced; all eight files LF and kept LF; the two stills read back as PNGs of the sizes printed in the run log.

Disclosure: GT_Flow and GT_Matching carried uncommitted hunks from another writer dated 20 September (the BLOCKED paragraph and the forward-only sentence; the ring-and-spokes rewrite of Matching), never committed by anyone: GT_Flow (4 lines), GT_Matching (8 lines). They land here whole; `before/` is the tree as found, so the diffs beside it are this pass alone.
