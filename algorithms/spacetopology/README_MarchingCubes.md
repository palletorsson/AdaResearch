# 🏔️ Marching Cubes & Spatial Topology

This directory contains spatial topology algorithms. For the **Marching Cubes** and **Rhizomatic Cave System** implementation, see:

📁 **Main Implementation**: [`algorithms/marchingcubes/`](../marchingcubes/)

## Quick Start

### Test the Algorithm
```gdscript
# Load and run the test scene
var test_scene = preload("res://algorithms/marchingcubes/scenes/marching_cubes_test.tscn")
get_tree().change_scene_to_packed(test_scene)
```

### Try the Interactive Demo
```gdscript
# Load the rhizomatic cave demo
var demo_scene = preload("res://algorithms/marchingcubes/scenes/rhizome_cave_demo.tscn")
get_tree().change_scene_to_packed(demo_scene)
```

### Generate a Cave Programmatically
```gdscript
# Use the simple example function
const SimpleCave = preload("res://algorithms/marchingcubes/examples/simple_cave.gd")
var cave_generator = SimpleCave.create_cave_procedurally(self, {
	"size": Vector3(80, 30, 80),
	"initial_chambers": 4
})
```

## 🎯 Features

- **✅ Complete Marching Cubes Implementation** with lookup tables
- **🌿 Rhizomatic Growth Patterns** for organic cave networks  
- **⚡ Physics Integration** with automatic collision generation
- **📊 Performance Optimization** with chunked generation
- **🎮 Interactive Demo** with real-time parameter adjustment
- **🧪 Test Suite** for algorithm verification

## 📖 Documentation

For complete documentation, see [`algorithms/marchingcubes/README.md`](../marchingcubes/README.md)

---

*The marching cubes implementation provides a foundation for spatial topology algorithms and 3D surface reconstruction.* 
