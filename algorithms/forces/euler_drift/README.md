# The same throw, different steps

`euler_drift#lesson:step_study` selects the optional metre-scale comparison in **VFM_05_Launch**, source cell (29,6), rotated 180 degrees toward entry. The original small scene still builds its original geometry without that configuration. Its old tunnelling caption has been corrected: the pink marker has no collider.

The five complete learner files are printed in [tutorial.md](tutorial.md), also appended to the canonical hall tutorial. `step_study.tscn` runs in the established Ada museum host; camera, player, XR Tools and ControlConsole are supplied. The original point class is unchanged.

**Contract:** same start, velocity, constant gravity and one second → explicit Euler at 10/20/40 steps → signed difference from the analytic formula → replay / independent throw. No engine clock change, contact, drag, stability or tunnelling claim. Max 41 saved states. Reference curve uses 80 display segments, separate from the numerical step count. Both markers show the latest completed simulation step. Both traces occupy one plane; the display preserves their difference vector.

**Controls:** hand slider selects step count; FIRE/PAUSE, ONE STEP, REPLAY, OTHER THROW and RESET are adjacent. OTHER THROW changes velocity from (4,4.9,0) to (3,6,0) m/s. Parameter changes reset and pause; replay restarts the same fixture. The inherited point is a calculated marker here, so pickup/collision are disabled.

**Tests:** `python tools/test_euler_step.py`; `python tools/test_euler_printed.py`; `python tools/run_encounter_probe.py VFM_05_Launch --sequence forces --render --probe tools/probes/euler_step_room.gd`.

**Short instruction:** P1built. ExistingLaunchprimarykept. PointBody→DisplayPoint;Eulerposition-oldvelocity→gravity;T1,h.1/.05/.025;Δ=-.5gTh. Model53checks;printed51;wrongorder+aliasrejected;museum22. Coreclock≠renderclock;41rowsmax;replay;handsteps. Renderedendpointcheckrequired. Noheadset/Quest/independentlearnerclaim. NextoriginalpackageP3budget,notP2.
