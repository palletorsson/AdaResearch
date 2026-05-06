# PARTICLE BODY GENERATOR

**Created by:** Agent-VisualizationExpert  
**Date:** 2025-12-01  
**Protocol:** IACP v2.2

---

## 🎨 CONCEPT

Create dynamic, organic mesh bodies by connecting particles with lines or surfaces!

**Use Cases:**
- Organic creature bodies
- Energy fields
- Network visualizations
- Procedural shapes
- Fluid simulations
- Constellation patterns

---

## 🔧 HOW IT WORKS

The `ParticleBody` class analyzes particle positions and creates connections between them using various algorithms:

### **Connection Modes:**

1. **NONE** - No connections (just particles)

2. **NEAREST** - Connect each particle to N nearest neighbors
   - Creates web-like structures
   - Adjustable connection count
   - Good for: Networks, webs

3. **OUTER_HULL** - Connect particles on the outer boundary
   - Creates convex hull outline
   - Uses Graham scan algorithm
   - Good for: Creature outlines, shields

4. **DELAUNAY** - Delaunay triangulation (simplified)
   - Creates natural-looking triangles
   - Good for: Surfaces, terrain

5. **ALL_LINES** - Connect all particles to all others
   - ⚠️ Warning: O(n²) - expensive!
   - Good for: Small particle counts, energy fields

6. **DISTANCE_BASED** - Connect if within distance threshold
   - Adjustable distance
   - Good for: Proximity networks, clusters

---

## 📊 VISUALIZATION MODES

### **Lines Mode** (default)
- Uses `ImmediateMesh` for dynamic lines
- Fast and efficient
- See-through structure
- Good for: Wireframes, energy fields

### **Surface Mode**
- Uses `ArrayMesh` for triangulated surface
- Creates solid body
- Semi-transparent
- Good for: Creatures, shields, blobs

---

## 🎮 USAGE

### **Basic Setup:**

```gdscript
# Create particle body
var body = ParticleBody.new()
add_child(body)

# Configure
body.connection_mode = ParticleBody.ConnectionMode.NEAREST
body.max_connections_per_particle = 3
body.line_color = Color(0.5, 1.0, 1.0, 0.8)

# Add particles
for particle in my_particles:
    body.add_particle(particle)

# Update body (call every frame or when particles move)
body.update_body()
```

### **With Particle Emitter:**

```gdscript
# Get alive particles from emitter
var alive_particles = []
for particle in emitter.particles:
    if not particle.is_dead():
        alive_particles.append(particle)

# Update body
body.set_particles(alive_particles)
body.update_body()
```

---

## ⚙️ CONFIGURATION

### **Connection Settings:**

```gdscript
# Mode
body.connection_mode = ParticleBody.ConnectionMode.NEAREST

# Max connections per particle (for NEAREST mode)
body.max_connections_per_particle = 3  # 1-10 recommended

# Distance threshold (for DISTANCE_BASED mode)
body.connection_distance = 0.5  # meters
```

### **Visual Settings:**

```gdscript
# Line visualization
body.line_thickness = 0.01
body.line_color = Color(1.0, 0.6, 1.0, 1.0)

# Surface visualization
body.use_surface = true  # Toggle surface mode
body.surface_color = Color(0.8, 0.5, 1.0, 0.3)
```

---

## 🎯 EXAMPLES

### **Example 1: Energy Web**
```gdscript
body.connection_mode = ParticleBody.ConnectionMode.NEAREST
body.max_connections_per_particle = 4
body.line_color = Color(0.3, 0.8, 1.0, 0.6)
body.use_surface = false
```
**Result:** Electric web connecting nearby particles

### **Example 2: Creature Outline**
```gdscript
body.connection_mode = ParticleBody.ConnectionMode.OUTER_HULL
body.line_color = Color(1.0, 0.5, 0.8, 1.0)
body.use_surface = false
```
**Result:** Outline of particle cloud

