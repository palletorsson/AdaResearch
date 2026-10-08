# What leaves? What remains?

Reusable physical prototype for the landscape research thread. Four trays compare a product of sines, independent random vertex heights, Perlin and cellular Euclidean F1. All four use the same sampled height range, mesh resolution, finish, physical material, tilt and sphere release pattern.

Open `res://commons/testing/landscape_flow_workshop.tscn` in Godot and run the current scene. Desktop controls: WASD and Q/E to move the camera; hold right mouse to look; left click a button. The camera is a workshop inspection tool, not a tested player locomotion receiver. Buttons use the project's XRTools pointer event path; a headset visit remains pending.

RELEASE replaces the batch with 32 physical spheres per tray. PAUSE freezes/resumes physical bodies and the observation clock. RESET clears the batch but keeps settings. TILT, RELIEF, SIZE, SEED and WINDOW start a fresh comparison. RULE reveals sampling, normalisation and physics assumptions. Maximum active bodies: 128. Exited spheres freeze in a collection display and stop colliding; they no longer feed back into the trial. A sphere can be recorded only once.

STILL IN means not recorded as an exit when the window ends. It does not establish equilibrium or permanent trapping. Side/back/fall-through exits are separate from downstream crossings. The experiment does not measure concealment, player walkability, entropy or an optimiser's progress.

The original 2021 report used 3,600 variable-size spheres in Unity. This prototype has newly specified geometry and settings and is not a numerical replication. See [historical sources, protocol and route](../../../doc/research/possible-bodies/landscape-thread.md).

Run `res://commons/testing/probe_landscape_flow.gd` for the finite physical trial and interface checks. Evidence is written to `ada_run/landscape_flow_probe.json`. The registry deliberately keeps this prototype out of automatic map placement until the single-tray variant has a verified museum home. Existing hall primaries remain intact.
