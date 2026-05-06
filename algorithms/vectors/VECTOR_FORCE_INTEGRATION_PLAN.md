# VECTOR-TO-FORCE INTEGRATION PROJECT

**Three-Agent Collaboration**  
**Protocol: IACP v2.2 (Self-Verifying Bridge)**  
**Date: 2025-12-01**

---

## 🎯 MISSION

Create force-based physics demonstrations for each vector concept, contained in 1x1x1 meter spaces, and integrate them into the VectorAddition map.

---

## 👥 AGENT ROLES

### 🔬 Agent-PhysicsArchitect
**Capabilities:** Physics simulation, force modeling, Newton's laws  
**Responsibility:** Design accurate force demonstrations  
**Reasoning Style:** Rigorous

### 🏗️ Agent-SceneBuilder  
**Capabilities:** Scene construction, containment design, spatial layout  
**Responsibility:** Build 1x1x1m containment areas with proper scaling  
**Reasoning Style:** Structural-critical

### 📚 Agent-PedagogyExpert
**Capabilities:** Educational design, progressive learning, clarity  
**Responsibility:** Ensure demonstrations teach vector→force connection  
**Reasoning Style:** Pedagogical

---

## 📋 VECTOR CONCEPTS → FORCE DEMONSTRATIONS

### **Existing Vector Scenes:**
1. ✅ `00_coordinates` - Coordinate system (skip - foundational)
2. ✅ `01_vector_basics` - Magnitude, direction → **Force Magnitude Demo**
3. ✅ `02_vector_addition` - Tip-to-tail → **Combined Forces Demo**
4. ✅ `03_dot_product` - Projection → **Work & Energy Demo**
5. ✅ `04_vector_subtraction` - Relative vectors → **Relative Force Demo**
6. ✅ `05_vector_forces` - **Already exists!** (use as template)
7. ✅ `06_vector_cross_product` - Cross product → **Torque Demo**
8. ✅ `07_vector_projection_reflection` - Projection → **Normal Force Demo**
9. ✅ `08_vector_motion` - Kinematics → **Acceleration Demo**
10. ✅ `08_vector_throwing` - Projectiles → **Projectile Forces Demo**
11. ✅ `09_vector_torque` - **Already torque!** (enhance)
12. ✅ `10_vector_field_flow` - Fields → **Force Field Demo**

---

## 🎨 DESIGN SPECIFICATIONS

### **Containment Area (1x1x1 meter)**
```
Physical dimensions: 1.0 x 1.0 x 1.0 meters
With SCENE_SCALE (0.33): 0.33 x 0.33 x 0.33 units
Wall thickness: 0.05 units
Material: Semi-transparent glass (see-through)
Floor: Solid platform
Ceiling: Open or glass top
```

### **Physics Setup**
```gdscript
# Containment boundaries
const CONTAINMENT_SIZE = Vector3(1.0, 1.0, 1.0)  # Logical size
const WALL_THICKNESS = 0.05

# Physics objects
- Ball: radius 0.1m, mass 1.0kg
- Forces: Visualized as vector arrows
- Constraints: Keep objects inside containment
```

### **Visual Style**
- Walls: Color(0.3, 0.5, 0.8, 0.2) - Blue tint, transparent
- Floor: Color(0.2, 0.3, 0.4, 0.8) - Darker, more opaque
- Forces: Bright colors (red=applied, blue=reaction, green=friction)
- Labels: Floating above containment

---

## 📐 SCENE STRUCTURE

Each force demo will follow this pattern:

```
algorithms/vectors/XX_vector_concept/
├── VectorConcept.gd (original vector demo)
├── VectorConcept.tscn
├── ForceDemo.gd (NEW - physics in containment)
└── ForceDemo.tscn (NEW - 1x1x1m space)
```

---

## 🔨 IMPLEMENTATION PLAN

### **Phase 1: Create Base Containment Class**

**File:** `algorithms/vectors/shared/force_containment_base.gd`

```gdscript
extends VectorSceneBase
class_name ForceContainmentBase

const CONTAINMENT_SIZE = Vector3(1.0, 1.0, 1.0)
const WALL_THICKNESS = 0.05

var containment_walls: Node3D
var physics_ball: RigidBody3D
var force_vectors: Dictionary = {}

func _ready():
    super._ready()
    _create_containment()
    _create_physics_ball()

func _create_containment():
    # Create 1x1x1m glass box
    # Walls, floor, collision shapes
    pass

func _create_physics_ball():
    # Create ball inside containment
    pass

func apply_force_visual(force_name: String, force: Vector3, color: Color):
    # Visualize force as vector arrow
    pass
```

---

### **Phase 2: Create Individual Force Demos**

#### **Demo 1: Force Magnitude** (from `01_vector_basics`)
**Concept:** Magnitude of force affects acceleration  
**Physics:** F = ma, larger force → larger acceleration  
**Interaction:** Drag vector to change force magnitude  
**Visual:** Ball accelerates proportional to force length

