# Nature of Code VR Translation Plan

This document catalogs every Nature of Code example in `content/examples`, noting core methods, supporting tools, constructs, agents, and a proposed 3D or VR adaptation concept. It closes with a roadmap for porting the 2D sketches into immersive set pieces.

## Global Constraints
- No 2D UI layers; all interactions occur directly within the volumetric scene.
- Exclude VR controller models or bespoke rigs; rely on the existing player embodiment.
- Assume the VR player stands on `res://commons/scenes/grid.tscn` for every translated example.
- Translate chapters in alternating order starting from Chapter 11 and stepping backward by two (11, 9, 7, 5, 3, 1).
- Stage each VR scene inside a 1 m x 1 m transparent fish-tank boundary anchored to the grid floor.
- Use a light queer pink palette for core visual accents and feedback cues.
- When interactive parameter controls are required, duplicate `res://commons/primitives/line/line.tscn` and evolve it into a matching 3D controller widget.
- After porting each example, run it end-to-end, fix any defects, and document the results.

## Architecture Highlights
- All VR translations inherit from `res://commons/scenes/grid.tscn`, attaching bespoke nodes under the shared `GridScene` mount point.
- Maintain the modular directory layout established in AdaResearch (core systems, algorithms per chapter, spatial UI widgets, utilities) to keep code reusable.
- Base simulation actors on a reusable `VREntity` class that encapsulates position, velocity, acceleration, and mesh/material setup for fast prototyping.
- Keep spatial UI elements inside `spatial_ui/` primitives (sliders, buttons, info labels) so every example uses the same interaction vocabulary.

## Implementation Phases
1. **Preflight (Week 0):** Confirm Godot XR template, fish-tank prefab, and light pink material library; seed the `/docs/progress/` log.
2. **Audit, Test, and Tag (Week 1):** Execute original p5.js sketches, log outcomes, and prioritise reverse alternating chapters (11, 9, 7, 5, 3, 1).
3. **Foundation Systems (Weeks 2-3):** Build core reusable scripts (`vr_entity.gd`, `force_system.gd`, `particle_system.gd`, `noise.gd`, spatial controller variants).
4. **Chapter Batches (Weeks 4-10):** Port examples in the reverse alternating sequence (11 -> 9 -> 7 -> 5 -> 3 -> 1), validating each inside the 1x1x1 m fish tank and documenting fixes.
5. **Advanced Showcase (Weeks 11-12):** Integrate neuroevolution highlights (GA + NN) and fractal gardens into cohesive arenas.
6. **Stabilisation (Weeks 13-14):** Optimise performance toward 90 FPS, refine visuals, and finalise educational annotations.

## Core Systems Design
- **VREntity Pattern:** Shared base node handles integration of forces, movement, and transformation updates for any simulated agent.
- **VRParticleSystem:** Pools and updates particles within the fish tank, exposing emission rate, lifespan, and material parameters through pink-tinted controllers.
- **Force and Flow Field Utilities:** Centralised scripts calculate steering, Perlin flow vectors, and apply constraints against the tank walls.
- **Spatial Controller Template:** Duplicate `res://commons/primitives/line/line.tscn`, extrude into sliders or dials, and pair with `Label3D` readouts for parameter tweaking.

## VR Interaction Guidelines
- Present all metrics, labels, and manipulators as floating 3D elements; never fall back to 2D CanvasLayers.
- Constrain every simulation to the transparent 1 m cubed fish tank for consistent scale anchoring.
- Accent movers, trails, and data glyphs with the light queer pink palette (`#FFC0E6`, `#E680CC`, `#FF99FF`) to maintain visual continuity.
- Use controller-agnostic gestures (grab, poke, hover) and rely on the existing player rig provided by `grid.tscn`.

## Progress and Success Metrics
- Update `docs/progress/progress_log.md` after each example with build state, test results, and outstanding fixes.
- Track frame timing inside Godot to ensure each scene sustains 90 FPS with headroom on target hardware.
- Log educational observations (clarity, engagement cues) so instructors can evaluate the VR enhancement impact.

