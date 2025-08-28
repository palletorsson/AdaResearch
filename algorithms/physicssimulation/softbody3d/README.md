# Soft Body 3D Physics Variations

A comprehensive demonstration scene showcasing different types of soft body physics with interactive elements, state management, and educational demonstrations.

## 🎯 Overview

This scene demonstrates multiple soft body variations with different physics properties and behaviors. The main attraction is **10 sphere soft bodies** with varying simulation precision and pressure coefficients, plus additional soft body types (box, cylinder, capsule). The scene automatically cycles through different demonstration modes and provides interactive controls for hands-on exploration of soft body physics.

## 🧱 Soft Body Variations

### **10 Sphere Variations** (Main Demonstration)
The scene features 10 identical sphere meshes with different physics configurations arranged in two rows:

**Back Row (Z = -6)**: Low to Medium Pressure (0.05 - 0.25)
- **SphereSoftBody01**: Precision 5, Pressure 0.05 - Very soft, minimal detail
- **SphereSoftBody02**: Precision 6, Pressure 0.1 - Soft, basic physics
- **SphereSoftBody03**: Precision 7, Pressure 0.15 - Medium-soft
- **SphereSoftBody04**: Precision 8, Pressure 0.2 - Balanced behavior
- **SphereSoftBody05**: Precision 9, Pressure 0.25 - Slightly firmer

**Front Row (Z = -3)**: Medium to High Pressure (0.3 - 1.0)
- **SphereSoftBody06**: Precision 10, Pressure 0.3 - Firm, detailed
- **SphereSoftBody07**: Precision 12, Pressure 0.4 - Very firm
- **SphereSoftBody08**: Precision 15, Pressure 0.5 - High pressure
- **SphereSoftBody09**: Precision 20, Pressure 0.7 - Extremely firm
- **SphereSoftBody10**: Precision 25, Pressure 1.0 - Maximum firmness

### **Additional Soft Body Types**

### 1. **Box**
- **Properties**: Structured deformation
- **Physics**: Pressure: 0.1, Simulation Precision: 6

### 2. **Cylinder**
- **Properties**: Fluid-like behavior
- **Physics**: Pressure: 0.3, Simulation Precision: 10

### 3. **Capsule**
- **Properties**: Organic movement
- **Physics**: Pressure: 0.4, Simulation Precision: 12

## 🔄 Demonstration Modes

The scene automatically cycles through four demonstration modes:

### 1. **Physics Variations Demo**
- Applies different pressure values to each body
- Shows how pressure affects deformation behavior
- Demonstrates pressure coefficient variations

### 2. **Interactive Forces Demo**
- Activates wind zones and force fields
- Bodies respond to environmental forces
- Shows external force interactions

### 3. **State Cycling Demo**
- Each body cycles through states at different rates
- Demonstrates state-based behavior changes
- Shows material and physics transitions

### 4. **Collision Demo**
- Applies random impulses to create collisions
- Shows soft body collision behavior
- Demonstrates momentum and energy transfer

## 🎮 Interactive Features

### **Wind Zone**
- Located at the center of the scene
- Applies horizontal wind forces to soft bodies
- Bodies entering the zone are affected by wind

### **Force Field**
- Creates a central attraction force
- Bodies are pulled toward the center
- Demonstrates force field physics

### **UI Controls**
- **Next Demo Mode**: Manually cycle demonstration modes
- **Random Physics**: Apply random physics properties
- **Reset All**: Return all bodies to default properties
- **Apply Impulse**: Add random forces to all bodies

## 🎨 Visual Features

### **Material Properties**
- Semi-transparent materials for better visibility
- Different colors for each body type
- Dynamic color changes based on state
- Metallic and roughness variations

### **State-Based Visuals**
- **Idle**: Subtle color variations
- **Active**: Brighter, more vibrant colors
- **Deformed**: Intense, saturated colors
- **Recovering**: Gradual return to original colors

## 🔧 Technical Details

### **Scripts**
- `softbody3d.gd`: Individual soft body behavior and physics
- `softbody3d_scene_controller.gd`: Overall scene management

### **Physics Parameters**
- **Simulation Precision**: Varies by complexity (6-12)
- **Pressure Coefficient**: Controls internal pressure and deformation
- **Mesh Type**: Determines the base shape and behavior

### **State Management**
- Four distinct states with automatic transitions
- Configurable state duration
- State-specific physics and visual changes

## 🚀 Usage

### **Running the Scene**
1. Open the scene in Godot
2. Press Play to start the demonstration
3. Watch the automatic cycling between modes
4. Use UI controls for manual interaction

### **Customization**
- Modify `type_properties` in the script for different physics
- Adjust `state_duration` for timing changes
- Add new demonstration modes in the controller
- Modify materials and colors in the scene

### **Performance Notes**
- Higher simulation precision increases CPU usage
- More soft bodies = more physics calculations
- Consider reducing precision for lower-end devices

## 📚 Educational Value

This scene demonstrates:
- **Physics Principles**: Pressure, forces, deformation
- **Material Behavior**: How different materials respond to forces
- **State Management**: Complex behavior through simple state machines
- **Interactive Physics**: Real-time physics property manipulation
- **Visual Feedback**: How physics affects visual appearance

## 🔮 Future Enhancements

Potential additions:
- More soft body shapes (toroid, custom meshes)
- Advanced material properties (elasticity, plasticity)
- Particle system integration
- Audio-reactive physics
- VR controller interaction
- Physics property animation curves
- Multi-body constraints and connections

## 🐛 Troubleshooting

### **Common Issues**
- **Bodies not moving**: Check if physics are enabled
- **Excessive deformation**: Reduce pressure_coefficient
- **Unstable physics**: Adjust simulation_precision
- **Performance issues**: Reduce simulation_precision

### **Debug Functions**
- Use `print_status()` on individual bodies
- Use `print_scene_status()` on the scene controller
- Check console output for physics information

---

*This scene provides a comprehensive foundation for understanding and experimenting with soft body physics in Godot 4.*
