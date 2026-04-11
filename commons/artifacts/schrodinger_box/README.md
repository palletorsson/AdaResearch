# Schrodinger's Box

A visualization of the Schrodinger's cat thought experiment, demonstrating quantum superposition and wavefunction collapse. The box holds a superposition state until the user observes it, at which point the state randomly collapses to one of two outcomes.

## How It Works

The box begins in a superposition state, displayed with a pulsing purple glow and the ket notation |psi> = alpha|alive> + beta|dead>. When the user clicks (desktop) or interacts (VR), the wavefunction collapses: the lid animates open via a tween, and the outcome is randomly chosen as either alive (glowing green sphere) or dead (flat gray box). After a configurable auto-reset timer, the box closes and returns to superposition. Signals are emitted on box opening, state collapse, and superposition re-entry.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `box_size` | Vector3 | `Vector3(0.4, 0.3, 0.3)` |
| `current_state` | State enum | `SUPERPOSITION` |
| `auto_reset_time` | float | `5.0` |

## Features

- Three states: Superposition, Alive, and Dead with distinct visual representations
- Animated lid opening and closing via tweens
- Pulsing superposition glow with oscillating alpha and emission
- Quantum notation labels (ket notation for superposition, collapsed state labels)
- Automatic reset to superposition after configurable delay
- Signals for box_opened, state_collapsed, and superposition_entered
- Desktop mouse click and VR-aware input handling

## Files

- `schrodinger_box.gd` -- Main script
- `schrodinger_box.tscn` -- Scene file
