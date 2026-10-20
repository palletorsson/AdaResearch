# What remains uncertain

<!-- @entropy_chairs_shannon -->

We have left a sphere returning to its centre. Here a pink chair stands against a wall, its feet on the same floor as ours. The seat is at knee height. A back, four legs, an empty place: the object is familiar before its part in an experiment is clear.

More chairs stand in groups nearby. We stop beside eight, four pink and four black. The wall proposes choosing one with equal chance, recording its colour and returning it. Pink or black: neither answer has an advantage. The reading is one bit. Shannon entropy measures the average uncertainty in that colour under the stated draw; two equally likely answers give one bit.

The neighbouring group has the same colours in different places. We look for a pink chair where a black one stood, then find the pink elsewhere. Both arrangements remain available to our gaze. Their readings agree.

Farther along, seven chairs are pink and one is black. We keep the black chair in sight. A guess of pink would succeed seven times out of eight. The entropy reading falls while our attention stays with the less likely colour. The calculation gives no extra weight to the chair that catches our eye.

The unchanged reading at the first two groups now needs another question. Those places are different. What would an account have to retain for their difference to matter?

<!-- @entropy_chairs_boltzmann -->

Across the low divider, four pink and four black chairs occupy eight marked places. In one version all the pink chairs are on the left. In two others, each half holds two of each colour. We can trace an arrangement from seat to seat and lose it when we look at the next version.

“Two pink on the left.” That brief still fits. Thirty-six colour assignments satisfy it. “Four pink on the left” fits only one. A complete assignment is a *microstate* here; the brief is its *macrostate*, a description that leaves some details open. Chairs of the same colour count as interchangeable.

The thirty-six possibilities are not thirty-six chairs hidden elsewhere. They are different ways of filling these eight places while keeping the stated totals. Only one assignment occupies each version in front of us.

Boltzmann entropy relates to how many microstates fit a macrostate. The plate prints S/kB = ln Ω: Ω counts the matching assignments, and kB is Boltzmann's constant. The logarithm puts that count on a scale where multiplying possibilities adds to the reading. One assignment gives zero; thirty-six give about 3.584. This is a finite counting model. The chairs' temperature has no part in it.

We look between the two arrangements that share thirty-six possibilities. The number cannot tell us which stands before us. A description of this particular arrangement would have to keep something more.

<!-- @entropy_chairs_description -->

Along the next wall, four groups of six chairs offer recipes. Two rows of three. The same rows with one chair shifted and turned. A disturbance repeated across the group. Then positions and angles that seem to resist a pattern we could carry away.

The last recipe is short too: seed 435 and the shared generator. The beginning familiar from the previous hall now supplies offsets and turns. It will supply them again. We would have to bring the generator with us; the number alone does not contain these chairs.

Algorithmic complexity asks for the shortest program that produces a specified arrangement in a chosen language. These are candidate recipes. The wall cannot certify that any is the shortest; no general procedure can always do that. Difficulty in seeing a rule has not established difficulty in writing one.[^description]

A drawing surface and loose notes wait nearby. A sketch could keep the view; a recipe could keep a way to construct it. But how exact must that recipe's beginning be? A small error in a chair position might remain small. A rule that uses its own result again could carry an error further.

<!-- @entropy_door_dynamics -->

Three doorways pass through a solid wall. At one side, a translucent leaf sits almost against a solid one. A narrow gap separates their edges. Will another movement widen it or bring the leaves together? A shared control marked STEP advances both pairs once. On this side, each angle halves. With another step the gap narrows again, until the leaves are difficult to distinguish.

Across the passage, another pair begins just as close. The same button doubles each angle, wrapping it back into the permitted range when it crosses the end. A starting difference too small to catch easily becomes visible. The leaves have not received different rules. They have carried different beginnings through the same rule.

We return to the beginning and reduce the gap. More steps may pass before the difference becomes conspicuous. At zero gap, the two leaves stay together. Neither experiment needs a new random number at each step.

Below each pair, LOW and HIGH keep a history: which half of the angle range held each leaf. The record is coarser than the movement. Two different angles can leave the same letter. With the default gap, the expanding pair meets again at step nine. Their earlier differences remain written below. A shared position has not given them a shared past.

The wall also calculates records from 1,024 equally likely starting positions. Over eight observations, halving leaves one bit of uncertainty about the record; doubling leaves eight. Longer records reach a ceiling of ten bits for this finite set of starts. Dynamical entropy concerns the rate at which information in such records grows. The computer experiment makes that question inspectable without measuring the ideal rule's long-term rate.

RESET returns the leaves and clears their histories. It supplies the starting values again; it does not retrace every intermediate angle. We can recover a beginning because the apparatus has kept the means to construct it. What would returning require if the change involved heat passing into something else?

The centre doorway stays open. We pass through with that question still attached to the reset.

<!-- @entropy_cooling_cup -->

Five cups share a table with a plate and a donut. We look down. White milk lies in brown coffee, first as a distinct region, then drawn into finer swirls. At the last cup the colour is even. Each surface represents the same quarter share of milk. The pale part has become harder to point to without becoming a smaller share.

