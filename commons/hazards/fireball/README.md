# Fireball

Projectile spawned by other hazards — glowing sphere with fire particles and explosion on contact.

## Behavior

Extends `RigidBody3D`. Used by armadillo_droideka, kresling_spire, and other hazards.

- Speed 15.0, damage 25.0, lifetime 8.0s
- 100 fire particles emitted during flight
- Explodes on contact with 2.0-radius explosion
- Audio on launch and explosion

## Files

| File | Purpose |
|------|---------|
| `fireball.gd` | Main script — physics, particles, explosion |

## Signals

- `fireball_hit` — On body contact
- `fireball_exploded` — On explosion
