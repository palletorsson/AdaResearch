# The context-free symbol has no neighbors — agential realism emerges at the exact moment grammar becomes context-sensitive

Every theoretical claim in this document is tested in code. The L-System is the first system in the pilot batch with two modes: context-free and context-sensitive. This is not a parameter change — it is a structural transition. The CF→CS shift changes the function signature from `f(symbol) → replacement` to `f(left, symbol, right) → replacement`. That single change — adding a context parameter — is the difference between Barad's agential realism holding or breaking. We can watch the transition happen inside one algorithm.

## Thrownness: The Axiom Is the Most Powerful Thrown Condition

Heidegger: initial conditions are given, not chosen. In L-Systems, the axiom is the initial condition. It determines everything.

The axiom is the most powerful thrown condition encountered so far. In forces, the initial velocity adds one vector. In boids, the initial scatter adds 200 positions that get eroded by steering forces. In L-Systems, the axiom determines the entire future of the system — every character, every branch, every fork — through exponential amplification. One extra character in the axiom doubles the tree at every generation.

And unlike boids, where steering forces erode the initial conditions over time, the L-System NEVER forgets its axiom. The trunk `F` from generation 0 persists in generation 5. It is surrounded by descendants but never replaced. Thrownness in L-Systems is permanent and growing — the thrown condition amplifies rather than decays.

**Verdict:** Thrownness confirmed, strongest in pilot batch. The axiom is thrown state — determines initial structure. The rules are thrown process — determine how structure evolves. Both are externally given, neither is self-derived. The axiom is never forgotten; it persists and amplifies. Heidegger's Geworfenheit holds in both registers: what you are and how you change are both imposed.

## Agential Realism: The CF→CS Transition Is the Test

Barad: properties are enacted through interaction, not possessed intrinsically. L-Systems provide a unique test because the same algorithm exists in two modes.

Context-free L-Systems break agential realism. The replacement is a property of the symbol alone. An `F` at the trunk base and an `F` at a branch tip are treated identically. There is no relational constitution — the symbol has its identity before and independent of its neighbors. This is the same pattern as noise (`get_noise_2d(x, z)` — no context) and waves (`sin(omega * t + phase)` — no neighbors). The function signature tells the story: one input, one output, no context parameter.

Context-sensitive L-Systems confirm agential realism. The replacement is a function of the symbol AND its neighbors. An `F` preceded by another `F` merely lengthens. An `F` preceded by a bracket branches fully. Same symbol, same rule table, different outcome. The neighbor constitutes the behavior.

This is the cleanest demonstration in the pilot batch. We can watch agential realism turn on and off by switching from CF to CS rules. The function signature changes from `f(symbol) → replacement` to `f(left, symbol, right) → replacement`. Adding the context parameters IS the transition from intrinsic to relational properties. Barad's claim is not universally true or false — it is true when and only when the function signature includes context.

**Verdict:** Agential realism has a formal on/off switch. CF grammars: broken (intrinsic properties, no context parameter). CS grammars: confirmed (relational properties, neighbor-dependent replacement). The transition is structural, not parametric — you either query neighbors or you don't. This maps onto the Chomsky hierarchy: context-free languages (Type 2) vs context-sensitive languages (Type 1). Barad's intra-action corresponds exactly to the CF→CS boundary in formal language theory.

## Performativity: Each Generation Constrains the Next

Butler: identity through constrained repetition. L-Systems are the strongest case for performativity in the pilot batch.

This is the strongest performativity confirmation. Unlike boids (where neighbor lists recalculate from scratch each frame) or forces (where acceleration resets each frame), in L-Systems NOTHING resets. Every character from every generation persists. The trunk `F` from generation 0 is still present in generation 5 — surrounded by descendants but never replaced. The string only grows. History is additive and permanent.

The irreversibility strengthens the performativity finding. You cannot recover the axiom from the final string. The original `F` has been overwritten — replaced by `F[+F]F[-F]F`, which was itself replaced, recursively. Butler says the original identity is produced by and then erased by the performance. The L-System literalizes this: the axiom is consumed by its own rewriting.

**Verdict:** Performativity confirmed, strongest in pilot batch. Each generation's output is the next generation's input — the definition of constrained repetition. History is permanent (no reset, no decay). The original axiom is erased by the performance — irreversible, non-recoverable. Butler's framework maps exactly onto recursive string rewriting.

## Boundary as Politics: Pruning and the Corridor

The corridor constraint from the technical provides the boundary test.

The corridor width is the clearest boundary-as-politics in the pilot batch. It is not a parameter of the grammar — it is an environmental constraint that the grammar knows nothing about. The pruning happens at interpretation time, between string and geometry. The grammar produces the same string regardless of corridor width. The corridor determines which branches survive into spatial form.

This is environmental politics: the rules are the same for everyone, but the environment determines who thrives. The clearing tree and the corridor tree have the same genome. They are different phenotypes — shaped by habitat, not instruction.

**Verdict:** Boundary confirmed. Corridor width is a political parameter that determines tree morphology without appearing in the grammar. Negation confirmed — pruning requires prior growth. You can only clip a branch that the grammar prescribed. Derrida's insight holds: negation depends on prior presence. The corridor is the institution; the grammar is the speech; pruning is censorship.

## Finitude as Constitutive: max_generations and String Length

