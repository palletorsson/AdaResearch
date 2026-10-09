# Change a rule, watch a population

How much of a collective pattern changes when one local rule changes?

<!-- @ant_colony_optimization -->

Watch the colony long enough to recognise a trail. Raise EVAPORATE and see whether that trail persists between visits. Use RESET before making a second comparison. Keep ANTS steady at first, so a change in the population does not obscure the effect of changing its shared memory.

The trail image is a record of deposits that are also disappearing. With faster evaporation, continued traffic matters more to keeping a route visible. A line that looks like a stable piece of the environment is actually being maintained by repeated events.

A useful comparison separates a trail’s width from its persistence. A busy route can spread across several cells while individual marks still disappear quickly. A narrower route can remain visible between relatively infrequent visits. Try describing both qualities before judging which colony is more organised. The heatmap lets many overlapping events become one visible pattern, so two similar-looking patches need not have been maintained by the same number of agents or the same timing of visits.

This is an agent-based model: individuals carry state and follow rules, while their interactions produce a population-level picture. Here those rules include movement, sensing, depositing traces and responding to food. The field is shared state. Changing evaporation changes what every agent can encounter without directly changing every agent’s position.

Next vary ANTS. This control changes the number of agents and respawns them, so treat it as a new population rather than a continuous observation of the old individuals. Compare fewer agents leaving more persistent marks with more agents leaving shorter-lived marks. They may produce superficially similar pictures for different reasons.

The MODE control offers three behaviours within this model family. It does not turn the room into a language for inventing arbitrary agents. A useful comparison still begins by naming exactly which rule or condition has changed.

An agent can be a convenient unit without being an adequate model of a person. These agents inherit the same limited sensory world, and the shared grid decides which traces can count. A simulation of people would need an argument for those omissions, not simply a change of labels from ants to citizens.

As a proposed extension, give two groups different sensing capacities while keeping the environment shared. Would a path that looks equally available from above remain equally available from within each agent’s world?

<!-- @ -->

The next colony makes one relation particularly clear: information about home and food travels in different channels.
