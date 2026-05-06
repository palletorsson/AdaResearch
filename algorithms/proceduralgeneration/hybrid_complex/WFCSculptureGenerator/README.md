# 🎨 WFC Sculpture Generator

A powerful Wave Function Collapse-based procedural sculpture generator with beautiful parameter exploration tools.

---

## 🚀 Quick Start

### Option 1: Browse Gallery (Recommended!)
```
1. Open: sculpture_gallery.tscn
2. Press F6 (Play Scene)
3. Wait ~30-60 seconds for sculptures to generate
4. Browse 24 beautiful pre-configured sculptures
5. Use ← → arrows to change pages
```

### Option 2: Generate Single Sculpture
```
1. Open: WFCSculptureGenerator.tscn
2. Select root node
3. Click "Generate Sculpture" in Inspector
4. Wait ~10-15 seconds
```

### Option 3: Random Discovery
```
1. Create new scene with sculpture_randomizer.gd
2. Press Space to generate random sculptures
3. Press S to mark beautiful ones
4. Export your favorites!
```

---

## 📁 Files

| File | Purpose | Use When |
|------|---------|----------|
| **sculpture_gallery.tscn** | 24 curated sculptures ⭐ | Browse beautiful examples |
| **sculpture_gallery_browser.gd** | Gallery system | Customize gallery |
| **WFCSculptureGenerator.gd** | Core generator | Create custom sculptures |
| **WFCSculptureGenerator.tscn** | Single sculpture | Test parameters |
| **sculpture_randomizer.gd** | Random explorer | Discover new forms |
| **GALLERY_README.md** | Gallery guide | Learn gallery controls |
| **SimpleWFCSculptureGenerator.gd** | Simple example | Quick start code |

---

## 🎭 10 Sculpture Types

1. **ABSTRACT_ORGANIC** - Flowing, natural abstract
2. **GEOMETRIC_CRYSTAL** - Sharp crystalline facets
3. **ARCHITECTURAL** - Building-like structures
4. **BIOLOGICAL** - Coral, sponge, bone forms
5. **MINERAL_FORMATION** - Natural rock formations
6. **FLUID_DYNAMIC** - Frozen fluid motion
7. **FIBROUS_NETWORK** - Woven fiber webs
8. **SPIRAL_TORUS** - Helical, spiral forms
9. **FRACTAL_TREE** - Tree-like branching
10. **SPHERE_CLUSTER** - Interconnected spheres

---

## 🎛️ Key Parameters

### Hollow Intensity (0.0 - 1.0)
- **0.3** - Mostly solid, minimal hollowing
- **0.5** - Balanced solid/hollow
- **0.7** - Significant hollow cavities
- **0.9** - Very hollow, delicate structure

### Surface Complexity (0.0 - 1.0)
- **0.4** - Smooth, clean surface
- **0.6** - Moderate texture detail
- **0.8** - Rich surface variation
- **0.9** - Highly textured, intricate

### Organic Flow (0.0 - 1.0)
- **0.2** - Geometric, angular (crystals)
- **0.6** - Balanced geometric/organic
- **0.8** - Flowing, smooth curves
- **0.95** - Extremely organic (fluid)

---

## 💡 Beautiful Combinations

### Smooth Organic
```gdscript
type = ABSTRACT_ORGANIC
hollow = 0.5
complexity = 0.4
organic = 0.9
# Result: Clean, flowing form
```

### Sharp Crystal
```gdscript
type = GEOMETRIC_CRYSTAL
hollow = 0.3
complexity = 0.8
organic = 0.2
# Result: Faceted gem
```

### Delicate Coral
```gdscript
type = BIOLOGICAL
hollow = 0.8
complexity = 0.9
organic = 0.9
# Result: Intricate coral branch
```

### Fluid Splash
```gdscript
type = FLUID_DYNAMIC
hollow = 0.5
complexity = 0.7
organic = 0.95
# Result: Frozen water splash
```

---

## 🎨 Workflow

### 1. Discovery Phase
```
sculpture_gallery.tscn → Browse examples → Note favorites
```

### 2. Exploration Phase
```
sculpture_randomizer.gd → Generate random → Mark beautiful
```

### 3. Refinement Phase
```
WFCSculptureGenerator.tscn → Adjust parameters → Perfect result
```

### 4. Production Phase
```
Use in your project → Add collision → Apply materials
```

---

## 📊 Performance

| Size | Voxels | Time | Quality |
|------|--------|------|---------|
| 10x10x10 | 1,000 | ~5 sec | Low detail |
| 12x15x12 | 2,160 | ~10 sec | Good (gallery) |
| 15x18x15 | 4,050 | ~15 sec | High |
| 20x25x20 | 10,000 | ~30 sec | Very high |
| 25x30x25 | 18,750 | ~60 sec | Extreme |

**Tip:** Start with small sizes for quick iteration!

---

## 🔧 Advanced Usage

### Create Programmatically

