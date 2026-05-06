# Cube Agent System

A procedural character generation system that builds articulated humanoid characters from JSON grid data, using the same format as map structures.

## Overview

The Cube Agent System creates walking characters by:
1. Reading a grid-based structure definition (like map_data.json)
2. Generating RigidBody3D cubes for each grid cell
3. Connecting cubes with Generic6DOFJoint3D at marked joint positions
4. Applying procedural walking animation through joint forces

## Architecture

### Core Components

**CubeAgentBuilder.gd** - Main builder class
- Reads agent_data.json
- Generates cube bodies from structure layer
- Creates joints from joints layer
- Classifies body parts (head, torso, arms, legs)

**CubeAgentWalkController.gd** - Movement controller
- Applies sinusoidal forces to leg joints for walking
- Swings arms opposite to legs
- Maintains balance through corrective torques
- Configurable walk speed and step frequency

**CubeAgentSpawner.gd** - Map integration
- Spawns agents in grid-based maps
- Compatible with interactables layer
- Supports configuration via # syntax

## Agent Data Format

The agent is defined in `agent_data.json` using the same grid format as maps:

```json
{
  "layers": {
    "structure": [
      ["0", "0", "1.5", "0", "0"],  // Head (height 1.5)
      ["0", "0", "1.0", "0", "0"],  // Neck
      ["1", "1", "1", "1", "1"],    // Shoulders/torso
      ["0", "1", "1", "1", "0"],    // Torso
      ["0", "1", "0", "1", "0"],    // Legs
      ["0", "1", "0", "1", "0"]     // Legs
    ],
    "joints": [
      [" ", " ", " ", " ", " "],
      [" ", " ", "j", " ", " "],    // Neck joint
      [" ", "j", " ", "j", " "],    // Shoulder joints
      [" ", " ", " ", " ", " "],
      [" ", "j", " ", "j", " "],    // Hip joints
      [" ", " ", " ", " ", " "]
    ]
  },
  "settings": {
    "cube_size": 0.2,  // Size of each cube in meters
    "gutter": 0.0
  }
}
```

### Structure Layer
- Numbers represent cube height/size (0 = no cube, 1 = full size, 1.5 = taller)
- Grid is (x, z) format like maps
- Multiple cubes stack vertically based on height value

### Joints Layer
- "j" marks positions where articulated joints should be created
- Joints connect cubes to adjacent grid positions
- Allows realistic limb movement

## Usage

### Method 1: Standalone Scene

```gdscript
# Create and spawn an agent programmatically
var agent_builder = CubeAgentBuilder.new()
agent_builder.agent_data_path = "res://commons/agent/agent_data.json"
agent_builder.cube_size = 0.2
add_child(agent_builder)

# Add walk controller
var walk_controller = CubeAgentWalkController.new()
agent_builder.add_child(walk_controller)

# Wait for build complete
await agent_builder.agent_built

# Start walking
walk_controller.start_walking(Vector3.FORWARD)
```

### Method 2: Test Scene

Open and run `res://commons/agent/cube_agent_test.tscn` to see the agent in action.

### Method 3: In Grid Maps

Add to map JSON interactables layer:

```json
"interactables": [
  ["agent_spawner", " ", " "],
  [" ", " ", " "]
]
```

With configuration:

```json
"interactables": [
  ["agent_spawner#direction:1,0,1", " ", " "],  // Walk northeast
  [" ", " ", " "]
]
```

## Configuration Options

### CubeAgentBuilder

- `agent_data_path`: Path to JSON file (default: "res://commons/agent/agent_data.json")
- `cube_size`: Size of each cube in meters (default: 0.2)
- `cube_mass`: Mass per cube (default: 0.5)
- `joint_stiffness`: Joint motor force (default: 100.0)
- `joint_damping`: Joint damping (default: 10.0)

### CubeAgentWalkController

- `walk_speed`: Forward movement speed (default: 2.0)
- `step_frequency`: Steps per second (default: 1.5)
- `step_height`: Leg lift force (default: 50.0)
- `balance_strength`: Upright torque (default: 20.0)

### CubeAgentSpawner (Grid Config)

Use # syntax in map JSON:
- `agent_spawner#direction:x,y,z` - Set walk direction
- `agent_spawner#size:0.3` - Set cube size

## Body Part Classification

The system automatically classifies cubes into body parts based on grid position:

- **Head**: z=0-1 (top rows)
- **Torso**: z=2-6, center columns
- **Left Arm**: z=2, x < 4
- **Right Arm**: z=2, x > 7
- **Left Leg**: z > 6, x < 5
- **Right Leg**: z > 6, x >= 5

## API Reference

### CubeAgentBuilder

```gdscript
# Get the root body (center of torso)
var root = agent_builder.get_root_body()

# Get cubes for a specific body part
var left_leg = agent_builder.get_body_part("left_leg")

# Get all cubes
var all_cubes = agent_builder.get_all_cubes()

# Apply force to a body part
agent_builder.apply_force_to_part("right_arm", Vector3(0, 10, 0))
```

### CubeAgentWalkController

```gdscript
# Start/stop walking
walk_controller.start_walking(Vector3.FORWARD)
walk_controller.stop_walking()
walk_controller.toggle_walking()

# Change direction
walk_controller.set_walk_direction(Vector3(1, 0, 1))

# Change speed
walk_controller.set_walk_speed(5.0)
```

## Creating Custom Agents

1. Duplicate `agent_data.json`
2. Modify the structure layer to change body shape
3. Add "j" markers in joints layer where you want articulation
4. Adjust settings like cube_size
5. Update `agent_data_path` in your code

### Example: 4-legged creature

```json
{
  "layers": {
    "structure": [
      ["1", "1", "1", "1"],  // Body
      ["1", "0", "0", "1"],  // Front legs
      ["1", "0", "0", "1"],  // Back legs
      ["1", "0", "0", "1"]
    ],
    "joints": [
      [" ", " ", " ", " "],
      ["j", " ", " ", "j"],  // Front leg joints
      ["j", " ", " ", "j"],  // Back leg joints
      [" ", " ", " ", " "]
    ]
  }
}
```

## Physics Considerations

- **Mass**: Total agent mass affects movement speed and stability
- **Joint Stiffness**: Higher values = stiffer joints, more rigid movement
- **Damping**: Higher values = slower, more controlled movement
- **Collision**: Agents use collision layer 2, collide with world (layer 1)

## Troubleshooting

**Agent falls apart:**
- Increase `joint_stiffness`
- Reduce `cube_mass`
- Check joints layer has "j" markers

**Agent doesn't walk:**
- Verify walk_controller is child of agent_builder
- Check `auto_walk` is true in spawner
- Ensure floor has collision (layer 1)

**Agent walks backwards:**
- Reverse walk_direction: `Vector3(-1, 0, 0)` instead of `(1, 0, 0)`

**Agent is too small/large:**
- Adjust `cube_size` parameter
- Scale applies uniformly to entire agent

## Future Enhancements

Potential additions:
- Machine learning-based walking (integrate with existing RL systems)
- IK (Inverse Kinematics) for foot placement
- Animation blending system
- Grabbing/interaction with hands
- Custom joint configurations per limb
- Ragdoll physics on death/impact

## Files

- `CubeAgentBuilder.gd` - Core builder system
- `CubeAgentWalkController.gd` - Walking behavior
- `CubeAgentSpawner.gd` - Map integration
- `agent_data.json` - Default agent structure
- `cube_agent_test.tscn` - Test scene
- `agent_spawner.tscn` - Spawner scene for maps

## License

Part of Ada Research project.
