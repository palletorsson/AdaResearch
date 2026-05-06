# Gradient Descent Sandbox


## Folder Summary

The `Gradient Descent Sandbox` module provides a 3D sandbox for exploring the ideas behind the Gradient Descent Sandbox workflows. It invites visitors to tune parameters, watch spatial feedback evolve in real time, and connect the algorithm's theory to an intuitive scene.

It ships with the scene file `gradient_descent.tscn`, controller scripts such as `GradientDescentDemo.gd` and `gradient_descent_tutorial.gd`, and supporting assets including `code_prompt.txt` and `meta.json`.

## Scene Assets
- `gradient_descent.tscn` - root scene with camera, light, terrain mesh, path/gradient renderers, and HUD label.
- `GradientDescentDemo.gd` - controller script that builds the noise surface and runs the iterative descent.
- `code_prompt.txt` - instructions for regenerating the controller with an AI assistant.
- `gradient_descent_tutorial.gd` - in-world BBCode tutorial card.
- `meta.json` - catalog entry for menus/search.

## How It Works
1. `_generate_terrain()` builds a grid of vertices using `FastNoiseLite` so the heightfield acts as a cost surface.
2. `reset_descent()` positions the walker on the plane (optionally randomised) and clears any previous path.
3. Each step estimates the gradient via central differences (sampling the height function along X/Z), then subtracts `learning_rate * gradient` from the position.
4. The walker is re-projected onto the surface, the path line extends, and a red gradient line visualises the local slope.
5. Descent stops after `max_steps` or when the gradient magnitude drops below `stop_gradient_magnitude`.

## Exported Controls
- `grid_resolution`, `grid_size`, `height_scale` - control terrain density and scale.
- `noise_frequency`, `noise_octaves`, `noise_lacunarity`, `noise_gain`, `noise_seed` - shape the underlying heightfield.
- `walker_start` - initial XZ coordinates for the walker.
- `learning_rate`, `step_interval`, `gradient_sample_distance`, `max_steps`, `stop_gradient_magnitude` - optimisation behaviour.
- `show_gradient`, `gradient_visual_scale` - gradient line visualisation.

### Helper Methods
- `reset_descent(randomise := true)` - clear the trail and optionally randomise the starting position.
- `_perform_descent_step()` - executes one optimisation tick (called automatically).
- `_update_info_label()` - updates the HUD with step count, slope magnitude, and state.

## Usage Tips
- Increase `learning_rate` for larger jumps or decrease it to show slower convergence.
- Change `walker_start` to drop the walker near different basins.
- Toggle `show_gradient` to focus on the path trail.
- Randomise `noise_seed` to showcase how local minima change.
- Invoke `reset_descent()` repeatedly to compare trajectories from new starting points.

## Extending Ideas
- Hook a UI slider to `learning_rate` or `step_interval` for interactive pacing.
- Add a heatmap overlay or contour lines from the height samples.
- Spawn multiple walkers with different rates to compare convergence behaviour.