The generation limit is constitutive in the most absolute sense. Exponential growth means that removing the limit doesn't produce a "better" tree — it produces no tree at all. The computation crashes before rendering. This is stronger than the CFL condition in Forces_1 (which produced incorrect results) or the Nyquist limit in waves (which produced aliased but renderable output). Here, removing the limit destroys the computation entirely.

**Verdict:** Finitude confirmed at two levels. Generation limit is absolutely constitutive — exponential growth destroys computation without it. Parametric decay is morphologically constitutive — it creates the trunk-to-twig hierarchy that makes trees recognizable. Both limits are not deficiencies but design elements. Remove them and the output becomes degenerate or impossible.

## Emergence: Axiom Plus Rules Plus Environment

Emergence confirmed with a refinement: L-Systems need axiom + rules (necessary and sufficient for basic emergence). The environment adds a third layer — adaptation, shaping, differentiation — but is not required for the tree to exist. This is different from boids (where all three steering rules were needed for full flocking) and from CA_11 (where both rules and geometry were needed for computation). L-System emergence is two-layered: rules + seed produce the basic form; environment modifies it.

**Verdict:** Emergence confirmed, two-layered. Axiom + rules are necessary and sufficient. Environment adds adaptation but is not required. Neither axiom nor rules alone produces a tree. Together they produce complex branching from a single character through iterated rewriting.

## QFEP Coordinates

Two QFEP locations in one algorithm. CF L-Systems sit at λ=0.0, φ=0.0 — as ordered as waves, as rigid as anything in the pilot batch. CS L-Systems shift slightly to λ=0.1 — still deterministic but with more structured variation through context-dependent branching. Both have φ=0.0 — neutral, no feedback between output and rules.

The comparison is telling. Boids (λ=0.35, φ=+0.2) are more exploratory and more self-organizing. Noise (λ=0.5) has more variation. Forces (φ=-0.3) has more dissipation. L-Systems are the most ordered interactive system — a pipeline applied repeatedly without feedback. The QFEP correctly predicts that L-Systems produce regular, self-similar, deterministic output — which is exactly what they do.

**Verdict:** QFEP confirmed. CF at (0.0, 0.0) — maximum order, no exploration, no feedback. CS at (0.1, 0.0) — slight variation from context, still no feedback. Correctly predicts deterministic, self-similar, pipeline-like behavior.

## Summary of Tests

| Claim | Source | Code Test | Verdict |
|-------|--------|-----------|---------|
| Thrownness | Heidegger | Axiom determines exponentially divergent trajectories; rules are thrown process; axiom never forgotten | **Confirmed, strongest.** Two registers: state (axiom) and process (rules) |
| Agential Realism | Barad | CF: broken (f(symbol) → replacement, no context). CS: confirmed (f(left, symbol, right) → replacement) | **Transition.** Agential realism turns on at the CF→CS boundary |
| Performativity | Butler | Output of gen N is input of gen N+1; original axiom erased by iteration; rewriting is irreversible | **Confirmed, strongest.** Permanent accumulation, no reset, irreversible |
| Boundary | Critical theory | Corridor width → 5 qualitatively different trees; pruning is Derridean negation | **Confirmed.** Environmental politics — same genome, different phenotype |
| Negation | Derrida | Pruning requires prior growth; clipping requires the branch to have been attempted | **Confirmed.** Negation depends on prior presence |
| Finitude | Heidegger/Chirimuuta | Generation limit is absolute (exponential growth → memory crash); parametric decay creates hierarchy | **Confirmed, absolute.** Removing limit destroys computation entirely |
| QFEP Location | QFEP | CF: λ=0.0, φ=0.0; CS: λ=0.1, φ=0.0 — deterministic pipeline, no feedback | **Confirmed.** Two locations for two modes; correctly predicts behavior |
| Emergence | Systems theory | Axiom + rules → tree (sufficient). Neither alone suffices. Environment adds adaptation layer | **Confirmed, two-layered.** Base emergence from two components; adaptation from three |

L-Systems provide the most important structural finding in the pilot batch: agential realism has a formal boundary. It corresponds exactly to the CF→CS transition in the Chomsky hierarchy. Context-free grammars (Type 2) are intrinsic — each symbol carries its replacement independently. Context-sensitive grammars (Type 1) are relational — replacement depends on neighbors. The transition is not gradual. It is a phase boundary. You either check neighbors or you don't.

This connects to every other map. Noise is context-free: `get_noise_2d(x, z)` — no neighbor query. Waves are context-free: `sin(omega * t + phase)` — no neighbor query. Both break agential realism. Boids are context-sensitive: `compute_separation(i, neighbors)` — explicit neighbor query. Boids confirm agential realism. The pattern is exceptionless: agential realism holds if and only if the update function includes a context parameter.

Performativity also finds its strongest home here. L-System rewriting is the purest form of constrained repetition: each generation's output becomes the next generation's input, with no reset, no decay, no forgetting. The original axiom is consumed by its own production. Butler's framework maps exactly onto recursive string rewriting — more precisely here than anywhere in the pilot batch.

The new finding: thrownness has two registers. The axiom is thrown state. The rules are thrown process. Both are externally given, both determine the system's future, but they operate in different ontological registers. Heidegger's Geworfenheit does not distinguish between being thrown into a state and being thrown into a process. The L-System code requires the distinction.
