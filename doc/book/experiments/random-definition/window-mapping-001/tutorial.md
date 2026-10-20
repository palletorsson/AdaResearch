# Where do the numbers act?

This continuation connects the colour window, the 48-value seed study and Out / Back. It starts with the existing paired-window implementation in `algorithms/randomness/seed_replay/seed_replay_demo.gd`; it is not a standalone reconstruction of the whole museum.

In Random Definition the window is configured with `#mapping_study:true`. The left pane retains ordinary RGB assignment. The right pane has three rectangular controls:

- **RIGHT: MAP** cycles RGB, RED ONLY and SWAP R/B.
- **RIGHT: RANGE** alternates [0, 1] and [0.2, 0.8] for the sampled channels.
- **RESET MAP** restores RGB and [0, 1]. It deliberately leaves +1 DRAW unchanged; the caption names an active offset.

Begin with RESET MAP and +1 DRAW off. Keep the seed and 4 × 4 matrix. Both panes receive the same 48 values: three per cell. Write down a prediction for one cell before changing only RIGHT: MAP or only RIGHT: RANGE. The bars above the windows show the first 24 raw draws, not the remapped channels.

For a raw value `u`, the output in a chosen interval is `low + (high - low) * u`. Narrow range therefore means `0.2 + 0.6 * u`. For example, 0.1 becomes 0.26. In RED ONLY, red uses the mapped first draw; green and blue stay at 0.5. All three draws are still consumed. In SWAP R/B, the third draw supplies red, the second supplies green, and the first supplies blue. These are assignments of values to channels, not new sources of randomness.

Compare the left and right windows. Record the seed, generator/runtime version, matrix size, draw offset, mapping mode and bounds. REPLAY retains the mapping and repeats its result. The museum visit-state record also preserves `mapping_mode` and `mapping_narrow`, alongside the existing seed, source receipt and draw-offset state. This is visit-state restoration, not a new portable export/import interface.

The range and map controls do not emit a seed change or restart the carrying sphere. This preserves the comparison: the sphere keeps its journey while the window changes what its values mean. Compare the two authored spaces. RGB channels have bounds; the sphere's angle and distance have bounds; its return is prescribed. A different mapping is not a claim that either source became more random.

Now independently compute the expected right-hand colour of one cell and compare it with the implementation. Then ask what the representation allowed you to notice. A result that is difficult to read can initiate another apparatus revision. Record the observation before changing the explanation or the controls.

The writing wall at `/long-museum/writing-wall?map=Random_Definition` holds this experiment beside the frame monitor's separate question: irregular measurements alone do not establish entropy. Both the tutorial and the final-text overlay can initiate the next experiment.
