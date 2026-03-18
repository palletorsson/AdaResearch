# Wet Paint Simulation

A canvas_item shader that simulates wet paint behavior — pigment flows downward under gravity, diffuses into neighboring pixels, and gradually dissipates toward white paper.

## How It Works

Each frame, the shader samples the screen texture at five points (center + four cardinal neighbors) with equal weights to produce a Gaussian-like blur. The sample coordinates are offset slightly upward (`-flow_speed`) to simulate gravity-driven flow. The blurred result is then mixed toward white by the `dissipation` factor, simulating paint drying over time.

## Parameters

| Uniform | Range | Default | Description |
|---------|-------|---------|-------------|
| `flow_speed` | 0.0–5.0 | 0.001 | Downward flow rate per frame |
| `dissipation` | 0.9–1.0 | 0.995 | Fade-to-white rate (higher = slower drying) |

## Files

- `wet_paint_simulation.gdshader` — Canvas-item shader implementing flow + diffusion + dissipation.
