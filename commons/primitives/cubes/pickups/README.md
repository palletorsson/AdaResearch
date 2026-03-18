# Pickups

Pickup cube variants with different transform animations.

## Files

- `pickup_wrapper.gd`: wrapper that disables internal collision for trigger zones
- Multiple `.tscn` variants: rotating, scaling, static, combined transform pickups

## Behavior

- Extends pick_up_cube base class.
- `_disable_internal_collision()` recursively disables StaticBody3D nodes.
- Allows player to enter pickup trigger zone unobstructed.
