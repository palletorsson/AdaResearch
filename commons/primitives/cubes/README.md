# Cube Development Tutorial & Documentation

## Overview

This tutorial teaches progressive 3D object development from basic cubes to complex VR interactive utilities. Each chapter builds on the previous one, introducing new concepts while maintaining code simplicity.

## Prerequisites

- Godot 4.x with XR-Tools addon
- Basic understanding of Node3D, MeshInstance3D, and Area3D
- VR headset (optional, works in desktop mode too)

---

## Chapter 1: Foundation Cube ✅

**File**: `res://commons/primitives/cubes/cube_scene.tscn` (Already exists)

### What You Learn
- Basic 3D scene structure
- StaticBody3D + MeshInstance3D + CollisionShape3D
- Material assignment and shader application

### Scene Structure
```
CubeScene (Node3D)
└── CubeBaseStaticBody3D (StaticBody3D)
	├── CubeBaseMesh (MeshInstance3D) - with Grid.gdshader
	└── CollisionShape3D (BoxShape3D)
```

**Key Concepts**: Scene composition, mesh rendering, collision detection

---

## Chapter 2: Shader Magic

**Files**: 
- `res://commons/primitives/cubes/cube_with_shader.tscn`
- `res://commons/primitives/cubes/CubeShaderController.gd`

### What You Learn
- Shader parameter animation
- Color cycling and emission effects
- Runtime material modification

### Implementation
```gdscript
# CubeShaderController.gd (30 lines)
extends Node3D

@export var color_cycle_speed: float = 1.0
var shader_material: ShaderMaterial

func _process(delta):
	var hue = fmod(time_elapsed * color_cycle_speed, 1.0)
	var emission_color = Color.from_hsv(hue, 0.8, 1.0)
	shader_material.set_shader_parameter("emissionColor", emission_color)
```

### Scene Setup
1. **Scene** → **Inherit** → `cube_scene.tscn`
2. **Attach** `CubeShaderController.gd` to root
3. **Save as** `cube_with_shader.tscn`

**Key Concepts**: Shader parameters, HSV color space, material animation

---

## Chapter 3: Animation System

**Files**:
- `res://commons/primitives/cubes/animated_cube.tscn`
- `res://commons/primitives/cubes/CubeAnimator.gd`

### What You Learn
- Transform animations (rotation, position, scale)
- Sine wave mathematics for organic motion
- Animation timing and coordination

### Implementation
```gdscript
# CubeAnimator.gd (40 lines)
extends Node3D

@export var rotation_speed: Vector3 = Vector3(0, 45, 0)
@export var oscillation_height: float = 0.2

func _process(delta):
	rotation_degrees += rotation_speed * delta
	
	var oscillation = sin(time_elapsed * oscillation_speed) * oscillation_height
	position = initial_position + Vector3(0, oscillation, 0)
```

### Scene Setup
1. **Inherit** from `cube_with_shader.tscn`
2. **Add Child** → **Node3D** → **Rename** "CubeAnimator"
3. **Attach** `CubeAnimator.gd` to CubeAnimator node

**Key Concepts**: Continuous rotation, oscillation patterns, scale pulsing

---

## Chapter 4: VR Interaction

**Files**:
- `res://commons/scenes/mapobjects/basic_pickup_cube.tscn`
- `res://commons/scenes/mapobjects/PickupController.gd`

### What You Learn
- VR interaction patterns
- Signal-based event handling
- Visual feedback systems

### Implementation
```gdscript
# PickupController.gd (50 lines)
extends Node3D

signal cube_grabbed(cube: Node3D)
var is_hovered: bool = false

func _on_hand_entered(area: Area3D):
	if "hand" in area.name.to_lower():
		_start_hover()
		cube_hovered.emit(self)
```

### Scene Setup
1. **Inherit** from `animated_cube.tscn`
2. **Add** Area3D → **Rename** "InteractionArea"
3. **Set** collision mask to 262144 (VR hands layer)
4. **Attach** `PickupController.gd` to root

