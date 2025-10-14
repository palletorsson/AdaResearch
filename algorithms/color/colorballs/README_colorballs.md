# Random Color Rigidbody Balls

A physics-based color demonstration featuring randomly colored balls with sizes between handballs and golfballs.

## Features

- **Physics Simulation**: Full rigidbody physics with realistic bouncing and collision
- **Random Colors**: Uses the integrated color palette system for diverse color schemes
- **Size Variation**: Balls range from golf ball size (3.5cm radius) to hand ball size (6cm radius)
- **Auto-Respawn**: Balls automatically respawn when they fall below a threshold
- **Interactive Controls**: Keyboard controls for adding/removing balls and cycling palettes

## Controls

- **Space**: Add a new ball
- **Escape**: Remove the last ball
- **Enter**: Cycle to next color palette
- **Home**: Regenerate all balls
- **End**: Clear all balls

## Ball Specifications

- **Size Range**: 3.5cm - 6cm radius (golf ball to hand ball size)
- **Mass**: 0.1 kg (configurable)
- **Bounce**: 0.8 (high bounce for playful interaction)
- **Friction**: 0.3 (moderate friction)
- **Physics**: Full rigidbody with gravity, damping, and collision

## Color System Integration

- Uses the existing color palette resource system
- Supports all 20+ color palettes (Bauhaus, Memphis Design, Cyberpunk, etc.)
- Random color selection from current palette
- Configurable color intensity and emission effects

## Physics Properties

- **Gravity Scale**: 1.0 (normal gravity)
- **Linear Damping**: 0.1 (gradual velocity reduction)
- **Angular Damping**: 0.1 (gradual rotation reduction)
- **Auto-Respawn**: Balls respawn when falling below -2m

## Usage in VR

Perfect for VR interaction and experimentation:
- Grab and throw balls
- Watch them bounce and interact
- Experience different color palettes
- Physics-based color exploration

## Configuration

All parameters are exposed as export variables for easy tweaking:
- Ball count, size range, and physics properties
- Spawn area and initial velocity settings
- Color intensity and material properties
- Respawn behavior and thresholds