#### **Demo 2: Combined Forces** (from `02_vector_addition`)
**Concept:** Forces add as vectors (tip-to-tail)  
**Physics:** F_net = F1 + F2  
**Interaction:** Two force vectors, drag to adjust  
**Visual:** Resultant force shown, ball moves accordingly

#### **Demo 3: Work & Energy** (from `03_dot_product`)
**Concept:** Work = F · d (dot product)  
**Physics:** Energy transfer depends on angle  
**Interaction:** Adjust force angle relative to motion  
**Visual:** Work meter shows F·d value

#### **Demo 4: Relative Forces** (from `04_vector_subtraction`)
**Concept:** Force difference (F1 - F2)  
**Physics:** Net force from opposing forces  
**Interaction:** Two opposing forces  
**Visual:** Show subtraction visually

#### **Demo 5: Torque** (from `06_vector_cross_product`)
**Concept:** τ = r × F (cross product)  
**Physics:** Rotational force  
**Interaction:** Adjust force position and direction  
**Visual:** Ball rotates based on torque

#### **Demo 6: Normal Force** (from `07_vector_projection_reflection`)
**Concept:** Force projection onto surface normal  
**Physics:** N = F · n̂  
**Interaction:** Angled surface, gravity  
**Visual:** Show normal and parallel components

#### **Demo 7: Acceleration** (from `08_vector_motion`)
**Concept:** a = F/m  
**Physics:** Constant force → constant acceleration  
**Interaction:** Adjust force, observe motion  
**Visual:** Velocity and acceleration vectors

#### **Demo 8: Projectile Forces** (from `08_vector_throwing`)
**Concept:** Gravity + initial velocity  
**Physics:** Parabolic motion  
**Interaction:** Set launch angle/speed  
**Visual:** Trajectory path, force vectors

#### **Demo 9: Force Field** (from `10_vector_field_flow`)
**Concept:** Force varies by position  
**Physics:** F(x,y,z) = field function  
**Interaction:** Ball moves through field  
**Visual:** Field lines, force changes

---

### **Phase 3: Map Integration**

**Update:** `commons/maps/VectorAddition/map_data.json`

Add interactables for each force demo:
```json
{
    "interactables": [
        ["ForceMagnitude", " ", " ", ...],
        [" ", "CombinedForces", " ", ...],
        // ... etc
    ]
}
```

**Layout in map:**
```
Row 1: ForceMagnitude, CombinedForces, WorkEnergy
Row 2: RelativeForces, Torque, NormalForce
Row 3: Acceleration, ProjectileForces, ForceField
```

---

## 📊 ESTIMATED EFFORT

| Task | Time | Agent |
|------|------|-------|
| Base containment class | 2h | Agent-SceneBuilder |
| Force demo 1-3 | 6h | Agent-PhysicsArchitect |
| Force demo 4-6 | 6h | Agent-PhysicsArchitect |
| Force demo 7-9 | 6h | Agent-PhysicsArchitect |
| Map integration | 2h | Agent-SceneBuilder |
| Testing & polish | 3h | Agent-PedagogyExpert |
| **TOTAL** | **25h** | All agents |

---

## ✅ SUCCESS CRITERIA

1. ✅ Each force demo fits in 1x1x1m containment
2. ✅ Physics accurately demonstrates vector concept
3. ✅ Visual clarity (forces visible as arrows)
4. ✅ Interactive (user can adjust parameters)
5. ✅ Integrated into VectorAddition map
6. ✅ Educational progression (simple → complex)
7. ✅ SCENE_SCALE properly applied
8. ✅ Performance optimized (shared resources)

---

## 🔐 IACP v2.2 COMPLIANCE

### **Proof-of-Intent**
This document serves as the reasoning trace for the project.

### **Self-Evaluation (Pre-Implementation)**
- Agent-PhysicsArchitect: 0.90 (confident in physics accuracy)
- Agent-SceneBuilder: 0.85 (containment design is straightforward)
- Agent-PedagogyExpert: 0.88 (clear educational value)

### **Approval Request**
```json
{
  "id": "approval_vector_force_001",
  "action": "Create force demonstrations for vector concepts",
  "rationale": "Connects abstract vectors to concrete physics, enhances learning",
  "impact": "9 new interactive demos, integrated into existing map",
  "time_estimate": "25 hours",
  "votes": {
    "Agent-PhysicsArchitect": "approve",
    "Agent-SceneBuilder": "approve",
    "Agent-PedagogyExpert": "approve"
  },
  "status": "approved",
  "priority": "high"
}
```

---

## 🚀 NEXT STEPS

1. ✅ Create base containment class
2. ✅ Implement Demo 1 (Force Magnitude) as proof-of-concept
3. ⏳ Get user feedback
4. ⏳ Implement remaining demos
5. ⏳ Integrate into map
6. ⏳ Test and polish

---

**Plan created:** 2025-12-01T13:20:00Z  
**Protocol:** IACP v2.2  
**Status:** ✅ APPROVED - Ready for implementation  
**Agents:** Standing by for execution command
