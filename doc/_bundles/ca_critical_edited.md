<<<ADA_BUNDLE>>>
sequence: cellularautomata
file: critical.md
maps: 8
skipped_passing: 1
created: 2026-04-23T22:45:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: CA_Introduction>>>
# The rug is an argument — local rule, global ornament, and the politics of collective decision

A Persian rug is usually admired as a decorative object. The map inverts the admiration. Instead of a finished pattern, the rug is a live cellular automaton: successive rows computed from triplets of cells in the row above, displayed from top to bottom as the rule fires. What looks like centuries of textile tradition is here a few lines of logic applied to a single row of cells, repeated.

Stuart Kauffman's work on self-organisation argues that order does not need to be imposed from above. A set of simple local rules, applied uniformly, can produce global structure that no single cell could have anticipated. The rug is Kauffman's thesis made walkable. Each cell looks only at its neighbours. Each cell applies the same rule. Each cell updates in the same generation. No cell is in charge, and yet the pattern is legible as a design.

The architectural artifacts on the floor extend the argument. A small column is assembled cell by cell from a rule that adds a supporting cell whenever two neighbours are filled. A bridge spans a gap using a similar rule with different neighbour thresholds. The structures are incidental to the sequence's argument; they are there to show that discrete local decisions pile up into structure that can carry weight.

The politics of this map are in the uniformity of the rule. Every cell applies the same transition. The symmetry is not a convenience; it is the condition for the rug's pattern. Break the symmetry — let cells apply different rules — and the global coherence disappears. The map argues that a particular kind of collective order requires every participant to follow the same procedure, and that relaxing this condition costs the order.

This is a quietly conservative argument. Emergent order from local rules sounds democratic; it is actually a thesis about uniformity. Real social systems rarely meet the conditions the map assumes. Individual cells do not usually apply identical rules, and attempts to enforce identical rules are the subject of entire critical literatures. The map does not claim otherwise; it claims only that under the uniformity assumption, structure emerges.

The grid quantises the world into cells. Each cell is either occupied or not; each cell has exactly four or eight neighbours; each cell updates on the same tick. Henri Lefebvre's analysis of grid-based space is relevant here: the grid is a political technology that reduces heterogeneous reality to cells it can address. The rug is beautiful, and the beauty is paid for in the quantisation that made computation possible at all.

Within the sequence, Introduction is the grammar lesson. It names the ingredients — discrete cells, discrete time, local rules, uniform application — and it argues that this is enough for pattern to arise. CA_GameOfLife and CA_ElementaryRules will next raise the stakes by showing that the ingredients can also produce life, universality, and unpredictability.

<<<MAP: CA_ElementaryRules>>>
# 256 worlds — Wolfram's classification, rule 110's universality, and the politics of a complete enumeration

Stephen Wolfram's classification of elementary cellular automata is an audacious move. Take the simplest possible setup — one dimension, two states, three-cell neighbourhoods — and enumerate every possible rule. There are 256 of them. Run each and observe. Wolfram claims that the observed behaviour falls into four classes — trivial, periodic, chaotic, and complex — and that this tiny rule space is enough to contain universal computation.

Douglas Hofstadter's work on strange loops anticipates the stakes. A system capable of universal computation is a system capable of representing itself, and once a system can represent itself, the usual separations between description and thing-described collapse. Rule 110 is proven Turing-complete. A three-cell-wide, two-state automaton can be compiled to run arbitrary computation. The rule space is tiny; the computational power inside it is unbounded.

The map stages the 256 rules as a walkable gallery. Each rule is shown as a scrolling one-dimensional automaton whose successive rows are stacked vertically. A scroll bar moves the learner through the rule space. Some rules die immediately; some produce clean nested triangles; some generate apparent chaos; a small number support moving structures. The gallery's flatness is the argument: 256 rules, 256 worlds, one per wall panel, and the learner can compare them without being told in advance which ones matter.

Two rules are pulled out for closer study. Rule 30 produces output indistinguishable from random noise despite being fully deterministic. Rule 110 is Turing-complete. A side panel sketches the proof at a high level. The proof is not the point; the point is that Turing-completeness is hiding inside a three-cell-wide rule table that a schoolchild could enumerate.

