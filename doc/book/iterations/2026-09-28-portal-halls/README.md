# One resident hall: standing portals

2026-09-28. Default museum navigation now uses standing portals in desktop and VR. Restart the museum to use the new loader. Point_Zero remains the opening hall and New Game starts there.

Walk into the pink doorway for the next hall. Previously visited halls have a violet return doorway. The old hall is freed before the next hall is constructed. A small persistent loading room supports the visitor during the transition. Scene resources load on workers where supported; scene construction still uses the main thread, so a heavy artifact can still pause loading.

The frame uses black lacquer, chrome edging, crossed lacing and rings, with a slowly moving pink veil. It does not render the next hall through another camera. No extra dynamic lights or particles are added. The floor inlay is flush; the frame collides at its jambs and lintel only.

The loader checks real floor support and headroom, waits for embedded grid simulations, preserves the tracked headset offset and locks locomotion while loading. It ignores repeated crossings while busy and requires the visitor to move away before rearming. A swept crossing test catches fast steps that a dwell-only trigger misses. The existing failed-load return path remains available.

Artifact state is retained only for artifacts implementing capture_museum_state / restore_museum_state; other exhibits rebuild from their authored setup on return. Navigation history lasts for the current loaded museum session.

Portal mode omits service corridors and neighbouring shells. Old packed hall cartridges are bypassed because they contain corridor geometry. Screenshot/bake/studio/autopilot/collision-proof tools retain continuous mode; --em-corridors explicitly restores that authoring route, and --em-portals remains accepted. Recipes explicitly listed as deferred by a sequence are skipped during normal portal journeys, but an explicitly selected deferred map can still be visited. Other plan extensions remain: Color_Walls leads to Biome_Ladder_Color, then Pattern_Disco.

## Verification

Five real museum journeys, forward and back: ten transitions. Every case passed with a peak of one resident hall, the old hall freed, a supported arrival, working return, no corridor appended and no immediate bounce on arrival. The forward tests sweep through the doorway in one step rather than resting inside its trigger.

- Desktop: Point_Zero -> Point_One.
- Simulated XR: Color_Nails -> Color_Rainbow.
- Simulated XR: Trans_Pre -> Trans_Introduction.
- Desktop with rendered proof: Color_Walls -> Biome_Ladder_Color.
- Desktop across chapters: Biome_Ladder_Color -> Pattern_Disco.

See verification.json for results and source hashes. Probe: tools/probes/hall_portal_navigation.gd, run through tools/run_encounter_probe.py. The image doorway.png is captured from the real Color_Walls hall. Existing unrelated asset warnings and bare-grid player-bounds errors still appear in engine logs; these checks assess portal navigation, not a clean full-project audit.

Live headset comfort, actual FPS/memory profiling, individual artifact state coverage, and checking doorway placement across every authored hall remain further verification work. The one-hall residency invariant is measured here; a specific frame-rate gain is not claimed.
