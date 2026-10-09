# Random Mushrooms review — 12 September 2026

Continued from Random_Gaussian. **Next: Random_Game on the active seven-hall randomness route.** The larger stored sequence contains additional maps and is not reordered here. Headset work remains deferred while Palle is remote.

## Delivered

- [Illustrated review and captured population explorer](http://localhost:3003/research/possible-bodies/random-mushrooms.html).
- [Primary and book passage](http://localhost:3003/necklace/thread?map=Random_Mushrooms&role=primary).
- Seven revised texts in `commons/maps/Random_Mushrooms/`; the technical document retains the useful staging details, with corrections.
- Builder: `tools/build_mushrooms_review.py`.
- Runner and capture helper: `ada_run/review_mushrooms.py`, `ada_run/mushrooms_review_extra.gd`.
- Alignment and verification: `ada_run/align_mushrooms.py`, `verify_mushrooms_review.py`, `verify_mushrooms_http.py`.

The meadow's existing role and final anchor already named `mushrooms`; its book hero incorrectly named the secondary reaction-diffusion artifact. The hero now agrees with the role and anchor. The live primary page shows one written mushroom card with 836 words; the complete final has 931 whitespace-delimited words. All six explicit placements match and build, with no refused or extra placements. Both museum plan rows now reflect the current map cells and agree.

Map changes affect descriptive metadata and JSON formatting. All 13×13 layers, the dimensions, museum settings, teleporter floor override, six-metre bed and three edible mushrooms remain. The mushroom scene file is byte-identical to its before snapshot. The existing secondary company remains. Registry prose, interaction descriptions, capacity and tags no longer present an explicit ring as ecological self-organisation or a fixed candidate count as a spatial Poisson process. Physical registry parameters and scene references are retained.

## The book's thread

Recognise a relationship; SHOW its template copies; remove only their extra scale; inspect rejected positions and the separate ring/cluster routines; encounter a similar cap with another capability. The edible mushroom extends the inquiry to the looking body. The prose lets the visitor act before explaining the relevant source, with fourteen verified GDScript excerpts across final/tutorial/technical.

Unit transform scale does not imply equal physical dimensions. A continuous scale parameter does not interpolate the discrete template recipes. New seeds can also change template detail: the puffball's twelve bump positions are chosen during construction, then copied. SIZE preserves those draws and replaces only the use of its scale value.

The population uses uniform ranges, not Gaussian sizing. Ground heights have a separate generator, derived from population seed + 1 unless explicitly overridden. NEW SEED rejects the current number, not every previous number. REGROW repeats construction under the same source and configuration; it does not rewind player health or every process in the museum.

Accepted/rejected accounts refer to the eighty scattered candidates. Ring and cluster members are added by separate routines and are not tested against that noise threshold. Uniform cluster radius is not uniform area; the centre can be denser without an attraction simulation. Overlap is permitted. The ring's plate count is placed membership, not the full request. These distinctions replace several unsupported claims in the prior text.

QFEP is used as an inquiry into a repertoire and its revisions. No numerical entropy, lambda or free-energy measurement is inferred from the appearance of this bed.

## Production changes

1. Enlarged the existing specimen readout from font 15 to 23, increased its plate height from 0.15 m to 0.19 m and adjusted the label inset. Its SIZE-off line now says `scale 1 · template sizes kept`. Source identity comments describe the actual construction and controls. No new physical control or template was introduced.
2. Fixed the desktop `mushroom_trip.gdshader`: an early `return` in the fragment processor prevented compilation. The zero-intensity and active branches are now an if/else with the original active operations retained.
3. Fixed `MushroomEffect`'s desktop ColorRect dimensions. It explicitly fills the viewport and connects to viewport size changes. The VR spatial shader and edible object's pickup/eating implementation are unchanged.

The effect's configuration is a ten-second hold plus one-second fade-in and 2.5-second fade-out. Calling this an exact ten-second total was incorrect. Eating calls `heal_player(5.0)` where available; that is not a universal five-percent claim.

## Independent evidence

Accepted run: **23:27:49–23:28:42 +02:00, PID 26376: 117 checks, zero assertion failures, engine exit 0.** Sources stayed stable and the saved hand was preserved by using an isolated copy. Full process inventories preceded every launch, with no other Godot process running. No other process was terminated.

Existing checks exercise the actual museum, all five button paths, desktop pointer REGROW/SHOW/NEW SEED, the grab ray and carry, grounded routes, collisions, counts, light cap, seed replay and template cleanup. Independent additions capture whole populations, compare every stored ground value rather than only a hash, compare template MultiMesh details and edible planting, and check ring geometry against its recorded centre/radius/template.

Three exported configurations contain 283 instance records: 94 at seed 31415, those same 94 at unit scale, and 95 at seed 27182. The first SIZE pair agrees in every instance field except scale, every stored ground height, every rejected candidate position, puffball bump positions and edible planting. SIZE on restores the full record; REGROW replays each selected seed. These are controlled source-driven captures; the table has no seed-entry field.

Seed 31415: 71 scattered, seven ring members, sixteen cluster members; nine rejected scatter candidates. Its ring requests seventeen positions and places seven. The eleven- and nine-member cluster requests place ten and six. Seed 27182: 65 scattered, seven ring members and 23 cluster members; fifteen rejected candidates; eight requested ring positions, seven placed. The browser's missing-ring positions were independently reconstructed and checked against actual members. They are a review feature, not a new VR overlay.

A fixed 128×96 test image is rendered without the effect, with zero intensity and with intensity 0.8. Zero intensity has mean RGB difference 0.0; intensity 0.8 has difference 0.44863558 in the final run. The latter depends on shader time and is evidence of change, not a constant expected output. The actual eating path also verifies that its rectangle fills the viewport. Its timer finishes naturally and intensity returns to zero before neutral room captures; this pass waited another 10.652 seconds after the intervening checks. The separate eaten image shows the active distortion. This establishes rendered desktop behaviour, not the headset experience.

Desktop carrying holds the edible beyond its 0.25 m eating distance. The probe explicitly calls `_eat()` after exercising the real grab ray and carry. The record makes this substitution visible; it does not claim the desktop has performed the headset gesture.

### Earlier runs retained

- PID 38004, 23:15:23–23:16:05: 112 assertions passed, exit 0, but the engine log revealed the shader compilation failure. Not accepted as complete visual verification. Preserved in `initial-112-shader-failure/`.
- PID 15408, 23:22:03–23:22:45: repaired shader rendered correctly, but the newly added full-viewport check failed; 115 checks, one failure, exit 1. Preserved in `overlay-size-failure/`.
- PID 25876, 23:23:32–23:24:15: all 115 checks passed after overlay sizing. The later readout captures still showed the active effect. Preserved in `passed-115-effect-in-captures/`; the final pass adds natural completion and zero-intensity checks before those captures.

There were no failed engine compile attempts caused by the new probe. A preparation-script file write was retried successfully, and helper placement/quoting errors were corrected before launch. Earlier evidence is not counted as final acceptance.

## Publication and open work

All **60 publication files** returned HTTP 200 with matching source hashes. Twelve browser observations cover the initial population, unchanged positions at unit scale, both seeds, ring requests and omissions, rejected candidates, four glowing-template copies, the exact instance selector, matching filtered photos, book disclosure and the correct live primary. Six visible image elements load; changing population selects the matching capture. The layout was visually inspected and has no horizontal overflow at the tested desktop width.

Clicking a crowded symbol initially selected its overlapping neighbour. The record preserves that observation. An explicit instance selector now provides exact selection independently of overlap; instance zero was verified through it. Plot symbols encode transform scale, not physical footprint. Local x/z coordinates, omitted height/lighting/collision and browser-only controls are stated beside the explorer.

The global WCN audit reports 35 maps, 19 active and final text for all. This room agrees. An unrelated Noise_Voxel mismatch remains: two primaries and only one book anchor. It is recorded in `other-hall-mismatches.json` for that hall's pass.

The accepted log has no script/shader compilation errors or ObjectDB shutdown leak warning. Existing audio UID, root certificate and logger errors, renderer/registry warnings and an obsolete material-parameter warning remain. A GLES shader-cache file-write error also remains; rendered pixel checks pass despite that cache-save failure. Exact stem-to-triangle contact is not established by the interpolated ground-height lookup; it is recorded as a further inspection rather than claimed solved. Headset lettering, tracked-hand approach, perception/comfort and Quest performance remain for the later visit.

No commit was made. Before snapshots, run receipts, captured data, publication hashes and browser/HTTP observations are retained here or under `ada_run/mushrooms-review-2026-09-12/`. Continue with **Random_Game**.