Wolfram's classification was controversial because it proposed that this tiny rule space is a universal lens on complexity. A New Kind of Science, his book, argued that phenomena from biology to physics to culture could be modelled as cellular automata. The argument is reductionist, and critics including Cosma Shalizi and Melanie Mitchell pushed back: universality is not explanation, and finding a CA that produces a pattern is not the same as showing that the CA is the cause of the pattern.

The map holds the controversy lightly. It does not claim that CAs explain everything; it claims only that the rule space is enumerable, that the enumeration includes universality, and that the combination of these two facts is worth sitting with. The 256 walls make the enumeration walkable. Rule 110 makes the universality unarguable. The rest is interpretation.

Within the sequence, ElementaryRules is the argument for minimalism. The previous map introduced cellular automata in two dimensions with Conway's Game of Life; this map strips the substrate to one dimension and shows that two dimensions were not required. The spectrum from triviality to universal computation fits inside the smallest possible substrate, and the learner leaves with the spectrum's weight.

<<<MAP: CA_GameOfLife>>>
# Birth, survival, and death — Conway's rules as biological vocabulary and the politics of naming

Conway's Game of Life has three rules. A cell is born when it has exactly three live neighbours. A live cell survives when it has two or three live neighbours. Every other configuration produces death. The rules are deliberately biological — birth, survival, death — and the biology is load-bearing rather than decorative. The language shapes what the learner sees the automaton doing.

Lorraine Daston's work on the moral economy of scientific language argues that the words chosen for scientific objects do political work. A cell that "dies" at two neighbours is a cell whose fate is dramatised. A cell that "survives" has been read as an individual with stakes in its own continuation. Conway's naming choices are not neutral; they enlist the observer into a particular kind of attention, and the attention treats the automaton's dynamics as a life cycle rather than as a state transition table.

The map stages six configurations around the floor. Each station runs a different initial seed and lets the same rule set unfold into different dynamics. One station stages an avalanche — a small seed that cascades across the grid. Another grows a dendrite that reaches outward in branches. A third demonstrates a stable oscillator, a fourth a slow crack, a fifth a percolation pattern, a sixth a short-lived ecosystem of gliders and glider guns. The same rules produce each, depending on what was there to start with.

The glider is the game's most charged structure. It is a small pattern that repeats its own shape at a fixed displacement every four generations, so it appears to walk across the grid. A glider gun is a larger pattern that emits gliders periodically. The universal computation results for Life are built from arrangements of gliders and guns configured to compute. Once again, the minimal substrate turns out to support arbitrary complexity.

Daston would note the biology-to-computation slide. A pattern that "walks" by repeating its shape is called a glider; a pattern that emits gliders is called a gun; a configuration of guns and walls is called a logic gate. The language migrates from life to machinery as the learner zooms out. This migration is part of Life's rhetorical power: it suggests that life and computation are different scales of the same phenomenon, and it trains the observer to see both at once.

The politics of the game are in what "life" means inside the rules. A cell is alive if it is one, dead if it is zero. Alive and dead are state labels, not properties. The stakes the observer feels — the dread when a promising configuration collapses, the pleasure when a glider escapes — are projections onto state transitions. Conway's game is not cruel; it is indifferent. The cruelty and the pleasure belong to the observer, and the observer's investment is what makes the automaton interesting.

Within the sequence, Game Of Life is where state transitions acquire the names living things carry. CA_ElementaryRules strips the biology out again and asks what happens in one dimension; this map establishes the vocabulary the strip will play against. The learner leaves having watched one rule set produce avalanches, cracks, ecosystems, and gliders, and the variety is the map's argument.

<<<MAP: CA_BeyondBinary>>>
# Totalism is a relaxation — hex grids, VR Life, and the politics of counting instead of configuring

Elementary cellular automata and Conway's Game of Life both look at the specific arrangement of neighbours. A rule for a cell might say "alive if top-left is alive and bottom-right is dead". Totalistic rules relax this. Instead of consulting the arrangement, they consult only the count — how many neighbours are in each state. The rule table shrinks dramatically, and similar configurations produce similar outcomes.

