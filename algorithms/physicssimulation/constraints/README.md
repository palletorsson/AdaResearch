# Constraints Visualization

## Overview
This scene demonstrates various types of mechanical constraints including hinges, sliders, and pendulums. It showcases how different constraint systems work and how they limit the motion of connected objects.

## Features
- **Hinge Constraint**: Rotational motion around a fixed axis
- **Slider Constraint**: Linear motion along a fixed path
- **Pendulum Constraint**: Gravity-driven oscillating motion
- **Fixed Bases**: Stable anchor points for constraint systems
- **Visual Indicators**: Clear representation of constraint types

## Physics Implementation
- **Constraint Types**: Hinge, Slider, and Pendulum systems
- **Simplified Physics**: Direct position and rotation manipulation
- **Real-time Animation**: Continuous constraint enforcement
- **Visual Feedback**: Color-coded constraint elements

## Controls
- **Reset Simulation**: Restores all constraint systems to initial positions
- **Pause/Resume**: Toggles constraint animation on/off

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Physics**: Simplified constraint simulation
- **Visualization**: Color-coded blocks and constraint indicators

## Files
- `constraints.tscn` - Main scene file
- `Constraints.gd` - Constraint simulation and animation script
- `ConstraintBlock.gd` - Individual block visualization script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see the constraint systems in action
3. Use the UI controls to reset or pause the simulation
4. Observe how different constraint types limit motion
5. Understand the relationship between constraint design and motion

## Educational Value
This visualization helps understand:
- Different types of mechanical constraints
- How constraints limit degrees of freedom
- The relationship between constraint design and motion
- Real-world applications in robotics and machinery
- Constraint-based physics simulation concepts
