# Ambient patch — 22 September 2026

Implemented a supporting ambient instrument in WaveFunctions_Synthesis_Lab at (4,6). Fixed visible patch, six physical sliders, three native buttons, live output PCM scope. Existing Ada Discreet/FM synthesis is baked on AsyncAudioGenerator; native effects and eight finite voices handle playback. No existing map artifact was removed.

`run_tests.py` records actual audio and validates synthesis, native slider signals, seeded events, bounds, lifecycle and cleanup. `run_hall.py ambient after` uses private museum runtime paths and validates actual hall reach, collision, approach and XR Tools grabs. `publish.py` refuses a passing claim if either report contains failures.

Latest result: 33 instrument checks + 82 hall checks passed. Preview has no clipped PCM. Headset performance, sound and comfort remain to test. Existing project startup UID/sequence warnings appear in the retained logs; no ambient patch script errors.

Review: http://localhost:3003/book-review/doc/book/iterations/2026-09-22-ambient-patch/index.html
