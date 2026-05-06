# Touch Scrolling for VR Clipboard

## What Changed

The clipboard now supports **hand touch scrolling** in VR! You can touch the text surface and drag up/down to scroll, instead of only using the ray pointer.

## How It Works

### XR Tools Integration

The existing XR Tools `viewport_2d_in_3d_body.gd` already converts hand interactions into touch events:
- `InputEventScreenTouch` - when your hand touches/releases the surface
- `InputEventScreenDrag` - when you drag your finger while touching

These events are automatically sent to the 2D viewport.

### Custom ScrollContainer

**TouchScrollContainer.gd** extends ScrollContainer to handle these touch events:

```gdscript
func _handle_touch(event: InputEventScreenTouch):
    if event.pressed:
        # Start drag - record starting position
    else:
        # End drag - apply momentum

func _handle_drag(event: InputEventScreenDrag):
    # Update scroll position based on drag delta
    scroll_vertical -= delta.y
```

### Scene Structure

**Before:**
```
Control
  └─ RichTextLabel  ← No scrolling!
```

**After:**
```
Control
  └─ ScrollContainer (TouchScrollContainer.gd)
      └─ RichTextLabel  ← Scrollable with touch!
```

## Files Modified

### 1. TextUIControl.tscn
- Added ScrollContainer with TouchScrollContainer script
- Moved RichTextLabel inside ScrollContainer
- Path changed: `Control/RichTextLabel` → `Control/ScrollContainer/RichTextLabel`

### 2. TouchScrollContainer.gd (NEW)
- Custom ScrollContainer that handles touch events
- Supports both VR touch and desktop mouse drag
- Includes momentum scrolling for smooth feel

### 3. codeDisplay.gd
- Updated path to find RichTextLabel in new location
- Tries `Control/ScrollContainer/RichTextLabel` first

## Usage in VR

1. **Grab the clipboard** with your hand (it's already grabbable via GrabPlane)
2. **Touch the text surface** with your other hand's finger
3. **Drag up/down** to scroll the content
4. **Release** and it will coast to a stop (momentum)

The ray pointer still works too! Now you have both options.

## Customization

You can adjust the scrolling feel by modifying exported variables in TouchScrollContainer.gd:

```gdscript
@export var scroll_damping := 0.2       # How much drag affects scroll
@export var scroll_speed := 1.0         # Multiplier for scroll distance
var _momentum_decay := 0.9              # How quickly momentum fades (0.9 = 90% per frame)
```

### Making it More Sensitive
```gdscript
scroll_speed = 2.0  # Doubles the scroll distance per touch movement
```

### Making it Less Momentum-y
```gdscript
_momentum_decay = 0.7  # Faster decay = stops quicker
```

### Disabling Momentum Entirely
```gdscript
_momentum_decay = 0.0  # Stops immediately when you release
```

## Testing on Desktop

The TouchScrollContainer also supports **mouse dragging** for easy desktop testing:
1. Click and hold left mouse button
2. Drag up/down
3. Release

This lets you test without putting on the VR headset!

## Technical Details

### Touch Event Flow

```
XR Controller (Hand)
  ↓
XRToolsInteractableBody (viewport_2d_in_3d_body.gd)
  ↓ Converts 3D position → 2D viewport coordinates
InputEventScreenTouch / InputEventScreenDrag
  ↓ Pushed to viewport
SubViewport
  ↓ Propagated to GUI
TouchScrollContainer._gui_input()
  ↓ Updates scroll position
ScrollContainer.scroll_vertical
  ↓ Shifts content
RichTextLabel (moves visually)
```

### Why ScrollContainer Doesn't Auto-Handle Touch?

Godot's default ScrollContainer **only auto-scrolls** on mobile devices when the OS reports touch events. In VR:
- XR Tools generates **synthetic** touch events via `viewport.push_input()`
- ScrollContainer doesn't recognize these as "real" touch input
- So we need custom `_gui_input()` handling to process them

### Momentum Physics

```gdscript
# Store velocity during drag
_scroll_velocity = -event.relative * scroll_speed

# Apply each frame when not dragging
func _process(delta):
    scroll_vertical += _scroll_velocity.y * delta * 60.0
    _scroll_velocity *= _momentum_decay  # Exponential decay
```

This gives a natural "flick and coast" feel, like scrolling on a phone.

## Troubleshooting

### "Touch doesn't work at all"

**Check:**
1. Is the HandPoseArea properly configured in codeDisplay.tscn?
2. Does the viewport_2d_in_3d_body have a CollisionShape3D?
3. Are your XR controllers tracking properly?

**Debug:**
Add this to TouchScrollContainer.gd:
```gdscript
func _gui_input(event: InputEvent) -> void:
    print("TouchScroll received event: %s" % event)  # Add this!
```

### "Scroll is too slow/fast"

Adjust `scroll_speed` in TouchScrollContainer.gd or via the Inspector.

### "It scrolls the wrong direction"

The script inverts the drag (drag down = scroll up, like natural scrolling). To flip:

```gdscript
# Change this line in _handle_drag():
scroll_vertical = int(_scroll_start.y + delta.y)  # Remove the minus
```

### "It's jittery in VR"

Try increasing damping:
```gdscript
scroll_damping = 0.5  # More damping = smoother but less responsive
```

Or disable momentum:
```gdscript
_momentum_decay = 0.0
```

## Future Enhancements

Possible improvements:

1. **Scroll bars** - Add visual scroll indicator
2. **Overscroll bounce** - Rubber-band effect at top/bottom
3. **Velocity threshold** - Ignore tiny movements
4. **Two-finger zoom** - Pinch to zoom text size
5. **Haptic feedback** - Vibrate controller when scrolling

## Compatibility

- **Works with:** XR Tools Viewport2Din3D, hand tracking, ray pointers
- **Tested on:** Godot 4.x with XR Tools addon
- **Desktop:** Mouse drag works for testing
- **VR:** Touch scrolling with hand tracking
