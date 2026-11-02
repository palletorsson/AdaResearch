# Playground halls - place specs walked as their own maps

A hall here is a place spec (commons/modular/places/place_spec.gd: places with their activities, framed boards)
that is walked as a separate Void trial: `python tools/playground_trial.py make --spec <file> --id <trial>` writes
commons/void/trials/<trial>/ (its slab sized to hold every piece) and registers it in playable.json; the trial's
floor holds the `playground_spec_hall` token, which compiles the spec when it loads. Walk it on the desktop with
`python tools/launch_void_desktop.py --trial <trial>`. Trials are drafts for the desktop and the editor; the Quest
plays tower floors, so a hall that proves itself moves into the skyscraper as a floor's space later.

| file | trial | what |
|---|---|---|
| playground_annex.json | playground_annex | what did not fit on floor 210: the shader path and posters, the tiling corridor, the pattern rack, the ball pit under its screen wall |

`python tools/playground_trial.py check --sidecar commons/void/trials/principal_places/activities.json --slab 42 18 --offset 0 -1`
checks that a tower hall's additions stand on the tower's 42 x 18 m slab; it exits with the number that do not.
