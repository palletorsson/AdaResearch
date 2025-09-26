# Basic VR Controller Interaction

- Query XRController3D nodes to read button and axis states.
- Use actions defined in the OpenXR action map (xr_get_action_state).
- Cast rays from the controller to interact with objects in the world.

```gdscript
# Detect trigger press on the right controller
var controller := $RightController
if controller.is_action_pressed("trigger_click"):
	print("Trigger pressed")
```
