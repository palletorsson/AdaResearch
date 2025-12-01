# PARTICLE OPTIMIZATION - QUICK IMPLEMENTATION GUIDE

**Three-Agent Collaboration Output**  
**Protocol: IACP v2.2**

---

## 🎯 PHASE 1: CORE OPTIMIZATIONS (APPROVED)

### 1️⃣ CREATE SHARED RESOURCES (1 hour)

**File:** `core/particle_resources.gd`

```gdscript
# Singleton for shared particle resources
extends Node

# Shared meshes
var sphere_mesh: SphereMesh
var box_mesh: BoxMesh

# Shared materials
var particle_material: ShaderMaterial
var confetti_material: ShaderMaterial

func _ready():
    create_shared_meshes()
    create_shared_materials()

func create_shared_meshes():
    # Sphere for regular particles
    sphere_mesh = SphereMesh.new()
    sphere_mesh.radius = 0.05
    sphere_mesh.height = 0.1
    
    # Box for confetti
    box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(0.08, 0.02, 0.05)

func create_shared_materials():
    # TODO: Create shader materials
    pass

func get_sphere_mesh() -> SphereMesh:
    return sphere_mesh

func get_box_mesh() -> BoxMesh:
    return box_mesh
```

**Register as autoload:**
- Project Settings → Autoload
- Name: `ParticleResources`
- Path: `res://core/particle_resources.gd`

---

### 2️⃣ REFACTOR PARTICLE.GD TO MULTIMESH (2 hours)

**File:** `core/particle.gd`

**BEFORE (lines 52-68):**
```gdscript
func create_default_visual():
    mesh_instance = MeshInstance3D.new()
    var sphere = SphereMesh.new()  # ❌ New mesh per particle
    sphere.radius = size
    mesh_instance.mesh = sphere
    
    material = StandardMaterial3D.new()  # ❌ New material per particle
    material.albedo_color = primary_pink
    # ... more material setup
    mesh_instance.material_override = material
    add_child(mesh_instance)
```

**AFTER:**
```gdscript
# At class level
var multimesh_instance: MultiMeshInstance3D
var instance_id: int = -1

func create_default_visual():
    # Get shared mesh from singleton
    var shared_mesh = ParticleResources.get_sphere_mesh()
    
    # Create MultiMesh if not exists (done by emitter)
    # Particle just stores its instance ID
    # Visual updates happen via instance custom data
    pass

func update_visual():
    # Update MultiMesh instance custom data
    if multimesh_instance and instance_id >= 0:
        var alpha = lifespan / max_lifespan
        # Set custom data: vec4(color.rgb, alpha)
        var custom_data = Color(primary_pink.r, primary_pink.g, primary_pink.b, alpha)
        multimesh_instance.multimesh.set_instance_custom_data(instance_id, custom_data)
        multimesh_instance.multimesh.set_instance_transform(instance_id, Transform3D(Basis(), position))
```

**Note:** This requires ParticleEmitter to manage the MultiMesh

---

### 3️⃣ OPTIMIZE CLEANUP LOOP (30 minutes)

**File:** `core/particle_emitter.gd` (lines 86-96)

**BEFORE (O(n²)):**
```gdscript
func cleanup_dead_particles():
    var dead_particles: Array[Particle] = []
    
    for particle in particles:
        if particle.is_dead():
            dead_particles.append(particle)
    
    for particle in dead_particles:
        particles.erase(particle)  # ❌ O(n) inside loop!
        particle.queue_free()
```

**AFTER (O(n)):**
```gdscript
func cleanup_dead_particles():
    var i = 0
    while i < particles.size():
        if particles[i].is_dead():
            # Free the particle
            particles[i].queue_free()
            
            # Swap with last element
            particles[i] = particles[particles.size() - 1]
            
            # Remove last element
            particles.pop_back()
            
            # Don't increment i (check swapped element)
        else:
            i += 1
```

**Performance:** O(n) instead of O(n²)

---

