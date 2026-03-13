# Cave System

A procedural cave generator that creates interconnected cavern networks using CSG (Constructive Solid Geometry) boolean operations. Primary caverns are placed randomly in 3D space, deformed with subtracted spheres for organic shapes, and connected via tunnels built with a minimum spanning tree algorithm. Stalactites, stalagmites, and rock formations add environmental detail, all textured with noise-generated materials.

This artifact teaches **procedural geometry generation through boolean operations and graph connectivity**. The cave system demonstrates two key randomness concepts: spatial randomness (where caverns and formations are placed) and structural randomness (which caverns connect to which). The minimum spanning tree ensures every cavern is reachable -- guaranteed connectivity from randomness.

## How It Works

1. **Cavern Placement**: `num_primary_caverns` CSG spheres are placed at random positions within the `cave_size` bounding volume. Each sphere has a random radius between 3.0 and 8.0 units.

2. **Cavern Deformation**: Each cavern receives 2-5 smaller CSG spheres as children using `OPERATION_SUBTRACTION`. These carve out irregular shapes from the main sphere, creating organic, non-uniform chamber walls.

3. **Tunnel Connectivity**: When `ensure_full_connectivity` is enabled (default), the algorithm builds a minimum spanning tree using Prim's approach:
   - Start with cavern 0 as "connected"
   - Repeatedly find the closest pair of (connected, disconnected) caverns
   - Create a CSG cylinder tunnel between them
   - Mark the newly connected cavern
   - Continue until all caverns are connected
   - Add extra random tunnels based on `extra_tunnels_ratio`

4. **Tunnel Construction**: Each tunnel is a CSG cylinder positioned at the midpoint between two caverns, rotated to align with the connection direction. Tunnels receive 2-5 subtraction spheres along their length for organic variation.

5. **Environmental Details**: Random CSG boxes serve as rock formations (10-30 placed randomly). Stalactites and stalagmites are generated as cone-shaped CSG cylinders placed at the ceiling and floor of the bounding volume.

6. **Procedural Texturing**: A 256x256 image is generated pixel-by-pixel using `FastNoiseLite` simplex noise with color variation around a base rock color. A normal map is derived from the height differences of neighboring pixels. Both textures are applied to all CSG shapes recursively.

7. **Connectivity Verification**: A BFS traversal can verify that the cave system forms a single connected component, using tunnel metadata to build an adjacency list.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `cave_size` | Vector3 | (20, 15, 20) | Overall bounding volume for the cave system |
| `num_primary_caverns` | int | 5 | Number of main cave chambers |
| `tunnel_complexity` | int | 10 | Number of interconnecting tunnels |
| `cave_seed` | int | 42 | Seed for consistent generation |
| `texture_scale` | float | 0.1 | Scale of the noise texture |
| `color_variation` | float | 0.2 | Amount of color variation in the texture |
| `ensure_full_connectivity` | bool | true | Guarantee all caverns are connected |
| `extra_tunnels_ratio` | float | 0.3 | Fraction of extra tunnels beyond the spanning tree |

## Features

- CSG boolean operations for organic cavern shapes (sphere subtraction)
- Minimum spanning tree algorithm ensuring full graph connectivity
- Configurable extra tunnels for loop paths beyond the spanning tree
- Organic tunnel variation via subtracted spheres along cylinder length
- Procedural stalactites and stalagmites placed at ceiling and floor
- Random rock formations scattered throughout the volume
- Noise-based procedural texture generation with albedo and normal maps
- Seeded `RandomNumberGenerator` for reproducible cave layouts
- BFS connectivity verification method
- Regeneration method with automatic retry if connectivity fails

## Files

| File | Description |
|------|-------------|
| `cave_system.gd` | Main script -- cavern placement, CSG deformation, MST tunneling, texturing |
| `caveSystem.tscn` | Scene file |
