# A runway with other wearers

Implemented 9 September 2026 in Pattern_Foundry. The catwalk is a secondary artifact at (30,21); the dressing mirror moves to (30,35), facing it. Four agents wear the same procedural outfits available to the visitor, walk a closed two-lane route, turn, pose and yield. Their console holds/resumes the show and swaps looks without moving them to new route positions or changing the visitor's saved outfit.

The hall grows from 25×38 to 37×38 with a connected annex. All 12 original machine positions and configurations are preserved. The only changed structure cells within the original footprint are (24,29), (24,30) and (24,31), opening the doorway. `before_map_data.json` preserves the map immediately before this addition.

The real museum probe exposed an automatic sculpture and its plinth blocking the runway. The map now reserves the annex through `map_info.museum.sculpture_clear_rects`. The museum translates those inclusive grid bounds into its own segment coordinates and excludes them when dealing sculptures. This is reusable for other embedded grids whose interaction floors need to remain clear.

Validation: 26 isolated checks and 33 museum checks pass. The isolated probe covers two simulated minutes, continuous turns, posed stops, minimum agent spacing (1.90 m), pointer controls, visitor yielding, gait and visible NPC heads. The museum probe covers registry instantiation, a body-sized capsule through the entrance and along the full runway, supporting floor height, running agents, player wardrobe isolation and the relocated reflection camera. JSON results are `ada_run/probe_drag_catwalk.json` and `ada_run/probe_drag_catwalk_museum.json`.

Rendered and inspected: `ada_run/drag_catwalk_shots/museum.png` and `dressing_end.png`, plus isolated views. These are actual Godot captures. The agents are authored choreography with animated targets, not learned behavior or full-body tracking. Desktop tests do not validate Quest frame time, comfort or stereo reflection; the existing mirror remains head-centred and monoscopic in XR.

Spine artifact order, long museum and necklace indexes regenerated. Existing corpus warnings remain outside this change; the run also reports the pre-existing audio-bus UID warning `uid://rwex60pqapc`.