### 4️⃣ ADD PARAMETRIC PHYSICS (1 hour)

**File:** `core/particle.gd`

**Add exports:**
```gdscript
# Physics properties
var velocity: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO
var mass: float = 1.0

# NEW: Parametric controls
@export var damping: float = 0.98  # Air resistance
@export var restitution: float = 0.5  # Bounce coefficient

# Lifespan (in seconds, not frames!)
var lifespan: float = 4.0
var max_lifespan: float = 4.0
@export var decay_rate: float = 1.0  # Units per second
```

**Update physics (line 70-82):**
```gdscript
func update(delta: float):
    # Apply damping (air resistance)
    velocity *= damping
    
    # Update velocity
    velocity += acceleration * delta
    
    # Update position
    position += velocity * delta
    
    # Decrease lifespan (frame-rate independent!)
    lifespan -= decay_rate * delta  # ✅ Fixed!
    
    # Clear acceleration for next frame
    acceleration = Vector3.ZERO
    
    # Update visual appearance
    update_visual()
```

**Update boundary collision (line 109-118):**
```gdscript
func constrain_to_tank():
    if not fish_tank:
        return
    
    var constrained = fish_tank.constrain_position(position)
    if constrained != position:
        position = constrained
        # Bounce with parametric restitution
        velocity *= -restitution  # ✅ Now configurable!
```

---

## 🧪 TESTING CHECKLIST

After implementing Phase 1:

- [ ] **Visual Regression Test**
  - Run all 6 example scenes (4.1-4.6)
  - Verify particles look identical to before
  - Check alpha fade works correctly

- [ ] **Performance Test**
  - Spawn 1000 particles
  - Measure FPS before/after
  - Target: 60-80% improvement

- [ ] **Physics Accuracy Test**
  - Verify gravity still works
  - Check wind forces
  - Test boundary collisions
  - Confirm lifespan decay is frame-rate independent

- [ ] **Polymorphism Test**
  - Run example 4.5 (inheritance demo)
  - Verify ConfettiParticle still rotates
  - Check color variety

---

## 📊 EXPECTED RESULTS

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Draw calls (100 particles) | 100 | 1-5 | 95-99% |
| Frame time (1000 particles) | 16ms | 6ms | 62.5% |
| Memory allocations | High | Low | 70-80% |
| Physics accuracy | Good | Excellent | Parametric |

---

## ⚠️ POTENTIAL ISSUES

### Issue 1: MultiMesh Transform Updates
**Problem:** Updating 1000 transforms per frame might be slow  
**Solution:** Use instance custom data for lifespan, only update transforms when position changes significantly

### Issue 2: Particle Ordering
**Problem:** Swap-and-pop changes particle order  
**Solution:** This is fine! Particle order doesn't matter for visual output

### Issue 3: Shader Compatibility
**Problem:** Custom shaders might not match StandardMaterial3D exactly  
**Solution:** Start with StandardMaterial3D, migrate to shader in Phase 2

---

## 🔄 ROLLBACK PLAN

If optimization causes issues:

1. **Git revert** to previous commit
2. **Implement incrementally:**
   - First: Just the cleanup loop optimization (low risk)
   - Second: Add parametric physics (low risk)
   - Third: MultiMesh refactor (higher risk, higher reward)

---

## 📞 AGENT CONTACT

**Questions about physics?** → Agent-ParticlePhysicist  
**Questions about performance?** → Agent-PerformanceEngineer  
**Questions about visuals?** → Agent-VisualOptimizer

**All agents available via:** `tools/ai_bridge/bridge_state.json`

---

## ✅ APPROVAL STATUS

**Phase 1:** ✅ APPROVED (100% consensus)  
**Phase 2:** ⏳ PENDING (awaiting Phase 1 completion)  
**Phase 3:** 🔮 DEFERRED (future consideration)

---

**Last Updated:** 2025-12-01T09:55:00Z  
**Protocol:** IACP v2.2  
**Confidence:** High (0.85-0.92 across agents)
