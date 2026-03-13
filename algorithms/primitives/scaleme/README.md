# Scale Me

A VR interaction artifact that scales the entire world (or a target node) when picked up. The player grabs a small object, which triggers a tweened scale-up of the environment by a configurable factor (default 100x), repositions the player, and optionally scales back down after a duration -- creating an "Alice in Wonderland" shrinking/growing experience.

## Concept Taught

**Relative scale and spatial transformation in VR** -- how scaling the world around a player changes their perceived size and relationship to the environment. The artifact teaches the difference between scaling the player versus scaling the world, the importance of repositioning the player's XR origin to maintain spatial coherence during scale changes, and the need for collision safety checks after geometric transformations.

## How It Works

1. The script extends `grab_sphere.gd` (a VR-grabbable rigid body). When the player picks up the object, `_on_picked_up()` triggers `_scale_world()`.

2. **Target Resolution**: The script searches for a node to scale in priority order: an explicit `world_node_path`, a node named "DarkSphere" in the scene tree, or the parent node.

3. **Scale-Up**: A cubic ease-in-out `Tween` scales the target node from its original scale to `original_scale * scale_amount` over `scale_up_time` seconds. The player's XR origin is repositioned: X and Z are multiplied by `scale_amount / 5`, and Y is set to 5.0.

4. **Safety Check**: After scaling, `_ensure_player_not_stuck()` uses `PhysicsShapeQueryParameters3D` to test if the player collides with geometry at head, chest, and feet level. If stuck, three strategies are tried: upward search, multi-directional raycasting, and a fallback 10-unit upward displacement.

5. **Scale-Down**: If `auto_revert` is true, a timer triggers a reverse tween after `scale_duration` seconds. The grab object is hidden and freed after scale-down completes.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `scale_amount` | float | 100.0 | Factor to multiply the world scale by |
| `scale_duration` | float | 20.0 | Seconds the world stays scaled before reverting |
| `scale_up_time` | float | 5.0 | Duration of the scale-up tween |
| `scale_down_time` | float | 5.0 | Duration of the scale-down tween |
| `world_node_path` | NodePath | "" | Optional explicit path to the node to scale |
| `xr_origin_path` | NodePath | "../../XROrigin3D" | Path to the player's XR origin |
| `auto_revert` | bool | true | Whether to automatically scale back after duration |

## Features

- VR grabbable trigger -- pick up to activate
- Configurable target node discovery (explicit path, named search, or parent)
- Smooth cubic ease-in-out tweened scaling (up and down)
- Player XR origin repositioning during scale change
- Post-scale collision safety check using sphere shape queries
- Three-strategy stuck-player recovery (upward search, directional raycast, fallback)
- Auto-cleanup: object hides, drops, disables collision, then frees after scale-down
- Optional permanent scale mode (`auto_revert = false`)

## Files

| File | Description |
|------|-------------|
| `scale_me.gd` | VR grabbable that scales the world on pickup with safety checks and auto-revert |
