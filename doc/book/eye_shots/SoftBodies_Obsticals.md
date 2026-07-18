# Eye shot — SoftBodies_Obsticals

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **2 overlaps, 3 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] pick_up_cube               <-> grab_long_stick            gap -0.12m (centers 1.00m)`
- `[OVERLAP] grab_long_stick            <-> pick_up_cube               gap -0.12m (centers 1.00m)`
- `[tight  ] grab_long_stick            <-> grab_long_stick:180        gap +0.63m (centers 2.00m)`
- `[tight  ] pick_up_cube               <-> grab_long_stick:180        gap +0.25m (centers 1.00m)`
- `[tight  ] grab_long_stick:180        <-> pick_up_cube               gap +0.25m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.036
      walkability improved: 1/1  mean Δ=+0.100

sibling **Trial_eye_SoftBodies_Obsticals** kept: overlaps 2→2, tight 3→0, pathfinder OK.

## The voice (qfep)
3 of 4 cast members carry a theory-claim; 1 mute.
- **breathing_room** — breath_amplitude — low amplitude creates subtle pulsing you barely notice, high amplitude compresses the walka
- **flagdancer** — wind_strength — controls the amplitude of the sine wave displacement; below 0.5 the flag barely stirs, above 1
- **pick_up_cube** — Pure S as carried displacement: the cube stays itself while its coordinates change. The artifact isolates tran
- mute: grab_long_stick

## The heuristic understanding
The floor was fighting the walk — bodies inside each other's clearance. The mover found a better seating; the ride confirms it in text. The voice column above says what the room is FOR; the next writing pass should say it in the walked page.
