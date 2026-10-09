# Four uses of a random draw

Read these works by following a sampled value into the operation that consumes it. Their shared use of random numbers does not make their outputs the same kind of process.

## A mark and a path

`algorithms/randomness/proceduralrandomness/movementbased/scenes/pollock2d/paint_dripping_2d.gd` draws into an `Image`. `_add_drip()` samples a position, palette index and radius. `_add_line()` begins at a sampled position and repeatedly turns a direction:

```gdscript
direction = direction.rotated(rng.randf_range(-line_curviness, line_curviness)).normalized()
var next_pos: Vector2 = points[-1] + direction * line_segment_length
```

Boundary checks reflect the direction when a step would leave the canvas. The resulting line segments are rasterized into the image; `stroke_path_generated` also sends their path to the 3D host. In `pollock_painting_in_3d.gd`, the host shows the SubViewport texture on a framed floor sprite and moves a cursor along that path. The gallery token chooses `#support:floor`.

This is a generative homage using marks and paths. There is no falling-paint collision calculation, and the visitor does not steer the cursor.

## A sample that contributes to an estimate

`algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd` draws two uniform coordinates in a unit square. `_throw_dart()` classifies the point against an inscribed circle, adds one to the total and, if inside, one to the inside count.

For a uniform square sampler:

`area(circle) / area(square) = pi / 4`

Therefore `4 × inside_count / total_count` estimates pi. An additional point can increase or decrease that estimate; convergence is not a promise of improvement after every throw. Sampling bias changes what the count measures.

The museum token selects `#disclosure:works` and `#controls:compact#control_front:1.0`. `museum_exhibit_stage.gd` relocates the existing button panel to a reachable console while preserving its signals. AUTO toggles continuous sampling; RESET clears the counts without toggling AUTO. Pause AUTO before making a sequence of individual THROW observations. The default maximum is 500 darts.

## A direction admitted by local rules

`algorithms/randomness/pipedream/PipeDream.gd` grows a path in six cardinal directions. `_choose_next_direction()` first gives straight-ahead motion a chance, then tests a shuffled list that excludes immediate reversal. `_is_outside_bounds()` rejects candidate endpoints beyond the configured box.

The default bounds extend ±6 m in x/z and ±4 m in y. Scaling the artifact to 0.25 gives a centreline volume 3 × 2 × 3 m; the pipe and joint radii add a small margin. Lifting its root 1.15 m keeps that volume above the gallery floor. `#residue:path` retains every segment of the run.

There is no occupancy set. The path can revisit earlier positions, and its 180-segment budget does not guarantee full coverage of the box. Changing that rule to reject visited cells would change the set of available choices at every later step.

## An update rule that changes with the chapter

`algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.gd` uses `#chapter:all` to cycle its five existing chapters. `start_demo()` restages the same particles at each transition; their update function then changes.

| Chapter | Procedure |
| --- | --- |
| Chaos | Add random forces to retained velocities, damp velocity and reflect particles at a radial boundary. |
| Noise | Sample a smooth field from the local `noise3()` helper, which is a product of sine and cosine terms rather than an implementation of Perlin noise. |
| Pattern | Combine spiral motion and oscillation with the opening sampled arrangement. |
| Emergence | Apply separation, alignment, cohesion and random nudges. |
| Evolution | Rank distance to a moving target; the leading tenth influence the other particles under the default selection rule. |

The particle count stays fixed. There is no reproduction, no heavy-tail sampler and no basis for interpreting all five chapters as independent uniform draws. The stage is a comparison of procedures, each with different dependencies and retained state.

The gallery token also opts into `#gallery_radius:7`. After restaging and each update, this boundary confines the entire particle sphere and reflects outward velocity. At scale 0.2 its diameter is 2.8 m, and the 1.5 m lift leaves a 0.1 m gap above the floor. The unconfigured artifact keeps its original behavior; the restored gallery is a bounded presentation of all five chapters.

Return to the room's question before entering Random Game: which variables may chance alter, and which constraints keep acting after the draw?
