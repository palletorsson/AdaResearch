# A hypothetical trace of the tree cut

**Text thought experiment. Not executed in Godot; no visitor has been observed through this record.** This is an authored prediction using the [proposition's](proposition.md) assumptions and its invented fixture. No configuration has been applied to a running node under this record's identity.

| Step | Assumed action/state | Predicted consequence | What execution must establish |
| --- | --- | --- | --- |
| 0 | Instantiate bridge_cut.tscn and set the baseline (graph="tree", cut="none", closure="open") via apply_grid_config | One grey component; plate "STILL CONNECTED / 1 piece"; component_count() 1, has_bridge() true with _bridge_edge 0 | A real boot, the configuration receipt and a probe readback |
| 1 | Ask for cut="chord" at the baseline | Nothing is removed; plate "NO CHORD TO CUT / every edge is a bridge / still 1 piece"; count stays 1 | That _chord_edge is -1 on the real node and the verdict bytes match |
| 2 | Apply the single change cut="bridge" | The trunk edge [0,1] becomes a red dashed stub; nodes recolour into pieces of 1 and 7; component_count() 2 | The union-find result, the recolour in a capture, and which edge was elected |
| 3 | Reset cut="none", set closure="returned" | Edge [4,7] appears; still 1 component; _chord_edge becomes 1; has_bridge() stays true | That the demotion is discovered by _find_special, not scripted |
| 4 | Ask for cut="chord" at closure="returned" | Edge [1,2] is removed and the body holds: "STILL CONNECTED / 1 piece" | That a circuit really makes a line on it dispensable in this build |
| 5 | A visitor writes a prediction, then cuts | The prediction cannot be read off the picture; a miss is informative | An actual human encounter at the plinth, the prediction kept from before the cut |
| 6 | Return to tutorial and final | Each review is decided independently | Evidence-linked reviews of both texts and a next-work decision |

A counter-trace is equally useful, as hypotheses rather than events. On the harness side: a probe that sets exports directly could be refused in silence on a typed property and measure the default instead of the variant, and `_rebuild` frees old meshes deferred, so a same-frame capture could photograph two generations at once.

On the mapping side: the plate text rather than the recolour might carry the meaning for a visitor, collapsing the comparison into reading; and the hall's reroute removes and re-attaches in one release while this artifact only ever removes or only ever adds, so neither axis alone may reproduce the passage (held as learning debt `bridge-cut.debt.reroute-vs-cut` in [the record](./experiment.json)). None of these failures has occurred; none has been ruled out.

No predicted recolour, verdict string or recognition is reported as an observed result. The [observation log](observations.md) stays empty until evidence exists.
