# Hand-only opening and integrated instruments

15 October 2026. Palle requested two-metre spacing, movement of only the touching hand, a small “select” stand at the falling page, an always-running Geiger with built-in controls, controls within the lava wall, and removal of Random Return's information board.

## Apparatus

- Random Touch keeps its three bare two-metre lines. Their centres are now two metres apart. Contact attaches only that controller's virtual hand to the sphere's displacement. The head, body, tracked controller and other hand retain their normal transforms. Withdrawing the tracked controller more than 20 cm from the contact position releases the hand and restores normal tracking. Pause and deletion also remove the override. Desktop right-click runs the sphere without moving the camera.
- The RAND page's small stand has a real 2D Label in a SubViewport, displayed on a world-space face. It says only “select”, faces the page's approach side and persists across reprints. Digit selection is unchanged.
- The Geiger starts playing on creation and loops its stored 96 detections. Repetition is explicitly labelled as recorded simulation; it does not claim new physical entropy. Ten controls are mounted in its front cabinet. RESTART replaces play/hold; SOUND can mute the clicks without stopping the experiment.
- The lava wall's controls occupy the central bay between baseline and current captures. Its status is part of the wall, with no separate control stand.
- Random Return's information board is removed. Its sphere, floor markings, replay controls and whole-body travel remain.

The current final retains the approved shared “we” voice, corrected to describe the hand-only apparatus. The tutorial now supplies all three source files. Both text plans and Random Touch's writing-wall notes agree. Existing map placements, magnet positions, tags and encounter order were retained. Earlier opening texts and the previous body-carry test are historical records.

## Evidence

- [Hand-only test log](touch-test.log): PASS. Exercises seeded paths and rates, waiting and return, saved phases, real XR Tools collision/visible hands, contact activation, withdrawal, pause and deletion. Checks the unchanged head/body/controller/other-hand transforms and restored hand targets.
- [Interface test log](interfaces-test.log): PASS. Checks automatic Geiger playback and recorded looping, muting, embedded button callbacks, lava baseline/capture comparison, page selection and reprint, and Random Return movement after board removal.
- [Page lifecycle test log](page-lifecycle-test.log): 59 checks, no failures. Uses the actual museum cartridge round trip, then reprint and other page modes.
- Godot rendered previews were inspected: [touch](touch.png), [page](page.png), [select stand](select.png), [Geiger](geiger.png), [lava](lava.png), [return](return.png). The select backing is unshaded to keep its small text legible under room lighting. The preview harness also includes existing project autoloads; its green background and HUD are unrelated to this change.

The test runtime reports existing Jolt solver-bias and missing-environment warnings; the combined interface run also reports ObjectDB instances at shutdown. No test failure or script error was reported. These checks do not establish physical headset comfort or an independently reconstructed experiment. The next observation is how the displaced virtual hand feels, and whether withdrawal is clear at the 20 cm threshold.

## Reproduce

Run Godot from the repository with `--headless --xr-mode off --audio-driver Dummy --path . --script` and one of:

- `tests/test_random_touch_hand.gd`
- `tests/test_random_hall_interfaces.gd`
- `tests/test_rand_page_lifecycle.gd`

Use `render.gd` in this directory with the Compatibility renderer for previews. Rebuild the canonical tutorial with `node doc/book/iterations/2026-10-15-hand-and-interfaces/build-tutorial.mjs`; `tutorial-source.md` supplies the prose and the builder embeds the current artifact files. The tutorial has 957 prose words and 297 nonblank code lines, counted separately in `text-counts.json`.