```gdscript
var sculpture = WFCSculptureGenerator.new()
sculpture.sculpture_type = WFCSculptureGenerator.SculptureType.BIOLOGICAL
sculpture.sculpture_size = Vector3i(15, 18, 15)
sculpture.voxel_size = 0.35
sculpture.hollow_intensity = 0.7
sculpture.surface_complexity = 0.8
sculpture.organic_flow = 0.9
sculpture.sculpture_seed = 12345

add_child(sculpture)
await sculpture.create_hollow_sculpture()
```

### Batch Generation

```gdscript
for i in range(10):
    var sculpture = WFCSculptureGenerator.new()
    sculpture.position = Vector3(i * 20, 0, 0)
    sculpture.sculpture_seed = i
    # ... set other parameters
    add_child(sculpture)
    await sculpture.create_hollow_sculpture()
```

### Parameter Sweep

```gdscript
for hollow in [0.3, 0.5, 0.7, 0.9]:
    for complexity in [0.4, 0.6, 0.8]:
        # Generate sculpture with these params
        # ... compare results
```

---

## 🎯 Use Cases

- **Art Installation** - Generate unique sculptures for galleries
- **Game Assets** - Procedural environment props
- **3D Printing** - Export sculptures as STL
- **Architectural Elements** - Building decorations
- **Organic Props** - Natural-looking objects
- **Abstract Backgrounds** - Visual interest
- **ML Training Data** - Generate varied 3D shapes

---

## 💾 Export & Save

### Save Favorite Parameters
```gdscript
# In gallery browser or randomizer
var favorite = {
    "type": sculpture.sculpture_type,
    "hollow": sculpture.hollow_intensity,
    "complexity": sculpture.surface_complexity,
    "organic": sculpture.organic_flow,
    "seed": sculpture.sculpture_seed
}
# Save to file or copy to code
```

### Export Mesh
```
1. Generate sculpture
2. Select mesh in scene tree
3. Right-click → Save Branch as Scene
4. Or export as glTF/FBX
```

---

## 🐛 Troubleshooting

### Generation Takes Forever
- Reduce `sculpture_size`
- Use smaller `voxel_size` values
- Close other programs

### Sculptures Look Blocky
- Increase `voxel_size` (larger voxels)
- Or decrease `sculpture_size` with higher voxel_size

### Memory Issues
- Generate fewer sculptures simultaneously
- Use smaller `sculpture_size`
- Clear unused sculptures

### Sculptures Don't Appear
- Wait longer (check console for progress)
- Check `auto_generate` is true
- Try manual generation

---

## 🌟 Tips for Beautiful Results

1. **High organic (0.8-0.9)** = smooth, flowing forms
2. **High complexity (0.7-0.9)** = interesting surface detail
3. **Medium hollow (0.5-0.7)** = balanced structure
4. **Low organic (0.1-0.3) + crystals** = sharp geometric
5. **Biological + high hollow** = coral-like structures
6. **Fluid + very high organic (0.95)** = water-like forms
7. **Different seeds** = unique variations with same params

---

## 📚 Algorithm Details

### Wave Function Collapse
- **Voxel-based** 3D grid generation
- **Material zones** with adjacency rules
- **Spatial biasing** for structure
- **Entropy-driven** collapse order

### Material Zones
- VOID - Empty space (hollows)
- CORE_SOLID - Dense interior
- SURFACE_SMOOTH - Clean exterior
- SURFACE_ROUGH - Textured exterior
- SURFACE_POROUS - Porous surface
- TRANSITION - Gradient zones
- SUPPORT - Structural elements
- DETAIL_FINE - Fine surface details
- DETAIL_DEEP - Deep carved details

---

## 🔗 Related Systems

- **Marching Cubes** (`marchingcave/`) - Continuous surfaces
- **WFC Rooms** (`wfcRooms/`) - Dungeon generation
- **CSG Boolean** (`randomboolean/`) - Carving operations

---

## 📖 Documentation

- **GALLERY_README.md** - Gallery browser guide
- **README.md** - This file (overview)
- **SimpleWFCSculptureGenerator.gd** - Code examples

---

## 🎪 Gallery Preview

**Page 1** - Organic & Natural
- 4 Organic variants
- 4 Crystal variants  
- 4 Biological variants

**Page 2** - Fluid & Complex
- 3 Fluid dynamics
- 3 Spiral forms
- 2 Tree structures
- 2 Sphere clusters
- 2 Fiber networks

**Total:** 24 curated beautiful sculptures

---

## 🚦 Next Steps

1. **▶️ Open `sculpture_gallery.tscn`** and press F6
2. **🎨 Browse the gallery** and find favorites
3. **📝 Note parameters** you like
4. **🎲 Try randomizer** for discovery
5. **🔧 Tweak parameters** for your needs
6. **💾 Export** for use in projects

---

**Happy sculpture generating!** 🎭✨

Created with ❤️ using Wave Function Collapse

