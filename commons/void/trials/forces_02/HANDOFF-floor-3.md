# Vectors_Act3_FieldsAndMotion (floor 3) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-3.json` and this note. **No Godot run.**
Static checks:
- With floors 3 and 4 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 6 IDs appear once, with the artifact key, every `#` config, `facing = yaw + 180`,
  token height (0) and scale 1.

## Approach (per Palle: "extend the building with a platform structure or use two floors")

The source hall is 28 x 104 m. Its instruments sit in old-grid zones of 20x18, 14x12, 16x14,
10x10 and 14x16 m (`force_halls/curation.json`). All but one go inside the tower.
**`gravity_oval` goes on an exterior platform** east of the slab.
- **Why it can't stay inside.** It is a vertical carry loop, centred 5.7 m up with radii
  2.8 x 4.5 m (`gravity_oval.gd` :5-6), so its top is about 10.2 m and its title is at
  11.5 m. Inside the tower, its upper half and the carried visitor would pass through
  floor 2's slab.
- **What the exterior placement gives.** Outside the footprint there is open sky.
- **Platform.** The oval's own 14 x 16 m solid floor patch (`play_space.gd` :70) becomes
  the platform: x 21..35, z -4..12, flush with the east slab edge.
- **Rejected.** A double-height cut through floor 2 would have been the alternative
  ("two floors").

| id | at | facing | notes |
|---|---|---|---|
| `f3_force_hall_06_0_0` | 5, 15 | 180 | Presentation only; see below. Its old lectern (local 2.1, 3) lands at (2.9, 12), 2.9 m east of the arrival. |
| `f3_force_play_vortex_14_13` | 0, 2.5 | 180 | Core x ±6.3, z -3.8..8.8: 1.2 m from both openings. ONE/MANY and RESET are at (±0.6, 10.0), 1.9 m before the arrival. |
| `f3_VectorFieldFlow_14_35` | 0, -10 | 0 | ±1.77 m |
| `f3_wind_room_14_52` | -16.5, 8.5 | 180 | 7 x 7 m, x -20..-13, z 5..12. 2 m north of shaft A's band; 1.55 m from columns. |
| `f3_force_vortex_14_72` | 10, -9 | 180 | 7 x 7 m, x 6.5..13.5, z -12.5..-5.5. 2.5 m from shaft B, 1.2 m from the riser at (6.5, -4.2), 1.05 m from column (14,-14), 7.5 m from the slab edge (it ejects the visitor). |
| `f3_gravity_oval_14_92` | **28, 4** (exterior) | 180 | Oval core x 25.2..30.8, z 3..5. The entry marks and words face the slab side (+z); the title is at y 11.5. |

## Adapters needed (coordinator-owned)

1. **`force_hall_06` presentation and navigation.** `hall_display.gd` builds in old-grid
   coordinates of 28 x 104 m from its origin (`curation.json` number 4, "The room gives a
   direction"):
   - an entrance lectern at (2.1, 3) with PREVIOUS/NEXT, travelling via
     `museum_portal_navigation`, which the Void lacks;
   - a rear title at z ≈ 102.4;
   - route marks at x 26 from z 4 to 100;
   - corner brackets for each old zone;
   - a bench at z 59.

   As placed, all of that extends off the floor; it needs your floor-local adapter.
2. **Play-space floor patch inside the tower.** `force_play_vortex` builds a solid
   20 x 18 m patch (x -10..10, z -6.5..11.5). It covers the inner 2.5 m of both shaft
   openings and the floor-3 pad (x -9.07..-7.53, z 0.8..3.0). Omit it inside the slab
   footprint, or clip it at the openings.
3. **Gravity-oval exterior platform:**
   - **Support.** Put the artifact root in `void_exterior_walk`, so the patch and every
     collider count as support. Add a `void_floor_extension` with `contains_visitor` over
     the patch, about 14 x 12 x 16 m, so floor streaming keeps it live.
   - **Carry exemption.** The carry lifts the visitor about 8-10 m above the patch.
     `game.gd` :428 `_exterior_walk_support` only rays 4.2 m down, so a carried visitor
     beyond |x| 24 would "fall beyond the building". Exempt the oval's carry volume, as a
     flight box is exempted (:394).
   - **XR.** `install_adapter` hooks `XRToolsPlayerBody` via `node_added`. The desktop
     walker already honours `ada_museum_carry`.
   - **Open edges.** The platform's outer edges are open to the void, as the source walls
     are not transferred. A platform frame or rail would be architecture, so that is your
     call.

## Dependencies and tests

- **Lessons.**
  - `VectorFieldFlow lesson:field_receivers` (:73), `wind_room lesson:hands_on_wind` (:19)
    and `force_vortex warning:beacon` (:320) are read from meta. The Void stamps it before
    `add_child`.
  - `force_vortex` joins `ada_museum_carry` and captures `player_body` or any
    `CharacterBody3D` (:367).
- **Vortex:** press ONE/MANY and check `lesson_focus` toggles and `lesson_note` changes.
  Check the 18 receivers keep orbiting, at radius ~5 m, inside the core.
- **VectorFieldFlow receivers:** move a receiver and read back its field arrow.
- **Wind room:** the hand-on-wind lesson responds.
- **Force vortex:** check that capture and ejection keep the visitor on the slab and clear
  of shaft B.
- **Gravity oval:** with the adapters, ride a full loop on desktop and synthetic XR; there
  must be no death and no floor-2 intrusion.
- **Clearances:** with the patch adapter, both openings and the floor-3 pad are clear.
