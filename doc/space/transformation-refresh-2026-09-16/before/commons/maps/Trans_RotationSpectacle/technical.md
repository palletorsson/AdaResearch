# Gallery configuration

`map_info.museum` declares an exhibition hall without a `simulation` block. The museum derives the floor and seven placements directly from this map. Source structure cells describe gallery architecture; they are not instantiated as a GridSystem simulation. The hall's cached plan row has also been refreshed to remove the previous crossing utilities.

## Boolean tunnel

Source: `algorithms/transformation/booleanTunnel/booleanTunnel.gd`.

The placement explicitly requests `num_segments:14`, `rotation_per_segment:10`, `accrual:ramp`. Segment index i receives i times ten degrees about z; the last receives 130 degrees. `spacing` remains 3 m. Each repeated scene subtracts an inner box from an outer CSG box. The subtraction creates the opening; rotation arranges the hollowed volumes. The corridor does not rotate over time.

`segment_vertical_offset:-0.65` seats the hollow geometry relative to the museum floor independently of automatic root placement. This parameter defaults to zero elsewhere. The gallery probe sweeps a 1.6 m tall, 0.22 m radius capsule through the centre of the passage.

## Five carousel configurations

Source: `algorithms/transformation/carousel_cake/carousel_cake.gd`.

Every placement sets its existing `profile` to one of cake, ziggurat, column, spindle or flare, with `gallery:clean`. That opt-in removes the scene's saved duplicate MultiMesh and saved collision bodies, leaves one live generated stack, and generates collision from the displayed profile radii. Legacy placements retain their existing behaviour.

All five use eight layers, identical heights, base speed 0.5 rad/s and multiplier 1.2:

```gdscript
var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
var angle: float = _rotation_angle * layer_speed
```

Each layer's angular speed stays constant over time; the progression is across the layer index. The radii determine silhouette and rim speed, not a different angular-speed rule. The labels identify profiles. No live speed slider is claimed.

`commons/testing/probe_spectacle_gallery.gd` checks actual museum installation, all profiles and their configuration, matching collision, tunnel geometry and capsule clearance, and the continuous viewing aisle. Human VR review remains pending.
