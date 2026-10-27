# Vectors_Act4a_KineticForces (floor 4) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-4.json` and this note. **No Godot run.**
Static checks:
- With floors 3 and 4 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 5 IDs appear once, with the artifact key, every `#` config, `facing = yaw + 180`,
  token height and scale 1.

## Approach (per Palle: platform structure where an instrument is too large)

The source hall is 30 x 80 m. `force_play_liquids` and `force_play_friction` are each
24 x 16 m bays (`encounter.gd` :244/:329).
- **Why friction can't stay inside.** Friction's content alone is about 23.4 x 15.4 m:
  four lanes at x ±10.1 by 14.3 m, a walk-up ramp at x 10.8, and a 22 m deck 2.05 m up
  along its front. The only shaft-free areas on the floor are:
  - the two full-width bands, 42 x 13;
  - the central strip, 15 x 32;
  - the side strips, 8.5 x 32.

  So friction cannot fit inside the tower with open shafts.
- **Platform.** **It goes on an exterior platform south of the slab**, using its own solid
  24 x 16 m patch: x -12..12, z -32..-16, flush with the south edge.
- **Liquids.** With friction moved out, it fits inside.

| id | at | facing | notes |
|---|---|---|---|
| `f4_force_hall_07_0_0` | 5, 15 | 180 | Presentation only. Its old lectern lands at (2.9, 12). |
| `f4_centrifuge_ring_15_69` | 0, 7 | 180 | 7 x 7 m, x ±3.5, z 3.5..10.5: 0.5 m north of the band, 1.5 m before the arrival. |
| `f4_viscosity_layers_15_52` | 8, 9 | 0 | Height 0.82. North of shaft B. |
| `f4_force_play_liquids_15_13` | 0, -10.5 | 180 | See the liquids notes below. |
| `f4_force_play_friction_15_35` | **0, -24** (exterior) | 180 | See the friction platform notes below. |

**Liquids at (0, -10.5):**
- **Tanks** at x -10.05..-4.35, -2.85..2.85 and 4.35..10.05, over z -16..-5, all south of
  the shaft band.
- **Controls.** BUOYANCY, DROP and RESET sit at (1.2/0/-1.2, -4.0); RESET is overridden
  (`encounter.gd` :43). The visitor stands in the band between the shafts, 6 m or more
  from either opening.
- **Columns** (±5,-14) stand inside the outer tank volumes.

**Friction platform at (0, -24):**
- **Deck and controls.** The deck runs along z -18.4..-16.3 at y 2.05. Visitors walk under
  it from the slab edge, with 1.97 m headroom. RELEASE, AUTO/PAUSE and RESET (:41) are on
  the deck at z -16.7.
- **Ramp.** It climbs from about (-10.8, -27.1) up to the deck.
- **Lanes** run over z -17.5..-31.8.

## Adapters needed (coordinator-owned)

1. **`force_hall_07` presentation and navigation.** Old grid 30 x 80 m (`curation.json`
   number 5, "What resists the journey"). It has the lectern, PREVIOUS/NEXT,
   the rear title at z ≈ 78.4, route marks and zone brackets.
   - **Viscosity pedestal.** It is placed at token height 0.82 m to sit on the hall's
     **pedestal** (`pedestal: true`, 1.9 x 0.82 x 1.4, `hall_display.gd` :49). That
     pedestal is built at the old cell (15,52) relative to the hall origin. Your adapter
     should put it under (8, 9), or viscosity floats.
2. **Liquids patch inside the tower.** Its solid 24 x 16 patch (x ±12, z -18.5..-2.5)
   covers the southern 0.5 m of both openings and overlaps the friction platform, so the
   two would z-fight. Omit it inside the slab footprint.
3. **Friction exterior platform:**
   - **Support.** Put the artifact root in `void_exterior_walk`: the patch, deck, ramp
     and basins are all its colliders. Add a `void_floor_extension` over z -32..-16 so
     streaming keeps it live. The precedent is `scale_chamber.gd`.
   - **Death check.** Beyond z -19 the Void's outside check (`game.gd` :428) applies.
   - **Open edges.** The platform's west, east and south edges are open; the source hall
     walls are not transferred. A frame or rail would be your call.
4. **Shared temp or none.** No cross-artifact lookups found for these four.

## Fit notes

- **Liquids title** ("WALK INTO RESISTANCE") floats at (0, 4.4, -18.1), above the
  friction platform. That is a label overlap only.
- **Liquids tanks** run flush to the south slab edge, which is also friction's patch
  joint.
- **The friction platform** extends the building by 16 m south at this level. Nothing is
  above it.

## Focused tests

- **Liquids:** DROP, then compare the three fall rates (thin, thick, very thick).
  BUOYANCY toggles `buoyancy_enabled`. Walk into a tank and check drag on the visitor.
- **Friction:** reach the deck via the ramp. RELEASE drops runners; AUTO/PAUSE toggles
  `slope_auto` on its 7 s clock. Check the bodies land in their basins on the platform.
- **Centrifuge hand ring:** spin by hand and read back the angular rate.
- **Viscosity:** check the layers respond on the pedestal.
- **Clearances:** with the patch adapter, both openings and the floor-4 pad
  (x -9.07..-7.53, z -3..-0.8) are clear. Walking the friction platform causes no death.