## Snapshot Metrics
- Total examples analysed: 157
- Technique coverage (top 10):
  - Vector algebra and kinematics: 76 examples
  - Stochastic sampling and random processes: 71 examples
  - Force accumulation and Newtonian motion: 58 examples
  - Particle system dynamics: 33 examples
  - Trigonometric oscillation: 20 examples
  - Autonomous steering behaviors: 15 examples
  - Perlin noise field sampling: 13 examples
  - Recursive or fractal generation: 11 examples
  - Rigid-body physics via Matter.js: 10 examples
  - Genetic algorithm search: 8 examples

## 00.5 Introduction

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| Nature Of Code Example Template | Stochastic sampling and random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |

## 00 Randomness

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| Example I 1 Random Walk Traditional | Stochastic sampling and random processes | p5.js | Walker | Walker | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example I 2 Random Distribution | Stochastic sampling and random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example I 3 Random Walk Tends To Right | Stochastic sampling and random processes | p5.js | Walker | Walker | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example I 4 Gaussian Distribution | Random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example I 5 Accept Reject Distribution | Stochastic sampling and random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example I 6 Perlin Noise Walker | Perlin noise field sampling | p5.js | Walker | Walker | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. |
| Exercise 0 1 Solution Skewed Random Walker | Stochastic sampling and random processes | p5.js | Walker | Walker | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 0 3 Solution Random Walk Towards Mouse | Stochastic sampling and random processes | p5.js | Walker | Walker | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 0 4 Solution Paint Splatter | Random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 0 5 Solution Gaussian Random Walker | Random processes | p5.js | Walker | Walker | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 0 6 Solution Quadratic Random Walker | Stochastic sampling and random processes | p5.js | Walker | Walker | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 0 7 Solution Perlin Noise Walker | Perlin noise field sampling | p5.js | Walker | Walker | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. |
| Exercise 0 8 Solution 2 D Noise Parameterized | Perlin noise field sampling; Stochastic sampling and random processes | p5.js | None | None | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 0 9 Solution 2 D Noise Animated | Perlin noise field sampling; Stochastic sampling and random processes | p5.js | None | None | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise I 10 Noise Terrain | Perlin noise field sampling; p5.js WEBGL rendering | p5.js, p5.js WEBGL mode | Terrain | Terrain | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. Also: Port shaders to stereoscopic meshes so players can step inside the visual effect. |
| Figure 0 2 Bell Curve High | Random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Figure 0 2 Bell Curve Low | Random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Figure I 11 Tree Stochastic Noise | Recursive or fractal generation; Perlin noise field sampling; Stochastic sampling and random processes | p5.js | None | None | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. Also: Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| Figure I 12 Flow Field With Perlin Noise | Force accumulation and Newtonian motion; Perlin noise field sampling; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | FlowField, Vehicle | FlowField, Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Figure I 4 Noise | Perlin noise field sampling | p5.js | None | None | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. |
| Figure I 5 Random | Stochastic sampling and random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Figure I Noise 2 D | Perlin noise field sampling | p5.js | None | None | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. |

## 01 Vectors
> Detailed VR translation breakdown: see `docs/progress/ch01_vr_translation_notes.md`

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| Example 1 1 Bouncing Ball With No Vectors | Vector math | p5.js | None | None | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 1 10 Accelerating Towards The Mouse | Vector algebra and kinematics | p5.js | Mover | Mover | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 1 2 Bouncing Ball With Vectors | Vector algebra and kinematics | p5.js | None | None | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 1 3 Vector Subtraction | Vector algebra and kinematics | p5.js | None | None | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 1 4 Vector Multiplication | Vector algebra and kinematics | p5.js | None | None | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 1 5 Vector Magnitude | Vector algebra and kinematics | p5.js | None | None | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 1 6 Vector Normalize | Vector algebra and kinematics | p5.js | None | None | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 1 7 Motion 101 Velocity | Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Mover | Mover | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example 1 8 Motion 101 Velocity And Constant Acceleration | Vector algebra and kinematics | p5.js | Mover | Mover | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 1 9 Motion 101 Velocity And Random Acceleration | Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Mover | Mover | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 1 3 Solution 3 D Bouncing Ball | Vector algebra and kinematics; p5.js WEBGL rendering | p5.js, p5.js WEBGL mode | Ball | Ball | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. Also: Port shaders to stereoscopic meshes so players can step inside the visual effect. |
| Exercise 1 5 Solution Accelerate And Decelerate | Vector algebra and kinematics | p5.js | CodingTrain | CodingTrain | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Exercise 1 8 Solution Attraction Magnitude | Vector algebra and kinematics | p5.js | Mover | Mover | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |

