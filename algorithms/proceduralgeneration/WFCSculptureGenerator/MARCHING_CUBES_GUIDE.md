# 🎨 Marching Cubes Sculpture Generator

Generate smooth, explorable sculptural forms using marching cubes algorithm with WFC-inspired density functions.

---

## 🚀 Quick Start

```
1. Open: marching_cubes_sculpture_scene.tscn
2. Select root node in Scene tree
3. In Inspector, set "Generate" = true
4. Wait ~5-10 seconds
5. Explore inside with WASD + Mouse!
```

---

## 🎮 Controls

### Movement (Fly Camera)
- **WASD** - Move forward/back/left/right
- **Q** - Move down
- **E** - Move up  
- **Right Mouse** - Look around (hold and drag)
- **ESC** - Release mouse

### Generation
- **Inspector → Generate** - Create new sculpture
- **Inspector → Clear Mesh** - Remove current sculpture
- **Inspector → Show Wireframe** - Toggle wireframe view

---

## 🎨 10 Sculpture Types

### 1. ABSTRACT_ORGANIC (Default)
Smooth, flowing organic forms with natural variation

**Best Settings:**
- Hollow: 0.6-0.8
- Complexity: 0.7-0.9
- Organic: 0.8-0.95

### 2. GEOMETRIC_CRYSTAL
Sharp crystalline structures with faceted surfaces

**Best Settings:**
- Hollow: 0.3-0.6
- Complexity: 0.6-0.9
- Organic: 0.1-0.3

### 3. BIOLOGICAL
Coral, sponge, bone-like organic structures

**Best Settings:**
- Hollow: 0.6-0.9
- Complexity: 0.8-0.95
- Organic: 0.8-0.9

### 4. MINERAL_FORMATION
Layered, stratified rock-like formations

**Best Settings:**
- Hollow: 0.4-0.6
- Complexity: 0.6-0.8
- Organic: 0.5-0.7

### 5. FLUID_DYNAMIC
Frozen water, flowing liquid forms

**Best Settings:**
- Hollow: 0.4-0.6
- Complexity: 0.6-0.8
- Organic: 0.9-0.95

### 6. SPIRAL_TORUS
Twisted torus, helical forms

**Best Settings:**
- Hollow: 0.5-0.7
- Complexity: 0.5-0.7
- Organic: 0.6-0.8

### 7. FRACTAL_TREE
Tree-like branching structures

**Best Settings:**
- Hollow: 0.4-0.6
- Complexity: 0.7-0.9
- Organic: 0.6-0.8

### 8. SPHERE_CLUSTER
Metaball-like interconnected spheres

**Best Settings:**
- Hollow: 0.3-0.6
- Complexity: 0.5-0.7
- Organic: 0.6-0.8

### 9. CAVE_NETWORK ⭐ (Great for exploration!)
Hollow shell with cave tunnels inside

**Best Settings:**
- Hollow: 0.7-0.9
- Complexity: 0.6-0.8
- Organic: 0.7-0.9

### 10. CELLULAR_STRUCTURE
Voronoi/cellular patterns, honeycomb-like

**Best Settings:**
- Hollow: 0.5-0.8
- Complexity: 0.6-0.9
- Organic: 0.5-0.7

---

## ⚙️ Parameters Explained

### Sculpture Parameters

#### Hollow Intensity (0.0 - 1.0)
- **0.0** - Completely solid
- **0.5** - Balanced  
- **0.8** - Very hollow, great for exploration
- **Effect**: Creates interior cavities and spaces

#### Surface Complexity (0.0 - 1.0)
- **0.3** - Smooth, clean
- **0.6** - Moderate detail
- **0.9** - Highly detailed, intricate
- **Effect**: Adds noise-based surface variation

#### Organic Flow (0.0 - 1.0)
- **0.1** - Geometric, angular
- **0.6** - Balanced
- **0.95** - Very smooth, flowing
- **Effect**: Smooths vs. sharpens features

### Marching Cubes Parameters

