# Navigator Noise — G2

Installed optional comparison in `SwarmIntelligence_Agent_Based_Modeling_ABM`, cell(3,8),180°. Full code and lesson: [tutorial.md](tutorial.md). Review: [museum, images and tests](../../../doc/book/iterations/2026-10-09-navigator-an-imperfect-observation/index.html).

Carry: unchanged `doc/book/studies/forces-point-lineage/point_body.gd`, saved inputs, vector movement, trace. New: true state → observed range or null → chosen command. Same fixed course, goal and authored detour for both agents. No navmesh, raycast sensor, contact solver, inertia, training or adaptive policy is claimed.

The lower point sets both starting heights; release runs. A physical slider and six nearby buttons control replay, range noise/dropout, strength, STOP/HOLD fallback, seed and reset. Sphere geometry/collider inherited; only lower point is a handle. Course collision is a swept 2D disc test using the same radii shown. Agent centre leaving x[−1.85,1.85],y[−.18,.8] ends LEFT COURSE; this is an explicit terminal outcome, not a silent clamp.

20Hz state/sensor updates;40 saved half-second blocks; Gaussian range error in metres OR missing uniform threshold. sigma0–.8m,missing fraction0–1; simulation20s maximum;400 trace records per pair. Gaussian values are not clipped. Missing is null. Last decision values remain after a terminal result. Point radius.14m,obstacle.25m,speed.6m/s;instant turns. Exact positions/directions and detour are supplied knowledge. Rendering panes translate identical model coordinates to two heights; this is a comparison instrument inside the museum.

Native runner: `python -X utf8 tools/test_navigator_noise.py`. Museum runner: `python -X utf8 tools/run_encounter_probe.py SwarmIntelligence_Agent_Based_Modeling_ABM --sequence swarmintelligence --render --probe tools/probes/navigator_noise_room.gd`. Evidence distinguishes core assertions, printed-code reconstruction and native supplied hand poses from physical VR/Quest/student checks, which remain open. Existing room UID/viewport diagnostics are retained in before and after logs.