Gilles Deleuze writes about the difference between molar and molecular organisation. Molar organisation treats elements as tokens of types, identified by their specific positions. Molecular organisation treats elements as statistical populations, identified by their distributions. Totalistic rules are molecular in Deleuze's sense. They do not care where the neighbours are, only how many of each kind there are, and the shift from configuration to count is a philosophical one as much as a computational one.

The first station in the map runs a 2D totalistic rule. Rather than consulting the arrangement of neighbours, the rule counts neighbours in each state and uses the totals to decide the next state. The rule table is small enough to print on a clipboard, and the map does. The behaviour is smoother than an elementary rule's: similar configurations produce similar outcomes, and sharp discontinuities give way to gradients.

The second station runs Game of Life on a hexagonal grid. A hex has six neighbours instead of eight, so the thresholds change; the rule set is re-derived live on a panel. Gliders still appear, but they travel in hex-aligned directions rather than grid-aligned ones. The map argues that the neighbourhood shape is not a natural property of cellular automata; it is a chosen constraint, and changing it changes which structures the rules can support.

A VR booth at the back of the room lets the learner place seeds in a three-dimensional hex grid and watch them unfold overhead. The booth is deliberately non-rectangular. Its geometry is part of the argument: neighbourhoods do not have to be square, rules do not have to be tuned to square neighbourhoods, and the assumption that cellular automata are fundamentally grid-based is a habit rather than a requirement.

Deleuze's molar/molecular distinction lands on a political question. A rule that cares about the specific configuration of neighbours is a rule that privileges legibility — the individual agent's position matters. A rule that cares only about the count is a rule that privileges aggregate behaviour — the population's statistics matter, and individual positions are interchangeable. Neither is automatically preferable, but they support different kinds of collective behaviour, and the map demonstrates that the choice between them is structural rather than aesthetic.

Within the sequence, Beyond_Binary loosens the substrate before CA_ExpandingSpace expands the neighbourhood. The sequence's trajectory is clear in retrospect: each map relaxes one of the earlier maps' implicit assumptions and watches the behaviour change. The loosening is itself a political practice — treating every assumption as revisable rather than as background.

<<<MAP: CA_ExpandingSpace>>>
# Neighbourhood is reach — radius as politics, locality as contested, and the 3D tree as evidence

Earlier maps assumed each cell sees only its immediate neighbours. Nearest-neighbour rules were the default; the assumption was quiet. This map makes the assumption explicit by treating the neighbourhood radius as a parameter. At radius one, the tree grows as a thin thread. At radius two, it thickens into a trunk. At radius three, it branches.

Manuel DeLanda's assemblage theory argues that the reach of a component — how far it can interact with others — is a determinative feature of any assemblage. Short reach produces tightly local structures with weak global integration. Long reach produces globally integrated structures with weaker local specificity. The reach is not fixed; it is a parameter of the assemblage, and different values produce different kinds of assemblage.

The central station runs a 3D tree driven by a local growth rule. The rule fires whenever enough cells within a chosen radius are filled. The radius is a slider at the entrance. Turning the slider changes the tree's morphology dramatically: the same rule, under larger neighbourhoods, produces qualitatively different structures. The parameter that looked like a detail turns out to shape the outcome as much as the rule does.

A second station runs a crossway automaton. Two influence zones from opposing corners of the grid overlap in the middle of the floor. Where they meet, the rules interfere: cells satisfy both conditions simultaneously and the boundary produces structure that neither zone would have produced alone. The interference is visible as a thickened band where the two zones' reach overlaps, and the band carries patterns that neither zone's rule would have generated by itself.

DeLanda's argument reads cleanly here. The assemblage is different when the reach changes, and the assemblage is different when two reaches meet. Neither the radius nor the shape of the neighbourhood is a detail; both are determinants of which structures the rules can support. The map argues that locality itself is a political decision, and that the choice to assume nearest-neighbour interactions is a decision that shapes the character of the whole computation.

The politics extend outward. Social systems are cellular automata-like assemblages whose reach parameters are the subject of constant contest. Whose word travels how far; whose influence extends how many hops; what counts as a neighbourhood — these are politically charged questions, and the map's radius slider is a small demonstration that the question is mechanical as well as ideological. Change the radius and you change the system.

