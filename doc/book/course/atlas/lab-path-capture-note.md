# Lab_Path — an exposed gap

The ordered Noise sequence includes Lab_Path. Its own map description calls it an optional return corridor available in the grid lane and says the museum continues directly onward.

On 10 October 2026, `python tools/run_encounter_probe.py Lab_Path --sequence noise --render --no-bridges --output-tag atlas-image --spec doc/book/course/atlas/lab-path-capture.json` exited 1: the requested hall did not load. The isolated museum loaded Random_Noise_Types instead. Its photograph must not stand in for Lab_Path.

The atlas keeps the declared hall and caption, and marks its capture absent. It does not silently remove the map or alter the museum route.

Evidence: [capture spec](/book-review/ada_run/encounter_pilot/Lab_Path/atlas-image/spec.json), [engine output](/book-review/ada_run/encounter_pilot/Lab_Path/atlas-image/stdout.log), [map description](/book-review/commons/maps/Lab_Path/map_data.json).
