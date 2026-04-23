# Chamber Arrays — Summary

Chamber_Arrays is the catalyst chamber for the Array Tutorial sequence. It is the only catalyst chamber in the curriculum that does not hand the learner a projection tool. Instead, the chamber is observational: a grid agent traverses the floor, and the learner arranges obstacles for it to adapt around.

The chamber is small. A grid covers the floor, labelled by row and column. A grid_agent:copy moves through the grid according to a simple traversal rule — row-major scan, with detours around obstacles. The learner carries a set of small blocks they can place on any cell. Each placement forces the agent to find a new path.

A science screen on the wall reads out the agent's current plan as a sequence of cell indices. As obstacles are added, the plan updates, and the screen highlights which indices changed. A second display tracks how many extra steps each new obstacle costs, so the learner can see their placements as increments to the agent's path length.

Within the sequence, Chamber_Arrays reframes the catalyst practice as arrangement rather than projection. The lesson is that arrays hold state, and state responds to what is placed within it. The chamber hands the learner back to the Lab with the array catalyst absent by design.
