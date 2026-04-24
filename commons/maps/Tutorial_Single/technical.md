# Tutorial Single — Technical

The map's only artifact is a single grabbable cube. The grab mechanism follows Godot's standard XRController3D input pattern.

```gdscript
class_name GrabbableCube extends RigidBody3D

@export var grab_distance: float = 0.3

var grabbing_controller: XRController3D = null

func _physics_process(_delta: float) -> void:
    if grabbing_controller != null:
        freeze = true
        global_position = grabbing_controller.global_position
    else:
        freeze = false

func _on_controller_button_pressed(button: String, controller: XRController3D) -> void:
    if button != "grip" and button != "trigger": return
    if grabbing_controller == null:
        var distance: float = controller.global_position.distance_to(global_position)
        if distance < grab_distance:
            grabbing_controller = controller

func _on_controller_button_released(button: String, controller: XRController3D) -> void:
    if controller == grabbing_controller:
        grabbing_controller = null
```

## Platform Dimensions

The platform is deliberately small: 4 cells × 3 cells at 1 metre per cell. Godot's CharacterBody3D with a collision layer restricts the learner to the platform surface.

## Teleporter Exit

The teleporter is an Area3D that triggers a scene transition when the learner enters.

```gdscript
class_name Teleporter extends Area3D

@export var target_map: String = ""

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        get_tree().change_scene_to_file("res://commons/maps/" + target_map + "/map.tscn")
```

## VR Input Contract

Godot 4's XR system exposes controller inputs as signals. The relevant signals for the tutorial are `button_pressed`, `button_released`, and `axis_changed`. Grip and trigger produce button events; joystick and trackpad produce axis events.

```gdscript
# Signal connections in _ready
var controllers := get_tree().get_nodes_in_group("xr_controllers")
for controller in controllers:
    controller.button_pressed.connect(_on_controller_button_pressed.bind(controller))
    controller.button_released.connect(_on_controller_button_released.bind(controller))
```

## Haptic Feedback

When the cube is grabbed, a brief haptic pulse confirms the action. The pulse uses the controller's built-in rumble.

```gdscript
func trigger_haptic_pulse(controller: XRController3D, intensity: float = 0.5, duration: float = 0.1) -> void:
    controller.trigger_haptic_pulse("haptic", 0.0, intensity, duration, 0.0)
```

## Accessibility

Some learners cannot close their hand around the cube (hand-tracking limitation or physical constraint). The map accepts grip-button press as a substitute for the grab gesture, and the tutorial diagram shows both.

## Complexity

The grab-and-release logic is O(1) per frame. The scene is minimal — one cube, one platform, one teleporter, one reference diagram. The whole map loads in under 200 milliseconds on typical hardware.

Within the sequence, Tutorial_Single is the VR baseline. Tutorial_Row will next add the first dimension and convert the grip into directed traversal.

## Physics Mode

When not grabbed, the cube is a RigidBody3D subject to gravity. Dropping it from a height produces realistic bouncing. The cube's mass (1 kg) and friction (0.5) are tuned for satisfying physical behaviour.

```gdscript
@export var mass_kg: float = 1.0
@export var friction: float = 0.5
@export var restitution: float = 0.3

func _ready() -> void:
    mass = mass_kg
    physics_material_override = PhysicsMaterial.new()
    physics_material_override.friction = friction
    physics_material_override.bounce = restitution
```

## Grab Stability

When the cube is grabbed, it is frozen (kinematic) and parented to the controller transform. This prevents it from being pushed around by collision with the hand.

```gdscript
func on_grabbed(controller: XRController3D) -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    reparent(controller)

func on_released() -> void:
    reparent(get_tree().root.get_node("World"))
    freeze = false
    # Inherit the controller's velocity at release
    linear_velocity = last_controller_velocity
    angular_velocity = last_controller_angular_velocity
```

The inherited velocity produces satisfying throw behaviour — releasing the cube while moving the controller launches it in the direction of motion.

## Collision Layer

The cube's collision layer is configured so it interacts with the platform but not with the teleporter Area3D. Collision layer masks in Godot are bit flags; the cube is on layer 2 and collides with layers 1 (world) and 2 (other grabbables) but not layer 3 (triggers).

## Tutorial Diagram

The reference diagram shows three states: open hand approaching, closed hand grabbing, open hand releasing. Each state has an arrow and a caption.

```gdscript
class_name TutorialDiagram extends Node3D

func _ready() -> void:
    $OpenApproachingLabel.text = "Open hand approaches"
    $ClosedGrabLabel.text = "Close hand: object attaches"
    $OpenReleaseLabel.text = "Open hand: object releases"
```

## Accessibility

The map supports three interaction modes: VR hand-tracking, VR controller grip, and desktop mouse click. The scene detects the active input method and shows the matching diagram.
## Save State

No save state is needed for the tutorial — it is a pass-through map. The learner enters, practises the grab, walks to the teleporter, and continues. Returning later starts the interaction fresh, which is appropriate for a motor-skill calibration map.

## Performance

One cube, one platform, one teleporter. The scene is trivial to render; the map runs at any practical frame rate on any supported VR device.