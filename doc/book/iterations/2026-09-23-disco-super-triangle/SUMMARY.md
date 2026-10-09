# Super Triangle on the existing disco floor

Requested: a black and white triangle movement in the same disco floor.

Built: PATTERN now includes SUPER TRIANGLE after SNAKE. Six families of half-square combinations turn through 24 poses: diagonals, chevrons, diamonds, turning waves, large diamonds and super diamonds. The last groupings use larger motif pitches across the fixed tiles. Continuous shader interpolation supplies the between-pose movement. HOLD freezes the fractional pose; ONE STEP reaches the next pose; SPEED preserves current progress. Musical column flashes continue and expire while held. The shared colour controller can supply its selected palette.

The 144 original tile transforms and collision are unchanged. One optional shader plane follows the actual receiver dimensions and floor height. The original four square modes remain available. The chapter gains two paragraphs and the six-state native illustration, connecting the changing figure to the fixed addresses. Existing prose and the sequence order remain.

## Evidence

- `report.json`: 121 focused checks pass in the isolated production museum, including the earlier controls/clock checks, all triangle poses, cycle return, intermediate hold, one step, pulses, palette inputs, mode restoration, collision and three selected ordinary-controller walks. Audio muted. The shared palette method was tested, not the later colour hall's physical interaction.
- The first pulse assertion ran before the controller's next process/render cycle. The corrected probe checks the event's stored column, then checks the shader texture after rendering. No production pulse workaround was needed. `first-report.json` and `first-stdout.log` preserve the first result.
- Six exact-pose native captures form `triangle-combinations.png`, also used in canonical `final.md`. `motion-000.png` through `motion-095.png` are native intermediate shader samples, resized to 768 by 512 and replayed at 8 fps. This is an edited silent preview, not a real-time recording.
- Publication: 24 preservation/source/HTTP checks, JavaScript syntax and seven viewer event checks pass.
- Native family/transition/eye-height/console images and the composed figure are visually inspected. Existing startup UID, viewport-texture and compatibility-renderer warnings are present; no new GDScript or shader errors.
- `Tutorial_Disco.diff` preserves the exact manuscript addition; `source-changes.diff`, before/after snapshots and hashes preserve implementation provenance.

Headset comfort, Quest performance, listening quality and learner response remain untested. The browser-control tool previously failed during sandbox startup; this preview is checked through served assets, script syntax and a small viewer interaction harness, not a claimed browser click session. No live museum restart, bake/save replacement, commit or full-book/audio rebuild.

Next: Color_Context_Placed and its existing long hall of accumulated primitive stacks.
