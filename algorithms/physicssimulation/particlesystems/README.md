# Particle Systems Algorithm

## Overview
This algorithm demonstrates advanced particle system simulation with four different types of particle effects: smoke, fire, sparks, and weather. Each system has unique behaviors, physics, and visual characteristics that create realistic environmental effects.

## Visualization Features
- **Four Particle Types**: Smoke, Fire, Sparks, and Weather effects
- **Real-time Physics**: Particles respond to gravity, wind, and turbulence
- **Dynamic Emission**: Continuous particle generation with configurable rates
- **Lifetime Management**: Particles fade out and are recycled automatically
- **Environment Interaction**: Particles collide with boundaries and respond realistically
- **Animated Emitters**: Dynamic source points that move and scale

## Technical Implementation
- **Particle Class**: Handles individual particle physics and rendering
- **Emitter System**: Manages particle creation and emission rates
- **Force Application**: Gravity, wind, and turbulence effects
- **Collision Detection**: Boundary collision handling with bounce effects
- **Memory Management**: Automatic cleanup of expired particles

## Parameters
- `max_particles`: Maximum number of particles in all systems (default: 200)
- `emission_rate`: Particles emitted per second (default: 10.0)
- `particle_lifetime`: Base lifetime of particles (default: 3.0)
- `particle_speed`: Initial velocity multiplier (default: 2.0)
- `gravity_strength`: Gravitational acceleration (default: 9.8)
- `wind_strength`: Wind force magnitude (default: 1.0)
- `turbulence_strength`: Random motion strength (default: 0.5)

## Particle Types

### Smoke Particles
- **Behavior**: Slow upward drift with random horizontal motion
- **Lifetime**: Extended duration (2x base lifetime)
- **Size**: Larger particles (0.05-0.15 radius)
- **Color**: Gray with transparency
- **Physics**: Low velocity, high drag

### Fire Particles
- **Behavior**: Fast upward motion with flickering
- **Lifetime**: Short duration (0.5x base lifetime)
- **Size**: Small to medium particles (0.03-0.1 radius)
- **Color**: Orange-red with high emission
- **Physics**: High velocity, rapid decay

### Spark Particles
- **Behavior**: Explosive outward motion in all directions
- **Lifetime**: Very short duration (0.3x base lifetime)
- **Size**: Small particles (0.02-0.06 radius)
- **Color**: Bright yellow with high emission
- **Physics**: High velocity, random directions

### Weather Particles
- **Behavior**: Downward falling motion (rain/snow simulation)
- **Lifetime**: Medium duration (1.5x base lifetime)
- **Size**: Small particles (0.02-0.08 radius)
- **Color**: Blue-white with transparency
- **Physics**: Consistent downward velocity

## Physics System
- **Gravity**: Constant downward acceleration
- **Wind**: Time-varying horizontal forces
- **Turbulence**: Perlin-like random motion
- **Damping**: Velocity reduction over time
- **Collision**: Boundary reflection with energy loss

## Environment Features
- **Bounded Space**: Enclosed environment with walls
- **Collision Response**: Particles bounce off boundaries
- **Energy Loss**: Collisions reduce particle velocity
- **Spatial Constraints**: Particles stay within defined volume

## Animation System
- **Emitter Animation**: Sources move, scale, and rotate
- **Control Animation**: Parameter indicators pulse and rotate
- **Dynamic Emission**: Variable particle generation rates
- **Visual Feedback**: Emitters change appearance based on activity

## Performance Features
- **Particle Pooling**: Efficient memory management
- **Automatic Cleanup**: Dead particles are removed automatically
- **Configurable Limits**: Adjustable maximum particle counts
- **Optimized Rendering**: Efficient visual node updates

## VR Integration Notes
- Optimized for VR viewing with emissive materials
- Clear visual separation between particle types
- Animated controls provide visual feedback
- Environment boundaries are clearly defined
- Particle trails show motion clearly
- Ready for XR world integration
