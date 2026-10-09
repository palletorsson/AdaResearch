# What happens after you let go?

This study comes after **Rotation**. It uses the retained values and `_process(delta)` introduced in Point Zero, local frames from Coordinates, and a turn about an axis. The optional corner record returns to Point Trace. Day Zero supplies a project you can open and run.

The room, plates, hinges, mouse input and camera are supplied. The code you change is [score.gd](score.gd). It is the actual policy used by the study, separated from the fabrication and viewer.

## First, keep a change

Open `project.godot` and run the supplied scene. Select a joint, move its slider, and let go. You can also drag a plate directly. The rose colour identifies the selected plate. Other plates can move because they are descendants of its joint.

The score gives an angle to the existing artifact:

```gdscript
specimen.set_hinge(joint, degrees)
```

The artifact clamps that angle to the joint’s limits and writes its rotation. No instruction returns it afterward. Remaining still here is a retained value; the program has not calculated the friction needed to hold real metal up.

## Then, decide what release means

These lines in the learner score determine what follows a release:

```gdscript
var return_on_release := false

func release() -> void:
    returning = return_on_release
```

The buttons choose this policy without replacing the shape. **Return it** sets the policy; the next release starts the return. **Leave it** cancels any return and keeps the current pose. Change `degrees_per_second` from `45.0` to `15.0`, run again, choose Return it and repeat the same movement. The target stays the same; the time allowed for your intervention changes.

The return uses this line for each joint:

```gdscript
var next := move_toward(float(current[joint]), float(starting_pose[joint]), degrees_per_second * delta)
```

`current` and `starting_pose` are arrays of angles in degrees. Their indices refer to the same five joints. `delta` converts the chosen angular speed into this frame’s step. `move_toward` stops at the target rather than overshooting it. The rest of `advance()` applies those values and stops once they all arrive. Read the complete executable [score](score.gd) after making the comparison.

The stored starting pose is a reference selected by us. There is no mathematical requirement for the object to return to it.

## Carry the trace into a new problem

With Leave it selected, enable **Follow one corner**. The marker belongs to the far corner of plate 5. Keep the camera still.

1. Start again. Set joint 1 to 50 degrees, then joint 2 to 30 degrees.
2. Keep a screenshot or note of the corner’s path.
3. Start again. Set joint 2 to 30 degrees, then joint 1 to 50 degrees.

The final local angles are identical. So is the final pose. The intermediate positions and their traces differ. This is not the earlier experiment of applying world-X and world-Y rotations in opposite orders to the same rigid body. Here you assign values to two different joints in a fixed hierarchy.

**A first work:** keep this joint tree and give it your own starting pose, reachable-angle choices and release rule. Make two versions with identical geometry and ask someone to describe what each allows their action to leave behind. Show their actions before explaining your rule.

## What remains supplied

The production specimen builds the meshes and their parent-child transforms. Its local hinges can be inspected later; you do not need to reproduce its material library, initial-pose search, thick XR pickup volumes or caption system for this exercise. The desktop kit intentionally runs without the XR addon.

The model does not solve gravity, plate-to-plate contact or contact with the plinth while a hinge is moved. The initial pose is checked by sampling; a later edit can still pass through another surface. Studying those physical constraints is a later Form Finding task. A typed angle and a valid transform do not, by themselves, make a physically possible object.
