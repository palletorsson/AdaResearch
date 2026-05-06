# Null Value Injector

Malicious chaos entity that injects null values into scene nodes to cause runtime errors.

## Behavior

Extends `Node3D`. Meta-hazard with void/dark aesthetic.

- 7 injection types: NULL_REFERENCE, EMPTY_STRING, ZERO_VECTOR, and more
- Targets random nodes, player components, and scene objects
- Corruption level escalates with cascading failure chains
- Error suppression hides debugging from the player

## Files

| File | Purpose |
|------|---------|
| `nullvalueinjector.gd` | Main script — injection logic, corruption tracking |

## Signals

- `null_injected(target_node, property, injection_type)` — On injection
- `corruption_spread(affected_nodes)` — On cascade
- `system_destabilized(severity)` — On critical corruption
- `reality_breach_detected()` — On maximum chaos
