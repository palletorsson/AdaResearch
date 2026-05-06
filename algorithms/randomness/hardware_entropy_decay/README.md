# Hardware Entropy Decay

A VR artifact that turns the player's own physical movements into a source of entropy that drives procedural surface decay. Controller velocity produces scratches, grip pressure accumulates grime, and head rotation feeds an entropy rate -- all rendered in real time through a custom decay shader applied to 3D display objects (cube, sphere, cylinder).

This artifact teaches that **hardware entropy** -- unpredictable physical inputs from the real world -- is a genuine source of randomness, unlike algorithmic pseudo-random generators. The player's body becomes the random number generator.

## How It Works

1. **Hardware Sampling**: Every frame, the script locates the XR origin, left/right controllers, and headset camera. It measures controller velocity (position delta / time delta), grip float values, and head angular velocity (basis rotation delta). If no VR hardware is detected, a time-based sinusoidal fallback provides simulated entropy.

2. **Decay Parameters**: The hardware readings are mapped to four decay channels:
   - **Scratch intensity** = controller velocity * `velocity_to_scratch` (fast hand movements create scratches)
   - **Grime buildup** = accumulated grip pressure over time (holding tight builds grime)
   - **Entropy rate** = head angular speed * `head_to_entropy` (looking around drives weathering)
   - **Overall decay** = passive background rate + boosted rate during active interaction

3. **Touch UV**: The dominant controller's position is mapped into UV space relative to the artifact, creating a localized decay hotspot that follows the player's hand.

4. **Shader Pipeline**: A custom `hardware_decay.gdshader` receives five uniforms (`decay_amount`, `scratch_intensity`, `grime_buildup`, `entropy_rate`, `touch_uv`). The shader computes:
   - Organic rust/corrosion via FBM noise masked by decay amount
   - Grime accumulation with gravity bias (settles toward UV bottom)
   - Directional scratch patterns using multi-layer rotated line noise
   - Edge wear at UV boundaries
   - Touch-localized intensification around the controller position
   - Entropy-driven micro-grain from hash noise
   - Normal map perturbation for physical depth
   - Hot-spot emission at freshly decayed areas

5. **Display Objects**: Multiple geometric shapes (box, sphere, cylinder, optionally torus and prism) sit on pedestals. Each receives the same shader material, letting the viewer compare how decay manifests on different surface geometries.

6. **Readout Panel**: A floating panel shows real-time hardware values (velocity, grip, head rotation) alongside computed decay percentages and cumulative statistics.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `velocity_to_scratch` | float | 0.35 | How much controller speed feeds scratch intensity |
| `grip_to_grime` | float | 0.12 | How fast grip accumulates grime |
| `head_to_entropy` | float | 0.25 | How head movement drives entropy |
| `passive_decay_rate` | float | 0.002 | Background decay per second |
| `interaction_decay_boost` | float | 0.015 | Extra decay when actively interacting |
| `decay_smoothing` | float | 3.5 | Lerp speed for visual smoothing |
| `panel_count` | int | 3 | Number of display objects |
| `panel_spacing` | float | 1.4 | Distance between display objects |
| `pedestal_height` | float | 0.7 | Height of pedestals |
| `show_readouts` | bool | true | Show the readout panel |
| `base_surface_color` | Color | (0.65, 0.68, 0.72) | Clean surface color |
| `rust_color` | Color | (0.45, 0.18, 0.05) | Rust/corrosion color |
| `dirt_color` | Color | (0.22, 0.18, 0.12) | Grime/dirt color |

## Features

- Real VR hardware entropy: controller velocity, grip pressure, head angular velocity
- Non-VR fallback with time-based sinusoidal simulation
- Custom spatial shader with FBM noise, directional scratch patterns, and gravity-biased grime
- Touch-localized decay follows the dominant controller's position
- Normal map perturbation for physical surface depth
- Multiple display geometries for comparative decay visualization
- Live readout panel with color-coded hardware input values
- VR push-button controls for RESET and PAUSE
- Slow rotation and gentle bobbing animation on display objects
- Source indicator showing whether VR hardware or simulated entropy is active

## Files

| File | Description |
|------|-------------|
| `hardware_entropy_decay.gd` | Main script -- VR sampling, decay logic, scene construction, readouts |
| `hardware_decay.gdshader` | Spatial shader -- FBM rust, scratch patterns, grime, edge wear, touch UV |
| `hardware_entropy_decay.tscn` | Scene file |