These five surfaces keep stages beside one another. Their swirls move, but waiting does not turn the first cup into the fifth. We can look back to a white patch that the final image no longer separates. The table preserves a comparison that a single stirred drink cannot hold in one view.

The labels follow another change: cooling at zero, five, fifteen, thirty and sixty seconds. In the calculation, a hotter body representing the cup exchanges heat with a larger, cooler body representing its surroundings. The latter is not pictured as another cup. Its temperature and entropy are included in the account.

The cup loses energy and its thermodynamic entropy falls. The surroundings gain energy and more entropy than the cup loses; the combined entropy rises as the temperatures approach one another. The units are joules per kelvin. These readings come from the heat model, not from the milk image or the rising wisp.[^heat]

Here the question from the doors acquires somewhere else to look. Restoring a cup's earlier temperature would require another exchange. Restoring both bodies with no other change would undo an irreversible process; the model supplies no such return. Reloading an earlier digital snapshot remains easy. That operation reconstructs the represented temperatures without returning heat from a room to a drink.

We look again at the even coffee surface. It has suggested a change whose physical account we could not read from the image alone. What a surface lets us distinguish is itself another question.

<!-- @entropy_frosted_chair -->

The pink chair returns behind glass. Five panes progressively spread its edges, until the last withholds the chair altogether. We walk along them. The furniture stays; access to its details changes.

The labels specify what each record retains. There are eight possible chair identities: two colours, with or without arms, with or without a lower back rail. Before a record, each is equally likely. Complete identity leaves one candidate. Colour and arms leave two. Colour alone leaves four. With no detail retained, all eight remain possible.

Two middle panes have different frost but the same colour record. Both leave two bits unresolved. Conditional entropy measures the uncertainty remaining after the specified observation. Its conditions are printed beside the glass; they are not inferred from our success at recognising the chair.

We can still lean towards a pane and try to find an armrest. The attempt has no reading here. Yet it makes the next decision concrete: if the record cannot identify the chair, which answer should we give?

<!-- @entropy_ball_pit -->

Beyond the glass, chairs rise in four pyramids. Nine stand on the floor, four rest above them, then two, then one. The seat that held a body now takes the feet of another chair. In the first pyramid, eight are pink and eight black. Here the question changes: which type will appear in a new draw? We choose pink, though black has as much claim, and use DRAW to reveal a chair. A gold ring marks it. Each of the sixteen IDs has the same draw chance; selecting it leaves it available for the next draw.

Either guess has a fifty percent chance. A single match proves very little about that chance. Min-entropy attends to the best possible single guess: minus the base-two logarithm of the largest outcome probability. Here it is one bit.[^guess]

In the next pyramid, half the black chairs have arms. There are three answers now: pink, black, black with arms. Pink still wins half the chances. Min-entropy stays at one, while Shannon entropy rises from one to one and a half bits. The less likely alternatives have acquired another distinction. The best guess gains nothing from it.

We can look for the armrests that make the readings disagree. If the answer kept only colour, those two black categories would merge again. The extra distinction belongs to the question as well as to the furniture.

The third pyramid has twelve pink chairs and four black. Pink wins three quarters of the chances; min-entropy falls to about 0.415 bits. CHANGE ONE turns a black chair pink. We can make the answer easier, one object at a time.

In the last pyramid all sixteen are pink. A chair near the floor carries more than its own weight. We can grip it and draw it out, or press into the stack as we walk. Whatever falls must find another support. Each chair keeps its letter and number as it moves; the draw still chooses among the same sixteen. The best colour guess remains certain, its min-entropy zero.

An upright pyramid and a fallen pile can give the same answer. Nothing in that movement can surprise the colour record. What the arrangement does to its neighbours is still available to another account.

<!-- @ -->

[^description]: The installed [chair comparison](../../artifacts/ordinary_entropies/comparison.gd) and [generator](../../artifacts/ordinary_entropies/model.gd) disclose the recipes. Paul Vitányi's [How incomputable is Kolmogorov complexity?](https://arxiv.org/abs/2002.07674) discusses the limits of finding the shortest program. The [tutorial](tutorial.md) reconstructs candidates without treating their lengths as proven minima.

[^heat]: The [implemented model](../../artifacts/ordinary_entropies/model.gd) uses two finite, internally uniform bodies with constant heat capacities and conserved combined energy. Each entropy change is C ln(T/T₀). [MIT's entropy-change notes](https://web.mit.edu/16.unified/www/SPRING/propulsion/notes/node40.html) explain the two-body calculation and its irreversibility. The installation does not model milk diffusion, evaporation or the heat cost of computation.

[^guess]: [NIST's min-entropy definition](https://csrc.nist.gov/glossary/term/min_entropy) formalises the largest-probability question. Readings use the displayed category inventory under uniform chair-ID selection with replacement. Each private generator resets to seed 435; knowledge of its state can reveal the next selection. The category readings do not certify cryptographic unpredictability.
