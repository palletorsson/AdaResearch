# Spherical Harmonics

A small sphere orbits a large sphere, mapping its position to sound parameters — the "Music of the Spheres" rendered as retro 8-bit coin sounds.

## QFEP Connection

Spherical harmonics are **eigenfunctions of angular momentum** — the shapes that emerge when waves wrap around a sphere. They're fundamental to quantum mechanics (electron orbitals), acoustics (room modes), and computer graphics (lighting). This visualization makes the abstract tangible: position = sound.

## How It Works

```
Position on sphere (θ, φ) → Sound parameters
├── θ (latitude, 0→π)  → Pitch (frequency range)
├── φ (longitude, 0→2π) → Snappiness (decay rate)
└── radius             → Amplitude
```

The orbiting sphere triggers a "Mario coin" sound effect each time it crosses a quadrant boundary, with synthesis parameters determined by its current position.

## Sound Synthesis

Square wave with frequency chirp and exponential decay:

```gdscript
freq_start: float = 440.0   # Starting frequency
freq_end: float = 880.0     # Ending frequency (one octave up)
decay_rate: float = 8.0     # Exponential decay speed
sound_duration: float = 0.5 # Length of sound
```

The chirp (frequency sweep) combined with rapid decay creates the classic 8-bit pickup sound.

## Parameters

| Variable | Description |
|----------|-------------|
| `theta` | Latitude angle (0 to π) |
| `phi` | Longitude angle (0 to 2π) |
| `radius` | Distance from center sphere |
| `orbit_speed_theta` | Latitude orbit rate |
| `orbit_speed_phi` | Longitude orbit rate |
| `auto_orbit` | Enable automatic orbiting |

## Performance

Uses **MultiMesh** for the 128-point trail visualization instead of individual nodes — single draw call for the entire trail.

## Files

| File | Purpose |
|------|---------|
| `SphericalHarmonics.tscn` | Scene with spheres and audio |
| `SphericalHarmonics.gd` | Orbit logic and synthesis |

## Mathematical Background

Spherical harmonics Yₗᵐ(θ,φ) are solutions to Laplace's equation on a sphere:

```
Y₀⁰ = constant (monopole)
Y₁⁰ = cos(θ) (dipole)
Y₂⁰ = 3cos²(θ) - 1 (quadrupole)
...
```

Each harmonic has:
- **l** (degree): number of nodal lines
- **m** (order): number of longitudinal nodal lines

This visualization doesn't render the harmonics directly, but uses the spherical coordinate system they're defined in.

## VR Experience

Watch the small sphere orbit while listening to the sounds it triggers. Notice how the pitch changes with latitude and the "snappiness" changes with longitude. The trail shows the recent path, creating a visual record of the sound's evolution.

## See Also

- `parametric_pendulum_waves/` — Another position→sound mapping
- `coupled_oscillator_lattice/` — Grid of connected oscillators
