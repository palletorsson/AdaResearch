# Brouwer_Intuitionism — Technical

## The Constructive Turn

L.E.J. Brouwer (1881-1966) proposed a radical response to the foundations crisis: abandon the logical principles that generate the paradoxes. Classical mathematics asserts existence through contradiction — "assume X doesn't exist; derive contradiction; therefore X exists." The object X is never produced. Its existence is inferred from the impossibility of its nonexistence. Brouwer rejected this. If you cannot construct X, you may not claim X exists.

The central rejection: **the law of excluded middle** (LEM), which states that for any proposition P, either P or not-P holds.

```
Classical: P ∨ ¬P (always true, no exceptions)
Intuitionistic: P ∨ ¬P (not assumed — must be proven for each specific P)
```

In classical logic, LEM is an axiom. In intuitionistic logic, it is a proposition that holds when it can be demonstrated and fails when it cannot. For decidable predicates (Is n = 5? Is this list empty?), LEM holds constructively. For undecidable predicates (Does this program halt? Is this number transcendental?), LEM is not available.

## What Is Lost

Rejecting LEM eliminates several proof techniques that classical mathematics relies on:

**Proof by contradiction (reductio ad absurdum)**: Assume not-P, derive contradiction, conclude P. In intuitionistic logic, this only proves not-not-P (double negation). The step from not-not-P to P requires LEM, which is unavailable. So intuitionistic logic has a weaker double negation law: `¬¬P` does not imply `P`.

**Non-constructive existence proofs**: "There exists an x such that P(x)" proved by showing "for all x, not-P(x)" leads to contradiction. The proof never identifies which x satisfies P. Intuitionistically, `∃x P(x)` requires exhibiting a specific x and a proof that P(x) holds.

**Specific casualties**:
- The intermediate value theorem (classical version: a continuous function that is negative at a and positive at b has a zero between a and b, but the zero is not constructed).
- The Bolzano-Weierstrass theorem (every bounded sequence has a convergent subsequence, but the subsequence is not constructed).
- Many results in analysis, measure theory, and topology that rely on Zorn's lemma or the axiom of choice.

## What Is Gained

### The Brouwer-Heyting-Kolmogorov (BHK) Interpretation

In BHK semantics, a proof of a proposition is not a truth value but a construction:

| Proposition | Proof is... |
|-------------|-------------|
| P ∧ Q | A pair: (proof of P, proof of Q) |
| P ∨ Q | A pair: (tag indicating which, proof of the tagged one) |
| P → Q | A function that transforms any proof of P into a proof of Q |
| ∃x P(x) | A pair: (witness x, proof that P(x)) |
| ∀x P(x) | A function that takes any x and returns a proof of P(x) |
| ¬P | A function that transforms any proof of P into a proof of absurdity |

Under this interpretation, proofs are programs. This is the **Curry-Howard correspondence**: propositions are types, proofs are programs, and proof verification is type checking. Every intuitionistic proof corresponds to a computable function. Every constructive existence proof yields an algorithm.

### Brouwer's Free Choice Sequences

Brouwer introduced **choice sequences**: infinite sequences of natural numbers where each element is freely chosen by a creating subject. A choice sequence is never complete — it is an ongoing process. This generates a novel theory of the continuum where real numbers are inherently unfinished, always in the process of being determined.

The free choice sequence challenges the classical picture where all mathematical objects exist timelessly. For Brouwer, mathematics is a temporal activity: objects come into existence through construction, and some objects are perpetually under construction.

## Map Architecture: Stepping Stones

The Brouwer_Intuitionism map is an 11x14 grid, max height 2. Its structure is radically fragmented: disconnected platforms floating over void, connected by bridges. Nothing is given in advance. The map uses `auto_reveal_on_entry: true` and `initial_tile_visibility: "hidden_except_start"` — platforms appear only as the player approaches, constructing the space in real time.

The structure layer:
- **Start row (row 0) and end row (row 13)**: Full-width floor at height 1, providing entry and exit.
- **Mid-section**: Scattered islands of height 1, separated by void (0). Small 2x2 or 1x1 platforms at rows 1, 3-5, 6-8, 10-12, connected by single-cell stepping stones.
- **Bridges**: Utility layer contains bridge markers (`br:z:3`, `br:-x:2`, `br:x:2`) that create physical connections between platforms. Without these, several platforms would be unreachable.

The fragmentation is intentional. Classical mathematics provides a continuous floor — you can walk anywhere because every point is assumed to exist. Intuitionistic mathematics provides only what has been constructed. The gaps between platforms are honest: they represent propositions that have not been proven, objects that have not been built, truths that are not yet available.

The auto-reveal mechanic deepens this: platforms are invisible until the player is close enough to "construct" them. The space builds itself under your feet. This is Brouwer's mathematics: existence follows construction, not the other way around.

## Artifact Analysis

