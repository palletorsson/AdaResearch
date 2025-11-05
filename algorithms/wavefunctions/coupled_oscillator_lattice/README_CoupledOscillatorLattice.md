# Coupled Oscillator Lattice

## Overview
A 2D grid of oscillators where each oscillator affects its neighbors through coupling forces. Demonstrates wave modes, synchronization phenomena, and collective behavior emerging from local interactions.

## Physics

### Equation of Motion
For each oscillator i:
```
m * ÿᵢ = -k * yᵢ - γ * ẏᵢ + Σⱼ κ(yⱼ - yᵢ)
```

Where:
- **m** = mass
- **yᵢ** = displacement of oscillator i
- **k** = spring constant (ω₀² = k/m)
- **γ** = damping coefficient
- **κ** = coupling strength
- **Σⱼ** = sum over neighboring oscillators

### Key Concepts

**Normal Modes**: Special patterns where all oscillators oscillate at the same frequency

**Dispersion Relation**: ω(k) relates wave frequency to wavelength

**Energy Transfer**: Energy flows between oscillators through coupling

**Synchronization**: Oscillators can phase-lock under certain conditions

## Parameters

### Lattice Structure
- **lattice_size**: Grid dimensions (default: 12×12)
- **oscillator_spacing**: Distance between oscillators
- **base_height**: Y position of equilibrium plane

### Oscillator Properties
- **natural_frequency**: Frequency without coupling (ω₀)
- **mass**: Mass of each oscillator
- **damping_coefficient**: Energy loss rate (γ)

### Coupling
- **coupling_strength**: How strongly neighbors interact (κ)
- **coupling_range**: Distance of interaction (1 = nearest neighbors)

### Excitation Modes
- **Sine**: Continuous sinusoidal drive at center
- **Pulse**: Single impulse to start wave propagation
- **Random**: Stochastic excitation (thermal noise analog)

### Visualization
- **color_by_displacement**: Blue = low, Red = high displacement
- **show_connections**: Draw lines between coupled oscillators

## Applications

### Physics
- **Phonons**: Quantized lattice vibrations in crystals
- **Crystal dynamics**: Atomic vibrations in solids
- **Wave propagation**: How waves travel through discrete media
- **Normal modes**: Fundamental vibration patterns

### Engineering
- **Mechanical systems**: Coupled spring-mass systems
- **Electrical circuits**: LC networks and transmission lines
- **Structural analysis**: Building and bridge vibrations
- **Array antennas**: Coupled electromagnetic oscillators

### Biology
- **Neural networks**: Synchronized neuron firing
- **Cardiac cells**: Heart rhythm generation
- **Circadian rhythms**: Biological clock synchronization

## Phenomena to Observe

1. **Wave Propagation**: Watch waves spread from center
2. **Reflection**: Waves bounce off lattice boundaries
3. **Interference**: Multiple waves combine
4. **Standing Waves**: Stable patterns from reflection
5. **Normal Modes**: Special synchronized patterns
6. **Energy Localization**: Energy trapped in regions
7. **Phase Transitions**: Sudden changes in collective behavior

## Interactive Control

```gdscript
# Get displacement at specific oscillator
var disp = get_displacement_at(5, 5)

# Set displacement manually
apply_displacement(6, 6, 0.5)

# Get total system energy
var energy = get_total_energy()
```

## Experiments to Try

1. **Change coupling_strength** from 0 (no coupling) to 5.0 (strong coupling)
   - Observe how waves speed up with stronger coupling

2. **Vary lattice_size** to see finite-size effects
   - Smaller lattices show more reflection

3. **Adjust damping_coefficient** to see energy decay
   - Higher damping = faster energy loss

4. **Try different excitation_modes**
   - Pulse: Clean wave propagation
   - Random: Thermal-like behavior

## Connection to Quantum Mechanics
This classical system is analogous to:
- **Phonons**: Quantized versions of these oscillations
- **Second quantization**: Creation/annihilation operators
- **Bose-Einstein condensation**: Of phonons at low temperature