Within the sequence, Expanding_Space is where locality becomes tunable. CA_SoftRules will next introduce non-determinism and ask what happens when the rule itself is a probability rather than a certainty. The trajectory of the sequence continues to be a serial relaxation of earlier assumptions, and this map's contribution is the observation that "local" was never a fixed quantity.

<<<MAP: CA_SoftRules>>>
# Stochasticity is a concession — Rule 30 under noise and the politics of imperfect rules

Cellular automata from the earlier maps are strictly deterministic. A rule fires if its conditions are met; a rule does not fire if they are not. The next generation is fully determined by the current one. Real systems rarely behave like this. Thermal noise, measurement error, quantum uncertainty — all introduce randomness into rule application, and the resulting dynamics can look very different from the clean deterministic sibling.

Ilya Prigogine's work on dissipative structures argues that noise is not always destructive. Under the right conditions, a system that admits small amounts of randomness can self-organise more effectively than its noiseless equivalent. The noise provides the symmetry-breaking fluctuations that allow new structures to emerge. Prigogine's insight is that determinism is not always the ideal; some kinds of order depend on a baseline of stochasticity.

The map revisits two rules the learner already knows: Rule 30 and Rule 110. Each is run in two copies — a clean version and a softened version that fires only 80 percent of the time. The clean versions reproduce the familiar deterministic outputs. The softened versions look similar at first and then drift. Edges fuzz, triangles lose their sharp corners, the characteristic texture of each rule degrades unevenly as randomness compounds across generations.

A third station applies external forcing in the form of gravity. Cells accumulate a bias toward a particular state, so the usual rule outcomes are pushed in one direction. The resulting patterns mimic physical systems where thermal noise, measurement error, or environmental drift perturb an otherwise deterministic rule. The drift is visible as a slow migration of the rule's characteristic structures toward the biased state, and the map labels the drift as a function of the bias parameter.

Prigogine would note that the stochastic versions are not merely noisier; they are different systems with different dynamics. Rule 30 under noise is not Rule 30 with an error bar. It is a new system whose behaviour has its own characteristic features, and those features can be studied on their own terms. The map's pairing of clean and noisy rules stages this equivalence explicitly: two systems, related but not identical, shown side by side.

The politics of stochastic rules are in the reframing of determinism. Strict determinism is a limit case rather than the default. Most real substrates — neurons, markets, weather — run stochastic versions of rules whose deterministic siblings look nothing like them. Treating the clean rule as primary and the noisy rule as a deviation is a decision about which model counts as the norm, and Prigogine argues that this decision has often been made badly.

Within the sequence, Soft_Rules is the bridge from clean mathematics to messy systems. The next map, CA_AgentsCircuits, will push further by treating computation itself as a practice within stochastic substrates. The sequence continues to unpack the idealisations of earlier maps, and this map's specific contribution is the observation that determinism is a modelling choice rather than a natural default.

<<<MAP: CA_EdgeOfChaos>>>
# Class IV is narrow — Wolfram's taxonomy, the edge of chaos, and the politics of computation's home

Wolfram's four-class taxonomy sorts cellular automaton rules by their long-run behaviour. Class I rules collapse to a uniform state: everything dies, or everything stabilises at a single value. Class II rules settle into periodic structures: stripes, oscillators, still lifes. Class III rules produce apparent randomness with long-range structure that the eye cannot predict. Class IV rules — the edge of chaos — support moving localised structures within an otherwise stable background. These are the rules that can, in principle, compute.

Chris Langton's computational mechanics work argues that computation lives in a narrow band of parameter space. Too much order and the system has no capacity for new state; too much chaos and the system cannot propagate signal reliably. The edge of chaos is the hinge between these extremes. Langton's lambda parameter measures a rule's transition density, and computational capacity peaks at intermediate lambda values. Class IV is the region where computation happens.

The map stages Wolfram's four classes as rooms the learner can walk between. The first room holds Class I rules: everything dies, or everything stabilises at a single value. Nothing moves. The second room holds Class II: periodic structures, stripes, oscillators, still lifes. The third room holds Class III: apparent randomness, long-range structure invisible to the eye. The fourth room holds Class IV: moving localised structures within an otherwise stable background. The learner walks through the first three rooms to reach the fourth, and the spatial ordering is the map's argument about where computation sits.

