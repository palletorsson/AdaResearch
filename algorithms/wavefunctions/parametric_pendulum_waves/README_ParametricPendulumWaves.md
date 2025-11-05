# Parametric Pendulum Waves

## Overview
An array of pendulums with carefully chosen lengths that create mesmerizing wave patterns. This famous physics demonstration (also called "pendulum snake" or "pendulum wave") shows how discrete oscillators with different frequencies create the illusion of continuous waves.

## The Magic Formula

### Pendulum Period
```
T = 2π√(L/g)
```
Where:
- **T** = Period (time for one complete swing)
- **L** = Pendulum length
- **g** = Gravitational acceleration (9.8 m/s²)

### Length Calculation
To create the wave effect, each pendulum must complete a specific number of oscillations in a given time window:

```
Lᵢ = (Tᵢ / 2π)² * g
```

Where pendulum i completes (N + i) oscillations in the recurrence time, creating the wave illusion.

## How It Works

### Phase Relationship
- All pendulums start at the same angle
- Pendulum 1 completes N oscillations
- Pendulum 2 completes N+1 oscillations
- Pendulum 3 completes N+2 oscillations
- etc.

### The Wave Illusion
At any moment, the pendulums form a sine wave pattern. The pattern appears to:
1. **Travel** like a wave moving left/right
2. **Reverse** direction periodically
3. **Reform** perfectly when all return to start

### Recurrence
After time T_recurrence, all pendulums complete integer cycles and return to the starting position, creating a perfect loop.

## Parameters

### Pendulum Array
- **num_pendulums**: Number of pendulums in the array (default: 15)
  - More pendulums = smoother wave appearance
- **pendulum_spacing**: Horizontal distance between pivots
- **base_height**: Y position of pivot bar

### Length Variation
- **shortest_length**: Length of fastest pendulum
- **longest_length**: Length of slowest pendulum
- The lengths are calculated to create N, N+1, N+2... oscillations

### Physics
- **gravity**: Gravitational constant (affects period)
- **damping**: Energy loss per frame (default: 0.998)
- **release_angle**: Starting amplitude in radians

### Visualization
- **bob_radius**: Size of pendulum bobs
- **color_by_index**: Rainbow color each pendulum
- **trail_length**: Number of positions to remember
- **show_pivot_bar**: Display horizontal support beam

## Famous Variations

### Standard Wave (51-65 oscillations)
```gdscript
num_pendulums = 15
# Creates classic traveling wave pattern
```

### Dense Array (High frequency)
```gdscript
num_pendulums = 30
# More pendulums show finer wave detail
```

### Short Recurrence
- Fewer oscillations (e.g., 10-25)
- Faster return to start
- Good for quick demonstrations

### Long Recurrence
- Many oscillations (e.g., 100+)
- Complex patterns before reset
- Beautiful but slow

## Physics Principles Demonstrated

1. **Simple Harmonic Motion**
   - Pendulum swing approximates SHM for small angles
   - Period independent of amplitude (for small angles)

2. **Frequency vs. Length**
   - Longer pendulums swing slower
   - Relationship is square root, not linear

3. **Superposition**
   - Multiple frequencies create complex patterns
   - Wave-like appearance from discrete oscillators

4. **Aliasing**
   - Discrete samples (pendulums) create continuous perception
   - Related to sampling theorem in signal processing

5. **Phase Relations**
   - Controlled phase differences create patterns
   - Demonstrates wave interference principles

## Mathematical Beauty

The pattern shows several mathematical concepts:
- **Beating**: Slow oscillation envelope from close frequencies
- **Standing Waves**: Apparent nodes and antinodes
- **Temporal Symmetry**: Perfect recurrence
- **Discrete-to-Continuous**: How discreteness creates continuity

## Real-World Applications

### Physics Education
- Intuitive demonstration of wave properties
- Shows relation between period and length
- Illustrates phase relationships

### Art Installations
- Mesmerizing kinetic sculpture
- Used in science museums worldwide
- Popular as decorative physics demonstration

### Signal Processing
- Analog of sampling theorem
- Demonstrates aliasing effects
- Shows frequency decomposition

## Building Your Own

This visualization accurately models a real pendulum wave that can be built:

**Materials:**
- 15-30 pendulum bobs (fishing weights work well)
- String or wire
- Horizontal support bar
- Precise length measurement tools

**Key Challenge:**
Getting the lengths exactly right. Small errors accumulate and the pattern won't recur perfectly.

## Interactive Functions

```gdscript
# Get position of specific bob
var pos = get_bob_position(5)

# Get current wave phase (0-1)
var phase = get_wave_phase()

# Reset to start
reset()
```

## Historical Note

This demonstration has been used in physics education for over a century. The modern "pendulum wave" became popular through:
- Science museum installations
- Viral videos in the 2000s
- Art installations worldwide

The mathematics was understood since pendulum studies by Galileo and Huygens, but the artistic presentation as a "wave machine" is relatively recent.

## Try This

1. **Watch one pendulum** - Notice it swings at constant frequency
2. **Watch the pattern** - See the traveling wave emerge
3. **Wait for recurrence** - All pendulums align again
4. **Change damping to 1.0** - See perpetual motion (no energy loss)
5. **Increase num_pendulums to 30** - Smoother wave appearance
