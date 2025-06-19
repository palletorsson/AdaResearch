# Cube Animation Tutorial Series
**Learning 3D Transformations with Modular Components**

## 🎯 Tutorial Overview

This folder contains a **progressive tutorial series** that teaches 3D animation concepts using **simple, modular components**. Instead of complex scripts, each animation concept is broken down into focused, easy-to-understand pieces.

### 🧩 **Modular Component Philosophy**
- **One script = One concept** (Position, Rotation, or Scale)
- **Mix and match** components to create complex animations
- **Easy to understand** - no overwhelming code
- **Perfect for beginners** - learn one thing at a time

---

## 📚 Tutorial Progression

### **Chapter 1: Moving Cube** 🔄
**File:** `transformation_cube.tscn`

**What You Learn:**
- Position animation using Tween
- Moving objects up and down
- Basic animation timing and looping

**Structure:**
```
TransformationCube (inherits cube_scene.tscn)
└── TransformationTween (Node) 
    └── Script: TransformationTween.gd
```

**Try This:**
- Change `movement_distance` in Inspector (try `Vector3(2, 0, 0)` for side movement)
- Adjust `duration` to make it faster/slower
- Toggle `loop_animation` on/off

---

### **Chapter 2: Spinning Cube** 🌀  
**File:** `rotating_cube.tscn`

**What You Learn:**
- Rotation animation using Tween
- Spinning objects around different axes
- Understanding rotation degrees vs radians

**Structure:**
```
RotatingCube (inherits cube_scene.tscn)
└── RotationTween (Node)
    └── Script: RotationTween.gd
```

**Try This:**
- Change `rotation_amount` to `Vector3(360, 0, 0)` for X-axis spin
- Try `Vector3(180, 180, 180)` for multi-axis rotation
- Experiment with different `duration` values

---

### **Chapter 3: Moving + Spinning Cube** 🔄🌀
**File:** `transformation_rotation_cube.tscn`

**What You Learn:**
- **Combining components** to create complex animation
- How independent systems work together
- Component interaction and timing

**Structure:**
```
TransformationRotationCube (inherits cube_scene.tscn)
├── TransformationTween (Node) - handles movement
└── RotationTween (Node) - handles spinning
```

**Try This:**
- Set both components to different speeds
- Make one component loop while the other doesn't
- Experiment with movement in different directions while spinning

---

### **Chapter 4: Fully Animated Cube** ✨
**File:** `transformation_rotation_scale_cube.tscn`

**What You Learn:**
- **All three transformations** working together
- Creating rich, complex animations from simple parts
- Scale/size animation concepts

**Structure:**
```
TransformationRotationScaleCube (inherits cube_scene.tscn)
├── TransformationTween (Node) - handles movement
├── RotationTween (Node) - handles spinning  
└── ScaleTween (Node) - handles growing/shrinking
```

**Try This:**
- Create a "breathing" effect with slow scale + rotation
- Make it move in a pattern while spinning and pulsing
- Try different timing combinations for each component

---

## 🔧 Component Reference

### **TransformationTween.gd** (Position Animation)
```gdscript
@export var movement_distance: Vector3 = Vector3(0, 1, 0)  # How far to move
@export var duration: float = 2.0  # How long each movement takes
@export var auto_start: bool = true  # Start automatically
@export var loop_animation: bool = true  # Keep moving back and forth
```

**Key Methods:**
- `start_movement()` - Begin animation
- `stop_movement()` - Stop animation
- `reset_position()` - Return to start

### **RotationTween.gd** (Rotation Animation)  
```gdscript
@export var rotation_amount: Vector3 = Vector3(0, 360, 0)  # Degrees to rotate
@export var duration: float = 3.0  # How long rotation takes
@export var auto_start: bool = true  # Start automatically
@export var loop_animation: bool = true  # Keep rotating
```

**Key Methods:**
- `start_rotation()` - Begin spinning
- `stop_rotation()` - Stop spinning
- `reset_rotation()` - Return to start

### **ScaleTween.gd** (Scale Animation)
```gdscript
@export var scale_amount: float = 1.5  # How big to grow (1.0 = normal)
@export var duration: float = 1.5  # How long scaling takes
@export var auto_start: bool = true  # Start automatically
@export var loop_animation: bool = true  # Keep growing/shrinking
```

**Key Methods:**
- `start_scaling()` - Begin size animation
- `stop_scaling()` - Stop size animation
- `reset_scale()` - Return to normal size

---

## 🎮 How to Use This Tutorial

### **For Students:**
1. **Start with Chapter 1** - Load `transformation_cube.tscn`
2. **Experiment** with Inspector values - see immediate results!
3. **Progress step by step** - don't skip chapters
4. **Try combinations** - mix different settings together
5. **Read the scripts** - they're simple and well-commented

### **For Teachers:**
1. **Demonstrate each concept separately** before combining
2. **Use Inspector values** for live demonstrations
3. **Encourage experimentation** - students learn by trying
4. **Show script simplicity** - remove fear of coding
5. **Build up complexity gradually** - don't overwhelm

### **Common Experiments:**
```gdscript
# Bouncing Ball Effect
movement_distance = Vector3(0, 2, 0)
duration = 0.8

# Fast Spinner  
rotation_amount = Vector3(0, 360, 0)
duration = 0.5

# Breathing Cube
scale_amount = 1.3
duration = 2.0

# Orbiting Motion
movement_distance = Vector3(2, 0, 0)  # Move side to side
rotation_amount = Vector3(0, 360, 0)  # Spin while moving
```

---

## 🏆 Learning Outcomes

By completing this tutorial series, students will understand:

### **🎯 Core Concepts:**
- **Position, Rotation, Scale** - the three fundamental 3D transformations
- **Tween animation** - smooth, time-based movement
- **Component design** - building complex behavior from simple parts
- **Vector3** - 3D coordinate system and directions

### **🛠️ Practical Skills:**
- **Godot Inspector** - changing values and seeing results
- **Scene inheritance** - building on existing work
- **Script attachment** - connecting code to objects
- **Animation timing** - making things feel natural

### **🧠 Programming Principles:**
- **Modular design** - small, focused components
- **Single responsibility** - each script does one thing
- **Reusability** - components work in any scene
- **Debugging ease** - simple scripts are easy to fix

---

## 🚀 Next Steps

After mastering these basics, students can explore:

1. **Pickup Interactions** - Making cubes grabbable in VR
2. **Physics Integration** - Adding realistic movement
3. **Advanced Oscillation** - Mathematical wave-based animation
4. **Custom Animations** - Creating their own movement patterns
5. **Game Mechanics** - Using animated cubes in interactive experiences

---

## 💡 Tips for Success

### **🎯 Start Simple**
- Master one component before adding another
- Use default values first, then experiment
- Don't try to understand everything at once

### **🔧 Experiment Freely**
- Change Inspector values and see what happens
- Try extreme values (very fast, very slow, very big)
- Combine components in unexpected ways

### **📖 Read the Code**
- Each script is only 70-80 lines
- Comments explain what each part does  
- Don't be afraid to look "under the hood"

### **🎮 Have Fun!**
- Animation should be playful and experimental
- There are no wrong answers - only learning opportunities
- Every weird result teaches you something new!

---

*Ready to start animating? Open `transformation_cube.tscn` and begin your journey into 3D animation!* 🎉 