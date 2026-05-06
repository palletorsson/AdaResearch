# 🏔️ Cave Explorer 3D UI

A scrollable, interactive 3D UI panel for exploring marching cubes cave parameters with real-time preview, inspired by the sound_3d_ui system.

---

## 🚀 Quick Start

```
1. Open: algorithms/proceduralgeneration/marchingcave/Scenes/cave_explorer_3d_ui.tscn
2. Press F6 (or place in your VR scene)
3. Use sliders or preset buttons to explore different caves!
```

---

## 🎮 How It Works

### 3D UI Panel
- **Screen** - Displays 2D UI in 3D space (like sound_3d_ui)
- **Mini Cave** - Scaled-down marching cubes preview (30% size)
- **Real-time Updates** - Cave regenerates as you adjust parameters

### Controls

#### Sliders
- **Noise Scale** (1.0 - 6.0)
  - Controls terrain detail/roughness
  - Lower = smoother, Higher = more complex

- **Iso Level** (0.0 - 1.0)
  - Surface threshold for cave generation
  - Lower = more solid, Higher = more hollow

- **Scale** (50 - 150)
  - Overall cave size
  - Preview is scaled to 30% for display

#### Preset Buttons
- **◄ Prev** - Load previous cave preset
- **Next ►** - Load next cave preset

---

## 🎨 5 Built-in Presets

### 1. Inside Cave (Default)
```gdscript
noise_scale: 3.8
iso_level: 0.88
chunk_scale: 100.0
```
Classic cave interior with natural formations

### 2. Flat Landscape
```gdscript
noise_scale: 3.5
iso_level: 0.05
chunk_scale: 100.0
```
Flat terrain with occasional caves

### 3. Torus Sculpture
```gdscript
noise_scale: 2.0
iso_level: 0.0
chunk_scale: 80.0
```
Hanging sculpture with torus topology

### 4. Dense Caves
```gdscript
noise_scale: 4.5
iso_level: 0.95
chunk_scale: 90.0
```
Complex, intricate cave network

### 5. Open Caverns
```gdscript
noise_scale: 2.5
iso_level: 0.7
chunk_scale: 110.0
```
Large, open cave spaces

---

## 🏗️ System Architecture

### Similar to sound_3d_ui.tscn

```
CaveExplorer3DUI (Node3D)
├── Screen (MeshInstance3D)
│   └── Viewport2Din3D
│       └── cave_control_panel.tscn (2D UI)
├── MiniCaveDisplay (Node3D)
│   └── MiniCave (MeshInstance3D with TerrainGenerator)
├── Stand (CSGCylinder3D)
└── Lights
```

### Key Components

1. **cave_explorer_ui.gd** - Main controller
   - Creates mini cave instance
   - Manages presets
   - Connects UI signals

2. **cave_control_panel.tscn** - 2D UI
   - Sliders for parameters
   - Preset navigation buttons
   - Real-time value display

3. **Viewport2Din3D** - XR Tools component
   - Renders 2D UI in 3D space
   - Enables VR interaction

---

## 🎯 Use Cases

### VR Cave Selection
```gdscript
# In VR scene
var cave_explorer = preload("res://...cave_explorer_3d_ui.tscn").instantiate()
cave_explorer.position = Vector3(2, 1.5, -2)
add_child(cave_explorer)
```

### Parameter Discovery
1. Adjust sliders to explore parameter space
2. Find interesting combinations
3. Note values for full-scale generation

### Preset Gallery
- Scroll through 5 pre-configured caves
- Compare different styles
- Pick one for your scene

---

## ⚙️ Customization

### Add New Presets

Edit `cave_explorer_ui.gd`:

```gdscript
var cave_presets = [
	# ... existing presets
	{
		"name": "Crystal Cavern",
		"noise_scale": 5.0,
		"iso_level": 0.75,
		"noise_offset": Vector3(300, 50, 100),
		"chunk_scale": 95.0
	}
]
```

### Adjust Mini Cave Scale

In `cave_explorer_3d_ui.tscn`:
```
MiniCaveDisplay → Transform → Scale
Default: 0.3 (30% size)
Try: 0.5 (50% size) for larger preview
```

