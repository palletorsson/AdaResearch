# World Map (VR + Desktop)

This module renders the sequence network as a subway-style map and supports both:

1. Progression view (only currently revealed content)
2. Full-map view (entire curriculum graph)

## Main Scene

- `res://commons/scenes/world_map/WorldMapOverview3D.tscn`

This is the 3D tablet used in VR.  
Current scene default:

- `show_full_map = true`

## Full Map Option

The full-map toggle is exposed at three levels:

1. `WorldMapOverview3D.gd`
- Export: `show_full_map`
- Runtime API: `set_show_full_map(enabled: bool)`

2. `WorldMapUI.gd`
- Export: `show_full_map`
- Runtime API: `set_show_full_map(enabled: bool)`

3. `SubwayMapRenderer.gd`
- Export: `show_full_map`
- Runtime API: `set_show_full_map(enabled: bool)`

Behavior:

- `show_full_map = false`: uses progressive reveal (`get_visible_sequences()`).
- `show_full_map = true`: shows all sequences (`get_all_sequences_with_states(true)`), including locked ones.
- In full-map mode, connections are forced visible.

## Hold-To-Enter Behavior

Selection is hover-hold based (matching the menu interaction style):

- Renderer export: `hold_time_required` (default `3.0`)
- Station activation occurs only after hold completion.
- Locked stations are still non-enterable.

Optional click select is available but off by default:

- `click_to_select = false`

## Visual Readability In Full Mode

To avoid "only primitives" look in VR full-map mode:

- Station labels are drawn in full mode by default:
  `show_station_labels_in_full_map = true`
- Locked nodes retain phase tinting (not flat gray).

Always-on labels can be enabled with:

- `show_station_labels = true`

## Runtime Example

```gdscript
var world_map := get_node("WorldMapOverview3D")
world_map.set_show_full_map(true)   # full graph
# world_map.set_show_full_map(false) # progression-only
```

