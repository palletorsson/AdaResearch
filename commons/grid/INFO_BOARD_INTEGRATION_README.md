# Info Board Integration with GridSystem

## Overview

This document describes the integration of info boards (`ib:vectors`, `ib:forces`, etc.) with the GridSystem utilities layer. The integration allows info boards to be placed in map JSON files using the `ib:` prefix syntax.

## Integration Components

### 1. UtilityRegistry.gd Updates
**Location**: `commons/grid/UtilityRegistry.gd`

**Changes**:
- Added `"ib"` utility type for info board handling
- Updated validation logic to handle `ib:` prefix
- Added InfoBoardRegistry integration for board type validation

**New Utility Type**:
```gdscript
"ib": {
    "name": "info_board_handheld",
    "file": "",
    "category": "educational",
    "description": "Handheld 3D info board for algorithm education (ib:randomwalk, ib:vectors, ib:forces, etc.)",
    "supports_parameters": true  # board_type, height_offset
}
```

### 2. GridUtilitiesComponent.gd Updates
**Location**: `commons/grid/GridUtilitiesComponent.gd`

**Changes**:
- Added direct info board placement (like teleports and other utilities)
- Added parsing logic for `ib:` utilities
- Added info board generation at specific grid positions
- Separated info board utilities from regular utilities

**New Methods**:
- `_parse_info_board_utility()` - Parses `ib:vectors:1.5` format
- `_generate_info_boards()` - Places info boards at their specific grid locations
- `_place_info_board_at_position()` - Places a single info board at a 3D position

### 3. GridSystem.gd Integration
**Location**: `commons/grid/GridSystem.gd`

**Changes**:
- GridUtilitiesComponent now handles both regular utilities and info boards
- Info boards are placed directly at their grid positions (like teleports)
- Seamless integration with existing grid generation workflow

## Usage in Map JSON

### Basic Syntax
```json
{
  "utilities": [
    ["ib:vectors", " ", "ib:forces"],
    [" ", "ib:randomwalk", " "],
    ["t:next", " ", "l:2.0"]
  ]
}
```

### With Height Offsets
```json
{
  "utilities": [
    ["ib:vectors:1.5", " ", "ib:forces:0.5"],
    [" ", "ib:randomwalk:2.0", " "],
    ["t:next", " ", "l:2.0"]
  ]
}
```

### Mixed Utilities
```json
{
  "utilities": [
    ["ib:vectors", "t:next", "ib:forces:1.5"],
    ["l:3.0", "ib:randomwalk", "sp:100"],
    [" ", " ", "ib:unitcircle:0.5"]
  ]
}
```

## Supported Info Board Types

Based on `InfoBoardRegistry.gd`:

- `ib:vectors` - Vector mathematics and physics
- `ib:forces` - Forces, gravity, friction, and motion  
- `ib:randomwalk` - Random walk algorithms
- `ib:unitcircle` - Trigonometry and waves
- `ib:bfs` - Breadth-First Search
- `ib:neural` - Neural Networks
- `ib:sorting` - Sorting Algorithms

## Parameter Support

### Height Offset
- `ib:vectors:1.5` - Places vectors board 1.5 units higher
- `ib:forces:0.5` - Places forces board 0.5 units higher
- `ib:randomwalk` - Uses default height (no offset)

### Future Parameters
The system is designed to support additional parameters:
- `ib:vectors:1.5:page2` - Height offset + specific page
- `ib:forces:0.5:auto` - Height offset + auto-advance mode

## Integration Workflow

### 1. Map Loading
1. GridSystem loads map JSON
2. GridUtilitiesComponent receives utility data
3. Utilities are separated into regular and info board types

### 2. Info Board Processing
1. `ib:` utilities are parsed for board type and parameters
2. Board types are validated using InfoBoardRegistry
3. Info boards are placed directly at their grid positions (like teleports)
4. Boards are positioned with height offsets at their specific locations

### 3. Regular Utility Processing
1. Regular utilities (t, l, s, etc.) are processed normally
2. Uses existing UtilityRegistry validation
3. Uses existing utility placement logic

## Validation

### Utility Validation
The system validates both regular utilities and info boards:

