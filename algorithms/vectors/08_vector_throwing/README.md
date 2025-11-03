# Vector Throwing Demo

An interactive VR demonstration of projectile motion using throwable balls with real-time velocity and gravity vector visualization.

## Overview

This example demonstrates fundamental physics concepts:
- **Velocity Vectors**: Calculated from hand movement while holding the ball
- **Gravity Vectors**: Constant downward acceleration (9.8 m/s²)
- **Projectile Motion**: Combining horizontal velocity with vertical acceleration
- **Collision Detection**: Hit targets to score points

## Components

### 1. ThrowBall (`throw_ball.tscn`)

Throwable physics ball with velocity tracking and vector visualization.

**Features:**
- Tracks hand position history (5 samples by default)
- Calculates velocity: `v = Δposition / Δtime`
- Displays real-time velocity vector (cyan arrow)
- Shows constant gravity vector (red arrow)
- Applies accumulated velocity on release
- Configurable physics parameters

**Exports:**
```gdscript
velocity_samples: int = 5           # Position samples for velocity calc
velocity_multiplier: float = 1.2    # Boost factor for better feel
max_throw_speed: float = 10.0       # Speed cap (m/s)
enable_gravity_on_throw: bool = true
show_velocity_vector: bool = true
show_gravity_vector: bool = true
ball_radius: float = 0.05
ball_mass: float = 0.5
```

### 2. HitTargetCube (`hit_target_cube.tscn`)

Target cube that reacts to ball impacts.

**Features:**
- Collision detection for throwable objects
- Visual feedback: color change and scale pulse
- Procedural audio feedback (pitch based on impact speed)
- Floating score label on hit
- Optional respawn system
- Configurable point values

**Exports:**
```gdscript
cube_size: float = 0.3
points_value: int = 10
enable_hit_animation: bool = true
enable_hit_sound: bool = true
destroy_on_hit: bool = false
respawn_time: float = 3.0
show_hit_label: bool = true
```

### 3. VectorThrowing (`VectorThrowing.tscn`)

Main scene combining all elements.

**Features:**
- Spawns multiple throwable balls
- Creates grid of target cubes (increasing difficulty/points)
- Real-time score tracking
- Physics equations info panel
- Instructions display
- Game reset functionality

## How It Works

### Velocity Calculation

The ball tracks its position over time while held:

```gdscript
# Store position history
position_history.append(global_position)
time_history.append(current_time)

# Calculate average velocity
velocity = (current_pos - oldest_pos) / time_diff
```

This creates a **circular buffer** that:
1. Captures smooth hand motion
2. Filters out jitter
3. Provides realistic throw feel

### Vector Visualization

**Velocity Vector (Cyan):**
- Updates in real-time while ball is held
- Length proportional to throw speed
- Points in direction of motion
- Fades out after release

**Gravity Vector (Red):**
- Constant downward direction
- Fixed magnitude (9.8 m/s²)
- Always visible while ball is held
- Represents Earth's gravitational acceleration

### Physics Transfer

On release:
```gdscript
var throw_velocity = calculated_velocity * velocity_multiplier
linear_velocity = throw_velocity  # Apply to RigidBody3D
gravity_scale = 1.0               # Enable gravity
```

The ball then follows **projectile motion**:
- Horizontal: constant velocity
- Vertical: constant acceleration (gravity)

## Usage

### In VR

1. **Grab a Ball**: Use VR controller grip button
2. **Build Velocity**: Move your hand in throwing motion
3. **Watch Vectors**:
   - Cyan arrow shows your velocity
   - Red arrow shows gravity
4. **Release**: Let go to throw
5. **Hit Targets**: Aim for higher rows (more points!)

### Desktop Testing

Can be tested in desktop mode with mouse/keyboard:
- Select ball in scene tree
- Manually set `linear_velocity` in inspector
- Run scene to see physics

## Scoring System

**Target Grid:**
- **Bottom Row**: 10 points (easiest)
- **Middle Row**: 20 points
- **Top Row**: 30 points (hardest)

**Scoring Display:**
- Real-time score updates
- Hit count tracking
- Throw accuracy percentage

## Physics Concepts Demonstrated

### 1. Velocity
- **Definition**: Rate of change of position
- **Formula**: `v = Δx / Δt`
- **Units**: meters per second (m/s)
- **Vector**: Has both magnitude and direction

