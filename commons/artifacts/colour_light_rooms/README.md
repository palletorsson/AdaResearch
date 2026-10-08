# White room / open light

Native walk-in light studies in Color_Flashlight's east annex. Enter a white room under one central changing light, approach a recessed pink opening, then walk beneath a stepped light well and climb to a raised landing.

The scene builds white receiving geometry with real static collision. The central light and roof washes cycle over 110 seconds; two pink recess washes remain fixed. Receiver albedo and geometry do not animate. Shared render layer 20 confines the coloured lights to this architecture; other museum illumination may contribute. This is a Godot RGB study, not a spectral simulation. The eight concealed washes do not use shadows; the central source retains them.

`get_museum_occupied_cells()` supplies only body-height partition/furniture cells, leaving the room, ramp and ceiling openings traversable in the museum's floor map. It is an opt-in contract; ordinary artifacts retain the existing bounding-body method.

## Verification

Current capture and collision comparison, from the repository root:

```text
python tools/capture_light_opening_museum.py
```

The 2 October report, native photographs and source hashes are in `doc/book/iterations/2026-10-02-light-an-opening/`. It checks the new recess and well, sampled standing-body clearances and floor support, route footprint and rendered light differences. The earlier 28 September archive contains 40 checks of the earlier configuration, including entry, ramp ascent and return. It remains historical evidence, not a claim about the revised geometry.

Inspired by the author's proposal and Turrell's use of architectural openings. It is not a replica. Headset performance/comfort have not been measured.
