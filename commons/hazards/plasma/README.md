# Plasma

Shapeshifting energy substance — the first critter. Raw form shocks on contact; touch with a stick tool to transform.

## Behavior

Extends `Area3D`. Embodies Q-FEP: same substance, different relational context, different manifestation.

5 forms:
1. **RAW** — Shocks on contact (default)
2. **FIRE** — Torch (via stick tool)
3. **HEAL** — Healing aura
4. **POWER** — Energy boost
5. **GEL** — (future)

- Core radius 0.18, 50 particles per form
- Fuel system: burn duration 60s before depletion
- Respawns to home position after fuel runs out
- Form determines visual configuration (colors, emissions, particles)

## Files

| File | Purpose |
|------|---------|
| `plasma_critter.gd` | Main script — form switching, fuel, damage/benefit |
| `plasma_critter.tscn` | Critter scene |
| `stick_tool.gd` | VR tool for interacting with plasma — triggers form change |
| `stick_tool.tscn` | Stick tool scene |