**Key Concepts**: Area3D interaction, collision layers, VR hand detection

---

## Chapter 5: Physics Integration

**Files**:
- `res://commons/primitives/cubes/physics_cube.tscn`
- `res://commons/primitives/cubes/PhysicsController.gd`

### What You Learn
- RigidBody3D physics simulation
- Collision detection and response
- Physics material properties

### Implementation
```gdscript
# PhysicsController.gd (35 lines)
extends Node3D

var rigid_body: RigidBody3D

func apply_impulse(direction: Vector3, strength: float = 5.0):
	rigid_body.apply_central_impulse(direction.normalized() * strength)

func _on_collision(body: Node):
	var impact = rigid_body.linear_velocity.length()
	if impact > bounce_threshold:
		_trigger_bounce_effects(impact)
```

### Scene Setup
1. **Create** new scene with Node3D root
2. **Add** RigidBody3D child with mesh and collision
3. **Copy** visual elements from `cube_with_shader.tscn`
4. **Attach** `PhysicsController.gd` to root

**Key Concepts**: Physics simulation, impulse forces, collision response

---

## Chapter 6: VR Gadget System

**Files**:
- `res://commons/primitives/cubes/vr_gadget_cube.tscn`
- `res://commons/primitives/cubes/VRGadgetController.gd`

### What You Learn
- 3D UI overlay systems
- Touch interaction in VR
- Proximity-based UI activation

### Implementation
```gdscript
# VRGadgetController.gd (60 lines)
extends "res://commons/scenes/mapobjects/PickupController.gd"

var ui_3d: Node3D
var player_camera: Camera3D

func _update_ui_visibility():
	var distance = global_position.distance_to(player_camera.global_position)
	var should_show = distance <= ui_show_distance
	
	if should_show != ui_visible:
		ui_3d.visible = should_show
```

### Scene Setup
1. **Inherit** from `basic_pickup_cube.tscn`
2. **Add** Node3D → **Rename** "UI3D" → **Position** above cube
3. **Add** Control child for 3D UI elements
4. **Override** script with `VRGadgetController.gd`

**Key Concepts**: 3D UI rendering, proximity detection, billboard effects

---

## Chapter 7: Teleporter System

**Files**:
- `res://commons/scenes/mapobjects/teleport_cube.tscn`
- `res://commons/scenes/mapobjects/TeleportController.gd`

### What You Learn
- Scene transition systems
- Particle effects and visual feedback
- Charging/activation sequences

### Implementation
```gdscript
# TeleportController.gd (45 lines)
extends "VRGadgetController.gd"

@export var destination: String = ""
@export var charge_time: float = 2.0

func _start_teleport_sequence():
	is_charging = true
	portal_effect.emitting = true
	
	await get_tree().create_timer(charge_time).timeout
	_activate_teleporter()

func _activate_teleporter():
	teleporter_activated.emit()  # Grid system catches this
```

### Scene Setup
1. **Inherit** from `vr_gadget_cube.tscn`
2. **Add** GPUParticles3D for portal effects
3. **Add** Area3D for beam detection
4. **Replace** script with `TeleportController.gd`

**Key Concepts**: Scene transitions, particle systems, signal chains

---

## Chapter 8: Smart Utility System

**Files**:
- `res://commons/scenes/mapobjects/utility_cube.tscn`
- `res://commons/scenes/mapobjects/UtilityCubeController.gd`

### What You Learn
- Runtime configuration systems
- Modular behavior architecture
- JSON-driven functionality

### Implementation
```gdscript
# UtilityCubeController.gd (70 lines)
extends "TeleportController.gd"

@export var utility_type: String = "teleporter"
var utility_config: Dictionary = {}

func _apply_utility_configuration():
	match utility_type:
		"teleporter": _configure_as_teleporter()
		"pickup": _configure_as_pickup()
		"physics": _configure_as_physics()

func set_utility_type(new_type: String):
	utility_type = new_type
	_load_utility_configuration()
```

