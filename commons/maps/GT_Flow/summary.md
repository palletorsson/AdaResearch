# GT Flow — Summary

GT_Flow is the seventh map in the Graph Theory sequence. It introduces capacity as a first-class property of edges and asks how much can pass from a source to a sink before the network saturates. The answer lives in the narrowest passage the graph contains.

The room is shaped as a funnel. A wide entrance holds many incoming pipes; a narrow exit at the far end holds few. Between them, a network of intermediate pipes with different capacities routes the flow. The learner walks the funnel and feels the constraint: the exit is tight, and whatever the network's internal capacity, the total throughput cannot exceed it.

A live simulation pushes flow from source to sink. Pipes fill until they saturate; saturated pipes glow and cap their throughput at their capacity. A running total above the sink reports the current flow. The algorithm is selectable — the map runs push-relabel or Ford-Fulkerson on demand, and both converge to the same answer.

The max-flow value is compared to a min-cut display on the side wall. The cut is drawn as a coloured line across the network separating source from sink; its total capacity equals the flow rate. The identity that max-flow equals min-cut becomes visible rather than memorised. Within the sequence, Flow is the throughput chapter. GT_Matching will next bring the sequence to its close.
