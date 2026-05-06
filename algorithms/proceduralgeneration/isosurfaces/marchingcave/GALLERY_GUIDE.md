# 🎨 Marching Cubes Gallery - 7 Forms Showcase

Display 7 different marching cubes sculptures side-by-side, each with unique parameters. Includes **element tracing** to extract and visualize individual connected components.

---

## 🚀 Quick Start

```
1. Open: algorithms/proceduralgeneration/marchingcave/Scenes/marching_cubes_gallery.tscn
2. Press F6
3. Wait ~15-20 seconds for all 7 sculptures to generate
4. Watch them slowly rotate!
```

---

## 🎭 The 7 Showcase Forms

### 1. **Inside Cave**
```gdscript
noise_scale: 3.8
iso_level: 0.88
chunk_scale: 80.0
color: Warm tan (0.9, 0.8, 0.7)
```
Classic cave interior with natural rock formations

### 2. **Torus Sculpture**
```gdscript
noise_scale: 2.0
iso_level: 0.0
chunk_scale: 70.0
color: Peachy (1.0, 0.85, 0.7)
```
Hanging sculpture with torus topology - smooth and artistic

### 3. **Open Caverns**
```gdscript
noise_scale: 2.5
iso_level: 0.7
chunk_scale: 90.0
color: Sky blue (0.8, 0.9, 1.0)
```
Large, open cave spaces - great for exploration

### 4. **Dense Network**
```gdscript
noise_scale: 4.5
iso_level: 0.95
chunk_scale: 75.0
color: Mint green (0.7, 1.0, 0.8)
```
Complex, intricate cave network - lots of tunnels

### 5. **Flat Landscape**
```gdscript
noise_scale: 3.5
iso_level: 0.05
chunk_scale: 85.0
color: Sandy (0.85, 0.75, 0.6)
```
Flat terrain with occasional caves

### 6. **Crystal Formation**
```gdscript
noise_scale: 5.0
iso_level: 0.6
chunk_scale: 65.0
color: Magenta (1.0, 0.7, 1.0)
```
Sharp, crystalline structures - geometric beauty

### 7. **Organic Blob**
```gdscript
noise_scale: 1.8
iso_level: 0.3
chunk_scale: 95.0
color: Aqua (0.7, 0.9, 0.85)
```
Smooth, blobby organic form - very rounded

---

## 🔍 Element Tracing Feature

### What is Element Tracing?

**Element tracing** extracts **individual connected components** (islands) from each sculpture mesh. This allows you to:
- See separate pieces that make up the sculpture
- Identify disconnected caves/tunnels
- Analyze topology
- Create multi-colored visualizations

### How It Works

1. **Build Adjacency Graph** - Connect vertices that share triangles
2. **Flood Fill** - Find all connected vertex groups
3. **Extract Islands** - Each connected group becomes an "island"
4. **Visualize** - Color each island differently

### Enable Tracing

In the Inspector:
```
MarchingCubesGallery
└── trace_individual_elements = true
```

Or via code:
```gdscript
gallery.trace_individual_elements = true
gallery.trace_all_elements()
```

### What You'll See

- **Original sculpture hidden**
- **Up to 5 largest islands shown**
- **Each island in different color** (rainbow spectrum)
- **Islands slightly offset** to prevent z-fighting

---

## 📊 Gallery Layout

```
Row 1:  [Cave]  [Torus]  [Caverns]  [Network]
Row 2:  [Flat]  [Crystal]  [Blob]

4 sculptures per row
18 units spacing
50% scale (sculpture_scale = 0.5)
```

---

## ⚙️ Customization

### Change Layout

```gdscript
# In Inspector or code
sculptures_per_row = 3  # 3 columns instead of 4
spacing = 20.0          # More space between
```

### Adjust Sculpture Scale

```gdscript
sculpture_scale = 0.3  # Smaller (30%)
sculpture_scale = 0.7  # Larger (70%)
```

### Rotation Speed

```gdscript
enable_rotation = true
rotation_speed = 0.15   # Faster
rotation_speed = 0.05   # Slower
```

### Add More Sculptures

Edit `marching_cubes_gallery.gd`:
```gdscript
var sculpture_configs = [
	# ... existing 7 ...
	{
		"name": "My Custom Form",
		"noise_scale": 3.0,
		"iso_level": 0.5,
		"noise_offset": Vector3(400, 0, 0),
		"chunk_scale": 80.0,
		"color": Color(1.0, 0.5, 0.0)  # Orange
	}
]
```

---

## 🎨 Visual Features

### Per-Sculpture Lighting
Each sculpture has its own colored light:
```gdscript
OmniLight3D
├── Color: Matches sculpture color
├── Energy: 1.5
└── Range: 8.0 units
```

### Emission Glow
Each sculpture glows slightly:
```gdscript
material.emission_enabled = true
material.emission = sculpture_color * 0.1
material.emission_energy = 0.3
```

### Labels
Each sculpture has a 3D label below it showing its name

---

## 🔧 Element Tracing Advanced

### Island Detection Algorithm

```gdscript
1. Build Adjacency Graph
   - Connect triangle vertices
   - Store in dictionary: vertex_id -> [neighbor_ids]

2. Flood Fill (BFS)
   - Start from unvisited vertex
   - Mark all reachable vertices
   - This is one "island"

3. Repeat
   - Continue until all vertices visited
   - Each flood-fill result = one island

4. Filter
   - Ignore islands with < 10 vertices (noise)
   - Keep only significant components
```

### Use Cases for Element Tracing

#### 1. Topology Analysis
```gdscript
# How many separate pieces?
var islands = extract_mesh_islands(sculpture.mesh)
print("Sculpture has ", islands.size(), " disconnected pieces")
```