#### Resolution (Vector3i)
- **32x32x32** - Fast, low detail (~5 sec)
- **48x48x48** - Balanced quality (~10 sec) ⭐
- **64x64x64** - High detail (~20 sec)
- **96x96x96** - Very high detail (~45 sec)

#### Iso Level (float)
- **-0.5** - Expands surface outward
- **0.0** - Standard surface  ⭐
- **0.5** - Shrinks surface inward
- **Effect**: Adjusts where surface forms

#### Chunk Scale (float)
- **10.0** - Small sculpture
- **20.0** - Medium sculpture ⭐
- **30.0** - Large sculpture
- **Effect**: Overall sculpture size

#### Noise Scale (float)
- **1.0** - Large features
- **2.0** - Medium features ⭐
- **4.0** - Fine details
- **Effect**: Scale of surface detail

---

## 🌟 Exploration Tips

### For Best Exploration Experience

1. **Use CAVE_NETWORK type**
   ```gdscript
   sculpture_type = CAVE_NETWORK
   hollow_intensity = 0.8
   ```

2. **Enable volumetric fog**
   - Creates atmospheric depth
   - Helps with spatial awareness

3. **Increase chunk_scale**
   - Larger sculptures = more space to explore
   - Try 30.0 or 40.0

4. **Higher resolution**
   - Smoother surfaces
   - Better visual quality
   - Try 64x64x64

5. **Adjust camera_speed**
   - Faster for large sculptures
   - Slower for detailed inspection

---

## 📊 Performance vs Quality

| Resolution | Time | Vertices | Quality | Exploration |
|------------|------|----------|---------|-------------|
| 24x24x24 | ~2 sec | ~5K | Low | Limited |
| 32x32x32 | ~5 sec | ~15K | Medium | Good |
| 48x48x48 | ~10 sec | ~40K | High | Great ⭐ |
| 64x64x64 | ~20 sec | ~80K | Very High | Excellent |
| 96x96x96 | ~45 sec | ~200K | Extreme | Best |

---

## 🎯 Recommended Presets

### "Organic Cave" - Best for Exploration
```gdscript
sculpture_type = CAVE_NETWORK
hollow_intensity = 0.85
surface_complexity = 0.75
organic_flow = 0.85
resolution = Vector3i(64, 64, 64)
chunk_scale = 25.0
```

### "Crystal Geode" - Beautiful Interior
```gdscript
sculpture_type = GEOMETRIC_CRYSTAL
hollow_intensity = 0.7
surface_complexity = 0.9
organic_flow = 0.2
resolution = Vector3i(48, 48, 48)
chunk_scale = 20.0
```

### "Coral Reef" - Complex Organic
```gdscript
sculpture_type = BIOLOGICAL
hollow_intensity = 0.8
surface_complexity = 0.95
organic_flow = 0.9
resolution = Vector3i(48, 48, 48)
chunk_scale = 22.0
```

### "Fluid Splash" - Smooth Flowing
```gdscript
sculpture_type = FLUID_DYNAMIC
hollow_intensity = 0.5
surface_complexity = 0.7
organic_flow = 0.95
resolution = Vector3i(48, 48, 48)
chunk_scale = 18.0
```

### "Cellular Structure" - Honeycomb
```gdscript
sculpture_type = CELLULAR_STRUCTURE
hollow_intensity = 0.75
surface_complexity = 0.8
organic_flow = 0.6
resolution = Vector3i(56, 56, 56)
chunk_scale = 20.0
```

---

## 🔧 Advanced Usage

### Generate from Code

```gdscript
var sculpture = preload("res://algorithms/proceduralgeneration/WFCSculptureGenerator/marching_cubes_sculpture.gd").new()

sculpture.sculpture_type = sculpture.SculptureType.CAVE_NETWORK
sculpture.hollow_intensity = 0.8
sculpture.surface_complexity = 0.75
sculpture.organic_flow = 0.85
sculpture.resolution = Vector3i(48, 48, 48)
sculpture.chunk_scale = 25.0
sculpture.sculpture_seed = 12345

add_child(sculpture)
sculpture.generate_sculpture()
```