## 02 Forces

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| Example 2 1 Forces | Force accumulation and Newtonian motion; Vector algebra and kinematics | p5.js | Mover | Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 2 2 Forces Acting On Two Objects | Force accumulation and Newtonian motion; Vector algebra and kinematics | p5.js | Mover | Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 2 3 Gravity Scaled By Mass | Force accumulation and Newtonian motion; Vector algebra and kinematics | p5.js | Mover | Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 2 4 Including Friction | Force accumulation and Newtonian motion; Vector algebra and kinematics | p5.js | Mover | Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 2 5 Fluid Resistance | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Liquid, Mover | Liquid, Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example 2 6 Attraction | Force accumulation and Newtonian motion; Vector algebra and kinematics | p5.js | Attractor, Mover | Attractor, Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 2 7 Attraction With Many Movers | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Attractor, Mover | Attractor, Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example 2 8 Two Body Attraction | Force accumulation and Newtonian motion; Vector algebra and kinematics | p5.js | Body | Body | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 2 9 N Bodies | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Body | Body | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 2 16 | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Mover | Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Nature Of Code Exercise 2 1 Solution | Force accumulation and Newtonian motion; Perlin noise field sampling; Vector algebra and kinematics | p5.js | Balloon | Balloon | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. |

## 03 Oscillation
> Detailed VR translation breakdown: see `docs/progress/ch03_vr_translation_notes.md`

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| Example 1 10 Accelerating Towards The Mouse | Vector algebra and kinematics | p5.js | Mover | Mover | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 3 1 Angular Motion Using Rotate | Oscillation systems | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 10 Swinging Pendulum | Force accumulation and Newtonian motion; Trigonometric oscillation; Vector algebra and kinematics | p5.js | Pendulum | Pendulum | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 11 A Spring Connection | Force accumulation and Newtonian motion; Vector algebra and kinematics | p5.js | Bob, Spring | Bob, Spring | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 3 2 Forces With Arbitrary Angular Motion | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Attractor, Mover | Attractor, Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example 3 3 Pointing In The Direction Of Motion | Vector algebra and kinematics | p5.js | Mover | Mover | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 3 4 Polar To Cartesian | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 5 Simple Harmonic Motion | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 6 Simple Harmonic Motion Ii | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 7 Oscillator Objects | Trigonometric oscillation; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Oscillator | Oscillator | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Example 3 8 Static Wave | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 9 The Wave | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 9 The Wave A | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 9 The Wave B | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 3 9 The Wave C | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Exercise 3 1 Baton | Oscillation systems | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Exercise 3 11 Oop Wave | Trigonometric oscillation; Vector algebra and kinematics | p5.js | Wave | Wave | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Exercise 3 12 Additive Wave | Trigonometric oscillation; Stochastic sampling and random processes | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 3 15 Double Pendulum | Trigonometric oscillation; p5.js WEBGL rendering | p5.js, p5.js WEBGL mode | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. Also: Port shaders to stereoscopic meshes so players can step inside the visual effect. |
| Exercise 3 5 Spiral | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Exercise 3 6 Asteroids | Force accumulation and Newtonian motion; Vector algebra and kinematics | p5.js | Spaceship | Spaceship | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |

