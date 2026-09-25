# The Self-Containing Set

A rule stands at the entrance, with two buttons beneath it. IN. OUT. It looks like enough choice.

The last room changed the space in which a triangle was measured. Here we try to make a collection. The trouble arrives when the collection asks to be counted among its own contents.

## Try both doors

<!-- @russell_paradox_workbench -->

The workbench begins at cell 5. Its rule reads: collect all sets that are not members of themselves. Call the result R. Does R belong to R?

Choose IN. Follow what the readout requires. Now choose OUT.

Neither button is broken. Each answer contradicts the rule that was supposed to make the collection. If R belongs to itself, it fails its own entrance condition. If it does not, it satisfies that condition and must belong. The arrows turn around the same disc. Your hand has somewhere to go; the proposed set does not.

The small computation behind this test is almost bare:

```gdscript
var required: bool = not assumed_in
var agrees: bool = assumed_in == required
```

Try the two possible values. More processing time will not produce a third Boolean. This is the contradiction in unrestricted comprehension: assuming that every condition, applied without a restricted domain, defines a set.

Move the slider one step further, to cell 6. The new rule begins with a collection that already exists: U. Filter its members rather than collecting from everything whatsoever. Try OUT again.

This time it holds. The workbench uses four small sets, named 0, 1, 2 and 3. Each contains the earlier numbers: 0 contains nothing, 1 contains 0, 2 contains 0 and 1, and so on. None contains itself, so all four survive the filter. The result is U again. But U is not one of those four members. The collection and a member of the collection are different things.

One phrase has changed what can be built: *within U*. The rule still uses “not”. A condition can still be applied to the result. What has gone is the permission to take everything as one set. This is the move made by separation in ZF set theory.[^1]

## What the boxes give us

<!-- @russell_set_box -->

The original box remains deeper in the hall. Its nested boxes give the eye an inward journey: an inside with another inside. The script draws a finite number of layers and then marks the continuation.

That limit belongs to the drawing. Rendering a thousand more boxes would not settle the membership question, and reaching the last visible box does not prove a contradiction. The workbench supplies the two-case argument; the box gives it a place to linger. An enclosing wall can be drawn even when the collection its label promises cannot exist as a set.

<!-- @self_membership_set -->

The nested braces nearby ask another question. Does drawing a set inside a set show a set belonging to *itself*? The second brace could enclose a different set. The picture alone cannot decide.

In standard ZF with Foundation, no set belongs to itself. Other choices of axioms require their own examination. “Self-reference is bad” would teach us too little: a program can name itself without collapsing, and a recursive call can have a perfectly good stopping condition. We need to find the particular demand that cannot be met.

## A barber, a lamp, a guest

<!-- @barber_paradox -->

Two labelled bins — SHAVES SELF, SHAVED BY BARBER — and a token that keeps moving between them. Suppose a barber shaves exactly those people in a group who do not shave themselves, and the barber belongs to that group. Who shaves the barber?

Follow both assignments as you did at the buttons. There is no barber satisfying all those conditions. We can change the story: place the barber outside the group, for instance. But then notice what we have changed. An exception is a new arrangement, not a hidden answer to the old one.

<!-- @liar_loop -->

A chalk sign reads THIS STATEMENT IS FALSE. Its lamp alternates. The animation gives a rhythm to the difficulty of assigning the sentence an ordinary true-or-false value. A timer makes the lamp flicker; logic does not force an electronic light to oscillate.

Here the rule concerns truth rather than membership. The family resemblance is useful, but the repairs cannot simply be carried from one material to another. Even in this small hall, the same-looking loop can ask for different work.

<!-- @hilbert_hotel -->

Then the hotel. Full, infinitely, every room occupied. A guest arrives. Everyone moves up one, and room 1 becomes free.

This one settles. The assignment is explicit: the guest in room n goes to room n + 1. Nobody loses a room and two guests never receive the same one. The finite display can suggest that assignment; the rule tells us how it continues.

Keep this surprise close to the contradiction. An offended expectation is not yet an inconsistency. Sometimes the answer requires a construction we had not imagined. Sometimes the requested construction cannot satisfy its own terms.

<!-- @euclid_postulates_plaque -->

The returning postulates plaque keeps the earlier question in view. Changing the parallel postulate led to other geometries. Russell asks us to withdraw a different permission: we cannot assume that every description calls a set into being. We can still state the question. Indeed, stating it carefully is how we learn why the unrestricted set cannot exist.

<!-- @ -->

The room's walls have let us pass. Its rule has not let every imagined object follow. Which restriction makes further work possible, and what does that restriction leave outside?

Gödel is next. There, even a sound, effectively specified theory with enough arithmetic cannot prove every arithmetic truth. We will need to distinguish a construction that contradicts itself from a truth a particular proof system cannot reach.

[^1]: For separation, the construction of finite numbers from sets, and the difference between describing a collection and assuming it is a set, see [John D. Norton's set-theory lectures](https://sites.pitt.edu/~jdnorton/teaching/paradox/chapters/sets/sets.html). The workbench evaluates a finite example, not arbitrary set-theoretic formulas. Foundation and the other ZF axioms are treated in [C. McMullen's Math 101 notes](https://people.math.harvard.edu/~ctm/home/text/class/harvard/101/16/html/home/course/course.pdf).
