# Every point in the cloth asks its neighbors where to go — agential realism through springs, finitude through the CFL condition, and material identity as stiffness ratio

Every theoretical claim in this document is tested in code. Cloth is a spring-mass lattice: 256 mass points connected by three types of springs, integrated with Verlet, constrained iteratively. It is the most densely connected interactive system in the pilot batch — each interior point has up to twelve spring connections (4 structural, 4 shear, 4 bend). If agential realism is about relational constitution, cloth is the stress test.

## Thrownness: Grid, Stiffness, Pins

Heidegger: initial conditions are given, not chosen. Cloth has three layers of thrownness.

Cloth has the richest thrownness in the pilot batch: three independent layers, each externally imposed, each determining the trajectory. Grid geometry determines mass distribution and topology. Stiffness determines material character. Pin configuration determines drape shape. The cloth cannot modify any of these during simulation.

But unlike boids, where steering forces erode the initial conditions, and unlike L-Systems, where the axiom amplifies into exponentially different structures, cloth thrownness is persistent and stable. The cloth reaches a draping equilibrium determined by all three thrown layers. It does not forget (like boids) or amplify (like L-Systems). It settles. The thrown conditions determine the attractor, and the attractor is permanent.

**Verdict:** Thrownness confirmed, three registers. Grid geometry, spring stiffness, and pin configuration are all externally given and permanently constitutive. The cloth settles into an equilibrium that directly reflects its thrown conditions — the most stable thrownness in the pilot batch.

## Agential Realism: Springs Are Relational By Definition

Barad: properties are enacted through interaction, not possessed intrinsically. The spring is the relational primitive.

The spring is agential realism in its most elementary form. A spring force requires two endpoints — it is undefined for a single point. The force is not a property of either endpoint individually; it is a property of their relation (distance vs. rest length). This is Barad's intra-action at the most granular level: the spring does not mediate between two pre-existing entities. It constitutes the force that moves them.

Material identity is topological. The difference between silk and canvas is not in the mass points (which are identical) but in the spring stiffness ratios (which are relational parameters). The difference between cloth and dust is not in the particles but in the connections. Remove the springs and the cloth ceases to be cloth. The material is constituted by its internal relations.

This is stronger than boids, where the function signature included a `neighbors` parameter (relational input). In cloth, the EXISTENCE of the entity depends on relations. A boid with no neighbors is a ballistic particle — still an entity, just a different kind. A mass point with no springs is a falling particle — it has no cloth-ness at all. The relations are not modifiers of pre-existing properties. They are the properties.

