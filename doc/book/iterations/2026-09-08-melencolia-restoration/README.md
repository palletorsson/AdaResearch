# Melencolia: the pyramid court returns

Restored 8 September 2026 at the user's request. The remembered structure survives in
`4beaa29b89ea1fe297fab7d747a6c44624d01bb1` (`40e15987f^`), identical to the July 7 layout.
It had already changed during July's promenade adoption, before August's museum conversion.
See [the historical inventory](historical-layout.md).

The installed room contains a 5×5 court, one metre above the floor, with four equal corner
pyramids, the long pyramid at its centre, and four half-scale cubes arranged in a cross.
A raised connection and a second ramp lead to Dürer's separate deck, two metres above
the floor. The tableau keeps its historical half scale and 180° rotation.

![Restored court, connection and Dürer deck in the actual museum](court_and_Durer.png)

The court is translated within the existing front gallery. The Dürer deck is enlarged
to 5×5 cells to support the current tableau; two extra rear floor rows make room to turn
toward the museum exit around automatic sculptures. The resulting hall is 13×27 cells.
Existing museum entry and exit remain connected. Old standalone-map exits are not restored.

The museum distinguishes raised floor from walls using this map's wall height of 4.
Both ramps use the existing wedge utility; the upper ramp has an explicit `p:1` base.
Pyramids and cubes are pinned to their authored court positions, with automatic individual
plinths disabled. Their rendered bases meet the court at y=1. The obsolete, differently
sized museum-layer snapshot was removed; the loader derives the room from structure.

The room's manuscript and ontology now describe the built court. The cubes have a secondary
tutorial role. The previous platform-spawning proposal was a mistaken interpretation of
the missing architecture: these surfaces exist before the puzzle is solved. The puzzle's
recognition rule and response remain unchanged. Existing author notes are preserved.

## Verification

[Runtime evidence](report.json) loads the actual `endless_museum` implementation, retaining
the live normal `grid_pack=0` mode, with isolated output paths. It checks rendered placements,
support heights and CharacterBody3D movement against the generated colliders. Both ramp
ascents, the surrounding floor route, rear turn and exit pass. The bent route passes between
the museum's automatically added sculptures. Screenshots show the actual generated hall;
these are not catalog previews. [Source fingerprints](source_manifest.json) identify the map
and museum implementation used.

The Dürer sphere rests at the deck's top, y=2. Its polyhedron intrinsically extends 0.225m
below the tableau origin at half scale; this pre-existing internal composition is recorded,
not corrected by lifting the entire tableau and floating the sphere. It is a separate artifact
refinement. Human desktop/controller comfort, headset use and teaching outcomes remain to
be checked; the restoration does not mark the room's learning baseline complete.

The probe source is archived alongside this report. Its working helper lives in
`ada_run/melencolia_restore/`; rerunning it uses that workspace and a local Godot 4.6 binary.
The final helper isolates derived output files. Earlier exploratory runs also refreshed the
live derived showing-card ledger; no authored map, museum source or control flags were changed
by the probe. The map and text changes were installed separately by the root task.

## Next walk

Approach from the front gallery, count the four corners, use the west ramp, compare the
long centre with the cross of cubes, follow the raised connection and climb to the tableau.
Return to the surrounding floor and continue through the rear turning space to the exit.
Try the same sequence alone and with a group. Record whether the composition is readable
before explaining it.

The reusable finding is to recover the last intact spatial composition, not merely the
revision immediately before a conversion, and translate its elevations into the current
loader's semantics. Check it with generated dressing and real colliders before copying the
method to another room; no second-room rollout is claimed.