### Change UI Colors

Edit `cave_control_panel.tscn`:
- Label colors: `theme_override_colors/font_color`
- Value colors for sliders
- Background in Viewport2Din3D

---

## 🔧 Integration with Full Cave System

### Apply Parameters to Full Scene

```gdscript
# From cave_explorer_ui.gd
var params = {
	"noise_scale": mini_cave.noise_scale,
	"iso_level": mini_cave.iso_level,
	"noise_offset": mini_cave.noise_offset
}

# Apply to full-scale cave
var full_cave = preload("marchingcubes_inside_cave.tscn").instantiate()
full_cave.get_node("Terrain").noise_scale = params.noise_scale
full_cave.get_node("Terrain").iso_level = params.iso_level
full_cave.get_node("Terrain").chunk_scale = 280.0  # Full size
```

### Export Current Parameters

Add to `cave_explorer_ui.gd`:
```gdscript
func export_parameters() -> Dictionary:
	return {
		"noise_scale": noise_scale,
		"iso_level": iso_level,
		"noise_offset": noise_offset,
		"chunk_scale": chunk_scale
	}
```

---

## 📊 Performance

### Mini Cave Preview
- **Resolution**: Same as full (64³)
- **Scale**: 30% of full size (chunk_scale: 50-150 vs 280)
- **Generation Time**: ~2-3 seconds per update
- **Memory**: ~10MB for mesh

### Optimization Tips
1. **Lower resolution** for faster updates
2. **Debounce slider changes** (wait 0.5s after last change)
3. **Cache recent presets** to avoid regeneration

---

## 🎨 Visual Setup

### Lighting
- OmniLight above screen (white, energy 2.0)
- OmniLight at mini cave (blue-tinted, energy 1.5)
- Creates studio-like presentation

### Materials
- Screen uses `settings_ui_material.tres`
- Stand uses same material for consistency
- Cave uses `TerrainMat.tres` (original)

---

## 🐛 Troubleshooting

### UI Not Responding
- **Check**: Viewport2Din3D scene path is correct
- **Fix**: Verify `cave_control_panel.tscn` exists

### Cave Not Updating
- **Check**: Console for "🏔️ Mini cave created" message
- **Fix**: Ensure `TerrainGenerator.gd` has `init_compute()` method

### Preset Buttons Don't Work
- **Check**: Signals connected (see console for "✅ UI signals connected!")
- **Fix**: Wait 2 frames for viewport initialization

### Mini Cave Too Small/Large
- **Adjust**: `MiniCaveDisplay` scale in scene (default 0.3)
- **Or**: Change `chunk_scale` range in sliders (50-150)

---

## 🌟 Features

✅ **Real-time Preview** - See changes immediately  
✅ **5 Presets** - Quick cave exploration  
✅ **VR Compatible** - Uses Godot XR Tools  
✅ **Scrollable Parameters** - Smooth slider controls  
✅ **Scaled Preview** - 30% size for performance  
✅ **Beautiful Lighting** - Studio-quality presentation  

---

## 🔗 Related Files

| File | Purpose |
|------|---------|
| `cave_explorer_3d_ui.tscn` | Main 3D scene |
| `cave_explorer_ui.gd` | Controller/logic |
| `cave_control_panel.tscn` | 2D UI panel |
| `cave_control_panel.gd` | UI logic |
| `marchingcubes_inside_cave.tscn` | Full-scale cave |
| `TerrainGenerator.gd` | Marching cubes algorithm |

---

## 💡 Inspired By

Based on `algorithms/wavefunctions/mariocontrol/sound_3d_ui.tscn`:
- Same Viewport2Din3D approach
- Similar screen/stand layout
- VR hand pose interaction
- Clean 3D UI presentation

---

## 🎯 Next Steps

1. **▶️ Open `cave_explorer_3d_ui.tscn`** and play
2. **🎮 Adjust sliders** to see real-time updates
3. **📜 Try presets** to explore different caves
4. **💾 Note parameters** you like
5. **🏔️ Apply to full scene** for final result

---

**Happy cave exploring!** 🏔️✨

Created with ❤️ using Godot XR Tools + Marching Cubes

