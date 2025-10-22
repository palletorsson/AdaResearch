# Using InfoBoards in Maps - Complete Guide

## ✅ Yes! You Can Use `ib:point`, `ib:line`, `ib:triangle` in Maps!

Just like you use `la:point` for labels, you can use `ib:point` for InfoBoards!

## Quick Example

### In your `map_data.json`:

```json
{
  "layers": {
    "utilities": [
      [" ", " ", " ", " ", " "],
      [" ", "ib:point", " ", " ", " "],
      [" ", " ", "ib:line", " ", " "],
      [" ", " ", " ", "ib:triangle", " "],
      [" ", " ", " ", " ", " "]
    ]
  }
}
```

**That's it!** The InfoBoards will automatically load with content from `infoboard_content.json`!

## Available InfoBoard IDs

From your centralized content:

```json
"ib:point"       // The Point - The Atom of Space (5 pages)
"ib:line"        // The Line - Connecting Points (5 pages)
"ib:triangle"    // The Triangle - The First Surface (5 pages)
"ib:randomwalk"  // Random Walk - Exploring Through Chance (1 page)
```

## Syntax Options

### Basic Syntax
```json
"ib:point"      // Load Point InfoBoard at default height
```

### With Height Offset
```json
"ib:point:0.5"  // Raise board 0.5 meters above default
"ib:line:-0.3"  // Lower board 0.3 meters
```

The height offset is added to the default height (usually 1.5m above the ground).

## Real Map Example

Here's a complete working map with InfoBoards:

```json
{
  "map_info": {
    "name": "Fundamentals Gallery",
    "description": "Point, Line, and Triangle InfoBoards"
  },
  "layers": {
    "structure": [
      ["1", "1", "1", "1", "1"],
      ["1", "1", "1", "1", "1"],
      ["1", "1", "1", "1", "1"],
      ["1", "1", "1", "1", "1"]
    ],
    "utilities": [
      [" ", " ", " ", " ", " "],
      [" ", "ib:point", "ib:line", "ib:triangle", " "],
      [" ", " ", " ", " ", " "],
      [" ", " ", "t", " ", " "]
    ]
  },
  "utility_definitions": {
    "t": {
      "type": "teleporter",
      "name": "Exit"
    }
  }
}
```

This creates a row of three InfoBoards at position (1,1), (2,1), and (3,1)!

## How It Works Behind the Scenes

When you use `ib:point` in the utilities layer:

1. **InfoBoardComponent** reads the utilities layer
2. Sees `ib:point` and calls **InfoBoardRegistry** to validate it
3. Tries to create board using **UniversalInfoBoard** template
4. Loads content from **infoboard_content.json** for board_id "point"
5. Creates a 3D handheld tablet with all 5 pages of Point content
6. Places it at the grid position

**Zero code needed!** All content comes from JSON.

## Combining with Labels

You can use both labels and InfoBoards together:

```json
"utilities": [
  [" ", "la:point", " ", " "],
  [" ", "ib:point", " ", " "],
  [" ", " ", " ", " "]
]
```

This puts a label above the InfoBoard - great for descriptions!

## Example: Educational Progression

Create a map that follows your learning progression:

```json
{
  "layers": {
    "structure": [
      ["1", "1", "1", "1", "1", "1", "1"],
      ["1", "1", "1", "1", "1", "1", "1"],
      ["1", "1", "1", "1", "1", "1", "1"]
    ],
    "utilities": [
      [" ", " ", " ", " ", " ", " ", " "],
      ["la:Fundamentals", "ib:point", "ib:line", "ib:triangle", " ", " ", "t"],
      [" ", " ", " ", " ", " ", " ", " "]
    ]
  }
}
```

This creates a linear path through your fundamental concepts!

## Testing Your Map

1. Save your `map_data.json` with `ib:point` in utilities
2. Load the map in your game
3. You should see the InfoBoard appear as a 3D handheld tablet
4. Walk up to it and interact (grab/click)
5. Navigate pages with Previous/Next buttons

## Checking If It's Working

The InfoBoardComponent will print to console:

```
InfoBoardComponent: Generating info boards
InfoBoardComponent: Created board 'point' using UniversalInfoBoard template (Content: 5 pages)
  Added Point Info Board at (1,1,1)
InfoBoardComponent: Added 1 info boards
```

If you see this, it's working!

## Troubleshooting

### "No content found for board ID"
- Check that board_id exists in `infoboard_content.json`
- Make sure it's spelled correctly: `ib:point` not `ib:Point`

### "Board validation issues"
- Check InfoBoardRegistry has the board type registered
- Look at console for specific errors

### InfoBoard doesn't appear
- Check the utilities layer has the `ib:` entry
- Make sure InfoBoardComponent is initialized in your scene
- Check console for warnings

### Content is empty/wrong
- Verify `infoboard_content.json` has pages for that board_id
- Check JSON syntax is valid
- Look for parse errors in console

## Advanced: Custom Board Definitions

You can customize boards in the map:

```json
{
  "utility_definitions": {
    "ib:point": {
      "properties": {
        "height": 2.0,
        "scale": 1.5
      }
    }
  },
  "layers": {
    "utilities": [
      ["ib:point", " ", " "]
    ]
  }
}
```

This overrides the default height and scale for the Point InfoBoard in this map.

## Best Practices

### 1. Logical Placement
Place InfoBoards near what they teach:
- `ib:point` near point demonstrations
- `ib:line` along pathways
- `ib:triangle` near mesh examples

### 2. Progressive Order
Arrange InfoBoards in learning order:
```json
"utilities": [
  ["ib:point", "→", "ib:line", "→", "ib:triangle"]
]
```

### 3. Combine with Interactables
```json
{
  "utilities": [["ib:point", " "]],
  "interactables": [["grab_sphere_point", " "]]
}
```
InfoBoard above, interactive example below!

### 4. Height Adjustments
Raise boards if map has uneven terrain:
```json
"utilities": [
  ["ib:point:0.5", "ib:line:1.0", "ib:triangle:0.8"]
]
```

## See Also

- **Example Map**: `commons/maps/InfoBoards_Example/map_data.json`
- **Content System**: `commons/infoboards_3d/content/CONTENT_SYSTEM.md`
- **InfoBoardRegistry**: For adding new board types
- **Point_1_1 Map**: Example using `la:point` (labels)

---

**Your map system now supports InfoBoards!** Just add `ib:boardname` to utilities and it loads automatically from your centralized content! 🎉