## 04 Particles

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| 4 1 Single Particle | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Particle | Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 4 2 Array Particles | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Particle | Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 4 3 Particle Emitter | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 4 4 Emitters 1 | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 4 4 Emitters 2 | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 4 4 Multiple Emitters | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 4 4 Multiple Emitters 0 | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 4 6 Particle System Forces | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Example 4 7 Particle System With Repeller | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Emitter, Particle, Repeller | Emitter, Particle, Repeller | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Example 4 8 Image Texture System Smoke | Force accumulation and Newtonian motion; Particle system dynamics; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Exercise 4 12 Particle Textures Array | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Particle, ParticleSystem | Particle, ParticleSystem | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Exercise 4 4 Asteroids | Force accumulation and Newtonian motion; Particle system dynamics; Vector algebra and kinematics | p5.js | Particle, ParticleSystem, Spaceship | Particle, ParticleSystem, Spaceship | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Exercise 4 6 Particle Shatter | Force accumulation and Newtonian motion; Particle system dynamics; Vector algebra and kinematics | p5.js | Particle, ParticleSystem | Particle, ParticleSystem | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Figure 4 8 Circles | Force accumulation and Newtonian motion; Particle system dynamics; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Figure 4 8 Image | Force accumulation and Newtonian motion; Particle system dynamics; Vector algebra and kinematics | p5.js | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 4 05 Particle System Inheritance Polymorphism | Force accumulation and Newtonian motion; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js | Confetti, Emitter, Particle | Confetti, Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 4 08 Particle System Smoke Webgl | Force accumulation and Newtonian motion; Particle system dynamics; Vector algebra and kinematics; p5.js WEBGL rendering | p5.js, p5.js WEBGL mode | Emitter, Particle | Emitter, Particle | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |

## 05 Steering
> Detailed VR translation breakdown: see `docs/progress/ch05_vr_translation_notes.md`


| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| 5 11 Quadtree Part 1 | Steering behaviors | p5.js | Point, QuadTree, Rectangle | Point, QuadTree, Rectangle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. |
| 5 6 Path Segments Only | Vector algebra and kinematics | p5.js | Path | Path | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Example 5 12 Sine Cosine Lookup Table | Trigonometric oscillation | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Example 5 9 Flocking | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Boid, Flock | Boid, Flock | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Example 5 9 Flocking With Binning | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Boid, Flock | Boid, Flock | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Exercise 5 13 Crowd Path Following | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Path, Vehicle | Path, Vector, Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Exercise 5 2 | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Target, Vehicle | Target, Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Exercise 5 4 Wander | Force accumulation and Newtonian motion; Trigonometric oscillation; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Vehicle | Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Exercise 5 9 Angle Between | Vector algebra and kinematics | p5.js | None | None | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Nature Of Code Example 5 5 Path Only | Vector algebra and kinematics | p5.js | Path | Path | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| Noc 5 01 Seek | Force accumulation and Newtonian motion; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Vehicle | Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 5 02 Arrive | Force accumulation and Newtonian motion; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Vehicle | Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 5 03 Stay Within Walls | Force accumulation and Newtonian motion; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Vehicle | Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 5 04 Flow Field | Force accumulation and Newtonian motion; Perlin noise field sampling; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | FlowField, Vehicle | FlowField, Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 5 05 Path Following Simple | Force accumulation and Newtonian motion; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Path, Vehicle | Path, Vector, Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 5 07 Separation | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Vehicle | Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 5 08 Path Following | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Path, Vehicle | Path, Vector, Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Noc 5 08 Separation And Seek | Force accumulation and Newtonian motion; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js | Vehicle | Vehicle | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |

