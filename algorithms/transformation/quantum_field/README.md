# Quantum Field

Visualization of quantum field theory concepts — vacuum fluctuations, virtual particles, and wave propagation.

## QFEP Connection

Quantum fields are **the ground state of reality** — even "empty" space fluctuates. Vacuum fluctuations (E, irreducible randomness) generate virtual particle-antiparticle pairs that blink in and out of existence. Wave sources create ordered disturbances (F) that propagate through the field. This is λ at the quantum scale.

## How It Works

```
Field at rest:              Field with fluctuations:
┌────────────────────┐     ┌────────────────────┐
│ · · · · · · · · ·  │     │ · ˙ · · ˙ · · · ·  │
│ · · · · · · · · ·  │  →  │ · · ˙ · · · ˙ · ·  │
│ · · · · · · · · ·  │     │ · ˙ · · ˙ · · ˙ ·  │
└────────────────────┘     └────────────────────┘

Wave propagation:           Virtual particles:
┌────────────────────┐     ┌────────────────────┐
│     ╭───╮          │     │       ⊕⊖           │
│   ╭─╯   ╰─╮        │     │    ⊕⊖    ⊕⊖       │
│ ╭─╯       ╰─╮      │     │       ⊕⊖           │
└────────────────────┘     └────────────────────┘
  Ripples from source        Pair creation/annihilation
```

## Parameters

### Grid
| Export | Default | Description |
|--------|---------|-------------|
| `grid_size_x/z` | 50/50 | Field resolution |
| `spacing` | 0.3 | Point distance |
| `particle_size` | 0.08 | Visual size |

### Field Dynamics
| Export | Default | Description |
|--------|---------|-------------|
| `vacuum_fluctuation_strength` | 0.15 | Background noise |
| `wave_speed` | 2.0 | Propagation velocity |
| `wave_amplitude` | 1.5 | Wave height |
| `field_decay` | 0.3 | Energy dissipation |
| `time_scale` | 1.0 | Animation speed |

### Virtual Particles
| Export | Default | Description |
|--------|---------|-------------|
| `enable_virtual_particles` | true | Show pair creation |
| `virtual_particle_density` | 0.02 | Spawn rate |
| `virtual_particle_lifetime` | 0.3 | Existence duration |

### Wave Sources
| Export | Default | Description |
|--------|---------|-------------|
| `num_wave_sources` | 3 | Active sources |
| `source_frequency` | 1.5 | Oscillation rate |

### Visualization
| Export | Default | Description |
|--------|---------|-------------|
| `color_low` | Dark blue | Negative field value |
| `color_mid` | Cyan | Zero/neutral |
| `color_high` | Orange | Positive field value |
| `height_scale` | 2.0 | Vertical exaggeration |

## Physics Concepts

### Vacuum Fluctuations
Even at absolute zero, quantum fields fluctuate due to the uncertainty principle:
```
ΔE × Δt ≥ ℏ/2
```
Brief energy "borrowing" creates momentary disturbances.

### Virtual Particles
Particle-antiparticle pairs pop in and out:
- Created from vacuum fluctuation
- Exist for time ≤ ℏ/(2ΔE)
- Annihilate back into field

### Wave Propagation
Disturbances spread as waves, interfering constructively and destructively.

## Files

| File | Purpose |
|------|---------|
| `quantum_field.gd` | Field simulation |
| `*.tscn` | Scene file |

## Usage

```gdscript
var field = preload("res://algorithms/transformation/quantum_field/quantum_field.tscn").instantiate()
field.vacuum_fluctuation_strength = 0.3  # More activity
field.enable_virtual_particles = true
add_child(field)
```

## VR Experience

Stand above the quantum field. Watch it shimmer with vacuum fluctuations. See virtual particle pairs flash into existence and disappear. Wave sources send ripples that interfere. This is what "empty space" actually looks like at quantum scales — a seething foam of activity.

## See Also

- `wavefunctions/` — Wave mathematics
- `randomness/` — Stochastic processes
- `swarmintelligence/physarum/` — Field-like behavior
