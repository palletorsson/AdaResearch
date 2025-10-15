# Unit Circle

## Overview
This algorithm provides an interactive visualization of the unit circle, demonstrating fundamental trigonometric concepts and their relationships to circular motion and wave functions.

## Scenes

### unit_circle.tscn
The original animated visualization showing how the unit circle generates sine and cosine waves over time. Watch as a point rotates around the circle and creates wave patterns.

### walkable_sine_bridge.tscn
An interactive, walkable bridge that follows a sine wave path. This demonstrates the unit circle concept in a physical, explorable way where you can walk along the wave that a rotating point would trace.

## Description
The unit circle is a fundamental mathematical concept that relates angles to coordinates on a circle with radius 1. This visualization shows how sine, cosine, and other trigonometric functions relate to positions on the circle, essential for understanding waves, oscillations, and circular motion.

## Key Features

### Unit Circle Animation (unit_circle.tscn)
- **Interactive Circle**: Dynamic unit circle visualization
- **Trigonometric Functions**: Sine, cosine, and tangent relationships
- **Angle Measurement**: Clear angle representation and measurement
- **Coordinate Display**: Real-time coordinate updates
- **3D Wave Generation**: See sine waves form in real-time
- **Color Gradients**: Beautiful blue-pink gradient following wave progression

### Walkable Sine Bridge (walkable_sine_bridge.tscn)
- **Physical Bridge**: Walk across a 3D sine wave path
- **Player Controls**: Use arrow keys to navigate the bridge
- **Unit Circle Reference**: Optional visualization showing the source circle
- **Support Structures**: Projection lines showing height from ground
- **Gradient Coloring**: Matching the animated unit circle colors
- **Collision Detection**: Physically interact with the wave surface

## Use Cases
- **Mathematics Education**: Learning trigonometry fundamentals
- **Physics Education**: Understanding circular motion and waves
- **Engineering**: Mathematical foundation for many applications
- **Scientific Visualization**: Clear mathematical concept demonstration

## Technical Implementation
The algorithm uses GDScript to create:
- Interactive circle rendering
- Trigonometric calculations
- Real-time coordinate updates
- Educational interface elements

## Core Concepts Covered
- **Unit Circle**: Basic circle with radius 1
- **Trigonometric Functions**: Sine, cosine, tangent relationships
- **Angle Measurement**: Degrees and radians
- **Coordinate Systems**: Cartesian coordinate relationships
- **Circular Motion**: Understanding periodic motion

## Benefits
- **Fundamental Concept**: Essential mathematical foundation
- **Visual Learning**: Intuitive understanding through visualization
- **Interactive Experience**: Hands-on mathematical exploration
- **Wide Applications**: Foundation for many scientific fields

## Applications
- **Mathematics Education**: Teaching trigonometry through visual and interactive methods
- **Physics Education**: Understanding waves and oscillations
- **Engineering**: Mathematical foundation for design
- **Scientific Research**: Understanding periodic phenomena
- **Game Design**: Creating wave-based level geometry
- **Interactive Learning**: Kinesthetic understanding of mathematical concepts

## Controls (Walkable Sine Bridge)
- **Arrow Keys / WASD**: Move the player across the bridge
- **Walk the Wave**: Experience the sine function by traversing its physical form

## Customization Options (Walkable Sine Bridge)
The walkable bridge scene includes many exported parameters for customization:

### Bridge Parameters
- `bridge_length`: Total length of the bridge (default: 30.0)
- `bridge_width`: Width of walkable surface (default: 2.0)
- `wave_amplitude`: Height of sine wave, equivalent to circle radius (default: 3.0)
- `wave_frequency`: Number of complete sine waves (default: 2.0)
- `bridge_segments`: Smoothness of the bridge mesh (default: 120)

### Visual Style
- `use_gradient`: Enable blue-pink gradient coloring (default: true)
- `bridge_color`: Base color if gradient disabled
- `emission_strength`: Glow intensity (default: 0.3)
- `show_unit_circle`: Display reference unit circle (default: true)
- `show_projection_lines`: Show vertical support structures (default: true)

### Player Settings
- `player_speed`: Movement speed (default: 5.0)
- `camera_follow_smoothing`: Camera tracking smoothness (default: 5.0)
- `spawn_player`: Create player character (default: true)
