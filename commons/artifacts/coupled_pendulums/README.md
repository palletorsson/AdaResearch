# Coupled Pendulums

Two pendulums connected by a spring that demonstrates energy transfer between coupled oscillators. Teaches normal modes, beat phenomena, and how coupling strength controls the rate of energy exchange.

## How It Works

Each pendulum obeys the equation of motion with a gravity term, a coupling spring force proportional to the angle difference, and linear damping. Semi-implicit Euler integration advances the system. Energy bars beside each pendulum grow and shrink to visualize kinetic + potential energy flowing back and forth. A VR slider controls the coupling constant k: weak coupling produces slow energy beats, strong coupling produces rapid synchronization. Four preset buttons demonstrate specific regimes: beats, synchronization, weak coupling, and chaotic behavior.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `pendulum_length` | float | `0.5` |
| `bob_radius` | float | `0.04` |
| `rod_thickness` | float | `0.008` |
| `gravity` | float | `9.8` |
| `coupling_strength` | float | `2.0` |
| `damping` | float | `0.02` |
| `initial_angle_1` | float | `30.0` |
| `initial_angle_2` | float | `0.0` |
| `color_pendulum_1` | Color | `(1.0, 0.3, 0.3)` |
| `color_pendulum_2` | Color | `(0.3, 0.5, 1.0)` |
| `color_spring` | Color | `(0.8, 0.8, 0.3)` |
| `color_energy` | Color | `(0.3, 1.0, 0.5)` |

## Features

- Two-pendulum spring-coupled system with real-time physics simulation
- Dynamic energy bars visualizing per-pendulum energy in real time
- VR coupling-strength slider and four preset buttons (BEATS, SYNC, WEAK, CHAOS)
- Spring visual with color intensity proportional to coupling strength
- Info label showing current coupling constant and total system energy
- Keyboard shortcuts for presets and coupling adjustment

## Files

- `coupled_pendulums.gd` -- Main script
- `coupled_pendulums.tscn` -- Scene file