## 06 Libraries and Physics

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| 6 1 Default Matter Js | Force accumulation and Newtonian motion; Rigid-body physics via Matter.js | p5.js, Matter.js | None | None | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 6 10 Collision Events | Rigid-body physics via Matter.js; Particle system dynamics; Stochastic sampling and random processes | p5.js, Matter.js | Boundary, Particle | Boundary, Particle | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. |
| 6 11 Simple Spring With Toxiclibs | Particle system dynamics | p5.js | Particle | GravityBehavior, Particle, Rect, Vec2D, VerletPhysics2D, VerletSpring2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. |
| 6 12 Soft String | Particle system dynamics | p5.js | Particle | GravityBehavior, Particle, Rect, Vec2D, VerletPhysics2D, VerletSpring2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. |
| 6 13 Force Directed Graph | Particle system dynamics; Stochastic sampling and random processes | p5.js | Cluster, Particle | Cluster, Particle, VerletPhysics2D, VerletSpring2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 6 14 Attraction Behaviors | Particle system dynamics; Stochastic sampling and random processes | p5.js | Attractor, Particle | AttractionBehavior, Attractor, Particle, Rect, VerletPhysics2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 6 2 Boxes Exercise | Physics and auxiliary libraries | p5.js | Box | Box | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 6 3 Boxes And Boundaries | Rigid-body physics via Matter.js; Stochastic sampling and random processes | p5.js, Matter.js | Boundary, Box | Boundary, Box | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 6 4 Polygon Shapes | Rigid-body physics via Matter.js; Stochastic sampling and random processes | p5.js, Matter.js | Boundary, CustomShape | Boundary, CustomShape | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 6 5 Compound Bodies | Force accumulation and Newtonian motion; Rigid-body physics via Matter.js; Stochastic sampling and random processes | p5.js, Matter.js | Boundary, Lollipop | Boundary, Lollipop | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 6 5 Compound Bodies Error | Rigid-body physics via Matter.js; Stochastic sampling and random processes | p5.js, Matter.js | Boundary, Lollipop | Boundary, Lollipop | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 6 6 Matter Js Pendulum | Physics and auxiliary libraries | p5.js | Pendulum | Pendulum | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 6 7 Windmill | Rigid-body physics via Matter.js; Particle system dynamics; Stochastic sampling and random processes | p5.js, Matter.js | Particle, Windmill | Particle, Windmill | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. |
| 6 8 Mouse Constraint | Physics and auxiliary libraries | p5.js | Boundary, Box | Boundary, Box | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 6 9 Matter Js Attraction | Force accumulation and Newtonian motion; Trigonometric oscillation; Stochastic sampling and random processes | p5.js | Attractor, Mover | Attractor, Mover | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Exercise 6 10 Cloth Simulation | Force accumulation and Newtonian motion; Particle system dynamics | p5.js | Particle, Spring | GravityBehavior, Particle, Spring, Vec2D, VerletPhysics2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Exercise 6 11 Soft Body Character Enhanced | Particle system dynamics | p5.js | Particle, Spring | Particle, Rect, Spring, VerletPhysics2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. |
| Exercise 6 13 Force Directed Graph | Particle system dynamics; Stochastic sampling and random processes | p5.js | Cluster, Particle | ArrayList, Cluster, Particle, VerletMinDistanceSpring2D, VerletPhysics2D, VerletSpring2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 6 2 Boxes | Rigid-body physics via Matter.js | p5.js, Matter.js | Box | Box | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. |
| Exercise 6 5 Bridge | Rigid-body physics via Matter.js; Particle system dynamics; Stochastic sampling and random processes | p5.js, Matter.js | Box, Bridge | Box, Bridge | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. |
| Exercise 6 7 Windmill Motor | Force accumulation and Newtonian motion; Rigid-body physics via Matter.js; Particle system dynamics; Stochastic sampling and random processes | p5.js, Matter.js | Particle, Windmill | Particle, Windmill | Upgrade rigid bodies to full 3D physics and let tracked hands grab or toss simulated props. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| Figure 6 18 | Particle system dynamics; Stochastic sampling and random processes | p5.js | Cluster, Particle | ArrayList, Cluster, Particle, VerletMinDistanceSpring2D, VerletPhysics2D, VerletSpring2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Soft Body Character Copy | Particle system dynamics | p5.js | Particle, Spring | GravityBehavior, Particle, Rect, Spring, Vec2D, VerletPhysics2D | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. |

## 07 Cellular Automata
> Detailed VR translation breakdown: see `docs/progress/ch07_vr_translation_notes.md`


| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| 7 1 Elementary Wolfram Ca | Cellular automata | p5.js | None | None | Wrap CA grids around spheres or walls and let fingertip touches toggle states in real time. |
| 7 2 Game Of Life | Stochastic sampling and random processes | p5.js | None | None | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 7 3 Game Of Life Oop | Stochastic sampling and random processes | p5.js | Cell | Cell | Fill the air with random walkers; players bias probability distributions by moving their hands. |
| Exercise 7 8 Hexagon Ca | Trigonometric oscillation; Stochastic sampling and random processes | p5.js | None | None | Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |

