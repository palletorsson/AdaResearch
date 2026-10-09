# Revision 1: retain one twig comparison

The complete original submission remains unchanged. These files were written after the evaluator returned native results and `museum/front.png`, `museum/oblique.png`, `museum/side.png`. I have not run Godot.

## Observation and chosen change

The front view makes the wave tree's asymmetric first fork visible. It is much harder to match one terminal twig between separated trees against the nearby block tree, interval drawing and rail. The oblique view changes apparent sizes. From the side, the two planar constructions and their grips substantially overlap. I could not establish equal terminal directions from these images alone.

I am keeping the wave rule, amplitude, frequency, phase and first-fork grips. I add one retained comparison: the same terminal branch in the original and changed construction, placed in a common frame with a neutral background. It is a reader of the generated records. It does not make another tree rule or change the fifteen generated branches.

`tree_wave_with_witness.gd` extends the unchanged first composition. At construction it reads both endpoints of terminal leaf 3 in depth-first order from the generated tree and a temporary original hierarchy with the same generations and shortening ratio. With three generations, this is the path first child, second child, second child (0, 1, 1). The temporary reference is freed; it is not another museum installation.

The witness draws the original twig in cyan, the wave twig in rose and their tip-to-tip connection in pale yellow. A single translation centres both records together, with no scaling or independent fitting. The data are retained at construction, as the caption states. Later manual editing of the main tree does not revise this saved comparison. Rerunning the study with different settings creates a new one.

## Execution

- Revised study entry: `attempt/revision/tree_wave_with_witness.gd`.
- Corrected native probe: `attempt/revision/prediction_probe_deferred.gd`.
- Keep the complete `attempt/` structure: this revision intentionally imports the unchanged first-submission files beside it.
- In the prepared museum, replace only the temporary wave study's entry script with the revised entry. Keep the original tree as its separate companion. Keep station scale `(1,1,1)` and the same original wave settings: generations 3, ratio 0.7, amplitude 12 degrees, frequency 0.25 cycles per parent level, phase `PI / 2`.
- The witness panel is centred at `(1.40, 1.25, 0)` relative to the revised study and is 0.95 m wide by 0.85 m high. Leave that area free. In the supplied comparison pair, it occupies the interval between the two study origins. This is still temporary placement; overlapping the existing recipe table would be a reason to reposition the whole pair, not to call it a final installation.
- Additional Inspector property: `witness_leaf_index = 3`, clamped against the actual terminal population. Inspect from local +Z before moving a grip. The retained card remains planar; the side view remains a demonstration of what its projection omits.

## Prediction recorded before revision execution

The original tree's source, the wave formula and the main grip behavior should remain unchanged. Both compared terminal segments should still be 0.2401 m long. Their direction-vector difference should be below 0.00001; their tips should differ. The added connector should have exactly that tip separation, modulo floating-point precision. A neutral background and paired lines should make this one comparison easier to inspect from the front, but that usability expectation needs another image or encounter.

At zero amplitude the twig pair should coincide and the zero-length connector should be hidden by the carried LineSkin. Changing phase may produce a nonzero direction difference; the witness reports rather than conceals it. These are predictions, not observed outcomes of this new file.

## Probe repair

The first `prediction_probe.gd` used top-level preloads. Its CLI load chain reached XRTools before `XRToolsUserSettings` was available. Deferring only `run_predictions()` did not defer script compilation. The revised runner has no top-level study preloads. It waits for a ready `XRToolsUserSettings` autoload, allows another process frame, then dynamically loads the study scripts using paths relative to its new `revision/` directory. It checks that all script resources exist and can instantiate, and exits with setup code 2 if the prerequisites fail.

The original assertions remain, followed by checks that the witness leaves the generated tree intact and retains the selected terminal lengths and directions. A pass message is only an assertion outcome. Acceptance must also inspect the engine log for script errors; this runner cannot certify its own loader by printing success. The revised runner has not yet been executed by me or confirmed by returned results.