### 2. Gravity
- **Constant Acceleration**: 9.8 m/s² downward
- **Force**: `F = ma`
- **Effect**: Curves projectile path

### 3. Projectile Motion
- **Independence of Components**: Horizontal and vertical motion are independent
- **Parabolic Path**: Combination of constant horizontal velocity and accelerated vertical motion
- **Range**: Depends on initial velocity and launch angle

### 4. Collision/Impact
- **Momentum Transfer**: Moving ball transfers energy to target
- **Impact Force**: Depends on velocity at collision
- **Sound Generation**: Procedural audio based on impact speed

## Customization

### Adjust Ball Physics

Edit `throw_ball.tscn` exports:
```gdscript
velocity_multiplier = 1.5  # Stronger throws
max_throw_speed = 15.0     # Higher speed cap
ball_mass = 1.0            # Heavier ball
```

### Modify Target Layout

Edit `VectorThrowing.tscn` exports:
```gdscript
target_rows = 5           # More rows
target_columns = 6        # Wider spread
target_distance = 5.0     # Further away
target_spacing = 0.4      # Tighter grid
```

### Change Difficulty

**Easier:**
- Increase `velocity_multiplier`
- Decrease `target_distance`
- Larger `cube_size`

**Harder:**
- Decrease `velocity_multiplier`
- Increase `target_distance`
- Enable `destroy_on_hit`

## Educational Extensions

### Add More Visualizations

1. **Trajectory Prediction**: Show parabolic arc before throwing
2. **Component Vectors**: Break velocity into X/Y/Z components
3. **Acceleration Vector**: Show rate of change of velocity
4. **Force Vectors**: Display applied forces (hand, gravity, drag)

### Code Examples

**Show Velocity Components:**
```gdscript
func _display_velocity_components(velocity: Vector3):
    var x_vec = spawn_vector(global_position, Vector3(velocity.x, 0, 0), Color.RED, "Vx")
    var y_vec = spawn_vector(global_position, Vector3(0, velocity.y, 0), Color.GREEN, "Vy")
    var z_vec = spawn_vector(global_position, Vector3(0, 0, velocity.z), Color.BLUE, "Vz")
```

**Predict Trajectory:**
```gdscript
func _predict_trajectory(initial_pos: Vector3, initial_vel: Vector3, steps: int = 50):
    var dt = 0.1
    var pos = initial_pos
    var vel = initial_vel

    for i in range(steps):
        pos += vel * dt
        vel.y -= 9.8 * dt  # Apply gravity
        # Draw point at pos
```

## Integration with VR Grid System

This scene can be integrated into the main VR grid system:

1. Add to map JSON:
```json
{
  "map_name": "Vector_Throwing",
  "grid_config": {
    "show_grid": true
  },
  "objects": [
    {
      "type": "VectorThrowing",
      "position": [0, 0, 0]
    }
  ]
}
```

2. Register in UtilityRegistry if needed

## Performance Notes

- **Velocity Tracking**: Minimal overhead (5 samples)
- **Vector Updates**: Only while ball is held
- **Collision**: Uses Area3D for efficient detection
- **Audio**: Procedurally generated, no external files
- **Target Grid**: Static bodies for efficiency

## Future Enhancements

- [ ] Add wind resistance (drag force)
- [ ] Implement spin/curve balls (Magnus effect)
- [ ] Add moving targets
- [ ] Create different ball types (heavy, light, bouncy)
- [ ] Add multiplayer scoring
- [ ] Implement combo system (consecutive hits)
- [ ] Add sound effects for different materials
- [ ] Create tutorial mode with guided throws

## Troubleshooting

**Ball doesn't throw:**
- Ensure XR Tools addon is enabled
- Check that ball extends XRToolsPickable
- Verify `velocity_samples > 1`

**Vectors not visible:**
- Check `show_velocity_vector` and `show_gravity_vector` exports
- Ensure ball is being held (vectors only show when grabbed)
- Verify vector colors aren't black/transparent

**Targets not detecting hits:**
- Confirm ball is in "throwable" group
- Check collision layers/masks
- Ensure Area3D is monitoring

**Performance issues:**
- Reduce `num_balls` in main scene
- Decrease `target_rows` and `target_columns`
- Disable `show_hit_label` on targets

## Credits

Part of the AdaResearch educational VR platform demonstrating vector mathematics and physics principles through interactive gameplay.

Based on the VectorSceneBase architecture from the Nature of Code implementations.
