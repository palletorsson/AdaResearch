# Core

> Physics and particle simulation engines

## Overview

Core provides base classes and engines for algorithm visualizations. These are reusable building blocks for physics simulations, particle systems, and agent behaviors.

## Structure

```
core/
├── physics/              # Force calculations, constraints
├── particle.gd           # Base particle class
├── particle_body.gd      # Particle with physics body
├── particle_emitter.gd   # Particle system manager
├── particle_resources.gd # Shared particle resources
├── walker3d.gd           # Random walk implementation
├── fish_tank.gd          # Bounded container for particles
├── blobfish_swarm.gd     # Swarm behavior
├── mover.gd              # Basic physics mover
├── vr_entity.gd          # VR-aware entity base
├── neural_network.gd     # Simple neural net
├── perceptron.gd         # Single-layer perceptron
├── line3d.gd             # 3D line rendering
└── confetti_particle.gd  # Visual effect particle
```

## Key Classes

### Particle

Base class for position, velocity, forces:

```gdscript
class_name Particle
extends Node3D

var velocity: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO
var mass: float = 1.0

func apply_force(force: Vector3):
    acceleration += force / mass

func update(delta: float):
    velocity += acceleration * delta
    position += velocity * delta
    acceleration = Vector3.ZERO
```

### Walker3D

Random walk implementation:

```gdscript
var walker = Walker3D.new()
walker.step_size = 0.5
walker.step()  # Move in random direction
```

### FishTank

Bounded container with edge behaviors:

```gdscript
var tank = FishTank.new()
tank.bounds = Vector3(10, 10, 10)
tank.edge_behavior = FishTank.WRAP  # or BOUNCE, STOP
```

## Physics Subfolder

`core/physics/` contains:
- Force calculations (gravity, drag, springs)
- Collision detection utilities
- Constraint systems (distance, angle)

## Usage in Algorithms

Most algorithm visualizations extend or compose these classes:

```gdscript
# In algorithms/randomness/random_walk.gd
extends Node3D

var walker: Walker3D

func _ready():
    walker = Walker3D.new()
    add_child(walker)

func _process(delta):
    walker.step()
```

## Nature of Code

Many classes are translations from Daniel Shiffman's *Nature of Code*, adapted for VR:
- Original Processing/p5.js → GDScript
- 2D → 3D with VR interaction
- Educational comments preserved
