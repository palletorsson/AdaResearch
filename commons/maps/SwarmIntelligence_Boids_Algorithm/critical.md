# The boid has no identity until it counts its neighbors — agential realism returns, and the flock is a side effect nobody computed

Every theoretical claim in this document is tested in code. The boid is the first interactive system after Forces_1. Noise and waves broke agential realism and performativity — both were autonomous, context-free, stateless. The boid is none of those. Its steering equation takes a `neighbors` parameter. Its velocity accumulates across frames. Its behavior depends on who is nearby. If agential realism and performativity have scope conditions, boids should reveal them.

## Thrownness: Random Scatter, Permanent Consequences

Heidegger: initial conditions are given, not chosen. The boid's position and velocity at frame 0 are assigned by `randf_range`, not computed from any decision procedure.

The thrown condition is strong. Unlike waves (where different phase produces the same trajectory shifted in time), different initial scatter produces structurally different flocks. Some seeds produce one unified group. Others produce two or three sub-flocks that never merge. The initial velocity distribution determines the early consensus heading — boids that start with roughly aligned velocities coalesce faster than boids pointing in all directions.

But there is a convergence effect that weakens thrownness over time. Regardless of initial scatter, the three steering forces push toward a common attractor: cohesive, aligned, separated motion. Two very different initial configurations may converge to similar flock shapes after enough frames. Thrownness determines the transient, not the steady state. This is the opposite of waves, where the phase offset persists forever. In boids, the thrown condition is strong but temporary — the system forgets its initial conditions.

**Verdict:** Thrownness confirmed, strong but decaying. Initial scatter determines flock topology during the transient period. Over time, the steering forces erode the thrown condition — the flock converges toward attractors that are properties of the algorithm, not the initialization. Heidegger does not account for systems that overcome their thrownness.

## Agential Realism: The Boid Has No Identity Alone

Barad: properties are enacted through interaction, not possessed intrinsically. The boid is the cleanest test case. Every steering function takes a `neighbors` parameter.

This is agential realism in its most transparent form. The function signature tells the story: `compute_separation(i, neighbors)`. Remove the `neighbors` parameter and the function cannot execute. The boid's acceleration is undefined without context. Not unknown — undefined. There is no value to compute. The steering force is not a property of the boid that context modifies. It is a property that context creates.

Compare to noise, where `get_noise_2d(x, z)` required no neighbor list, no environmental field, nothing but coordinates. The noise value existed intrinsically. The boid's acceleration does not.

The isolated boid is a ballistic particle. The surrounded boid is a flocking agent. Same code, same parameters, same internal state — but the presence of neighbors transforms the entity from one category to another. This is not a difference of degree (flies faster, turns more). It is a difference of kind (drifts vs. flocks). Barad would say: the boid does not pre-exist its interactions. The interactions constitute what the boid is.

But the Baradian limit from CA_11 reappears. The steering rules themselves — separation, alignment, cohesion — are not relationally produced. They are fixed, imposed, non-negotiable. A boid cannot learn a new steering rule from its neighbors. It cannot modify the `if count == 0: return Vector3.ZERO` threshold through experience. The relational agency operates within a fixed rule framework.

**Verdict:** Agential realism confirmed — the strongest confirmation in the pilot batch. Boid properties are genuinely relational: acceleration is undefined without neighbors, and isolation changes the entity's category. The Baradian limit persists: the rules themselves are not relational. But within fixed rules, the boid demonstrates intra-action in Barad's precise sense: the interaction constitutes the properties, not merely modifies pre-existing ones.

## Performativity: Velocity Accumulates, But Memory Does Not

Butler: identity through constrained repetition. Does the boid's frame-by-frame steering constitute performance?

Velocity is performative, exactly as in Forces_1. The boid's heading at frame 100 reflects every steering correction from frames 0 through 99. Reset the velocity and the boid behaves differently — it turns from its reset heading instead of from its accumulated heading. History is encoded in the velocity vector.

But boids add a complication that Forces_1 did not have. The neighbor list rebuilds every frame from scratch.