## 08 Fractals

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| 8 1 Recursion | Recursive or fractal generation | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| 8 2 Recursion | Recursive or fractal generation | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| 8 3 Recursion Circles | Recursive or fractal generation | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| 8 4 Cantor Set | Recursive fractals | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| 8 5 Koch Curve | Recursive or fractal generation; Vector algebra and kinematics | p5.js | KochLine | KochLine | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| 8 6 Tree | Recursive or fractal generation | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| 8 7 Stochastic Tree | Recursive or fractal generation; Stochastic sampling and random processes | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 8 8 L System String Only | Recursive fractals | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| Example 8 9 L System | Recursive or fractal generation | p5.js | LSystem, Turtle | LSystem, Turtle | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| Exercise 8 1 Fractal Lines | Recursive fractals | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| Exercise 8 2 Koch Snowflake | Recursive or fractal generation; Trigonometric oscillation; Vector algebra and kinematics | p5.js | KochLine | KochLine | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. Also: Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| Exercise 8 7 Branch Thickness | Recursive or fractal generation | p5.js | None | None | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. |
| Exercise 8 8 Branch Objects Animation | Recursive or fractal generation; Vector algebra and kinematics | p5.js | Branch, Leaf | Branch, Leaf | Grow branching fractals from the floor and ceiling; two-hand gestures scale or twist the structure. Also: Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |

## 09 Genetic Algorithms
> Detailed VR translation breakdown: see `docs/progress/ch09_vr_translation_notes.md`


| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| 9 1 Ga Shakespeare | Genetic algorithm search; Stochastic sampling and random processes | p5.js, Custom GA toolkit | DNA | DNA | Evolve 3D creatures in an arena while the player selects favorites via gaze or hand ray selection. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 9 2 Smart Rockets Basic | Force accumulation and Newtonian motion; Genetic algorithm search; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js, Custom GA toolkit | DNA, Population, Rocket | DNA, Population, Rocket | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 9 3 Smart Rockets | Force accumulation and Newtonian motion; Genetic algorithm search; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js, Custom GA toolkit | DNA, Obstacle, Population, Rocket | DNA, Obstacle, Population, Rocket | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 9 4 Interactive Selection | Genetic algorithm search; Trigonometric oscillation; Stochastic sampling and random processes | p5.js, Custom GA toolkit | DNA, Flower, Population, Rectangle | DNA, Flower, Population, Rectangle | Evolve 3D creatures in an arena while the player selects favorites via gaze or hand ray selection. Also: Suspend pendulums and springs in space so players can pluck or displace them for tactile oscillations. |
| 9 5 Evolving Bloops | Genetic algorithm search; Perlin noise field sampling; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js, Custom GA toolkit | Bloop, DNA, Food, World | Bloop, DNA, Food, World | Visualize a 3D noise flow as ribbons or fog that bends when a controller probe moves through it. Also: Evolve 3D creatures in an arena while the player selects favorites via gaze or hand ray selection. |
| Exercise 9 6 Annotated Ga Shakespeare | Genetic algorithm search; Stochastic sampling and random processes | p5.js, Custom GA toolkit | DNA, Population | DNA, Population | Evolve 3D creatures in an arena while the player selects favorites via gaze or hand ray selection. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |

## 10 Neural Networks

| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| 10 1 Perceptron With Normalization | Neural network inference or training; Stochastic sampling and random processes | p5.js, Custom neural net helpers | Perceptron | Perceptron | Lay out neurons as glowing 3D nodes so users can feed sample inputs and watch activations travel. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 10 2 Gesture Classifier | ml5.js machine learning utilities; Neural network inference or training; Vector algebra and kinematics | p5.js, ml5.js, Custom neural net helpers | None | None | Lay out neurons as glowing 3D nodes so users can feed sample inputs and watch activations travel. Also: Project live ML classification overlays on floating canvases the user can draw on with controllers. |

