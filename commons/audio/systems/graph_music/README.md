# Graph Music

Graph-based music composition where nodes represent musical elements and edges define transitions.

## Files

| Script | Purpose |
|--------|---------|
| `MusicGraphSystem.gd` | Core graph engine — manages nodes, edges, and traversal |
| `MusicGraphNode.gd` | Individual node in the music graph (pitch, rhythm, timbre) |
| `GraphAgent.gd` | Autonomous agent that walks the graph, generating music from traversal |
| `GraphSynth.gd` | Synthesis engine driven by graph state |
| `GraphVisualizer.gd` | Visual display of the graph structure and agent position |
| `CircleOfFifthsSystem.gd` | Specialized graph using the circle of fifths for harmonic progression |
| `GitTimelineSystem.gd` | Maps git commit history to musical timeline |

## Scenes

- `GraphMusicTest.tscn` — General graph music test
- `CircleOfFifthsTest.tscn` — Circle of fifths harmonic exploration
- `GitTimelineTest.tscn` — Git history sonification

## Architecture

`MusicGraphSystem` maintains a directed graph of `MusicGraphNode` instances. `GraphAgent` traverses the graph following weighted edges, producing sequences that `GraphSynth` renders as audio. The circle of fifths variant constrains the graph to musically meaningful harmonic relationships.
