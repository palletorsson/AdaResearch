# Capacity Bracelet

A wrist-mounted ring that appears when the player picks up their first Becoming Catalyst. Collects glowing gems for each unlocked catalyst mode and lets the player rotate the ring with their other hand to switch between them.

## How It Works

1. Player picks up a Becoming Catalyst crystal in any lab scene
2. Crystal absorbs into the hand (shrinks and reparents to controller)
3. `BecomingCatalyst._deferred_reparent()` calls `CatalystCapabilityManager.spawn_bracelet_on_controller(controller)`
4. Bracelet pops in on the wrist with an elastic animation
5. One gem per unlocked mode, colored from `CatalystVisual.MODE_COLORS`
6. Active gem pulses brighter; inactive gems stay dim

## Switching Modes

- **Physical rotation**: Grab one of the 4 handle points with the other hand and rotate the ring. Stepped snapping converts rotation angle to mode index with haptic ticks.
- **Thumbstick fallback**: Thumbstick left/right on the catalyst hand still works. The bracelet syncs via `sync_to_mode()`.

## Scene Persistence

The bracelet survives scene transitions through `CatalystCapabilityManager` (autoload):

- `_bracelet_activated` flag is saved to `user://capability_progression.json`
- `_bracelet_tracker` remembers which hand (left/right) the catalyst was absorbed into
- When a new scene loads, `_on_node_added` detects the matching `XRController3D` and re-spawns the bracelet instantly (no animation on re-spawns)
- New catalyst instances in later scenes auto-link for bidirectional mode sync

## Architecture

```
CatalystCapabilityManager (autoload, persists)
    owns _bracelet instance reference
    spawns/re-spawns on scene changes
    notifies bracelet of new mode unlocks

BecomingCatalyst (scene node, per-lab)
    triggers spawn_bracelet_on_controller() on absorb
    calls get_bracelet().sync_to_mode() on thumbstick switch
    bracelet calls catalyst.set_mode_index() on ring rotation

CapacityBracelet (Node3D, parented to XRController3D)
    builds scene procedurally in _ready()
    InteractableHinge + 4 InteractableHandle grab points
    gems rebuilt when modes change
```

## Files

| File | Purpose |
|------|---------|
| `capacity_bracelet.gd` | Main bracelet script, procedural scene builder |
| `capacity_bracelet.tscn` | Minimal scene (root Node3D + script ref) |
| `../../managers/CatalystCapabilityManager.gd` | Autoload that owns bracelet lifecycle |
| `../becoming_catalyst.gd` | Catalyst pickup that triggers initial spawn |
| `../catalyst_visual.gd` | Mode colors used for gem tinting |

## Scene Hierarchy (built in `_ready()`)

```
CapacityBracelet (Node3D)
  BraceletRing      (MeshInstance3D, TorusMesh, dark translucent)
  GemContainer      (Node3D)
    Gem_primitives   (SphereMesh, silver)
    Gem_transformation (SphereMesh, purple)
    ...              (one per unlocked mode)
  ModeLabel          (Label3D, billboard, fades after 2s)
  BraceletGlow       (OmniLight3D, pulses in active mode color)
  HingeOrigin        (Node3D)
    InteractableHinge  (XRTools hinge, stepped snapping)
      Handles          (Node3D)
        Handle1..4     (RigidBody3D + InteractableHandle script)
```

## Key Constants

| Constant | Value | Notes |
|----------|-------|-------|
| `RING_INNER_RADIUS` | 0.035 | TorusMesh inner |
| `RING_OUTER_RADIUS` | 0.045 | TorusMesh outer |
| `GEM_RADIUS` | 0.008 | SphereMesh per mode |
| `GEM_ACTIVE_SCALE` | 1.5x | Active gem scale boost |
| `GEM_ACTIVE_EMISSION` | 3.0 | Active gem glow |
| `HANDLE_OFFSET` | 0.055 | Distance from center for grab points |
| `NUM_HANDLES` | 4 | Grab points around the ring |

## Testing

Use `apply_grid_config()` to test without VR:

```gdscript
bracelet.apply_grid_config({
    "unlock_modes": ["primitives", "transformation", "chromatic"],
    "active_mode": "transformation",
    "visible": true
})
```

Or through `CatalystCapabilityManager` debug methods:

```gdscript
# Unlock all modes and force bracelet spawn
var mgr = get_node("/root/CatalystCapabilityManager")
mgr.unlock_all_capabilities()
```