### Scene Setup
1. **Inherit** from `teleport_cube.tscn`
2. **Add** Node children: "BehaviorManager", "ConfigLoader"
3. **Replace** script with `UtilityCubeController.gd`

**Key Concepts**: Runtime reconfiguration, behavior composition, JSON integration

---

## Integration with Grid System

### Adding Cubes to Maps
```json
{
	"layers": {
		"interactables": [
			["animated_cube", " ", "physics_cube"],
			[" ", "teleport_cube:next_level", " "]
		]
	}
}
```

### Utility Registry Integration
```gdscript
# In UtilityRegistry.gd
"animated_cube": {
	"name": "animated_cube",
	"file": "animated_cube.tscn",
	"category": "interactive"
}
```

---

## Best Practices

### Code Organization
- ✅ Keep scripts under 100 lines
- ✅ Use inheritance for behavior extension
- ✅ Prefer scene composition over complex code
- ✅ One responsibility per script

### Scene Structure
- ✅ Inherit from simpler versions
- ✅ Use descriptive node names
- ✅ Group related nodes under containers
- ✅ Set proper collision layers/masks

### Performance
- ✅ Cache node references in `_ready()`
- ✅ Use `set_process(false)` when not needed
- ✅ Avoid `find_child()` in `_process()`
- ✅ Pool objects for physics cubes

---

## Extending the System

### Custom Behaviors
```gdscript
# Create new utility types
utility_cube.set_utility_type("hybrid")
utility_cube.update_config({
	"behaviors": ["pickup", "teleporter", "physics"]
})
```

### Animation Presets
```gdscript
# Quick animation configurations
cube_animator.set_animation_preset("rotation_only")
cube_animator.set_animation_preset("all")
```

### Chain Interactions
```gdscript
# Connect multiple cubes
func _on_physics_cube_settled():
	if cube.global_position.y < trigger_height:
		teleporter.set_destination("secret_room")
```

---

## Troubleshooting

### Common Issues

**Shader not animating**
- Check Grid.gdshader is applied to material_override
- Verify shader_material reference in script

**Animation stuttering**
- Use `delta` parameter consistently
- Check project FPS settings
- Cache initial transform values

**VR interaction not working**
- Verify collision layer 262144 for hands
- Check Area3D monitoring is enabled
- Ensure XR-Tools is properly set up

**Scene inheritance errors**
- Create scripts before .tscn files
- Use Godot editor instead of copying .tscn text
- Check all resource paths exist

---

## Next Steps

### Advanced Tutorials
- **Chapter 9**: Networked multiplayer cubes
- **Chapter 10**: AI-driven behavior trees
- **Chapter 11**: Procedural cube generation

### Alternative Base Objects
- **Sphere foundation**: `sphere_scene.tscn` for round objects
- **Platform foundation**: `platform_scene.tscn` for flat surfaces
- **Crystal foundation**: `crystal_scene.tscn` for complex geometry

Each chapter builds naturally while teaching fundamental 3D development, VR interaction, and modular system design principles.

# Reset Player Cube (r) - Safety Utility

## Overview

The Reset Player Cube is a safety utility that prevents players from getting lost or stuck outside the map boundaries. When a player approaches the cube, it automatically teleports them back to a safe position.

## Files Required

- **Script**: `res://commons/scenes/mapobjects/ResetPlayerController.gd`
- **Scene**: `res://commons/scenes/mapobjects/reset_cube.tscn`
- **Registry**: Add "r" entry to `UtilityRegistry.gd`

## Key Features

### 🔴 **Visual Warning System**
- Red glowing cube with warning particles
- "RESET ZONE ⚠️ DANGER ⚠️" label
- Distance-based warning effects

### ⚡ **Automatic Activation**
- Proximity-based trigger (no interaction needed)
- Configurable warning distance (default: 2.0 units)
- Fast activation (1 second charge time)

### 🎯 **Safe Reset Position**
- Teleports to Vector3(0, 1.5, 0) by default
- Configurable via JSON parameters
- Automatic height offset for safety