## 11 Neuroevolution
> Detailed VR translation breakdown: see `docs/progress/ch11_vr_translation_notes.md`


| Example | Methods | Tools | Constructs | Agents | VR translation concept |
| --- | --- | --- | --- | --- | --- |
| 11 1 Flappy Bird | Force accumulation and Newtonian motion; Stochastic sampling and random processes | p5.js | Bird, Pipe | Bird, Pipe | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Fill the air with random walkers; players bias probability distributions by moving their hands. |
| 11 2 Flappy Bird Neuro Evolution | Force accumulation and Newtonian motion; ml5.js machine learning utilities; Neural network inference or training; Stochastic sampling and random processes | p5.js, ml5.js, Custom neural net helpers | Bird, Pipe | Bird, Pipe | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Project live ML classification overlays on floating canvases the user can draw on with controllers. |
| 11 3 Smart Rockets Neuro Evolution | Force accumulation and Newtonian motion; Genetic algorithm search; ml5.js machine learning utilities; Neural network inference or training; Particle system dynamics; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js, Custom GA toolkit, ml5.js, Custom neural net helpers | Obstacle, Population, Rocket | Obstacle, Population, Rocket | Spawn volumetric emitters the player can walk through, adjusting emission rate and gravity live. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 11 4 Neuro Evolution Steering Seek | Force accumulation and Newtonian motion; Genetic algorithm search; ml5.js machine learning utilities; Neural network inference or training; Perlin noise field sampling; Stochastic sampling and random processes; Autonomous steering behaviors; Vector algebra and kinematics | p5.js, Custom GA toolkit, ml5.js, Custom neural net helpers | Creature, Glow, Population | Creature, Glow, Rocket | Fill the volume with flocking agents and let players paint flow fields or targets with controllers. Also: Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. |
| 11 5 Creature Sensors | Vector algebra and kinematics | p5.js | Creature, Food, Sensor | Creature, Food, Sensor | Render 3D arrows that align with controller orientation to teach addition, subtraction, and normalization. |
| 11 6 Neuroevolution Ecosystem | Force accumulation and Newtonian motion; ml5.js machine learning utilities; Neural network inference or training; Stochastic sampling and random processes; Vector algebra and kinematics | p5.js, ml5.js, Custom neural net helpers | Creature, Food, Sensor | Creature, Food, Sensor | Show force vectors as 3D arrows and give players tethers to push, pull, or pin masses. Also: Project live ML classification overlays on floating canvases the user can draw on with controllers. |

## Execution Roadmap
1. **Audit, Test, and Tag (Week 1):** Run each p5.js sketch, fix any defects, document the outcome, and prioritize scenes for VR impact using the chapter tables above.
2. **Prototype VR Sandbox (Week 2):** Stand up a reusable Godot or Unity OpenXR template with shared systems for input, interactable gizmos, particle emitters, and shader-driven skyboxes.
3. **Core Systems Port (Weeks 3-5):** Implement reusable 3D equivalents for vectors, forces, particle systems, flow fields, and neural or genetic visualizers.
4. **Chapter Conversions (Weeks 6-12):** Convert one thematic chapter at a time, reusing prefabs and ensuring each scene presents a unique VR interaction hook such as grabbing, sculpting, or gaze-driven control.
5. **Neuroevolution Showcase (Weeks 13-14):** Merge GA and NN demos into an interactive ecosystem where evolved agents inhabit a 3D arena around the player.
6. **Polish and Performance (Weeks 15-16):** Optimize shaders and physics, add comfort options (teleport, vignette), and document usage patterns for educators and developers.

### Immediate Next Steps
- Stand up a shared progress log to capture per-example test status and fixes.
- Choose the target VR runtime (e.g., Godot OpenXR, Unity XR, or WebXR) and confirm deployment platforms.
- Select three flagship sketches (for example flow-field flocking, fractal garden, neuroevolution arena) for vertical-slice prototypes.
- Establish an asset pipeline for procedural meshes, particle materials, and spatial audio cues tied to simulation states.




