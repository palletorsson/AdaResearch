# Change a rule, watch a population

How much of a collective pattern changes when one local rule changes?

<!-- @ant_colony_optimization -->

Watch the colony long enough to recognise a trail. Use RESET and watch the beginning again. The food returns to the same places, with the same qualities; the ants begin with the same headings. Now raise EVAPORATE, reset, and compare. Keep ANTS steady at first. You are changing how quickly the ground forgets, while giving the next colony the same beginning.

The trail image is a record of deposits that are also disappearing. With faster evaporation, continued traffic matters more to keeping a route visible. A line that looks like a stable piece of the environment is actually being maintained by repeated events.

A useful comparison separates a trail’s width from its persistence. A busy route can spread across several cells while individual marks still disappear quickly. A narrower route can remain visible between relatively infrequent visits. Try describing both qualities before judging which colony is more organised. The heatmap lets many overlapping events become one visible pattern, so two similar-looking patches need not have been maintained by the same number of agents or the same timing of visits.

This is an agent-based model: individuals carry state and follow rules, while their interactions produce a population-level picture. Here those rules include movement, sensing, depositing traces and responding to food. The field is shared state. Changing evaporation changes what every agent can encounter without directly changing every agent’s position.

Next vary ANTS. The control replaces the population but leaves its field behind. The new ants arrive in a world marked by ants that are no longer there. Watch whether they pick up an old route. Then RESET: this time the marks disappear too. Replacing the travellers and erasing their history are two different acts. Compare fewer agents leaving more persistent marks with more agents leaving shorter-lived marks; similar pictures can have different histories.

The MODE control offers three behaviours within this model family. Colony is the foraging you have been watching. Communication lets an ant returning with good food send a ring out from the nest and lead one idle ant to the source in tandem. Multi-Source nudges foragers towards richer food and draws each source’s quality as a ring around it. It does not turn the room into a language for inventing arbitrary agents. A useful comparison still begins by naming exactly which rule or condition has changed.

An agent can be a convenient unit without being an adequate model of a person.[^braitenberg] These agents inherit the same limited sensory world, and the shared grid decides which traces can count. A simulation of people would need an argument for those omissions, not simply a change of labels from ants to citizens.

As a proposed extension, give two groups different sensing capacities while keeping the environment shared. Would a path that looks equally available from above remain equally available from within each agent’s world?

<!-- @ -->

The next colony makes one relation particularly clear: information about home and food travels in different channels.

[^braitenberg]: Valentino Braitenberg built the classic version of this warning in 1984: vehicles with two sensors and two motors, wired straight or crosswise, that any observer describes as fearful, aggressive or loving. He called it synthetic psychology, and noted that it is downhill to invent such a creature and uphill to analyse one; the attribution comes free with the watching. Reynolds's vehicles, and these ants, descend from his.
