A door frame with two leaves in it, one swung open and one shut, both there at once, and you can walk through.

The last room answered the crisis by giving things up: assert only what you have built, and lose the theorems that depended on assuming otherwise. This room answers it the other way. It keeps the contradiction, keeps working, and gives up something much smaller than you would expect.

What it gives up is a single inference rule. Not truth, not rigour, not consistency in any sense you would miss — one rule, called *ex falso quodlibet*, which says that from a contradiction anything whatsoever follows.

## The rule that does the damage

<!-- @both_true_gate -->

```gdscript
# both_true_gate.gd:15
## truth: P and not-P, and the world does not end — the contradiction is contained,
##   not detonated.
```

In classical logic, one contradiction is fatal to a whole system — not locally, everywhere. If both P and not-P are derivable then every sentence in the language is derivable, including every falsehood, and the system stops distinguishing anything from anything. That total collapse is why a single inconsistency is treated as catastrophic. It is not that the contradiction is embarrassing. It is that it spreads.

Paraconsistent logic blocks that step and nothing else. Contradictions may be derivable and are not permitted to imply arbitrary conclusions. The tutorial in this room states the containment exactly: *contradictions exist in the box; they cannot escape as anything follows.*

The gate makes it a thing you walk through. Both leaves are real, the frame holds them, and the room around it is not on fire. That is the entire claim, and the reason it needs to be a body rather than a sentence is that the sentence sounds like a trick and the door does not.

## A resting state, not an exception

<!-- @florensky_sphere -->

```gdscript
# florensky_sphere.gd:21
# critical_parameter: current_state — BOTH (A ∧ ¬A) is the resting state, not the
#   exception; observation collapses it to A or ¬A only briefly
```

A double-faced sphere whose skin reads from both sides, holding A and not-A on one surface.

Read the parameter carefully, because the ordering is the argument. BOTH is where the object rests. Looking at it can knock it briefly to one side, and it returns. This is the inverse of the arrangement you would expect and the inverse of the two objects across the room: the single-valued states are the transient ones, and the contradiction is the stable configuration.

Pavel Florensky was a mathematician, an Orthodox priest and an electrical engineer, and he argued that the deepest truths are antinomic — that a contradiction properly held is not a failure of thought but its highest form. He wrote that while working as a physicist in the Soviet Union; he was executed in 1937. The artifact's header calls the contradiction *a MODE OF BEING* rather than a defect, and that is a fair rendering of his position rather than a decoration on it.

One mechanical detail earns a look. To show both faces of one surface the artifact has to disable back-face culling, so the inside and the outside of the same skin both catch light. Everywhere else in this project turning culling off is a compromise; here it is the argument. A surface that can only be seen from one side cannot hold two readings.

## The foil, and it is a foil

<!-- @schrodinger_box -->

<!-- @superposition_display -->

```gdscript
# schrodinger_box.gd:12  ·  superposition_display.gd:10 — the same axis, twice
# critical_parameter: remainder — where the box puts the part of the state it cannot
#   show you (core | twin | seam | haze | witness)
```

Two quantum objects stand across from the two logical ones, and it would be easy to read them as the same idea in physics dress. They are the opposite idea, and the room is arranged so you can catch the difference.

The cat is both alive and dead until observed — and then it is not. Observation collapses the superposition to one branch and the other is gone. The display says the same thing about a qubit: `|ψ⟩ = α|0⟩ + β|1⟩`, genuinely occupying both, and genuinely resolving to one when measured. Both are contradictions *with an expiry*. The world tolerates them precisely because looking ends them.

Now notice what the two of them share and the other two do not. Both carry an axis called `remainder`, with five settings, and its job is to decide where the object puts *the part of the state it cannot show you*. Core, twin, seam, haze, witness — five architectures for the unshowable.

The gate and the sphere have no such axis, and do not need one. Nothing is being held back. Both leaves are in the frame; both faces are on the sphere. The quantum pair need a hiding place because their contradiction is not permitted to persist in view; the paraconsistent pair do not, because theirs is.

That is the distinction to leave the room with, and it is easy to lose: **collapse-on-observation is the foil, not the model.** Superposition resolves and paraconsistency refuses to. Placing them four metres apart is the room's whole method.

## Two answers, both live

Stand back and this room and the last one are a matched pair, and the sequence puts them in this order deliberately.

Brouwer takes the crisis to mean the standard was too loose: stop asserting what you cannot construct, accept a third state between true and false, lose the theorems. Florensky takes it to mean the demand was too strong: keep both assertions, block the explosion, lose one inference rule.

Neither repairs the foundation. Both are ways of continuing to work on a foundation that is known not to close, and they disagree about which piece of classical logic was the mistake. That they are both viable is the actual state of the field, and it is more interesting than a resolution would have been.

The last room takes that seriously in a way neither of these two quite does. If the gap cannot be closed by tightening or by loosening, then the gap is not a defect in the method — it is what the method runs on.

Paraconsistent logic doesn't resolve contradiction. It refuses the demand that contradiction must resolve.
