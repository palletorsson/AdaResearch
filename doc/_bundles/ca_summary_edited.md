<<<ADA_BUNDLE>>>
sequence: cellularautomata
file: summary.md
maps: 9
skipped_passing: 0
created: 2026-04-23T19:15:42
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: CA_Introduction>>>
# CA Introduction — Summary

CA_Introduction opens the Cellular Automata sequence. A grid of discrete cells covers a wide floor. Each cell has a small, identical neighbourhood and a single rule that updates its state by looking at that neighbourhood. The grid ticks in discrete steps, and everything updates at once. Nothing in the space moves continuously.

The central feature is a Persian-rug pattern produced by a simple 1D rule running top to bottom along a wall. Each row is the successor of the row above, computed in parallel from triplets of cells. Local symmetry propagates outward and produces the woven ornament across the whole surface. The rug makes the claim of the sequence visible at the entry: complex pattern can come from a local rule applied uniformly.

Across the floor, small architectural artifacts extend the point. A short column is assembled cell by cell from a rule that adds a supporting cell whenever two neighbours are filled. A bridge spans a gap using a similar rule with different neighbour thresholds. The structures are incidental — the sequence is not about making bridges — but they show that discrete local decisions can pile up into structure.

Within the sequence, Introduction is the grammar lesson. CA_GameOfLife and CA_ElementaryRules will take these ingredients — discrete cells, discrete time, local rules — and raise the consequences.

<<<MAP: CA_ElementaryRules>>>
# CA Elementary Rules — Summary

CA_ElementaryRules is the third map in the Cellular Automata sequence. It drops the grid from two dimensions to one in order to expose the minimum conditions under which cellular automata behave in interesting ways. Each cell has exactly two states, sees its left neighbour and its right neighbour, and applies one of 256 possible rules indexed 0 through 255.

The map is laid out as a gallery. Wolfram's 256 elementary rules are plotted on the walls, each shown as a scrolling one-dimensional automaton whose successive rows are stacked vertically. A scroll bar moves the learner through the rule space. Some rules die immediately; some produce clean nested triangles; some generate apparent chaos; a small number support moving structures.

Two rules are pulled out for closer study. Rule 30 produces output indistinguishable from random noise despite being fully deterministic. Rule 110 has been proven Turing-complete — a three-cell-wide, two-state automaton that can be compiled to run arbitrary computation. A side panel sketches the proof at a high level.

Within the sequence, this map is the argument for minimalism. The previous map showed Conway's Game of Life in two dimensions; this one shows that two dimensions are not required. The spectrum from triviality to universal computation fits inside the smallest possible substrate.

<<<MAP: CA_GameOfLife>>>
# CA Game Of Life — Summary

CA_GameOfLife is the second map in the Cellular Automata sequence. It introduces Conway's Game of Life as the canonical example of a cellular automaton and treats the biological vocabulary attached to it — birth, survival, death — as load-bearing rather than decorative.

The rules are posted at the entrance. A cell is born when it has exactly three live neighbours. A live cell survives when it has two or three live neighbours. Every other configuration produces death. That is the entire specification. The rest of the map is consequence.

Six stations around the floor run different initial configurations of Life and let the same rule set unfold into different dynamics. One station stages an avalanche — a small seed that cascades across the grid. Another grows a dendrite that reaches outward in branches. A third demonstrates a stable oscillator, a fourth a slow crack, a fifth a percolation pattern, a sixth a short-lived ecosystem of gliders and glider guns. The same rule produces each, depending on what was there to start with.

Within the sequence, Game Of Life is where state transitions acquire the names living things carry. CA_ElementaryRules will next strip the biology back out and ask what happens in one dimension.

<<<MAP: CA_BeyondBinary>>>
# CA Beyond Binary — Summary

CA_BeyondBinary is the fourth map in the Cellular Automata sequence. It relaxes two of the assumptions the earlier maps took for granted: that cells have exactly two states, and that the grid is rectangular. The space is a hexagonal tiling that reaches to the edges of the room.

The first station runs a totalistic rule. Rather than consulting the specific arrangement of neighbours, the rule counts how many neighbours are in each state and uses the totals to decide the next state. The rule table shrinks dramatically as a result, and the map shows it in full on a clipboard. Similar configurations produce similar outcomes, so the automaton reads as smoother than an elementary rule.

The second station runs Game of Life on the hexagonal grid. A hex has six neighbours instead of eight, so the thresholds change; the rule set is re-derived live on a panel. Gliders still appear, but they travel in hex-aligned directions rather than grid-aligned ones.

A VR booth at the back of the room lets the learner place seeds in a three-dimensional hex grid and watch them unfold overhead. The booth is deliberately non-rectangular — the map's broader argument is that neighbourhoods do not have to be square.

Within the sequence, Beyond_Binary loosens the substrate before CA_ExpandingSpace expands the neighbourhood.

<<<MAP: CA_ExpandingSpace>>>
# CA Expanding Space — Summary

CA_ExpandingSpace is the sixth map in the Cellular Automata sequence. It treats the neighbourhood radius as a parameter rather than a fixed constant. Earlier maps assumed each cell sees only its immediate neighbours; this map extends the reach to second, third, or further rings of cells and asks what changes.

