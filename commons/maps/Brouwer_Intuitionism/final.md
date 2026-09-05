A staircase with a few steps at the bottom and nothing above them, and the nothing is not unfinished. It is the correct state.

Everything so far in this sequence has been a limit discovered from inside: a postulate that cannot be proved, a set that cannot be defined, a loop that cannot close. This room is the first of two answers, and it is the severe one. Brouwer's response to the crisis was not to patch the foundations. It was to say that a large part of what mathematics had been doing was never legitimate, and to give up the results rather than the standard.

The rule is one sentence. **To assert that something exists, you must produce it.**

## The third option

<!-- @excluded_middle_demo -->

```gdscript
# excluded_middle_demo.gd:9
# essence: P ∨ ¬P — the law of excluded middle; Brouwer: "not always!"
```

Two glowing spheres, P and not-P, with the disjunction between them, and a slider that flips the room between classical acceptance and intuitionistic doubt.

Classically, `P ∨ ¬P` is free. Every proposition is true or false; you may use that before knowing which. It is what licenses proof by contradiction: assume not-P, derive absurdity, conclude P — and you have proved P exists without ever exhibiting it.

Brouwer refused the licence. For him a mathematical statement is not a description of a pre-existing fact but a report on a construction, and a construction either has been carried out or has not. So there is a third state, and the tutorial in this room names it exactly: not true, not false, **not yet constructed**. The third option is the whole point, and it is not ignorance. There is no fact of the matter waiting to be uncovered, because on this account the fact is made by the proof.

This is one of two objects in the room you can actually operate. Hold on to that.

## Show me

<!-- @constructive_proof -->

```gdscript
# constructive_proof.gd:9
# essence: ∃x P(x) requires exhibiting x — no proof by contradiction allowed
# critical_parameter: the witness — without an explicit construction, the proof is rejected
```

The distinction, made into an object: knowing something exists, versus being able to point at it.

The classical proof that there exist irrational `a` and `b` with `a^b` rational is the standard demonstration of how wide the gap is. Take √2 to the power √2. Either it is rational, in which case you are done, or it is irrational, in which case raise it to √2 again and you get 2, and you are done. The proof is valid, it is three lines, and at the end of it you cannot say which of the two cases you are in. It has proved that a witness exists without producing one.

Brouwer's answer is that it has therefore proved nothing. The word *exists* was doing work it had not paid for.

What that costs is enormous, and honesty about the cost is part of teaching it: intuitionistic mathematics loses large parts of analysis, most of the theory of infinite sets, and any theorem whose only proof runs through contradiction. Brouwer accepted the loss. Hilbert, who did not, wrote that taking excluded middle from the mathematician was like taking the telescope from the astronomer.

## Always unfinished

<!-- @brouwer_choice_sequence -->

```gdscript
# brouwer_choice_sequence.gd:8
# essence: a₁, a₂, a₃, ... , ?, ? — each term chosen freely, never completed
# critical_parameter: time — the sequence unfolds perpetually, dots gently bobbing
```

A row of terms trailing off into question marks. Brouwer's choice sequences are his positive proposal, not just his prohibition: an infinite object that is never completed, only ever extended, where the next term is chosen and not determined. Infinity as a process rather than a finished set.

Now read the two lines above against each other. The essence says *each term chosen freely*. The critical parameter is `time`, and the sequence unfolds perpetually on its own. Its header names the missing piece without flinching — *could add ability to "choose" the next term* — so the object whose entire content is free choice runs on a timer and chooses for you.

That is the room's central irony and it is not confined to this one body. Of the four stations of the argument, two have controls and two do not; `constructive_proof` says *VR controls [missing]* in the same breath as declaring that the witness must be exhibited. A room whose claim is that nothing exists until a hand makes it, in which most of the hands are absent.

I would not repair that by wiring buttons to everything. The gap is more useful named than closed, because it is the actual condition the philosophy describes: the construction is *possible*, nobody has performed it, and on Brouwer's own terms that means it does not yet exist. The room is in the state it is teaching.

## The step that is not there yet

<!-- @constructive_staircase -->

```gdscript
# constructive_staircase.gd:14
## truth: the next step isn't true-or-false until you build it — existence is
##   construction, not the absence of a contradiction.
```

Built steps are solid. Above them there is nothing, and the nothing is not a gap in the model.

A classical mathematician looks at the unbuilt region and says: either the seventeenth step exists or it does not, we simply have not looked. Brouwer says there is no seventeenth step to have a property, and there will be one when someone builds it. Not hidden. Not undetermined. Absent.

That is the difference between an epistemic gap and an ontological one, and it is the hardest idea in the room, which is why it is worth having it as a thing you can stand at the bottom of and look up from.

## The one that does it properly

<!-- @cantor_diagonal_workbench -->

```gdscript
# cantor_diagonal_workbench.gd:6
# desire: learner viscerally feels uncountability — you can list "all" reals, and we
#   will construct one that isn't in the list, just by flipping the diagonal
```

Nothing in the room says why this bench is here, so here is why it earns its place: it is the model constructive proof, and it is the other object you can operate.

Cantor's diagonal argument is often taught as a proof by contradiction — assume the reals are listable, derive absurdity — but it does not have to be, and this bench does not present it that way. Turn the slider, the list grows, the diagonal extends, and a number is *built*, digit by digit, that differs from the first entry in the first place, the second in the second, and so on. At the end you are holding the witness. It is not that a missing real must exist; it is that here it is, and you watched it being made.

So this is what Brouwer is asking for, standing in the same room as the objects that cannot deliver it. The procedure scales, it terminates at any length you choose, and it hands you the thing.

## The two that assert

<!-- @angle_sum_triangle -->

<!-- @parallel_lines -->

Two objects have been carried forward from the first room and left here without explanation. They are the triangle whose angles sum to 180°, and the pair of parallel lines.

They are also, of everything in this sequence, the two artifacts that *assert rather than construct*. The triangle does not measure its corners; it prints the string `"60° + 60° + 60° = 180°"`, and the `curvature` knob its own header names appears six times in the file, every one of them inside a comment. The parallel lines have no script at all — the scene file is two line instances and two hand-typed transform matrices, parallel because somebody decided so and typed the numbers.

In a room about constructive proof, that is the entire lesson standing in the corner. Both objects state a result. Neither exhibits a witness. Both are, on the strict reading this room is teaching, claims for which no construction has been performed — and both are perfectly convincing to look at, which is the danger Brouwer was pointing at.

Whether they were placed here for that reason, I cannot tell from the map. They earn the position either way.

## What it costs

This is the harder of the two responses to the crisis, and it works by giving things up. Brouwer keeps certainty by shrinking mathematics to what has been made, and pays for it in theorems.

The next room takes the opposite route. Rather than refusing to assert what cannot be built, it refuses to panic about holding two assertions that contradict each other. Where Brouwer removes the third option and calls it *not yet*, Florensky keeps both options at once and declines to let the contradiction spread.

No existence without witness. No truth without a hand that built it.
