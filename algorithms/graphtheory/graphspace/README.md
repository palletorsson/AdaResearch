# Graph Space -- Walkable Graph Theory Environment

A procedural graph-based world generator that creates **walkable room networks connected by bridges**, using force-directed layout, Dijkstra's shortest path, and flexible structure placement. Includes a specialized subclass implementing the **Seven Bridges of Konigsberg** problem -- the founding problem of graph theory.

## Concept Taught

**Graph theory fundamentals -- nodes, edges, connectivity, and Eulerian paths.** This artifact makes abstract graph concepts tangible by instantiating rooms (nodes) connected by walkable bridges (edges) in 3D space. The force-directed layout algorithm teaches how graphs can be spatially arranged using physics simulation. Dijkstra's algorithm computes shortest-path distances to drive environmental ambience. The Konigsberg Bridge subclass teaches Euler's theorem: a connected graph has an Eulerian path if and only if it has exactly 0 or 2 vertices of odd degree -- and demonstrates why no such path exists in the historical seven-bridge configuration.

## How It Works

### GraphSpace (Base System)
1. A connected undirected graph is built by first creating a random spanning tree (ensuring connectivity), then adding extra edges until the average degree target is met.
2. A **force-directed layout** iterates through repulsion (nodes push apart), spring attraction (edges pull connected nodes together), and soft boundary constraints.
3. Optional **planar layout** constrains nodes to a plane by zeroing vertical forces and snapping Y positions.
4. **Rooms** are instantiated at node positions from a PackedScene. Doors are carved toward each connected neighbor via `carve_door_facing()`.
5. **Bridges** (CSGBox3D with collision) and **portals** (bidirectional teleporters) are placed at edge midpoints, oriented along the edge direction.
6. **Structures** are placed at nodes using a flexible selection system: random, degree-based, distance-based, single-type, or custom pattern.
7. **Ambience** is driven by Dijkstra distances from a focal node -- light energy and audio volume attenuate with graph distance.

### KonigsbergBridge (Subclass)
1. Overrides the base graph with the specific Konigsberg topology: 4 landmasses (Altstadt, Lobenicht, Kneiphof, Vorstadt) connected by 7 bridges.
2. Uses fixed historical positions instead of force-directed layout.
3. Performs **Euler analysis**: counts vertex degrees, determines odd/even classification, and concludes whether an Eulerian path or circuit exists.
4. Displays an educational UI panel explaining the problem, degree analysis, Euler's theorem, and the impossibility conclusion.
5. Historical bridge data includes names and construction dates (1286--1542).

### Supporting Scripts
- **Portal**: Area3D-based bidirectional teleporter that sends the player from one endpoint to the other.
- **Room CSG**: Carves door openings in a CSG shell by placing subtraction boxes oriented toward connected neighbors.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `room_scene` | PackedScene | -- | Scene to instantiate at each node |
| `portal_scene` | PackedScene | -- | Scene for edge portals/teleporters |
| `structure_scenes` | Array[PackedScene] | [] | Structure options for node decoration |
| `structure_type` | StructureType | BY_DEGREE | Selection strategy for structures |
| `node_count` | int | 12 | Number of graph nodes |
| `avg_degree` | float | 2.2 | Target average edges per node |
| `layout_iters` | int | 250 | Force-directed layout iterations |
| `room_radius` | float | 6.0 | Desired spacing between rooms |
| `repulsion` | float | 180.0 | Node repulsion strength |
| `edge_stiffness` | float | 0.08 | Spring force along edges |
| `planar_layout` | bool | true | Constrain layout to XZ plane |
| `make_bridges` | bool | true | Generate walkable CSG bridges |
| `bridge_width` | float | 1.2 | Bridge walkway width |
| `focal_node` | int | 0 | Ambience attenuation source |

## Features

- Complete graph generation with guaranteed connectivity via spanning tree
- Force-directed layout with repulsion, spring attraction, and boundary constraints
- Planar layout mode for flat map generation
- Dijkstra's shortest path for distance-based ambience attenuation
- Five structure selection strategies: random, degree-based, distance-based, single-type, custom pattern
- CSG bridge generation with collision for walkability
- Portal-based bidirectional teleportation between rooms
- Room door carving via CSG subtraction oriented toward neighbors
- Konigsberg Bridge educational mode with Euler analysis and historical data
- Interactive educational UI with degree analysis and theorem explanation
- Editor tool support with configuration warnings

## Files

- `graphspace.gd` -- Core graph generation, layout, and world instantiation system
- `konigsbergBridge.gd` -- Konigsberg Bridge subclass with Euler analysis and educational UI
- `portal.gd` -- Bidirectional teleporter for graph edges
- `room_csg.gd` -- CSG-based room with door carving
- `graphspace.tscn` -- Main graph space scene
- `KonigsbergBridge.tscn` -- Konigsberg problem scene
- `portal.tscn` -- Portal scene
- `room.tscn` -- Room scene
- `room2.tscn` -- Alternate room scene
