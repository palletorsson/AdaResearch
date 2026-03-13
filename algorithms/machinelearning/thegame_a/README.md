# The Axiom Garden -- L-System Puzzle Game

A puzzle game built around **L-System string rewriting** where players craft production rules to grow procedural plants that reach target goals while avoiding obstacles. The system is composed of modular components developed across nine iterative stages: the L-System engine, turtle interpreter, MultiMesh renderer, game controller, targets, obstacles, and neon-void environment.

## Concept Taught

**L-Systems (Lindenmayer Systems) as formal grammars for growth.** L-Systems use string rewriting rules to model biological development -- a simple axiom string is repeatedly transformed by production rules, producing complex branching structures. This artifact turns that concept into a puzzle: players must discover which production rules cause a plant to grow into a specific shape, reach spatial targets, and avoid collision with obstacles. It teaches formal language theory, recursive string expansion, and the relationship between symbolic rules and geometric output.

## How It Works

### L-System Engine (LSystem.gd)
1. Starts with an axiom string (e.g., `"F"`) and a dictionary of production rules (e.g., `{"F": "F[+F]F[-F]"}`).
2. Each generation iterates through every character in the current string: if a rule exists for that character, it is replaced by the rule's successor; otherwise it passes through unchanged.
3. Supports both deterministic rules (string successor) and stochastic rules (array of alternatives chosen randomly).

### Turtle Interpreter (Turtle.gd)
1. Reads the generated instruction string character by character.
2. `F` moves forward and records a line segment. `f` moves without drawing.
3. `+`/`-` rotate around the Z axis (yaw). `&`/`^` rotate around X (pitch). `\`/`/` rotate around Y (roll). `|` reverses direction.
4. `[` pushes the current position and heading onto a stack. `]` pops to restore state, enabling branching.

### Garden Renderer (GardenRenderer.gd)
1. Uses `MultiMeshInstance3D` for efficient rendering of hundreds or thousands of branch segments.
2. Each segment is a thin cylinder oriented and scaled to match the line segment from start to end.
3. Default material is green with emissive glow for a neon aesthetic.

### Game Controller (AxiomGarden.gd)
1. Provides a UI with rule input, grow button, and solution navigation (next/prev).
2. Six built-in solutions demonstrate different L-System patterns: The Seed, The Ladder, The Bush, The Vine, The Dragon (curve), and The Fern.
3. After growing, performs **collision detection** using physics raycasts against obstacle bodies.
4. Checks if any branch segment endpoints reach target spheres within their radius.
5. Enforces a `max_segments` constraint -- overly complex plants "wither."

### Supporting Components
- **Target** (Target.gd): A semi-transparent cyan sphere marking a goal position. Emits `target_reached` signal.
- **Obstacle** (Obstacle.gd): A red box `StaticBody3D` that plants cannot touch. Added to the `"obstacles"` group.
- **AxiomEnvironment** (AxiomEnvironment.gd): Sets up the neon-void atmosphere with dark background, screen-blend glow, and volumetric fog.

## Parameters

### AxiomGarden
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `generations` | int | 4 | Number of L-System iterations |
| `step_length` | float | 0.5 | Turtle forward movement distance |
| `angle` | float | 25.0 | Turtle rotation angle in degrees |
| `max_segments` | int | 2000 | Maximum branch segments before withering |

### GardenRenderer
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `material` | StandardMaterial3D | -- | Custom branch material (defaults to green neon) |
| `thickness` | float | 0.05 | Branch cylinder radius |

### Target
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `radius` | float | 0.5 | Goal detection radius |

## Features

- Complete L-System engine with deterministic and stochastic rules
- Full 3D turtle graphics with 6-axis rotation (yaw, pitch, roll)
- MultiMesh rendering for efficient display of thousands of segments
- Six built-in L-System solutions (seed, ladder, bush, vine, dragon curve, fern)
- Physics raycast collision detection against obstacle bodies
- Target proximity detection with signal emission
- Complexity constraint -- plants exceeding max_segments are killed
- Rule parsing from user input text (format: `F=F[+F]F[-F]`)
- Multi-rule support via comma separation (format: `X=...,F=...`)
- Neon-void environment with glow, volumetric fog, and dark background
- Nine test iteration scripts documenting the iterative development process

## Files

- `AxiomGarden.gd` -- Main game controller with UI, solution management, collision/goal checking
- `LSystem.gd` -- L-System string rewriting engine
- `Turtle.gd` -- 3D turtle interpreter producing line segments
- `GardenRenderer.gd` -- MultiMesh-based branch renderer
- `Target.gd` -- Goal sphere with detection signal
- `Obstacle.gd` -- Collision barrier body
- `AxiomEnvironment.gd` -- Neon-void atmosphere setup
- `AxiomGarden.tscn` -- Main scene file
- `test_iteration_1.gd` through `test_iteration_9.gd` -- Iterative development test scripts
- `test_full_playthrough.gd` -- Complete playthrough test
