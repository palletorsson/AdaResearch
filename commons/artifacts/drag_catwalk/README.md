# The Floor Is Yours

A joinable runway with four other wearers, placed at (30,21) in the `Pattern_Foundry` annex. Enter through the opening in the east wall near the far end of the original hall. The dressing mirror faces the runway from (30,35).

Each performer wears one of the player's four authored outfits: Latex Cathedral, Chrome Orchid, Holographic Fan and Pearl Rococo. They follow two passing lanes, turn smoothly and pause at the end marks to pose. Their hands swing and their boots step with distance travelled. A performer pauses when the visitor comes within 0.95 m of its next position, and resumes when the path clears. Other performers also yield when closing within 1.25 m. Visitors can join anywhere along the level surface; performers have no solid collision that can push the player.

The console beside the dressing end has actual pointer/poke controls:

- **Hold / Play** stops or resumes the show.
- **Swap Looks** cycles outfits between performers while preserving their places in the walk.

These are choreographed agents, with inferred bodies and animated hand/head targets. They reuse `super_drag_outfit.gd`; they do not create player wardrobe managers, earn trophies or save appearance preferences. NPC heads use ordinary world geometry visibility even when the visitor's own head is hidden from their first-person camera.

The 3.8 m × 11.8 m floor marking is 18 mm thick with no collision lip. Clear side margins and light arches frame the show. The map provides the continuous supporting floor and enclosing walls. The original pattern machines have not moved: a 12-cell annex extension and a three-cell doorway provide the additional space. Scene parameters expose walking speed and initial running state.

The map declares `map_info.museum.sculpture_clear_rects: [[25,19,35,36]]`. These are inclusive grid-cell bounds; the museum converts them into segment coordinates before choosing automatic sculpture locations. This keeps the annex free of random plinths without disabling sculptures in the original hall. Other embedded grid maps can use the same declaration for performance or interaction floors.

Distance beyond 35 m suspends the choreography, in addition to normal museum artifact culling. Six local lights have no shadows. The geometry and material count of four full costumes still needs headset profiling; desktop checks do not establish Quest frame rate or comfort. The existing mirror remains head-centred and monoscopic in XR.

Validation scripts:

- `commons/testing/probe_drag_catwalk.gd`: two-minute movement simulation, route continuity, separation, poses, visible heads, pointer controls, yielding and gait. Add `-- --shots` with a renderer for captures.
- `commons/testing/probe_drag_catwalk_museum.gd`: real registry/grid loading, doorway and runway capsule clearance, floor height, live movement and relocated mirror. Add `-- --shots` for museum captures.

Both scripts use Godot 4.6 with `--xr-mode off`. Reports and screenshots are written under `ada_run/`. The museum probe disables appearance persistence before dressing its test player.

Verified 9 September 2026: **26 isolated checks and 33 actual museum checks passed**. Over two simulated minutes, agents stayed on the runway with minimum pair spacing of 1.90 m. Desktop Compatibility/OpenGL captures of the runway and dressing mirror were inspected. Headset profiling remains outstanding.