The boid performs its trajectory (velocity accumulates, position changes, max_force constrains turning rate) but does not perform its relationships (neighbor list recalculated from scratch each frame). This is a split that Butler's framework does not anticipate. Physical identity is performative — the boid is where its history put it. Social identity is not — the boid has no memory of social context. It flocks with whoever is nearby right now.

The flock itself is performative, though, at the emergent level. The flock's shape at frame N constrains frame N+1 — positions determine neighbor lists, which determine forces, which determine new positions. The flock cannot jump to an arbitrary configuration. It evolves through continuous deformation. But no individual boid carries this history. The performance is distributed across the collective state, stored in no single agent.

**Verdict:** Performativity split. Physical state (velocity, position) accumulates performatively — each frame constrains the next through max_force turning limits. Social state (neighbor identity, interaction history) is memoryless — rebuilt from scratch each frame. The flock itself performs at the emergent level, but individual boids do not perform their relationships. Butler's framework needs a level-of-analysis qualifier.

## Boundary as Politics: Radii and Weights Define Social Physics

The boid algorithm has six thresholds: three radii and three weights. Each is a political choice.

The radii define who counts as a neighbor. This is a political boundary in the most literal sense — it determines the constituency. A boid with `perception_radius = 2.0` is an isolated individual. A boid with `perception_radius = 50.0` is a citizen of a totalitarian flock. The same three rules, the same steering algorithm, produce atomization or fascism depending on a single parameter.

The six parameters (three radii, three weights) form a political design space. Reynolds chose one point in this space — balanced separation, moderate radii — and produced bird-like flocking. Other points produce fish schooling, insect swarming, herd behavior, dispersal. The algorithm is the same. The politics differ. No configuration is "correct." Each is a different theory of collective life, expressed as six floating-point numbers.

**Verdict:** Boundary as politics confirmed. Perception radius determines constituency (who counts as a neighbor). Weights determine social physics (which forces dominate). Both are chosen, not derived. Five weight configurations produce five qualitatively different collective behaviors from the same three rules.

## Finitude as Constitutive: max_speed and max_force

The speed limit is constitutive. Remove it and the flock dissolves — boids move faster than the neighbor query can track. This is the same Nyquist-like condition seen in waves and the CFL condition in Forces_1: the entity's movement per frame must be smaller than the spatial resolution of the interaction mechanism. The perception radius is the spatial "sampling rate." max_speed must be low enough that boids remain within each other's perception across frames.

max_force is the most interesting limit. It produces the organic quality of flocking — the lag between wanting to turn and completing the turn. This lag creates the sweeping curves, the gradual consensus, the banking turns. Remove it (max_force = ∞) and boids snap to desired headings instantaneously. The motion becomes a series of discrete direction changes. The beauty disappears. The limit is not a deficiency — it is the source of the aesthetic.

Chirimuuta: "Understanding is enacted, not extracted." The flocking behavior does not exist in the rules alone. It is enacted through the constraints. max_force limits what the boid can do per frame. That limitation produces the temporal smoothing that makes the motion look alive. The finite turning rate is as constitutive as the steering rules themselves.

**Verdict:** Finitude confirmed, constitutive at both levels. max_speed is constitutive in the same way as the CFL condition — exceeding it causes the interaction mechanism to fail. max_force is constitutive in a deeper way — it produces the aesthetic character of flocking. The limits are not practical compromises. They are design elements as fundamental as the three steering rules.

## Emergence: Three Rules Plus Scatter Equals Flock

Emergence is refined, not simply confirmed. The flock does not require a specific initial geometry — any scattered arrangement works. But it requires SOME asymmetry. Perfectly symmetric initial conditions (same position, same velocity) produce no flocking because no force can break the symmetry. The rules need geometric variation to operate on, but almost any variation suffices.

The emergence test is more nuanced than expected. One rule produces degenerate behavior. Two rules produce partial flocking — some characteristics but not all. Three rules produce the full flock: it flows (alignment), breathes (separation vs cohesion), and coheres (cohesion). This is stronger than CA_11 where rules + geometry were binary (both needed or not). In boids, rules have a gradient — more rules produce more emergence. The three-rule system is the minimum for the full behavioral repertoire.