**Verdict:** Agential realism confirmed, strongest in pilot batch alongside boids. Springs are inherently relational (force requires two endpoints). Material identity is topological (springs, not points, define material character). Constraint satisfaction is iterative mutual constitution (each spring's adjustment affects every connected spring). The cloth is the most densely Baradian system tested — every property emerges from relations.

## Performativity: Verlet Integration Encodes History

Butler: identity through constrained repetition. Verlet integration stores history in position.

Verlet integration is performativity in its most elegant form. There is no velocity variable. Velocity is the difference between where the point is now and where it was last frame. The history is not auxiliary data — it IS the dynamics. Reset `old_position` and the cloth freezes. The past is not stored alongside the present; the past is encoded IN the present. Butler's constrained repetition: each frame's position constrains the next frame's velocity, which constrains the next frame's position.

**Verdict:** Performativity confirmed with damping. Verlet integration stores history in the position-difference (implicit velocity). Each frame constrains the next. But damping (0.999 multiplier) causes history to decay — the cloth gradually forgets its impulses. This is performativity with dissipation: Butler's constrained repetition plus Heidegger's being-toward-death (energy lost to friction). The cloth performs its trajectory but the performance decays.

## Boundary as Politics: Stiffness Ratios Define Material

**Verdict:** Boundary confirmed. Stiffness ratios define material identity (five ratios → five qualitatively different fabrics). Constraint iterations are a political choice disguised as a numerical parameter — they affect material behavior, not just accuracy. The solver's iteration count is as much a design decision as the spring constants themselves.

## Finitude as Constitutive: The CFL Condition

This is the map where finitude is most clearly constitutive. The CFL (Courant-Friedrichs-Lewy) condition constrains the timestep.

The CFL condition is the purest finitude-as-constitutive in the entire pilot batch. It is not a practical compromise (like max_speed in boids). It is not an aesthetic choice (like max_force in boids). It is a mathematical necessity: exceed it and the simulation explodes. The limit is not imposed by the designer — it is derived from the mathematics of spring-mass dynamics. You cannot negotiate with the CFL condition. You can only obey it.

The CFL condition also creates an interesting tension with material design. Stiffer materials (higher k) require smaller timesteps (smaller delta_t). To simulate rubber at 60 fps, you need substeps — multiple integration passes per frame. This means that stiffer materials are more computationally expensive. Rigidity costs compute. Softness is cheap. The physics has an economics.

**Verdict:** Finitude refined with clear distinction. The CFL condition is constitutive — exceeding it causes exponential explosion, destroying the simulation. Grid resolution is practical — higher resolution produces strictly better results, limited only by compute. Same pattern as waves (Nyquist = constitutive, amplitude = practical) and noise (convergence = practical, aliasing = constitutive). The constitutive limits are always about temporal/frequency resolution, not spatial quantity.

## Emergence: Springs Plus Gravity Plus Pins

Emergence confirmed with three required components. Unlike boids (where random scatter was needed but any scatter worked) or L-Systems (where environment was optional), cloth requires ALL THREE: springs (internal relations), gravity (external force), and pins (boundary conditions). Remove pins and the cloth falls without deforming. Remove gravity and the cloth floats without draping. Remove springs and the cloth dissolves into particles. Draping is a three-way interaction between internal structure, external force, and boundary attachment.

**Verdict:** Emergence confirmed with gradient, same pattern as boids. Three spring types each contribute a different aspect of material behavior: structural (resist stretching), shear (resist angular deformation), bend (resist curvature). One type produces partial cloth. Two types produce better cloth. Three types produce full cloth. The graded emergence pattern is now confirmed across two independent domains (boids and cloth), suggesting it may be a general property of multi-force systems.

## Negation: Collision as Exclusion

**Verdict:** Negation confirmed. Collision resolution requires prior penetration — you can only push a point out of a space it has entered. Self-collision requires prior proximity — you can only separate points that have approached each other. Both are negation that depends on prior positive state, confirming Derrida's insight that absence is always secondary to presence.

## QFEP Coordinates

Cloth at λ=0.0, φ=-0.3: deterministic and dissipative. Same coordinates as Forces_1. The cloth shares Forces_1's fundamental character: it settles toward equilibrium, absorbing disturbances rather than amplifying them. This is the opposite of boids (φ=+0.2, self-organizing). Cloth does not create order from disorder — it loses energy until it reaches the minimum-energy configuration.

The QFEP correctly predicts that cloth will settle, not self-organize. A disturbed cloth oscillates and damps. It does not discover new configurations (like boids discovering flocking). It does not maintain perpetual motion (like waves). It dies down to rest. The negative phi captures this exactly: the system resists change, absorbs perturbation, seeks equilibrium.

**Verdict:** QFEP confirmed. λ=0.0 correctly predicts deterministic, reproducible draping. φ=-0.3 correctly predicts energy dissipation and equilibrium-seeking behavior. Same (λ, φ) as Forces_1 — both are conservative physics simulations that settle toward minimum energy.

## Summary of Tests

| Claim | Source | Code Test | Verdict |
|-------|--------|-----------|---------|
| Thrownness | Heidegger | Grid, stiffness, and pins are three layers of thrown condition; all persist permanently | **Confirmed, three registers.** Richest thrownness in pilot batch |
| Agential Realism | Barad | Spring force requires two endpoints; material identity is topological; constraint satisfaction is mutual constitution | **Confirmed, strongest.** Relations constitute the entity, not just modify it |
| Performativity | Butler | Verlet stores history in position-difference; damping decays history over time | **Confirmed with damping.** History matters but fades — performativity with dissipation |
| Boundary | Critical theory | Stiffness ratios → 5 material characters; constraint iterations affect physics not just accuracy | **Confirmed.** Numerical parameters are political choices |
| Negation | Derrida | Collision requires prior penetration; self-collision requires prior proximity | **Confirmed.** Negation depends on prior presence |
| Finitude | Heidegger/Chirimuuta | CFL is constitutive (exceed → explosion); grid resolution is practical (more → better) | **Refined.** Temporal finitude constitutive, spatial finitude practical |
| QFEP Location | QFEP | λ=0.0, φ=-0.3 — deterministic, dissipative, equilibrium-seeking | **Confirmed.** Same location as Forces_1 — conservative physics |
| Emergence | Systems theory | Springs + gravity + pins all required; three spring types = graded emergence | **Confirmed, three-component.** Same graded pattern as boids |

Cloth confirms nearly everything. All eight claims hold (with refinements). This is expected — cloth is an interactive, stateful, neighbor-dependent system with feedback, damping, and boundary conditions. It is the kind of system the theories were written about.

The most important finding from cloth: the CFL condition as the sharpest finitude in the pilot batch. Forces_1 introduced the CFL condition for springs. Cloth makes it unavoidable — with 700+ springs at various stiffnesses, the CFL condition is the binding constraint on the entire simulation. Exceed it and the cloth explodes. This is not a practical limit (like grid resolution, which produces strictly better results at higher values). It is a constitutive limit: a mathematical boundary between functional simulation and numerical catastrophe.

The second finding: graded emergence appears again. Boids had three steering rules, each adding a behavioral dimension (separation → alignment → cohesion). Cloth has three spring types, each adding a material dimension (structural → shear → bend). The pattern is now confirmed across two independent domains: multi-force systems exhibit graded emergence where each force contributes a distinct quality, and the full behavior requires all forces. Emergence is not binary (present/absent) but graded (partial/full).

The third finding: the QFEP correctly groups cloth with Forces_1 at (0.0, -0.3) — deterministic, dissipative physics. Both are conservative systems that settle toward equilibrium. Neither self-organizes (like boids at φ=+0.2) or maintains perpetual state (like waves at φ=0.0). The QFEP is discriminating: it separates cloth/forces from boids/waves despite all four being interactive systems, based on whether they dissipate energy or not.