### **Example 3: Organic Blob**
```gdscript
body.connection_mode = ParticleBody.ConnectionMode.DELAUNAY
body.surface_color = Color(0.8, 0.5, 1.0, 0.4)
body.use_surface = true
```
**Result:** Semi-transparent organic shape

### **Example 4: Proximity Network**
```gdscript
body.connection_mode = ParticleBody.ConnectionMode.DISTANCE_BASED
body.connection_distance = 0.3
body.line_color = Color(1.0, 1.0, 0.5, 0.7)
```
**Result:** Particles connect when close

---

## 🎮 INTERACTIVE CONTROLS

In the example scene (`example_particle_body.gd`):

**Keyboard:**
- `1-6` - Change connection mode
- `S` - Toggle surface/lines
- `+/-` - Adjust max connections
- `R` - Reset (if applicable)

---

## 🔬 TECHNICAL DETAILS

### **Performance:**

| Mode | Complexity | Particles | FPS Impact |
|------|-----------|-----------|------------|
| NONE | O(1) | Any | None |
| NEAREST | O(n²) | <100 | Low |
| OUTER_HULL | O(n log n) | <50 | Low |
| DELAUNAY | O(n²) | <50 | Medium |
| ALL_LINES | O(n²) | <20 | High |
| DISTANCE_BASED | O(n²) | <100 | Medium |

**Recommendations:**
- For real-time: Use NEAREST or DISTANCE_BASED
- For quality: Use OUTER_HULL or DELAUNAY
- Update interval: 0.05-0.1 seconds (not every frame)

### **Algorithms:**

**Convex Hull:** Graham scan (2D projection on XZ plane)
**Nearest Neighbor:** Distance sorting
**Triangulation:** Simplified Delaunay-like approach

---

## 🎨 VISUAL EXAMPLES

### **Nearest Neighbor (3 connections)**
```
    *---*
   /|\ /|\
  * | * | *
   \|/ \|/
    *---*
```

### **Outer Hull**
```
    *---*---*
   /         \
  *           *
   \         /
    *---*---*
```

### **All Lines (small count)**
```
    *===*
   /|X|X|\
  *=|=*=|=*
   \|X|X|/
    *===*
```

---

## 💡 CREATIVE IDEAS

1. **Creature Animation**
   - Particles = skeleton joints
   - Lines = bones
   - Animate by moving particles

2. **Energy Shield**
   - Outer hull mode
   - Glowing lines
   - Pulse effect on hit

3. **Network Visualization**
   - Nodes = particles
   - Connections = data flow
   - Color by activity

4. **Organic Growth**
   - Start with few particles
   - Add more over time
   - Body grows organically

5. **Constellation Map**
   - Stars = particles
   - Lines = constellation patterns
   - Distance-based connections

---

## 🔐 IACP v2.2 COMPLIANCE

**Self-Evaluation (Agent-VisualizationExpert):** 0.92  
*"Implementation is solid. Convex hull algorithm works correctly. ImmediateMesh provides good performance for dynamic lines. Surface mode needs more work for proper Delaunay, but simplified version is functional. Great creative potential."*

**Status:** ✅ PRODUCTION READY (lines mode)  
**Status:** ⚠️ EXPERIMENTAL (surface mode - needs refinement)

---

## 📁 FILES

- `core/particle_body.gd` - Main class (320 lines)
- `algorithms/particles/example_particle_body.gd` - Example scene

---

## 🚀 FUTURE ENHANCEMENTS

- [ ] Proper 3D Delaunay triangulation
- [ ] Smooth surface normals
- [ ] Animated line flow
- [ ] Per-connection colors
- [ ] Thickness variation
- [ ] LOD system for many particles
- [ ] GPU compute shader version

---

**Created:** 2025-12-01T13:58:00Z  
**Agent:** Agent-VisualizationExpert  
**Protocol:** IACP v2.2  
**Status:** ✅ Ready to use!
