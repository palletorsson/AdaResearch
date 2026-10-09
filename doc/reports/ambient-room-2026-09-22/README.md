# Slow Circuits — walk-in room, 22 September 2026

User clarified that the instrument should be a room to walk inside. Implemented a round 6.4 m environment with an open centre, three physical wall stations, visible spatial sound positions and real PCM waveform. The inherited XR rig keeps tracked height and offset. Desktop fallback is supported.

Entrance: ENTER ROOM on ambient_patch in WaveFunctions_Synthesis_Lab. Exit: doorway or BACK TO HALL. The staging loader replaces the museum while the room is active; return selects the same hall. Other artifacts are preserved.

Validation: 87 room checks, 33 shared-audio regression checks, 86 actual museum/entrance checks; all passed. Native hand-grab tests, standing clearances, approach and interaction rays, spatial audio source movement, staging request contracts, tracked-head arithmetic and cleanup. The room run has no script errors; startup UID and exit object-leak warnings remain in the log. No headset hardware validation is claimed.

Commands:
- python doc/reports/ambient-room-2026-09-22/run.py
- python doc/reports/ambient-patch-2026-09-22/run_tests.py
- python doc/reports/ambient-patch-2026-09-22/run_hall.py ambient after
- python doc/reports/ambient-room-2026-09-22/publish.py

Review: http://localhost:3003/book-review/doc/book/iterations/2026-09-22-ambient-room/index.html

Next: headset listening, movement and performance check.
