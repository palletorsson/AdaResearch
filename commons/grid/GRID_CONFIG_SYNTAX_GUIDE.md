# Grid Configuration Syntax Guide

This guide explains the enhanced token parsing system in `GridInteractablesComponent.gd` that supports both legacy overrides and the new `#` configuration syntax.

## Overview

The grid system now supports two types of artifact customization:
1. **Legacy Overrides** (`:` syntax) - For basic transformations (rotation, position, scale)
2. **Configuration Data** (`#` syntax) - For complex artifact-specific settings

## Legacy Override Syntax (`:`)

### Basic Format
```
artifact_name[:rotation][:y_position][:scale][|label]
```

### Examples
```json
"scifi_panel_wall"                    // Basic placement
"scifi_panel_wall:45"                 // Rotate 45 degrees on Y axis
"random_book:0:2.5:1.2"              // No rotation, +2.5 Y offset, 1.2x scale
"entrance:90|Level 3"                // 90° rotation with custom label
```

## New Configuration Syntax (`#`)

### Basic Format
```
artifact_name#config_key:config_value[#config_key2:config_value2]...
```

### Examples
```json
"clipboard#pages:point,line,triangle"              // Set clipboard pages
"clipboard#title:Getting Started"                  // Set clipboard title
"clipboard#pages:point,line#title:My Clipboard"    // Multiple configs
"infokiosk#message:Hello World#color:red"          // Configure info kiosk
```

## Clipboard-Specific Configuration

The clipboard artifact supports these configuration keys:

### `pages` - Snippet Keys
Configure which code snippets to show:
```json
"clipboard#pages:point"                    // Single snippet
"clipboard#pages:point,line,triangle"      // Multiple snippets
```

### `title` - Custom Title
Set the clipboard title:
```json
"clipboard#title:Getting Started with Points"
```

### `content` - Raw Content
Provide raw content instead of snippets:
```json
"clipboard#content:Welcome to VR coding!"           // Single page
"clipboard#content:Page 1|Page 2|Page 3"           // Multiple pages (| separator)
```

### Combined Example
```json
"clipboard#pages:point,line,triangle#title:Geometry Basics"
```

## How It Works

### 1. Token Parsing
The `GridInteractablesComponent._parse_interactable_token()` method:
- Detects `#` symbols and routes to `_parse_config_token()`
- Parses multiple config pairs separated by `#`
- Returns a dictionary with `lookup_name`, `overrides`, and `config_data`

### 2. Configuration Application
During artifact placement, `_apply_artifact_config()`:
- Sets metadata on the artifact node (`config_*` keys)
- Calls `apply_grid_config()` method if it exists on the artifact
- Falls back to metadata-only if no config method exists

### 3. Artifact Handling
Artifacts can handle configuration by implementing:
```gdscript
func apply_grid_config(config_data: Dictionary) -> void:
    # Handle configuration logic here
    if config_data.has("pages"):
        # Process pages configuration
    if config_data.has("title"):
        # Process title configuration
```

## Available Code Snippets

The clipboard system uses `snippets.json` with these keys:
- `point` - Create 3D points
- `line` - Connect points with lines
- `triangle` - Build triangular surfaces
- `vector` - Vector operations
- `transform` - 3D transformations
- `material` - Material and shading
- `mesh` - Custom mesh creation
- `animation` - Simple animations
- `collision` - Collision detection
- `vr` - VR interaction patterns

## Map JSON Integration

### In your map's `interactables` layer:
```json
{
  "layers": {
    "interactables": [
      [" ", " ", " "],
      [" ", "clipboard#pages:point,line#title:Learn Geometry", " "],
      [" ", " ", " "]
    ]
  }
}
```

### Result:
- Places a clipboard at position (1,1)
- Configures it to show `point` and `line` code snippets
- Sets the title to "Learn Geometry"
- Automatically expands `code#point` and `code#line` syntax to rich code examples

## Benefits

1. **Clean Separation**: Overrides for transforms, configs for content
2. **Extensible**: Any artifact can implement `apply_grid_config()`
3. **Backward Compatible**: Legacy `:` syntax still works
4. **Flexible**: Multiple configs per artifact
5. **Maintainable**: Configuration logic stays with each artifact

## Adding Config Support to New Artifacts

To make your artifact configurable:

1. **Add the config method**:
```gdscript
func apply_grid_config(config_data: Dictionary) -> void:
    if config_data.has("your_config_key"):
        var value = str(config_data.your_config_key)
        # Apply configuration
```

2. **Use in maps**:
```json
"your_artifact#your_config_key:your_value"
```

3. **Access metadata** (alternative):
```gdscript
func _ready():
    if has_meta("config_your_key"):
        var value = get_meta("config_your_key")
        # Apply configuration
```

This system provides a powerful, flexible way to configure artifacts directly from map JSON without hardcoding specific logic in the grid system.
