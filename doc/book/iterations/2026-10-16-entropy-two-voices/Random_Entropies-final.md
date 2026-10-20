# What remains uncertain

<!-- @entropy_chairs_shannon -->

We have left a sphere returning to its centre. Here, a pink chair rests on a shelf against the wall. Below, more chairs stand in groups: seats at the height of our knees, backs, four legs, spaces a body could enter. The object is familiar before its place in the experiment is clear.

We stop beside eight chairs, four pink and four black. The wall asks us to imagine choosing one with equal chance, recording its colour and returning it. Pink or black: neither answer has an advantage. The reading is one bit. Shannon entropy measures uncertainty in the colour under this rule; two equally likely answers give one bit.

In the neighbouring version, the colours occupy different places. Both groups remain in view. We can carry a pattern from one to the other and find that it no longer fits. The reading stays at one.

Farther along, seven chairs are pink and one is black. We keep the black chair in sight. A guess of pink would now succeed seven times out of eight. The entropy reading falls while our attention stays with the less likely colour. The reading follows the colour probabilities. It gives no extra weight to the chair that catches our eye.

<!-- @entropy_chairs_boltzmann -->

We cross the low divider. Four pink and four black chairs stand on eight marked places. In one version all the pink chairs occupy the left half. In two others, each half holds two of each colour. The last two arrangements differ, though the words describing them do not.

“Two pink on the left.” That brief fits thirty-six colour assignments. “Four pink on the left” fits only one. A complete assignment is a *microstate* here; the brief is its *macrostate*, an account that leaves some details open. Chairs of the same colour count as interchangeable.

Boltzmann entropy relates to how many microstates fit a macrostate. The plate prints S/kB = ln Ω: Ω is the number of matching assignments, and kB is Boltzmann's constant. The logarithm, ln, puts the count on a scale where multiplying possibilities adds to the reading. The values are zero for one assignment and about 3.584 for thirty-six. These chairs supply a small counting model. Their temperature has no part in the calculation.

We look between the two groups that share thirty-six possibilities. The number cannot tell us which group stands before us. Describing this particular arrangement would require something more.

<!-- @entropy_chairs_description -->

Along the next wall, four groups of six chairs offer descriptions. Two rows of three. The same rows with one chair shifted and turned. A disturbance repeated across the group. Then positions and angles that seem to resist a pattern we could carry away.

The last recipe is short too: seed 435 and the shared generator. The seed familiar from the previous hall has found another use. Given that procedure, it supplies the offsets and turns again. We would have to bring the generator with us; the number alone does not contain these chairs.

Algorithmic complexity asks for the shortest program that produces a specified arrangement in a chosen language. The wall offers candidate recipes. It cannot certify that any is the shortest; no general procedure can always do that. Yet the scatter already unsettles a simpler judgement. Difficulty in seeing a rule has not established difficulty in writing one.[^description]

A drawing surface and loose notes wait nearby. A sketch could keep the arrangement as it looks from here. The recipe would keep a way to construct it. Neither has to do the other's work.

<!-- @entropy_door_dynamics -->

The next rule moves. Three doorways pass through a solid wall. At one side, a translucent door leaf sits almost against a solid one. They start a little apart, then close by halving their angles at each step. Their separation narrows until the leaves are difficult to distinguish.

Across the passage, another pair begins just as close. Its rule doubles each angle and wraps it back into the allowed range. The leaves separate. We wait through the repeating cycle; closeness at the beginning no longer tells us how close the next positions will be.

The apparatus records a smaller event than the whole moving door: LOW or HIGH, according to which half of the angle range it occupies. Across 1,024 equally likely starting bins, the expanding rule keeps adding distinctions to an eight-step record. The closing rule retains the first distinction and soon adds no more. Dynamical entropy concerns the rate at which such information grows through time. This finite comparison makes the question inspectable without claiming to measure its long-term rate.

The centre doorway stays open. We pass between the two rules.

<!-- @entropy_cooling_cup -->

Behind the wall, five cups share a table with a plate and a donut. We look down. White milk lies in brown coffee, first as a distinct region, then drawn into finer swirls. At the last cup the colour is even. Each surface represents the same quarter share of milk. There is no last pale island to follow there.

The swirls continue moving. The five cups hold prepared stages beside one another; waiting does not turn the first into the fifth. Their labels carry a separate calculation, at zero, five, fifteen, thirty and sixty seconds of cooling.

In that model, heat passes from the cup into a cooler surrounding body. The cup's thermodynamic entropy falls; the surroundings gain more than it loses. Their combined entropy increases as their temperatures approach each other. The units have changed to joules per kelvin. Here temperature and energy enter the account. The milk image and the steam wisp supply neither reading.

We can return our gaze to the first cup while the last remains beside it. The table allows a comparison that an ordinary cooling drink cannot keep on its own.

<!-- @entropy_frosted_chair -->

The pink chair returns behind glass. Five panes progressively spread its edges, until the last withholds the chair altogether. We walk along the panes. The object stays; access to its details changes.

The labels declare what each record retains. There are eight possible chair identities: two colours, with or without arms, with or without a lower back rail. Before a record, each is equally likely. Complete identity leaves one candidate. Colour and arms leave two. Colour alone leaves four. With no detail retained, all eight remain possible.

Two middle panes have different frost but the same colour record. Both leave two bits unresolved. Conditional entropy measures the uncertainty remaining after the specified observation. Here its conditions are printed beside the glass. The shader changes what we see; the declared record determines the number.

We can still try to recognise the chair through a pane. That attempt has no reading here.

<!-- @entropy_ball_pit -->

Beyond the glass, colour becomes a guess. Three tables hold sixteen equal-sized balls each: eight pink and eight teal, then twelve pink and four teal, then sixteen pink.

We choose a colour before an imagined draw, with each ball equally likely and returned afterward. At the first table either guess would succeed on eight of sixteen chances. At the second, pink would succeed on twelve. At the last, pink cannot miss.

Min-entropy attends to this best chance. It takes minus the base-two logarithm of the largest outcome probability: one bit, about 0.415 bits, then zero. Shannon entropy averages surprise across the possible outcomes; this reading follows the most likely answer.[^guess]

We stop at the all-pink table. Every ball's place remains visible, but the colour answer is settled. We could rearrange the whole tray and leave that answer untouched.

<!-- @ -->

[^description]: The recipes are visible in the installed [chair comparison](../../artifacts/ordinary_entropies/comparison.gd); the [generator](../../artifacts/ordinary_entropies/model.gd) is part of their construction. Paul Vitányi's [How incomputable is Kolmogorov complexity?](https://arxiv.org/abs/2002.07674) explains the limits of computing the shortest program. The [tutorial](tutorial.md) reconstructs the comparisons without treating a candidate program as a proven minimum.

[^guess]: [NIST's min-entropy definition](https://csrc.nist.gov/glossary/term/min_entropy) formalises the largest-probability question. Here the probabilities come from the displayed colour inventory under the stated uniform-ball draw.
