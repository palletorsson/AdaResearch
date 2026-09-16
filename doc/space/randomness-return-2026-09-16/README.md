Restored pairing: waiting and profile

Historical source: git c47be1717, commons/maps/Random_Cubes/map_data.json has two random_object_spawner placements and multiple random_edge_profile rows.

This is a new bounded staging of that pairing: original grabbable wooden cube and ProfileRandom generator, two alternating slots, maximum two bodies, waits 0.3–1.3 s after the first second. Holding either cube suspends the clock and reset. Profile uses seventeen samples and fixed ends; it is not the arrival history.

Godot probe activates the exhibit for its independent capture camera: the museum otherwise suspends far-away geometry and physics while the player remains at the entrance. Actual headset pickup remains unverified.

Run: python doc/space/randomness-return-2026-09-16/run_probe.py Random_Game