Three working demonstrations sit inside the Class IV room. A disease-spread model shows a front of infection propagating through a susceptible population. A self-organisation demo shows a pattern assembling itself from noise. A volumetric fog uses a Class IV rule to sustain thick, drifting cloud without collapsing or dissolving. Each demonstration runs a rule at the edge of chaos and shows the computation-carrying behaviour in action.

Langton would note that the edge of chaos is narrow. Most of rule space is Class I, II, or III. Class IV rules are rare, and small perturbations to a Class IV rule tend to push it into one of the neighbouring classes. The map acknowledges this by letting the learner tune rules and watch the class membership shift. A small change in parameters moves a rule from "interesting" to "boring", and the transition is often abrupt.

The politics of the edge of chaos are in its narrowness. Computation lives in a specific region of a larger space; most of the space is uninhabitable by computation. This is a claim about what kinds of substrates can support what kinds of processes, and it has consequences for any project that wants to build computing systems from physical substrates. The edge of chaos is not where biology or society usually operates; it is a specific configuration that has to be engineered and maintained.

Within the sequence, Edge_Of_Chaos is the theoretical consolidation. It names where computation happens in rule space and prepares the learner for the sandbox that CA_AgentsCircuits provides. The next map lets the learner build computation at the edge of chaos rather than only observing it, and the distinction between observation and construction is what the sequence has been building toward.

<<<MAP: Chamber_CA>>>
# Rule systems in contact — Conway meets Conway and the politics of mutual seeding

Chamber_CA is the catalyst chamber for the Cellular Automata sequence. It stages the sequence's closing gesture: two cellular automata share a surface, and the encounter is neither damage nor negotiation but mutual seeding — each side's patterns enter the other and are rewritten by its rules.

Gilbert Simondon's work on individuation argues that an entity is always the product of an ongoing process rather than a finished substance. The entity does not pre-exist its relations; it is constituted by them. The chamber's two automata are individuations in Simondon's sense. Neither the learner's catalyst pattern nor the creature's hide is a finished object. Both are patterns that exist because rules are producing them continuously.

The learner holds the cellular catalyst, which emits bursts of live cells. On contact with the creature — a lifeform_walker whose surface texture is a live 2D Game of Life grid — the bursts seed local perturbations in the creature's hide. The perturbations propagate through the hide according to Conway's rules. Some die out; some stabilise as oscillators; some produce travelling gliders. The creature's hide is never the same twice after a strike, because the hide has been running its own rule all along.

The science screen on the wall shows both grids side by side. One grid is the projected pattern the catalyst is currently emitting. The other is the creature's hide at the point of contact. Active gliders on each are highlighted. A second panel tracks which perturbations have survived more than a few ticks — the ones that found structure rather than dissolving.

Simondon would note that neither pattern can claim ownership of the encounter. The catalyst's burst enters the creature's grid; the creature's grid processes the burst; the resulting state is neither pure burst nor pure hide but a new individuation emergent from their contact. The encounter is a shared rule-processing event rather than a transfer of damage from attacker to attacked.

The politics of mutual seeding are in what counts as success. A combat chamber would reward the learner for reducing the creature's state toward collapse. This chamber rewards the creation of surviving structure. A perturbation that dies out registers as a missed opportunity; a perturbation that seeds a new oscillator or a travelling glider registers as a contribution to the hide. The screen's second panel tracks these contributions, and the chamber's texture of success follows the contributions rather than the damage.

The creature's response is not combat-shaped. As the hide stabilises new patterns from the learner's bursts, the creature shifts its posture from defensive to curious. The shift is a rule-level phenomenon: the creature's movement logic reads the hide's stabilised regions as signs of integration rather than of threat, and integration is the condition the map rewards.

Within the sequence, Chamber_CA closes Cellular Automata by putting two rule systems in contact across the player-creature boundary. The chamber hands the learner back to the Lab with the cellular catalyst in their kit and with a body-level sense that rule systems can meet as collaborators rather than as opponents.