### Batch Generate Multiple Forms

```gdscript
var types = [
	SculptureType.ABSTRACT_ORGANIC,
	SculptureType.GEOMETRIC_CRYSTAL,
	SculptureType.BIOLOGICAL,
	SculptureType.CAVE_NETWORK
]

for i in range(types.size()):
	var sculpture = preload("marching_cubes_sculpture.gd").new()
	sculpture.sculpture_type = types[i]
	sculpture.position = Vector3(i * 30, 0, 0)
	sculpture.sculpture_seed = i
	add_child(sculpture)
	sculpture.generate_sculpture()
```

---

## 🎨 Density Functions

Each sculpture type uses a different density evaluation function:

### Organic
```
density = base_sphere + multi_layer_noise + hollowing
```

### Crystal
```
density = base_sphere + faceted_planes + sharp_features
```

### Biological
```
density = base_sphere + coral_noise + porous_structures
```

### Cave Network
```
density = -shell + cave_tunnels + 3D_noise
```

### Cellular
```
density = voronoi_cells + wall_thickness + surface_noise
```

---

## 🐛 Troubleshooting

### Generation is Slow
- **Reduce resolution** (32x32x32 or 24x24x24)
- **Decrease chunk_scale**
- Close other applications

### Sculpture Looks Blocky
- **Increase resolution** (64x64x64 or higher)
- **Adjust surface_complexity** for smoother surfaces

### Can't See Inside
- **Increase hollow_intensity** (try 0.8-0.9)
- **Use CAVE_NETWORK type**
- Material is double-sided by default

### Camera Moves Too Fast/Slow
- **Adjust camera_speed** in Inspector
- Try 3.0 for slow, 15.0 for fast

### Sculpture Too Small/Large
- **Adjust chunk_scale**
- 10.0 = small, 30.0 = large

---

## 💡 Creative Ideas

### VR Sculpture Garden
- Generate multiple sculptures
- Use teleportation between them
- Different types in different areas

### Procedural Caves
- Use CAVE_NETWORK type
- High hollow_intensity
- Add lights inside for atmosphere

### Crystal Gallery
- Multiple GEOMETRIC_CRYSTAL sculptures
- Vary organic_flow parameter
- Dramatic lighting

### Organic Architecture
- BIOLOGICAL type with low hollow
- Use as building structures
- Merge multiple together

### Abstract Installation
- Mix different sculpture types
- Vary all parameters
- Create composition

---

## 🌐 Integration

### With Original WFC System
```gdscript
# Get WFC parameters
var wfc_params = wfc_generator.get_parameters()

# Apply to marching cubes
mc_sculpture.hollow_intensity = wfc_params.hollow
mc_sculpture.surface_complexity = wfc_params.complexity
mc_sculpture.organic_flow = wfc_params.organic
```

### With Marching Cubes Cave System
The density functions are compatible with the cave system:
- Both use iso-surface extraction
- Same noise functions
- Can share parameters

---

## 📚 Technical Details

### Algorithm
1. **Generate 3D density field** based on sculpture type
2. **Apply marching cubes** to extract iso-surface
3. **Create triangle mesh** from surface
4. **Apply smooth materials** and lighting

### Density Field
- 3D grid of float values
- Positive = inside surface
- Negative = outside surface
- iso_level = surface threshold

### Marching Cubes
- Classic algorithm for iso-surface extraction
- Creates smooth surfaces from voxel data
- 256 possible cube configurations
- Interpolates vertex positions

---

## 🎯 Next Steps

1. **▶️ Open scene** and generate first sculpture
2. **🎮 Explore** with fly camera controls
3. **🎨 Try different types** (CAVE_NETWORK recommended!)
4. **⚙️ Adjust parameters** to find beautiful forms
5. **💾 Save favorites** by noting seed values
6. **🔧 Integrate** into your projects

---

**Happy sculpting and exploring!** 🎨✨

Created with ❤️ using Marching Cubes + WFC-inspired density functions

