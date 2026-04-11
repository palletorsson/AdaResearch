# Pattern Library

Exported from the [Pattern Studio](/pattern-studio) web editor.

## Format

Each pattern is a JSON file with optional companion PNG:

```json
{
  "name": "Greek Key Border",
  "group": "PMM",
  "zone": "border",
  "domain_size": 8,
  "tile_scale": 6,
  "grout_width": 0.02,
  "noise_distort": 0.01,
  "palette": ["#f2ead9", "#cc3326", "#263f80", "#b38c33"],
  "domain": [[0,0,1,1,...], [0,1,0,1,...], ...]
}
```

## Usage in Godot

```gdscript
var pkg := PatternLoader.load_package("res://commons/patterns/my_pattern.json")
PatternLoader.apply_to_mesh(carpet_mesh, pkg)
```

## Web Editor

Export patterns at `localhost:3003/pattern-studio` using the "Export Godot Package" button.
