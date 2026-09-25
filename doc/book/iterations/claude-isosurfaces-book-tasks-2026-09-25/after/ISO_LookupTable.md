# Eight samples, one local decision

<!-- @fifteen_cases_demo -->

What can eight corner samples tell you about the space between them?

Compare two tiles in the fifteen-case display. Find their corner indicators before following their triangle edges. Look for a tile with one separated corner, then another in which several corners share a classification. How does the boundary change when the arrangement of classified corners changes?

Choose a pair of indicators on opposite ends of an edge and ask whether their classifications agree. If they disagree, locate the corresponding boundary crossing where it is visible. Repeat on another edge before trying to read the whole tile. This lets you build an explanation from a relation small enough to check directly. When the corner arrangement becomes more complicated, retain that edge-by-edge reading instead of guessing a familiar shape. The case table organises many such local questions, but each crossing still begins with values at particular sample positions.

The corner values used by the indicators also feed the surface generator. A comparison with the threshold turns each corner into a bit. Eight bits provide a case number, which selects a triangle arrangement from a table. Edge crossings are then positioned using the numerical values at their endpoints.

These are two different uses of the samples. Their signs choose a connection pattern; their magnitudes help decide where a crossing lies along an edge. Two cells can choose the same table case while placing its triangle vertices at different positions.

The previous room showed the assembled surface. This display makes some of its recurring local decisions easier to inspect. The fifteen examples show selected arrangements, while the complete corner classification contains two hundred and fifty-six masks. Symmetries help relate cases; they do not remove every ambiguity about a continuous surface between samples.

There is another scale to attend to: the displayed pieces include surrounding sampled cells. Read the marked corners as the local question under study, rather than assuming every visible triangle belongs to one isolated cube.

Press TRACE. Gold markers appear where the cage edges cross the selected level. Choose one before pressing MARGIN. The values change from 0.30/0.70 to 0.14/0.54, then 0.44/0.84 and 0.48/0.88. The threshold remains 0.50. Every low value stays below it and every high value stays above it.

From the high endpoint toward the low endpoint, the crossing moves through 0.50, 0.10, 0.85 and 0.95 of the edge. Watch the marker before looking at the entire sheet. Its movement follows a small calculation:

```gdscript
t = (threshold - d0) / (d1 - d0)
position = p0.lerp(p1, t)
```

OPERANDS hides the extracted sheets, leaving the cages and samples. SURFACE removes those guides and shows the generated result. RESET restores the complete display and evenly spaced values. MARGIN changes the values in any of these views. Which view lets you explain what just happened, and which invites you to forget the construction?

The labels expose another convention. The inherited arrangement number sets bits for high-valued corners. The extractor sets bits for values below 0.50. Those masks are complements: arrangement 1 has table mask 254. The positions and values agree; the two names count opposite classes. “Inside” has not arrived with an independent physical meaning.

These are fifteen selected arrangements, including empty and full classifications, not a demonstrated exhaustive catalogue of distinct topologies. On alternating faces, corner classifications alone leave a connectivity question for the algorithm. This display shows the installed table’s choice; it does not compare every ambiguity-resolution strategy. Keep that limit in view; the next work in the hall is where the whole sequence is put on trial.

<!-- @the_threshold_opinion -->

Between the fifteen cases and the rear pair stands one field in the dock, shown as a lattice of rods whose lengths are its values: the invisible standing in plain sight. Around it, five surfaces extracted from that one field at five thresholds, a fat blob, a lean one, a pinched pair, a thin shell, one broken into islands, and nothing in the field changed between them. MARGIN moved the values and held the cut; here the cut moves and the values are on show. Beside them the same threshold is sampled on a 4, an 8 and a 14 lattice, a brass rack holds the fifteen cases you have just read, and one pair of blobs is caught mid-merge at the crossing, seamless where no mesh operation could have joined them.

<!-- @ -->

Next, the field will describe familiar objects. The triangle-making procedure stays the same while the description handed to it changes.
