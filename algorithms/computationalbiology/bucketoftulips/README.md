# Bucket of Tulips

A procedurally generated flower arrangement that creates randomized tulip bouquets in metallic buckets, demonstrating how parameterized randomization and template instancing produce natural-looking organic variation.

## How It Works

The single-bucket script creates a cylindrical bucket with a torus handle, then generates tulips from three template styles: closed (cone-shaped bud), open (six-petal sphere arrangement), and drooping (tilted capsule). Each tulip is placed at a random position within the bucket radius, given a random lean angle, scale variation, and flower color drawn from a palette of six common tulip colors with slight per-instance noise. The companion script (`ten_tulip_buckets.gd`) instantiates ten copies of the bucket scene in a 5x2 grid, randomizing each bucket's tulip count (10--20), orientation, scale, and bucket color. A regenerate button lets users reshuffle all arrangements at runtime. This teaches how stochastic variation applied to a small set of templates produces convincing organic diversity -- a core technique in procedural content generation.

## Parameters

Bucket of Tulips:

| Export | Type | Default |
|--------|------|---------|
| `tulip_count` | int | 15 |
| `bucket_radius` | float | 0.4 |
| `bucket_height` | float | 0.3 |
| `color_variation` | bool | true |

Ten Tulip Buckets:

| Export | Type | Default |
|--------|------|---------|
| `bucket_spacing` | float | 3.0 |
| `grid_size` | int | 5 |
| `randomize_colors` | bool | true |
| `randomize_positions` | bool | true |

## Features

- Three tulip flower styles: closed bud, open petals, drooping head
- Procedural color variation from a six-color tulip palette
- Random position, lean, and scale for natural arrangement
- Ten-bucket grid variant with per-bucket randomization
- Runtime regeneration via UI button or keyboard
- Three-point lighting and procedural sky environment

## Files

- `bucket_of_tulips.gd` -- Single bucket generator
- `ten_tulip_buckets.gd` -- Ten-bucket grid arranger
- `bucket_of_tulips.tscn` -- Single bucket scene
- `ten_tulip_buckets.tscn` -- Ten-bucket scene