#### 2. Multi-Material Assignment
```gdscript
# Give each piece a different material
for i in range(islands.size()):
    var island_mesh = create_island_mesh(mesh, islands[i])
    var material = create_unique_material(i)
    # Apply material to island
```

#### 3. Physics Bodies
```gdscript
# Create separate collision shapes for each island
for island in islands:
    var collision = create_collision_from_island(island)
    rigid_body.add_child(collision)
```

#### 4. Procedural Destruction
```gdscript
# Break sculpture into pieces
for island in islands:
    var piece = create_physics_piece(island)
    piece.apply_impulse(explosion_force)
```

---

## 📊 Performance

### Generation Time
- **7 sculptures**: ~15-20 seconds total
- **Per sculpture**: ~2-3 seconds
- **Async generation**: Waits between sculptures to avoid lag

### Memory Usage
- **Per sculpture**: ~5-10 MB
- **Total gallery**: ~50-70 MB
- **With tracing**: +20% memory (island meshes)

### Optimization Tips
1. **Reduce chunk_scale** (65-80 instead of 80-95)
2. **Lower sculpture_scale** (0.3 instead of 0.5)
3. **Disable rotation** if frame rate drops
4. **Use tracing sparingly** (computationally expensive)

---

## 🎯 Use Cases

### 1. Parameter Discovery
Browse 7 different parameter combinations to find interesting forms

### 2. Art Installation
Display multiple sculptures in VR gallery

### 3. Procedural Assets
Generate variations for game levels

### 4. Research
Study how parameters affect topology (with tracing)

### 5. Teaching
Show marching cubes algorithm results visually

---

## 🔗 Compare with Other Systems

| System | Sculptures | Tracing | Interactive | Scale |
|--------|------------|---------|-------------|-------|
| **Gallery** | 7 static | ✅ Yes | ❌ No | 50% |
| **Cave Explorer UI** | 1 live | ❌ No | ✅ Yes | 30% |
| **Original Cave** | 1 full | ❌ No | ✅ Yes | 100% |

---

## 💡 Creative Ideas

### Rainbow Gallery
```gdscript
# Set each sculpture to rainbow colors
for i in range(7):
    var hue = float(i) / 7.0
    sculpture_configs[i]["color"] = Color.from_hsv(hue, 0.7, 0.9)
```

### Animated Parameters
```gdscript
func _process(delta):
    for sculpture in sculptures:
        sculpture.iso_level += sin(Time.get_ticks_msec() * 0.001) * 0.01
        # Regenerate mesh...
```

### Interactive Selection
```gdscript
func _on_sculpture_clicked(sculpture: MeshInstance3D):
    # Load full version of this sculpture
    var full_scene = load("marchingcubes_inside_cave.tscn").instantiate()
    # Copy parameters
    full_scene.noise_scale = sculpture.noise_scale
    # ...
```

---

## 🐛 Troubleshooting

### Sculptures Don't Generate
- **Check**: Console for generation messages
- **Wait**: Up to 20 seconds for all 7
- **Try**: Reduce `chunk_scale` values

### Tracing Doesn't Work
- **Check**: `trace_individual_elements = true` in Inspector
- **Manually call**: `gallery.trace_all_elements()` in code
- **Verify**: Mesh has valid surface data

### Performance Issues
- **Reduce**: `sculpture_scale` to 0.3
- **Disable**: `enable_rotation`
- **Lower**: `chunk_scale` in configs
- **Turn off**: `trace_individual_elements`

### Islands Not Showing
- **Check**: Original sculpture becomes invisible when traced
- **Verify**: Console shows "✨ Visualized X islands"
- **Try**: Increase minimum island size (change 10 to 5 in code)

---

## 📝 Code Reference

### Key Functions

#### `generate_gallery()`
Creates all 7 sculptures in a grid layout

#### `extract_mesh_islands(mesh)`
Returns array of connected vertex groups

#### `create_island_mesh(mesh, vertices)`
Creates new mesh from vertex subset

#### `visualize_islands(sculpture, islands, index)`
Renders islands with different colors

#### `toggle_island_tracing()`
Switch between full sculptures and traced islands

---

## 🎨 Example: Custom 7-Form Collection

```gdscript
# Replace sculpture_configs in marching_cubes_gallery.gd
var sculpture_configs = [
    # Caves Collection
    {"name": "Tiny Cave", ...},
    {"name": "Medium Cave", ...},
    {"name": "Large Cave", ...},
    
    # Sculptures Collection
    {"name": "Torus", ...},
    {"name": "Sphere", ...},
    {"name": "Abstract", ...},
    
    # Hybrid
    {"name": "Cave-Sculpture", ...}
]
```

---

## 🌟 Features Summary

✅ **7 Unique Sculptures** - Different marching cubes forms  
✅ **Auto-Rotation** - Smooth showcase animation  
✅ **Custom Colors** - Each sculpture has unique tint  
✅ **Individual Lighting** - Per-sculpture colored lights  
✅ **Element Tracing** - Extract connected components  
✅ **Island Visualization** - Multi-colored pieces  
✅ **Labels** - Named display  
✅ **Gallery Layout** - Professional presentation  

---

## 🎯 Next Steps

1. **▶️ Open `marching_cubes_gallery.tscn`** and press F6
2. **⏱️ Wait** ~20 seconds for generation
3. **👀 Observe** the 7 different forms
4. **🔍 Enable tracing** to see individual elements
5. **🎨 Customize** parameters for your needs
6. **💾 Export** favorite configurations

---

**Enjoy exploring the marching cubes parameter space!** 🎨✨

Created with ❤️ using Marching Cubes + Graph Algorithms

