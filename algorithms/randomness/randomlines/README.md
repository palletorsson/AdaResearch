# Random Lines

A simple visualization that spawns a set of lines with randomly positioned endpoints within a 3D volume. Each line uses the project's shared interactive line primitive, making the endpoints grabbable in VR. The artifact demonstrates random line segment generation in three-dimensional space.

## Concept Taught

Random line segments are a fundamental geometric primitive in computational geometry and stochastic geometry. This artifact teaches how random geometric objects are constructed by sampling their defining parameters -- in this case, two independent random points that determine a line segment. The result illustrates concepts like random graphs (connecting random points), spatial density, and the visual difference between structured and unstructured geometric arrangements. In VR, learners can grab and rearrange the endpoints, exploring how individual changes affect the overall random configuration.

## How It Works

1. **Line scene loading** -- The script preloads `line.tscn` from the commons primitives library, which provides an interactive line with two grabbable endpoint spheres connected by a visual segment.
2. **Random endpoint generation** -- For each of `num_lines` lines:
   - The line scene is instantiated and added as a child
   - The `lineContainer` node is accessed, containing two endpoint nodes (`GrabSphere` and `GrabSphere2`)
   - Each endpoint receives a random position uniformly distributed within the volume defined by `area_size`, centered at the origin
3. **Connection refresh** -- If the line container has a `refresh_connections` method, it is called (deferred) to update the visual connection between the newly positioned endpoints.
4. **Initialization** -- `randomize()` is called to seed the RNG, ensuring different configurations each run.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_lines` | int | 20 | Number of random lines to spawn |
| `area_size` | Vector3 | (2.0, 2.0, 2.0) | Size of the volume for random endpoint placement |

## Features

- Configurable number of random line segments
- Each line uses the shared interactive line primitive with grabbable endpoints
- Endpoints are independently randomized within a configurable 3D volume
- VR-interactive: endpoints can be grabbed and repositioned
- Deferred connection refresh ensures proper visual updates

## Files

| File | Description |
|------|-------------|
| `randomlines.gd` | Main script -- line instantiation and random endpoint placement |
| `randomlines.tscn` | Scene file |
