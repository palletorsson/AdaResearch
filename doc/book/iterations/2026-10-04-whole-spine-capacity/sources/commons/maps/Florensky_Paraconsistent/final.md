# Holding Contradiction Without Collapse

A door frame with two leaves in it, one swung open and one shut. Both are faint enough to see the room through them.

Which one will your body believe?

Walk through. The closed leaf lets you pass. Turn back: it is still there. Nothing has fallen apart to accommodate you.

In the last room, a row waited for your next choice. Here two answers have already arrived, and they disagree. Before choosing between them, find out what the room does with their disagreement.

## One door, two reports

<!-- @both_true_gate -->

Three buttons stand beside the threshold. Clear the reports, then press **P: OPEN**. One leaf appears. Add **not-P: CLOSED**. The first stays where it was; the second joins it.

These are reports about the same door at the same moment. This little study allows only the opposed descriptions open and closed. The two ghost leaves give each report a shape. Seeing two meshes together is easy for an engine. Deciding what follows from incompatible claims is another problem.

Look at the last line of the display: **Q: alarm triggered = NO SUPPORT**. Add a report, remove it, hold both. Their disagreement supplies no evidence about an alarm. “No support” does not mean the alarm has been proved silent. We have simply learned nothing about it from these buttons.

The small piece of code that keeps the reports is almost disappointingly hospitable:

```gdscript
var report_open: bool = true
var report_closed: bool = true
```

Two places in memory. Neither overwrites the other. The apparatus stores conflicting information; it does not decide which report is true or implement a whole logic. But it lets us hold a problem still long enough to ask what a logic would permit us to conclude.

In classical logic, if both P and not-P are available as premises, any proposition Q follows. This is called *explosion*: the premises cease to constrain the conclusion. Paraconsistent logics prevent that general consequence. They are a family of approaches, with different rules and commitments, rather than one small patch that leaves everything else untouched.[^1]

The room continues to stand. That is the image. The limited fact store on the console is the working model. Neither makes a proof out of a door.

And your passage? The engine gives collision to the frame, but not to the ghost leaves. The visible assertion “closed” has no authority to stop you. Someone had to make that decision. A system can preserve conflicting descriptions and still have to decide who gets through.

## Stay with both

<!-- @florensky_sphere -->

Beyond the gate, a small sphere carries **A ∧ ¬A**. Its colours continue to shift. The label holds.

Circle it. Wait. In this hall, looking does not force a verdict. We have set the object to keep both readings, so that attention can last longer than the demand to settle it.

Pavel Florensky explored religious antinomies in *The Pillar and Ground of the Truth* (1914). His treatment has been read in several ways, including paraconsistent and rhetorical ones. The sphere borrows the invitation to remain with an antinomy; it should not make those disputed readings look like a single established “Florensky logic”.[^2]

Its skin has an ordinary technical provision: back-face culling is disabled, allowing both sides of the mesh to be drawn. An outside and an inside can catch the eye on one surface. This is a way of staging two readings. It does not make the sphere exist and not exist.

Nor does paraconsistency require us to believe that some contradictions are true. That further position is called *dialetheism*.[^1] We can keep conflicting reports without first accepting both as facts. This distinction leaves room for investigation: a mistake may need correcting; incompatible accounts may need keeping while we discover how they arose.

There is a desire here to inhabit something before its description has settled. A body can outgrow the terms supplied for it. It need not become a logical contradiction to deserve more room. The question returns to the doorway: must every account agree before a passage can be allowed?

## What the next pair can show

<!-- @schrodinger_box -->

<!-- @superposition_display -->

Two older works wait at the back: Schrödinger's box and a superposition display. Their resemblance to the sphere is useful precisely because it invites a shortcut.

The box stays sealed here. Its own label admits it opens only on a desk, and that when it does the program decides the result by a coin it flips. This is a scripted toy, and a box that will not open for you says so more plainly than one that would: the program chooses what the opening would reveal.

Beside it, two forms fade against each other around the expression `|ψ⟩ = α|0⟩ + β|1⟩`. A slider changes the pace. Watch long enough: the display keeps cycling. It has no measurement operation, and the opacities it draws are not quantum amplitudes.

Quantum superposition describes a state in relation to a basis; it is not simply the logical assertion P and not-P.[^3] These objects cannot lend physics as a certificate for the sphere. They can help us notice how readily a shared visual language—two colours, a sealed box, a change when watched—makes different problems seem identical.

Keep the resemblance. Investigate what it leaves out. We have been learning to do that since a thin rendered line first asked us to walk straight.

## Continue without settling everything

Brouwer's hall asked what you could construct and what counted as a witness. This hall asks what follows when the available claims conflict. One question does not answer the other.

At the exit, the reports may still disagree. Your movement has not resolved them. It has exposed another rule: the decision that lets you pass while the disagreement remains.

The next room brings these different responses together. We will need their differences. A foundation that cannot answer every question is not permission to say anything whatsoever.

[^1]: See the [Stanford Encyclopedia of Philosophy, “Paraconsistent Logic”](https://plato.stanford.edu/entries/logic-paraconsistent/), especially its distinctions between non-explosion, inconsistency and dialetheism.

[^2]: Paweł Rojek, [“Pavel Florensky's Theory of Religious Antinomies”](https://doi.org/10.1007/s11787-019-00234-0), *Logica Universalis* 13 (2019), 515–540, examines four interpretations and the difficulties in Florensky's formulas.

[^3]: IBM Quantum, [“Superposition with Qiskit”](https://quantum.cloud.ibm.com/learning/en/modules/quantum-mechanics/superposition-with-qiskit). The museum's box and opacity animation are visual comparisons, not implementations of the quantum state described there.
