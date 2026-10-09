# White room / open light

Two connected light rooms now occupy an east annex in Color_Flashlight. The first retains near-white receiving surfaces and one central changing light. The second gives the light three open ceiling levels, with a shallow ramp to a 1.2 m landing. The slow colour cycle runs without a panel.

## Why here

The original handheld lamps change position while keeping their RGB values. The annex reverses that comparison: fixed room and source, changing colour. In the taller chamber, moving and climbing change how the openings overlap. The visitor supplies the changing viewpoint. The book adds that walk after the original board and faceted-sphere encounter, before the handoff to Nails.

## Reference

James Turrell is a reference for attention to light and architectural openings. The [Guggenheim release for Aten Reign](https://jamesturrell.com/wp-content/uploads/2013/06/gug_turrell-release-final.pdf), hosted by the artist, describes concentric elliptical rings of changing light viewed from below. Our rectangular rooms and raised walking route are an original study, not a reconstruction. Their RGB illumination, emitting rims and existing rendered sky are stated in the manuscript; no spectral optics or measured perceptual effect is claimed.

## What changed

- Registered colour_light_rooms and placed it in Color_Flashlight at source-grid coordinates (25,0,10), pinned at floor level.
- Expanded the map east from 19 by 20 to 42 by 20 cells. Opened five existing east-wall cells. Preserved all other original cells, the torch placement and utility positions.
- Added an opt-in partition footprint for walk-in artifacts. Walls and furniture reserve floor cells; roofs, floors and the traversable ramp do not seal the whole interior. Fixed artifacts retain their existing behaviour.
- Regenerated only this hall's live and packaged plan rows. No live bake, control or save was changed.
- Added the second primary to the curation entry, a short encounter to final.md, companion documentation and a refreshed eight-hall Colour capture.

## Native evidence

40 checks pass in the actual museum under the desktop Compatibility renderer. They cover retained torch/sphere, real colour changes with fixed albedo and geometry, removal of the central light's contribution, open roof rays, blocking walls, the museum's route footprint, ordinary walking from the older hall into the annex, ramp ascent, landing height and the return walk. Photographs come from these native views; the side-by-side figure only arranges two unchanged screenshots.

The first run passed 36 checks; a second added route-map verification and an approach from within the old hall, passing all 40. Existing startup UID, audio-path and renderer warnings remain in stdout.log; no script or shader errors occurred. Other museum illumination remains visible when the new central source is hidden. This is not a total-darkness test.

Headset comfort, tracked movement and performance are still untested. The seven shadowed point lights need device-specific performance review before claiming a headset frame-rate target.

## Where to go

Load Color_Flashlight in the Colour sequence. The opening in the east wall leads through the white room to the taller room. Return by the same doorway to continue to Color_Nails. An already running museum needs to reload the hall to pick up these source changes.


## Concurrent museum alignment

During final publication, another task added a half-cell offset to all embedded museum grids to close gaps at hall exits. That change is retained and archived separately in `parallel-grid-alignment.diff`. Our footprint hook is unchanged. The final native room test passes 40/40 against the combined museum source; its final source snapshot records both changes. The diff for our hook uses the source captured before that independent alignment edit.

The final test uses the task-local `run_probe.py` runner and a unique output directory, `ada_run/encounter_pilot/Color_Flashlight_light_rooms/`, because a parallel floor test was using the normal per-map output directory. Final screenshots, log, report and source manifest are archived here together.
