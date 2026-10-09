# The lines move themselves

Palle requested smooth animated arrangements with no interface. Removed all eight buttons, four control plinths and their prompts from the primary Line Space Workshop. The four count labels and floor marking remain. Existing map placement and surrounding artifacts are unchanged.

Each station holds an arrangement for six seconds, then moves for five seconds using eased rigid transforms. Rods are persistent XRTools pickables; they neither respawn nor change length between configurations. The four-edge square folds around its diagonal, keeping all corners joined, then unfolds before rearranging into a grid. Extra cube edges fade in at full length, becoming pickable only when fully visible. Hidden rods have no active collision layer.

Holding any line pauses that station's automatic motion. On release, the arrangement stays for twelve seconds. Recovery interpolates from the actual hand-made positions back to the paused target over five seconds; it does not snap or restart from an authored pose. Other stations keep moving. No scheduled background automation was created.

The book, registry description, README, saved encounter and local encyclopedia research report now describe this behavior. Only the workshop passage was changed; the rest of the book and map inventory were checked for preservation. The 29-case geometry research remains a separate study of arrangements, not a measurement of the animation.

Validation: 22 runtime checks passed, including no control colliders, continuous arrival, mid-animation fold closure, real grab-driver pause/release/recovery, faded-edge pickup eligibility, fixed lengths across 500 animation samples and completion of every station's cycle. The production route model remains connected. Headset comfort and reach remain unverified. Actual museum capture: `ada_run/line-workshop-museum.png`; runtime log: `ada_run/line-animation-museum.log`.

Run the current behavior check with `ada_run/line_workshop_check.tscn`, which references `line_workshop_animation_check.gd`. Snapshots of the prior button implementation and text are under `before/`.