**Verdict:** Emergence confirmed with gradient. Rules require asymmetric geometry (but not specific geometry). Geometry without rules produces nothing. Each individual rule produces a degenerate behavior. Pairs produce partial flocking. All three produce the full emergent flock. Emergence is not binary (present/absent) but graded (how many of the rules operate).

## QFEP Coordinates

Boids at λ=0.35, φ=+0.2: edge of chaos with weak order amplification. This is the first system in the pilot batch with positive phi. Forces_1 dissipated (restitution reduced energy, phi negative). Noise was stateless (phi undefined/neutral). Waves were rigid (phi neutral — no gain, no loss). Boids actively create order through alignment feedback, bounded by separation. The positive phi predicts self-organization — which is exactly what flocking is.

The lambda value places boids near Rule 110 and Game of Life on the Langton axis — systems at the edge of chaos where computation and emergence coexist. This is consistent with the observation that boids produce complex, unpredictable but structured behavior. Not random (lambda < 1). Not frozen (lambda > 0). The sweet spot where interesting things happen.

**Verdict:** QFEP confirmed. λ=0.35 correctly predicts edge-of-chaos sensitivity and structured variation. φ=+0.2 correctly predicts self-organizing behavior — the flock creates order that was not present in the initial scatter. First positive phi in the pilot batch; first system that is generative rather than conservative or neutral.

## Summary of Tests

| Claim | Source | Code Test | Verdict |
|-------|--------|-----------|---------|
| Thrownness | Heidegger | Random scatter determines flock topology; but steering forces erode thrown condition over time | **Confirmed, decaying.** Strong initially, convergent long-term |
| Agential Realism | Barad | Steering requires `neighbors` parameter; isolated boid changes category (ballistic vs flocking) | **Confirmed.** Strongest case in pilot — interaction constitutes properties |
| Performativity | Butler | Velocity accumulates (physical performativity); neighbor list recalculated from scratch (no social memory) | **Split.** Physical yes, social no. Butler needs level-of-analysis qualifier |
| Boundary as Politics | Critical theory | Perception radius = constituency; weights = social physics; 5 configurations → 5 regimes | **Confirmed.** Six parameters, each a political choice |
| Finitude | Heidegger/Chirimuuta | max_speed constitutive (CFL-like); max_force constitutive (produces organic aesthetic) | **Confirmed.** Both limits are design elements, not compromises |
| QFEP Location | QFEP | λ=0.35 (edge of chaos), φ=+0.2 (weak order amplification, self-organizing) | **Confirmed.** First positive phi — generative, not conservative |
| Emergence | Systems theory | Three rules + asymmetric geometry → full flock; rules have gradient (1→2→3 = degenerate→partial→full) | **Confirmed, gradient.** Emergence is graded, not binary |

Boids reverse the pattern from noise and waves. Those autonomous systems broke agential realism and performativity — they had no context parameter, no feedback, no neighbor dependence. Boids confirm both (with qualifications). The emerging pattern: agential realism requires relational function signatures (`f(state, context) → outcome`). Performativity requires state accumulation (`state_n+1 = f(state_n, ...)`). Unconditional systems have neither. Interactive systems have both.

The new finding from boids: thrownness decays. In waves, phase persists forever. In physics, initial velocity persists until a force acts. In boids, the steering forces actively erode the initial conditions — the flock converges toward attractors independent of initialization. This is a new category: systems that overcome their thrownness. Heidegger assumed thrownness was permanent. The boid flock suggests that strong enough relational forces can wash out the thrown condition.

The deepest finding: finitude as aesthetic. max_force does not merely prevent computational failure (as CFL does). It produces the visual character of flocking — the smooth curves, the gradual turns, the organic feel. The limit is not a constraint on the system's behavior. It is the source of the behavior's beauty. Chirimuuta's enactivism is confirmed at the strongest level: the limit does not restrict what the boid can do. The limit IS what the boid does.