### excluded_middle_demo (row 4, col 2)
**@identity essence**: `P ∨ ¬P — the law of excluded middle; Brouwer: "not always!"`

Two glowing spheres represent P (blue) and ¬P (red) with a disjunction symbol between them. The critical parameter `show_rejection` toggles between classical acceptance (both spheres glow, the disjunction connects them) and intuitionistic doubt (the disjunction fades, the spheres dim, and a question mark appears between them).

The implementation uses two `MeshInstance3D` spheres with emissive materials. In classical mode, both spheres have `emission_energy > 0` and a connecting arc mesh is visible. In intuitionistic mode, the arc fades (alpha lerps to 0), the spheres' emission drops, and a `Label3D` with "?" fades in. The toggle is triggered by interaction.

The pedagogical point: in classical logic, the disjunction P ∨ ¬P is always available — it is an axiom. In intuitionistic logic, it must be demonstrated for each specific P. The artifact lets the learner toggle the axiom on and off and see what the logical landscape looks like without it.

### constructive_proof (row 4, col 9)
**@identity essence**: `∃x P(x) requires exhibiting x — no proof by contradiction allowed`

This artifact demonstrates the difference between classical and constructive existence. The implementation presents a claimed existence statement and two proof strategies side by side:

- **Classical panel**: Shows the proof structure "Assume ∀x ¬P(x). Derive contradiction. Therefore ∃x P(x)." The witness x is labeled "?" — it exists but is not identified.
- **Constructive panel**: Shows the proof structure "Here is x₀. Here is the verification that P(x₀)." The witness is concrete, displayed, inspectable.

The critical parameter is "the witness": without an explicit construction, the proof is rejected. The constructive panel glows green (valid); the classical panel glows amber (accepted classically, rejected intuitionistically). Toggling between panels highlights what is lost and what is gained.

### brouwer_choice_sequence (row 7, col 5)
**@identity essence**: `a₁, a₂, a₃, ... , ?, ? — each term chosen freely, never completed`

A visual display of an infinite sequence being generated in real time. The implementation creates a row of `MeshInstance3D` spheres, each representing a term in the sequence. Spheres materialize one by one, left to right, with gentle bobbing animation. Past terms are solid; the current term pulses; future terms are invisible.

```gdscript
func _process(delta):
    _time += delta
    var visible_count = int(_time / interval)
    for i in range(visible_count):
        if i < spheres.size():
            spheres[i].visible = true
```

The critical parameter is time: the sequence unfolds perpetually, never completing. The rightmost visible sphere always has siblings to the right that have not yet appeared. The learner watches a mathematical object being constructed in real time — an object that is always unfinished, always open to the next freely chosen term.

The sequence is not predetermined. Each term's value (represented by the sphere's color) is chosen by a pseudo-random process, echoing Brouwer's insistence that choice sequences are not deterministic. The colors drift and settle: each term becomes fixed once it appears, but the next term is genuinely open.

## Curry-Howard Correspondence

The deepest technical legacy of Brouwer's intuitionism is the Curry-Howard correspondence, which establishes a formal isomorphism between:

| Logic | Type Theory | Computation |
|-------|-------------|-------------|
| Proposition | Type | Specification |
| Proof | Term/Program | Implementation |
| Implication P → Q | Function type P → Q | Function |
| Conjunction P ∧ Q | Product type (P, Q) | Pair |
| Disjunction P ∨ Q | Sum type P + Q | Tagged union |
| ∃x P(x) | Dependent pair Σ(x:A) P(x) | Data structure + proof |
| ∀x P(x) | Dependent function Π(x:A) P(x) | Polymorphic function |

Under this correspondence, writing a program that type-checks IS proving the corresponding theorem. Modern proof assistants (Coq, Agda, Lean) exploit this isomorphism: mathematicians write proofs as programs, and the type checker verifies correctness.

Brouwer's intuitionism, once considered a fringe position that crippled mathematics, turns out to be the logical foundation of computer science. The discipline he demanded — existence requires construction — is exactly the discipline that programming requires. A function that "exists" but cannot be computed is useless. An algorithm that "works" but cannot be implemented is not an algorithm. Constructive mathematics is what happens when mathematics takes computation seriously.

## The Map as Constructive Space

The auto-reveal mechanic is the map's deepest technical feature. In a standard map, all tiles exist from the start — the player reveals what was always there. In Brouwer_Intuitionism, tiles are created by the player's approach. The space does not preexist the traversal. This is the BHK interpretation made spatial: a proposition (tile) exists only when there is a proof (the player's presence) that constructs it.

The stepping-stone layout means the player must plan their path — some platforms are reachable only via specific routes. There is no omniscient view of the full map. You build the ground as you walk, and the ground you build determines what ground you can build next. This is constructive mathematics as lived experience: each theorem enables further theorems, and the ones you cannot reach from here are not "false" — they are simply unconstructed.
