# Between smoothing and disturbance

<!-- @self_organization_ca -->

When a patch changes, is it following its neighbours or being disturbed away from them?

Watch the self-organisation display for several updates. Choose a boundary between differently coloured regions. Does the boundary soften, spread, break apart or persist? Compare one small patch with the larger arrangement before deciding that the whole display is orderly or chaotic.

Try following two patches at different scales. In a small patch, individual changes may appear abrupt; across a larger region, their combined effect may look gradual. Keep the observation time similar for both readings. Also distinguish an enduring boundary from a boundary that repeatedly disappears and returns nearby. A single glance can make those histories look alike. Before reaching for a category such as chaos, state the shorter description you can support: a patch persisted, a difference spread, or several neighbouring values became more alike during the interval you watched.

The cells hold integer states from zero to nine. Their next values combine a response to a neighbourhood average with a random disturbance, followed by conversion back to the allowed range. The displayed configuration therefore makes two tendencies compete: neighbours can pull states towards one another, while disturbance can separate them again.

An authored parameter called lambda couples those tendencies. Across its range, neighbour coupling decreases as the amount of random disturbance increases. That is a particular design for exploring a transition. It is not the same thing as measuring every possible cellular rule and locating a universal boundary between order and chaos.

The display uses labels for a supposed critical region, but those labels are not an experimental result. To support such a claim, we would need to define what is measured: persistence, sensitivity to a changed seed, correlation length, or something else. A complex-looking picture cannot decide between them.

The most useful extension would show two runs with the same starting state and random sequence, differing only in one cell. We could then watch whether the difference disappears, remains local or spreads. A second comparison could vary neighbour coupling independently of disturbance, revealing what the current single parameter combines.

<!-- @ -->

You have now met repeated local updates that create structures larger than their neighbourhoods. The next sequence approaches repetition from another direction: a construction that explicitly calls for smaller instances of itself. Carry the difference between an emerging resemblance and an instruction to repeat.
