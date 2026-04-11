# IK Arm Demo

Standalone showcase of TwoBoneIK3D arm inverse kinematics. Two procedural arms with animated targets trace figure-8 patterns, demonstrating the same IK solver used for VR body tracking without requiring a headset.

## How It Works

The demo builds a torso with two skeletal arms, each containing three bones (UpperArm, LowerArm, Hand) driven by TwoBoneIK3D modifiers. Animated Marker3D targets move in offset figure-8 patterns during `_physics_process`, and the IK solver negotiates joint positions each frame. The arm meshes are procedurally skinned ArrayMeshes with per-bone vertex weights, so they deform naturally as the skeleton tracks the targets.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| arm_color | Color | Color(0.85, 0.75, 0.65) |
| shoulder_width | float | 0.36 |
| upper_arm_length | float | 0.28 |
| lower_arm_length | float | 0.25 |

## Features

- Two independently animated arms with TwoBoneIK3D solvers
- Procedurally generated skinned mesh with per-bone vertex weights
- Animated figure-8 target patterns with visible emissive target spheres
- Pole targets for elbow direction hints
- Capsule torso and sphere head for body context
- Yellow emissive shoulder joint markers
- Configurable via `apply_grid_config`

## Files

- `ik_arm_demo.gd` -- Procedural IK arm builder with animated targets and skinned meshes
- `ik_arm_demo.tscn` -- Scene file
