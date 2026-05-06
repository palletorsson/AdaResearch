# Water Land Ride

A rideable helical water slide that teaches **parametric helix geometry**, **Frenet-Serret frames**, and **path-following kinematics** by generating a tubular slide along a descending spiral and carrying the player through it. Two complementary generators approach the same problem differently -- one assembles prefab segments, the other builds a continuous mesh.

## How It Works

Both generators create a descending helix defined by:
- `center(t) = (R * cos(u), H * (1 - t), R * sin(u))` where `u = t * turns * TAU`
- `tangent(t)` = derivative of center, normalised
- `normal(t)` = radial outward direction `(cos(u), 0, sin(u))`
- `binormal(t)` = tangent cross normal

**SegmentSlideGenerator** places prefabricated tube segment scenes at each sample point along the helix, oriented using a Frenet-like basis with flip correction (if consecutive binormals dot negative, the binormal is inverted to prevent sudden twists). An alignment rotation export allows fine-tuning the segment orientation.

**SlideGenerator** builds a continuous tube mesh using `SurfaceTool`. At each of its 150+ sample points, it extrudes a circular cross-section ring using the normal and binormal vectors, then connects adjacent rings with indexed triangles. The result is a seamless tubular mesh with proper normals and tangents for lighting. It applies a translucent water material with subsurface scattering for a wet, glassy appearance.

The slide generator also implements a **ride system**: entry pads (glowing cyan discs with collision detection) are placed at intervals along the slide exterior. When a player in the "players" group steps onto a pad, the ride begins. Each physics frame, the rider's position is interpolated along the baked path distances, with their transform oriented by the local Frenet frame plus a height offset. Player input is disabled during the ride and restored on completion.

Collision is generated from the mesh triangles, with upward-facing faces filtered out to prevent the player from standing on top of the tube.

## Parameters

### SegmentSlideGenerator
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `segment_scene` | PackedScene | tube_segment | Prefab scene for each segment |
| `major_radius` | float | 4.0 | Helix radius |
| `tube_radius` | float | 1.2 | Tube cross-section radius |
| `height` | float | 12.0 | Total vertical descent |
| `turns` | float | 2.5 | Number of spiral turns |
| `segments` | int | 60 | Number of placed segments |
| `segment_alignment_degrees` | Vector3 | (-90, 0, 0) | Rotation offset per segment |

### SlideGenerator
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `major_radius` | float | 4.0 | Helix radius |
| `tube_radius` | float | 1.2 | Tube cross-section radius |
| `height` | float | 12.0 | Total vertical descent |
| `turns` | float | 2.5 | Number of spiral turns |
| `segments` | int | 150 | Mesh longitudinal resolution |
| `tube_segments` | int | 20 | Mesh radial resolution |
| `generate_collision` | bool | true | Create collision shape from mesh |
| `pad_count` | int | 3 | Number of entry pads |
| `pad_radius` | float | 0.6 | Entry pad size |
| `ride_speed` | float | 12.0 | Speed along the slide in units/s |
| `rider_height_offset` | float | 0.35 | Height above tube surface during ride |
| `rider_group` | StringName | "players" | Group name for ride-eligible bodies |

## Features

- Parametric helix path generation with configurable radius, height, and turns
- Frenet-Serret frame computation with binormal flip correction
- Continuous tube mesh with SurfaceTool indexing, normals, and tangents
- Segment-based alternative using prefab scene instantiation
- Translucent water material with subsurface scattering
- Rideable player transport with path-distance interpolation
- Entry pads with Area3D collision detection and visual glow
- Collision mesh generation with upward-face filtering
- Player input suppression during ride with clean state restoration
- Optional auto-rotation for display purposes

## Files

| File | Description |
|------|-------------|
| `segment_slide_generator.gd` | Segment-based helix slide using prefab placement with Frenet frames |
| `slide_generator.gd` | Continuous-mesh helix slide with ride system, collision, and entry pads |
| `water_land_ride.tscn` | Main scene file |
| `segment_slide.tscn` | Segment-based variant scene |
