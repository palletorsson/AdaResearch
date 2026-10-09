# A form above, a shadow below

The last space of Primitives Ignorance is an open moon court. A charcoal torus hangs horizontally with its centre five metres above the existing floor. Its outer diameter is five metres; its inner and outer radii are 1.4 and 2.5 metres. The museum's existing directional moon casts the actual mesh shadow. No painted shadow or second moon is added.

Rings descend from 48 to 4 with tube segments held at 24. Segments then descend to 4 with rings held at 4. Both recover in the same order. One count changes at a time, with a 1.5-second interval and a 42-second cycle. Size, position and orientation remain fixed. The wall readout shows both counts. Geometry is rebuilt only when a count changes.

The final station's local roof, floor overlay and fill lights were removed. The map opts out of the global ceiling; the first two galleries retain their own roofs. The original hanging catalyst moves to the side, with its bracket and cable. Its pickup, simplification, shooting and return behaviour is preserved. The two rings/segments specimens remain on white plinths beside the shadow field. Room structure, exits and map placements stay the same.

## Text

final.md adds a short encounter with the torus and its shadow, then turns to the nearby point. The tutorial remains unchanged: this is a museum encounter with a construction already being explored, not a new required programming subject.

## Evidence

102 native Godot checks passed, including every resolution state, fixed radii/height/orientation, real moon/shadow settings, animation timing and the earlier catalyst's interaction regression checks. Trigger events are supplied by the probe. These results do not establish headset comfort or Quest performance.

All images were captured inside the actual Endless Museum. Fine/coarse comparison images use the same camera and frozen moon phase. In ordinary play the museum's moon continues moving. A separate control disables only the torus shadow caster: 432,560 floor-region pixels darken by more than 8 RGB levels when it is enabled. Changing only rings changes 228,235 floor-region pixels above that threshold. See shadow-check.json for the bounded comparison. This confirms a rendered shadow, not a performance benchmark.

One pre-existing unknown resource UID warning remains in the engine log. No new script error was observed.

Run again: `python -X utf8 tools/run_encounter_probe.py Primitives_Ignorance --sequence primitives --render --probe tools/probes/ignorance_moon_torus.gd`
