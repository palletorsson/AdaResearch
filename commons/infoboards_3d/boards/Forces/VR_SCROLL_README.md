# VR Scroll Functionality for Info Boards

## Overview

This document describes the VR scroll functionality implemented for the Forces info board and other info boards in the AdaResearch project. The VR scroll system allows users to scroll through text content using VR controller triggers.

## Components

### 1. VRInfoBoardInput.gd
**Location**: `commons/infoboards_3d/base/VRInfoBoardInput.gd`

**Purpose**: Handles VR controller input for scrolling and navigation in info boards.

**Key Features**:
- VR controller detection (left/right controllers)
- Trigger-based scrolling with sensitivity control
- Haptic feedback for user interaction
- Button mapping for navigation (A/X, B/Y, Menu buttons)
- Automatic scroll container targeting

**Usage**:
```gdscript
var vr_input_handler = VRInfoBoardInput.new()
vr_input_handler.set_target_scroll_container(text_scroll)
vr_input_handler.set_info_board_base(self)
vr_input_handler.set_scroll_sensitivity(0.15)
```

### 2. AlgorithmInfoBoardBase.gd Updates
**Location**: `commons/infoboards_3d/base/AlgorithmInfoBoardBase.gd`

**Changes**:
- Added VR input handling by default to all info boards
- Integrated VRInfoBoardInput automatically
- Added VR-specific signal handling
- Configurable VR input parameters

### 3. ForcesInfoBoard.gd Updates
**Location**: `commons/infoboards_3d/boards/Forces/ForcesInfoBoard.gd`

**Changes**:
- Inherits VR functionality from base class
- Custom VR behavior for Forces-specific interactions
- Override methods for custom VR feedback

## VR Input Mapping

### Controller Buttons
- **Trigger (Left/Right)**: Scroll through text content
- **A/X Button**: Next page
- **B/Y Button**: Previous page  
- **Menu Button**: Toggle animation play/pause

### Scroll Behavior
- **Trigger Sensitivity**: Configurable scroll speed (default: 0.15)
- **Scroll Deadzone**: Minimum trigger value to activate scrolling (default: 0.1)
- **Haptic Feedback**: Controller vibration on scroll (configurable intensity)

## Testing

### VRScrollTest.gd
**Location**: `commons/infoboards_3d/boards/Forces/VRScrollTest.gd`

**Purpose**: Test script for verifying VR scroll functionality.

**Test Commands**:
- **Key 1**: Simulate VR trigger press
- **Key 2**: Test scroll container access
- **Key 3**: Test VR controller detection

### Test Scene
**Location**: `commons/infoboards_3d/boards/Forces/VRScrollTest.tscn`

**Usage**: Load this scene to test VR scroll functionality with the Forces info board.

## Configuration

### VR Input Parameters
```gdscript
# Scroll sensitivity (higher = faster scrolling)
vr_input_handler.set_scroll_sensitivity(0.15)

# Haptic feedback settings
vr_input_handler.set_haptic_feedback(true, 0.3)

# Scroll deadzone (minimum trigger value)
scroll_deadzone = 0.1
```

### InteractionArea Setup
The `InteractionArea` in `HandheldInfoBoard.tscn` provides the collision detection for VR interaction:

```gdscript
# InteractionArea configuration
collision_layer = 5242881  # VR interaction layer
collision_mask = 0         # No collision with other objects
```

## VR Controller Detection

The system automatically detects VR controllers using multiple methods:

1. **XR Origin Group**: Searches for `xr_origin` group
2. **Controller Names**: Looks for "LeftController" and "RightController"
3. **XR Controllers Group**: Searches for controllers in `xr_controllers` group
4. **Fallback**: Searches for any `XRController3D` nodes

## Integration with Existing Info Boards

All info boards now automatically include VR scroll functionality through the base class. No additional setup is required for new info boards.

### For New Info Boards
1. Extend `AlgorithmInfoBoardBase`
2. VR functionality is automatically included
3. Override `_on_vr_scroll_changed()` and `_on_vr_input_detected()` for custom behavior

### For Existing Info Boards
The VR functionality is automatically added to all existing info boards that extend `AlgorithmInfoBoardBase`.

## Troubleshooting

### Common Issues

1. **VR Controllers Not Detected**
   - Ensure XR is properly initialized
   - Check that controllers are in the scene
   - Verify controller naming conventions

2. **Scroll Not Working**
   - Check that `text_scroll` is properly assigned
   - Verify trigger sensitivity settings
   - Ensure VR input handler is created

3. **Haptic Feedback Not Working**
   - Check controller haptic support
   - Verify haptic intensity settings
   - Ensure controller is properly connected

### Debug Information
The system provides debug output for:
- VR controller detection
- VR input handler configuration
- Scroll position changes
- Button press events

## Performance Considerations

- VR input is processed every frame for responsive interaction
- Haptic feedback is throttled to prevent excessive vibration
- Scroll accumulation prevents micro-movements from causing scrolling
- Controller detection is cached to avoid repeated searches

## Future Enhancements

1. **Gesture Recognition**: Add swipe gestures for scrolling
2. **Voice Commands**: Integrate voice navigation
3. **Eye Tracking**: Use eye tracking for scroll direction
4. **Custom Haptic Patterns**: Different haptic patterns for different actions
5. **Scroll Speed Adaptation**: Dynamic scroll speed based on content length

## Dependencies

- **Godot XR Tools**: For VR controller interaction
- **OpenXR**: For VR runtime support
- **Godot 4.x**: For 3D scene and input handling

## Related Files

- `commons/infoboards_3d/base/VRInfoBoardInput.gd` - Core VR input handler
- `commons/infoboards_3d/base/AlgorithmInfoBoardBase.gd` - Base info board class
- `commons/infoboards_3d/boards/Forces/ForcesInfoBoard.gd` - Forces-specific implementation
- `commons/infoboards_3d/boards/Forces/VRScrollTest.gd` - Test script
- `commons/infoboards_3d/base/HandheldInfoBoard.tscn` - 3D handheld board template