The central station is a 3D tree. A local growth rule fires whenever enough cells within a chosen radius are filled. At radius one, the tree grows as a thin thread. At radius two, it thickens into a trunk. At radius three, it branches. The same rule, under larger neighbourhoods, produces qualitatively different structures — the parameter that looked like a detail turns out to shape the outcome as much as the rule does.

A second station runs a crossway automaton. Two influence zones from opposing corners of the grid overlap in the middle of the floor. Where they meet, the rules interfere: cells satisfy both conditions simultaneously and the boundary produces structure that neither zone would have produced alone.

Sliders at each station adjust the radius, the neighbourhood shape, and the activation threshold. Within the sequence, Expanding_Space is where locality itself becomes tunable. CA_SoftRules will next introduce non-determinism.

<<<MAP: CA_SoftRules>>>
# CA Soft Rules — Summary

CA_SoftRules is the seventh map in the Cellular Automata sequence. It introduces stochastic automata — rules that fire with a probability rather than a certainty. After six maps of strict determinism, the sequence admits noise.

The map revisits two rules the learner already knows. Rule 30 and Rule 110 run side by side, each in two copies: a clean version and a softened version in which the rule fires only 80 percent of the time. The clean versions reproduce the familiar deterministic outputs. The softened versions look similar at first and then drift — edges fuzz, triangles lose their sharp corners, the characteristic texture of each rule degrades unevenly as randomness compounds across generations.

A third station applies external forcing in the form of gravity. Cells accumulate a bias toward a particular state, so the usual rule outcomes are pushed in one direction. The result mimics physical systems where thermal noise, measurement error, or environmental drift perturb an otherwise deterministic rule.

A panel at the exit reframes the lesson. Strict determinism is a limit case. Most real substrates — neurons, markets, weather — run stochastic versions of rules whose deterministic siblings look nothing like them. Within the sequence, Soft_Rules is the bridge from clean mathematics to messy systems.

<<<MAP: CA_AgentsCircuits>>>
# CA Agents Circuits — Summary

CA_AgentsCircuits is the twelfth and final map in the Cellular Automata sequence. It stages Wireworld — a four-state cellular automaton designed to simulate digital logic — and hands the learner an open editor for defining their own rules.

A Wireworld circuit takes up the main floor. Cells can be empty, conductor, electron head, or electron tail. Electrons travel along conductor paths according to a short rule: a head becomes a tail, a tail becomes a conductor, and a conductor becomes a head when exactly one or two of its neighbours are heads. That short rule supports logic gates, delay lines, and clocks; a small demonstration builds an AND, an OR, and a clocked ring, and wires them into a visible binary counter.

Along one wall, a Wolfram CA explorer lets the learner define any rule over any neighbourhood. Sliders set the state count, the neighbourhood size, and the individual rule entries. Running the rule on a small canvas shows its behaviour in real time, and the learner can save configurations to a small gallery.

Within the sequence, this map is the synthesis and the sandbox. The sequence has argued that simple local rules can compute anything; Wireworld makes that argument concrete, and the explorer invites the learner to find the next example.

<<<MAP: CA_EdgeOfChaos>>>
# CA Edge Of Chaos — Summary

CA_EdgeOfChaos is the eleventh map in the Cellular Automata sequence. It names the classification Wolfram used to organise the behaviour of cellular automata and stages the four classes as rooms the learner can walk between.

The first room holds Class I rules: rules that collapse to a uniform state. Everything dies, or everything stabilises at a single value. Nothing moves. The second room holds Class II: rules that settle into periodic structures — stripes, oscillators, still lifes. The third room holds Class III: rules that produce apparent randomness, with long-range structure that the eye cannot predict. The fourth room holds Class IV, the edge of chaos: rules that support moving localised structures within an otherwise stable background. These are the rules that can, in principle, compute.

Three working demonstrations sit inside the Class IV room. A disease-spread model shows a front of infection propagating through a susceptible population. A self-organisation demo shows a pattern assembling itself from noise. A volumetric fog uses a Class IV rule to sustain thick, drifting cloud without collapsing or dissolving.

Within the sequence, Edge_Of_Chaos is the theoretical consolidation. It names where computation happens in rule space and prepares the learner for the sandbox that CA_AgentsCircuits provides.

<<<MAP: Chamber_CA>>>
# Chamber CA — Summary

Chamber_CA is the catalyst chamber for the Cellular Automata sequence. It is the last map before the learner returns to the Lab. The chamber puts two cellular automata in contact across the player-creature boundary: the learner fires cellular bursts, and the creature's armour is itself a Game of Life grid.

A lifeform_walker creature paces the chamber. Its hide is a live 2D automaton, with cells flickering between states according to Conway's rules. The learner holds the cellular catalyst, which emits bursts of live cells into the space. Where a burst lands on the creature, the incoming cells seed a perturbation in its hide. Conway meets Conway: the two rule systems interact, and the encounter plays out as a pattern conflict rather than damage.

A science screen on one wall shows both grids side by side, labels active gliders on each, and highlights where the bursts have introduced perturbations that survived more than a few ticks. A second display tracks the creature's state as it shifts from defensive to curious as its hide stabilises.

Within the sequence, Chamber_CA reframes the catalyst practice as rule systems encountering other rule systems. The chamber hands the learner back to the Lab with the cellular catalyst in their kit.
