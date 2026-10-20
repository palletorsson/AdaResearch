# Void fog / full runtime repair

User reported no fog during play after the nine-level change. Reproduced with
the full project and the actual desktop player camera, Forward+. NatureRenderer
binds the tower WorldEnvironment during deferred boot. At the account's loaded
vegetation density 1.0 it tweened fog_density from 1.0 to 0.01. At density 0 it
would disable fog. It also overwrote ambient light. The prior isolated native
capture/test project did not include this autoload.

Fix: commons/void/atmosphere.gd tags its Environment with
scene_owned_atmosphere=true. NatureRenderer._update_fog and _update_sky respect
that tag. No per-frame enforcement, competing tweens, fog quads or layout edits.
Normal untagged biome environments retain their existing weather behaviour.

Full-project regression: tools/test_void_fog.py, tools/probes/void_fog_probe.gd
and .tscn. The probe runs with real autoloads, without --no-bridges. Checks
startup and scene callbacks, active gameplay camera, fog range, real controller
calls at density 0 and 0.7, unchanged biome weather on an untagged Environment,
and the tower's violet cycle. Controller inputs do not modify ecosystem progress.
9 checks passed on Forward+ and 9 on Mobile, with native player-camera images.
Physical headset has not been verified. Full project user editor/play processes
were left running. User must restart play to construct the tagged Environment.

Evidence: doc/book/iterations/2026-10-18-void-fog-runtime. before.json and
before.png captured before the fix; after.png uses matching camera geometry.
shaft-down.png leans the actual camera over the rim with movement paused for
the depth view. Mobile output is in mobile/. No source or user placement changes
were made to the room layout or artifacts.
