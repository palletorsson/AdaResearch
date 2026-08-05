# VR Gravity Gun

A VR gravity gun that attracts and launches small objects using force fields.

## Files Created

### Gravity Gun
- **gravity_gun.gd** - Main gravity gun script
- **gravity_gun.tscn** - Gravity gun scene (attach to player's hand)

### Shootable Objects
- **shootable_sphere.gd** - Small sphere that can be picked up and shot
- **shootable_sphere.tscn** - Shootable sphere scene

### Test Scene
- **gravity_gun_test_scene.gd** - Test scene with 10 spheres
- **gravity_gun_test_scene.tscn** - Test scene (spawn in world to test)

## How to Use

### 1. Add Gravity Gun to Player Hand

In your VR player scene:
1. Find your XRController3D node (left or right hand)
2. Instance `res://algorithms/forces/gravity_gun.tscn` as a child
3. Position it relative to the controller (usually forward and down slightly)

Example hierarchy:
```
XROrigin3D
├── RightController (XRController3D)
│   └── GravityGun
```

### 2. Add Test Scene to World

Instance `gravity_gun_test_scene.tscn` in your world to spawn 10 spheres for testing.

### 3. Using the Gravity Gun

**Attraction:**
- Objects within the attraction radius (default 1.5m) are pulled toward the gun
- Objects get "captured" when they get close enough (0.2m)
- Up to 5 objects can be captured at once

**Launching:**
- Press the VR controller trigger button to launch all captured objects
- Objects launch in the direction the gun is pointing
- Objects have gravity enabled after launch

## Customization

### Gravity Gun Settings

In the Inspector, you can adjust:

**Attraction Settings:**
- `attraction_radius` - Range of force field (default: 1.5m)
- `attraction_strength` - Force strength (default: 15.0, increased to lift objects)
- `capture_radius` - Distance to capture objects (default: 0.2m)
- `max_captured_objects` - Max objects held (default: 5)
- `disable_gravity_on_attraction` - Disables gravity while attracting (default: true)

**Launch Settings:**
- `launch_force` - Launch velocity (default: 15.0, increased for better throw)
- `launch_spread` - Randomness in launch (default: 0.1)
- `launch_cooldown` - Time before objects can be recaptured (default: 1.0 sec)

**Visual Settings:**
- `show_force_field` - Display force field sphere (default: true)
- `force_field_color` - Color of force field (default: cyan)
- `show_gun_model` - Show gun model (default: true)
- `gun_color` - Color of gun (default: light blue)

**VR Controller:**
- `controller_path` - Path to XRController3D (auto-detected from parent)
- `trigger_button_action` - Button action name for launching (default: "trigger")
  - Set to match your hand's trigger_action property (commonly "trigger" or "trigger_click")

**Debug:**
- `debug` - Enable console debug output (default: false)
  - Set to true to see detailed logging about attraction, capture, and launching

### Test Scene Settings

**Spawn Patterns:**
- `arrangement` - Choose: "grid", "ramp", "ring", or "stack" (default: "grid").
  Promoted 2026-08-05 from `spawn_pattern`; the old words "circle" and "pyramid"
  still work through `set_pattern()`, and a map can set it with
  `gravity_gun_test_scene#arrangement:ring`.
- `spawn_count` - Number of spheres (default: 10). Note: "grid" and "stack" build a
  fixed ten regardless; only "ring" reads this.
- `spawn_spacing` - Distance between spheres (default: 0.3m)
- `spawn_gravity_scale` - Multiplies each spawned sphere's gravity (default: 1.0).
  0.0 holds the collection in the pose it was filed in — for captures and stills.
- `randomize_colors` - Use random colors from palette
- `color_seed` - 0 (default) recolours on every launch; any positive value seeds it

## How It Works

### Force Field Physics
The gravity gun uses an inverse-square law for attraction:
```gdscript
force = attraction_strength / (distance * distance)
```

Objects are pulled toward the gun's muzzle point, and captured when close enough.

### Object Requirements

Objects must be RigidBody3D to work with the gravity gun. They should:
- Have collision layer 1 or 2
- Not be in the "no_gravity_gun" group (if you want to exclude them)
- Not be frozen initially

### VR Integration

The gun automatically detects the parent XRController3D and listens for trigger button presses. You can also call `launch_all()` manually from code.

## Example Usage in Code

```gdscript
# Get reference to gravity gun
var gravity_gun = $XROrigin3D/RightController/GravityGun

# Change settings
gravity_gun.set_attraction_strength(10.0)
gravity_gun.set_attraction_radius(2.0)

# Check how many objects are captured
var count = gravity_gun.get_captured_count()

# Manually trigger launch
gravity_gun.launch_all()

# Release objects without launching
gravity_gun.release_all()
```

## Signals

The gravity gun emits these signals:
- `object_captured(object)` - When an object is captured
- `object_launched(object, velocity)` - When a single object is launched
- `objects_launched(count)` - When all objects are launched

## Tips

1. **Adjust attraction strength** based on object mass
2. **Increase capture radius** to grab objects more easily
3. **Change spawn pattern** in test scene to "pyramid" for a fun stack
4. **Disable force field visual** in production for cleaner look
5. **Add custom colors** to spheres for different object types

## Troubleshooting

### Objects just roll on the ground instead of floating up
✓ Fixed! The gun now automatically disables gravity on objects while attracting them.
- Default `attraction_strength` increased to 15.0
- Set `disable_gravity_on_attraction` to false if you want objects to stay grounded

### Trigger button not working
✓ Fixed! Changed default to "trigger" to match XR Tools hand setup.

The gun prints debug messages every second showing the polling status:
```
[GravityGun] Polling - Controller: RightHand Active: true Button: trigger Pressed: false Captured: 3
[GravityGun] *** TRIGGER PRESSED! Launching 3 objects...
```

If you don't see polling messages:
1. Check the gravity gun is a child of an XRController3D node
2. Verify the controller is active when you're in VR

If polling shows but trigger doesn't fire:
1. Check the `trigger_button_action` matches your hand's `trigger_action` property
2. In base.tscn, the hand uses `trigger_action = "trigger"`
3. Set the gravity gun's `trigger_button_action` to match

### Controller not detected
Check the console output:
```
[GravityGun] Connected to controller: RightController
```
If you see a warning, make sure the gun is a child of an XRController3D node.

### Objects captured but nothing happens when pressing trigger
✓ Fixed! Objects were being launched but immediately recaptured.

Now objects have a 1-second cooldown after launch where they can't be recaptured:
```
[GravityGun] 🚀 LAUNCHING 5 OBJECTS!
[GravityGun]   → Launched ShootableSphere at velocity 15.0
[GravityGun] ✓ Successfully launched 5 objects
[GravityGun] Object ShootableSphere can now be recaptured  (after 1 sec)
```

If objects still don't fly far enough:
- Increase `launch_force` (try 20.0 or 25.0)
- Increase `launch_cooldown` to 2.0 seconds

## Integration with Existing Systems

The gravity gun works with:
- Existing force systems in `res://algorithms/forces/`
- Destructible objects in `res://algorithms/vectors/08_vector_throwing/destructibles/`
- Any RigidBody3D object in your scene

Objects can be shot at destructible targets like:
- `health_cube.tscn` (requires 2 hits)
- `simple_destroy_cube.tscn` (breaks on impact)
- Other destructibles in the destructibles folder