### 🧠 **Smart Player Detection**
- Finds VR origin, player bodies, or character controllers
- Resets physics velocity to prevent bouncing
- Works with both VR and desktop players

## Usage in Maps

### Basic Usage
```json
{
	"layers": {
		"utilities": [
			[" ", " ", " ", " ", "r"],
			[" ", " ", " ", "r", " "]
		]
	}
}
```

### Advanced Configuration
```json
{
	"utility_definitions": {
		"r": {
			"properties": {
				"reset_position": [2, 2, 2],
				"warning_distance": 3.0,
				"reset_height_offset": 1.0,
				"fade_duration": 0.5
			}
		}
	}
}
```

## Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `reset_position` | Vector3 | [0, 1.5, 0] | Where to teleport the player |
| `warning_distance` | float | 2.0 | Distance to start warning effects |
| `reset_height_offset` | float | 0.5 | Extra height above reset position |
| `fade_duration` | float | 0.3 | Fade in/out time (0 = instant) |

## Integration Example

### In GridUtilitiesComponent.gd
```gdscript
func _apply_utility_parameters(utility_object: Node3D, utility_type: String, parameters: Array):
	match utility_type:
		"r":  # Reset cube
			if parameters.size() > 0:
				# Parse reset position from parameter
				var pos_string = parameters[0]
				var coords = pos_string.split(",")
				if coords.size() >= 3:
					var reset_pos = Vector3(
						float(coords[0]), 
						float(coords[1]), 
						float(coords[2])
					)
					utility_object.set_reset_position(reset_pos)
```

### Usage with Parameters
```json
{
	"layers": {
		"utilities": [
			["r:2,3,4", " ", " "]
		]
	}
}
```

## Safety Implementation

### Automatic Player Detection
```gdscript
func _find_player_node():
	var potential_players = [
		get_tree().get_first_node_in_group("player"),
		get_tree().current_scene.find_child("XROrigin3D", true, false),
		get_tree().current_scene.find_child("VROrigin", true, false)
	]
```

### Physics Reset
```gdscript
func _reset_player_physics():
	var character_body = player_node.find_child("CharacterBody3D", true, false)
	if character_body and "velocity" in character_body:
		character_body.velocity = Vector3.ZERO
```

## Visual Design

### Red Warning Theme
- **Base Color**: Red/orange gradient
- **Emission**: Bright red glow
- **Particles**: Warning sparks
- **Animation**: Pulsing intensity

### Distance-Based Effects
```gdscript
func _show_warning_effects():
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", Color.RED)
			material.set_shader_parameter("emission_strength", 5.0)
```

## Common Use Cases

### 1. **Map Boundaries**
Place reset cubes at the edges of floating platforms or limited play areas.

### 2. **Danger Zones**
Use near cliffs, pits, or areas where players shouldn't go.

### 3. **Tutorial Safety**
Ensure new VR users can't get lost during tutorials.

### 4. **Puzzle Resets**
Reset player position when they solve or break a puzzle.

## Signals

### Available Signals
```gdscript
signal player_reset_started()
signal player_reset_complete(new_position: Vector3)
signal player_approaching_reset(distance: float)
```

### Signal Usage Example
```gdscript
func _on_reset_cube_ready():
	reset_cube.player_reset_complete.connect(_on_player_reset)

func _on_player_reset(new_position: Vector3):
	print("Player was reset to: ", new_position)
	# Maybe show a UI message or play a sound
```

## Testing & Debugging

### Force Reset (for testing)
```gdscript
# In console or debug script
reset_cube.force_reset_player()
```

### Debug Information
```gdscript
# Check if player node is found
print("Player node: ", reset_cube.player_node)
print("Reset position: ", reset_cube.get_reset_position())
```

## Performance Notes

- ✅ **Lightweight**: Only processes when player is nearby
- ✅ **Efficient**: Uses Area3D for collision detection
- ✅ **Safe**: No scene loading or complex transitions
- ✅ **VR Optimized**: Smooth position changes without motion sickness

The reset cube provides essential safety functionality for VR environments where players can easily get disoriented or move outside intended boundaries!
