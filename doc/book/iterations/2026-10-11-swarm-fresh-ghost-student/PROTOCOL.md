# Fresh ghost student — assessment protocol

Completed 11 October 2026 at the user's request. This protocol records the assessment conditions. Results: [supervisor assessment](index.html) and [fresh student report](student-report.html).

## What makes this run fresh

A separate student agent was started with `fork_turns: none`. It received no conversation history, earlier verdicts, prior ghost-student findings or existing test probes. It was instructed to read the seven current tutorial/final pairs in order, reconstruct the named scripts from their printed blocks, execute complete hosts, and choose an independent variation.

The supervisor prepared a reading-only packet from the frozen reviewer ZIP. It includes fourteen exact canonical texts, seven museum photographs and the optional study assignment. Prior outcomes linked from that assignment are explicitly withheld. The packet contains no prebuilt `.gd` or `.tscn` lesson files. `input-manifest.json` records the package and input hashes and the protected project files.

These are task-enforced reading restrictions. The agent shares the filesystem and tools; this is not a security sandbox. Its reading and assistance log must disclose any additional sources. The supervisor already knows the author's work and will verify the evidence, but will not provide test answers or choose the student's variation.

## Preparation supplied

The student is an experienced coding AI with general Godot/GDScript knowledge, not a novice human. The lessons assume prior programming concepts and a prepared Endless Museum. The agent may use the explicitly declared XRTools, physical button, ecosystem and their dependencies in the project. The supervisor supplies the workspace and Godot executable paths, the headless invocation and a separate output directory.

Student work stays under `student/`. Printed originals, variants, minimal scenes, predictions, test harnesses, execution logs and results must remain inspectable. Canonical text, production models, layout and order are held fixed during the assessment.

## Required evidence

1. Seven lesson pairs read in spine order; twenty-two printed files reconstructed without using the author's study implementations.
2. Actual Godot execution of each complete reconstructed host and relevant model checks invented by the student.
3. A recorded prediction before executing at least one independently chosen variation beyond the supplied exercise. Variants remain separate from exact reconstructions.
4. Failures retained and classified: lesson instruction, undeclared dependency, student/harness mistake or environment limitation. Any help from the supervisor is recorded.
5. A report of the learning progression and the experiment's measured outcome, including contrary results.

Synthetic input can assess implementation behaviour. It does not test bodily reach, headset comfort or learning by a human. A fresh AI reconstruction supplies a different kind of evidence from the author's earlier checks; neither alone establishes educational effectiveness.