```gdscript
# Regular utility validation
UtilityRegistry.validate_utility_grid(utility_layout)

# Info board validation (automatic)
InfoBoardRegistry.is_valid_board_type(board_type)
```

### Error Handling
- Invalid board types are reported as errors
- Missing scene files are reported as warnings
- Height offset parameters are validated as floats

## Testing

### Integration Test
**Location**: `commons/grid/InfoBoardIntegrationTest.gd`

**Test Commands**:
- **Key 1**: Test utility parsing
- **Key 2**: Test info board validation  
- **Key 3**: Test registry integration
- **Key 4**: Test complete integration workflow

### Manual Testing
1. Create a test map with `ib:` utilities
2. Load the map in GridSystem
3. Verify info boards are generated correctly
4. Check height offsets are applied
5. Test VR interaction and scrolling

## File Structure

```
commons/grid/
├── GridSystem.gd                    # Main grid system
├── GridUtilitiesComponent.gd        # Updated with info board support
├── UtilityRegistry.gd               # Updated with ib: utility type
├── InfoBoardIntegrationTest.gd      # Integration test script
├── InfoBoardIntegrationTest.tscn   # Test scene
└── INFO_BOARD_INTEGRATION_README.md # This documentation

commons/infoboards_3d/
├── base/
│   ├── InfoBoardComponent.gd        # Info board component
│   └── InfoBoardRegistry.gd         # Board type registry
└── boards/
    ├── Vectors/                     # Vectors info board
    ├── Forces/                      # Forces info board
    └── RandomWalk/                  # Random walk info board
```

## Benefits

### For Map Designers
- Simple `ib:` syntax for info board placement
- Height offset support for positioning
- Validation prevents invalid board types
- Consistent with existing utility syntax

### For Developers
- Clean separation of concerns
- Reuses existing InfoBoardComponent
- Maintains compatibility with regular utilities
- Extensible for future parameters

### For Users
- Info boards work seamlessly in VR
- VR scroll functionality included
- Consistent interaction patterns
- Educational content easily accessible

## Future Enhancements

### Additional Parameters
- Page specification: `ib:vectors:1.5:page3`
- Auto-advance mode: `ib:forces:0.5:auto`
- Custom themes: `ib:randomwalk:1.0:dark`

### Advanced Features
- Board linking: `ib:vectors:1.5:link:forces`
- Conditional display: `ib:forces:1.5:if:completed`
- Dynamic content: `ib:vectors:1.5:dynamic:user_progress`

## Troubleshooting

### Common Issues

1. **"Invalid info board type"**
   - Check board type spelling
   - Verify board is registered in InfoBoardRegistry
   - Use `InfoBoardRegistry.print_registry_summary()` for available types

2. **"InfoBoardComponent not initialized"**
   - Ensure GridUtilitiesComponent is properly initialized
   - Check that InfoBoardComponent is added to parent node

3. **"Scene file missing"**
   - Verify info board scene files exist
   - Check InfoBoardRegistry scene paths
   - Ensure all required dependencies are loaded

### Debug Commands
```gdscript
# Print available info board types
InfoBoardRegistry.print_registry_summary()

# Validate utility grid
var validation = UtilityRegistry.validate_utility_grid(utility_layout)
print("Valid: ", validation.valid)
print("Errors: ", validation.errors)

# Test info board parsing
var parsed = UtilityRegistry.parse_utility_cell("ib:vectors:1.5")
print("Type: ", parsed.type)
print("Parameters: ", parsed.parameters)
```

## Dependencies

- **InfoBoardRegistry**: Board type definitions and validation
- **InfoBoardComponent**: Board generation and placement
- **UtilityRegistry**: Utility type definitions and validation
- **GridUtilitiesComponent**: Utility placement and management

## Related Files

- `commons/infoboards_3d/base/InfoBoardRegistry.gd` - Board type registry
- `commons/infoboards_3d/content/InfoBoardComponent.gd` - Board generation
- `commons/grid/GridSystem.gd` - Main grid system
- `commons/grid/GridUtilitiesComponent.gd` - Utility management
- `commons/grid/UtilityRegistry.gd` - Utility type definitions
