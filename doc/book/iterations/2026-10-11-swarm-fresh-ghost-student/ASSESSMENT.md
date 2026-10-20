# Swarm: a fresh student reconstructs the book

**All seven lessons ran from the printed code. The fresh student also designed, predicted and executed its own Flow Fields variation.** This is useful evidence that the current sequence supports reconstruction and extension by an experienced coding AI. It found no blocking omission within the declared prepared museum project.

The student had no conversation history, previous verdicts or author-written test probes. It received the seven tutorial/reflection pairs and existing hall images from the frozen review package. It read them in order, extracted 22 printed scripts, wrote seven minimal scenes, and tested the complete hosts in Godot 4.6. Its work and first execution log are preserved separately from the book.

## What passed

| Evidence | Result | What it establishes |
|---|---|---|
| Printed reconstruction | 22 scripts match the frozen listings exactly; seven new scene attachments | The complete listings can be assembled in the stated environment. |
| Actual execution | All seven full hosts entered Godot's scene tree | Models, displayed objects and controls were constructed together. |
| Student-written checks | 120 passed; zero failed | Numerical rules, state transitions and synthetic interactions behaved as asserted. |
| Independent extension | Two modified Flow models and their full hosts ran | The student could turn a new question into executable changes and an interpretable experiment. |
| Preservation | 84 protected text, code, layout and order files unchanged | This assessment did not quietly repair the book to obtain a pass. |

The 120 include 40 loading/button-presence checks. Several numerical expectations already appear in the lessons. The stronger evidence of transfer is the student's own pre-execution derivation, separate variants, measured traces and interpretation of an unexpected later consequence.

## A variation the student chose

The student made a **braking strip**: inside it the field requests zero velocity; outside it requests motion to the right. The same sphere enters with the same velocity. One copy updates every .05 seconds, the other every .025 seconds. Both run ten seconds of model time.

Before running, it calculated that the coarse version would travel at most 1.35 cells in the strip, while the fine version could travel 1.425. The boundary is 1.4 cells away. It predicted that only the finer-step sphere would get out, on step 79.

That happened. The coarse sphere settled near x=8.95. The fine sphere first crossed x=9 after **1.975 seconds**, accelerated in the outer field, then wrapped around the grid and entered the strip again. The student explicitly corrected the possible overstatement: first escape does not mean permanent escape. A final-position screenshot alone would miss the difference.

![Measured horizontal position of both Flow variants](flow-variation.png)

This chart uses the student's Godot measurements. It is not a rendered scene or an illustration of an assumed outcome. [Prediction recorded before execution](predictions.html) · [Variant source](student/variants/fine/field.gd) · [All measurements](student/results.json).

## How the sequence held together

The student could follow a consistent question: **where is the information kept, and how does it change the next movement?** Physarum leaves a shared mark; Flow reads a supplied direction; Boids reads neighbours; ABM adds individual cargo; Ant Colony separates two shared channels; PSO replaces trails with scored memories; Population Support accounts for events that change the group.

That progression does not require pretending each algorithm extends the previous algorithm unchanged. The same point and familiar interaction let the information source change. The student noticed the deliberate breaks: ABM sets flocking aside; PSO replaces trail-following with remembered evaluations; the last hall adds an account around a supplied ecosystem.

Its smaller probes also found the distinctions the reflection needs: a wrap seam does not automatically create periodic neighbours; equally scored PSO positions still need a tie policy; and a fabricated birth and loss can cancel in an account without making the history true. These are concrete limits of the models, not claims that the algorithms explain society.

## What this leaves open

The reconstruction used complete printed listings and the declared prepared museum dependencies. This was an experienced AI reader, not a beginner installing Godot in an empty project. The last hall reconstructs the observer/account around the existing ecosystem, not the whole ecology from scratch. Reading restrictions were task instructions, not filesystem isolation; the student's assistance log discloses its additional reads.

The checks exercised synthetic grab callbacks, action/button signals and keyboard events under translated and rotated hosts. They did not test physical XR pickup, reach, text legibility, headset comfort or the student's ability to navigate a rendered room. The hall photographs below are existing museum images supplied to the reader, not screenshots of this headless run.

There were no failed lesson assertions. The run retained an unresolved project audio UID, a missing-player notice and a supplied Jolt shape warning. A Windows console encoding error occurred while printing the already-saved successful log; the student fixed only its wrapper's output encoding. The first engine run and its evidence remain intact.

**My judgment: keep the current edition for review.** This run gives no reason for another broad rewrite. The next useful check is an observed human attempt to reconstruct one hall and make a variation, with special attention to the prepared-project assumptions and the difference between installed hand controls and the minimal printed host.

## Inspect the evidence

- [Full fresh-student report](student-report.html)
- [Before-run predictions](predictions.html)
- [Student's new test code](student/probe.gd), [results](student/results.json), and [original Godot log](student/logs/20261011T183427Z.log)
- [Reading and assistance log](student/READING_AND_ASSISTANCE.md)
- [Input and protected-file manifest](input-manifest.json), [reconstruction provenance](student/provenance.json), and [supervisor verification](verification.json)
- [Assessment protocol](PROTOCOL.md) and [observer log](observer-log.json)
- [Reproduce the run](student/run_probe.py): execute from this repository with its prepared dependencies. This is a verification script, not a standalone Godot distribution.
