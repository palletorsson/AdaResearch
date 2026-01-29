# CSG Boolean Carving - Quick Start 🚀

## 3-Minute Setup

### Option 1: Basic Random Walk
```
1. Open randboolean.tscn
2. Press F6 (Play Scene)
3. See 3 cubes with carved tunnels!
```

### Option 2: All Patterns Demo
```
1. Open all_patterns_demo.tscn
2. Press F6
3. See 6 different carving patterns!
```

### Option 3: Create Your Own
```
1. New Scene → Add Node3D
2. Add CSGCombiner3D as child
3. Attach random_walk_carver.gd
4. Press F6
5. Instant carved cube!
```

---

## 📝 Files

| File | What It Does |
|------|-------------|
| `randboolean.tscn` | ⭐ Start here - 3 examples |
| `all_patterns_demo.tscn` | All 6 patterns shown |
| `random_walk_carver.gd` | Simple random walk |
| `advanced_carver.gd` | 5 patterns + options |
| `README.md` | Full documentation |

---

## ⚙️ Quick Parameters

### In Inspector (when script is attached):

**Size**
- `cube_size` → How big the solid is

**Carving**
- `walk_steps` → More = longer tunnel
- `sphere_radius` → Bigger = wider tunnel
- `step_size` → Smaller = smoother tunnel

**Randomness**
- `random_seed` → Same number = same result
- `random_seed = -1` → Random every time

---

## 🎨 Pattern Types (advanced_carver.gd)

```gdscript
pattern = 0  # Random Walk - organic caves
pattern = 1  # Spiral - helix/DNA shape
pattern = 2  # Branches - tree-like
pattern = 3  # Perlin Path - smooth curves
pattern = 4  # Grid Tunnels - regular grid
```

---

## 💡 Common Tweaks

### Bigger Tunnels
```gdscript
sphere_radius = 0.8
step_size = 0.6
```

### More Organic
```gdscript
radius_variation = 0.3
avoid_self_crossing = true
```

### Smoother Paths
```gdscript
step_size = 0.3
sphere_radius = 0.5
```

### Maze-Like
```gdscript
avoid_self_crossing = false
walk_steps = 100
```

---

## 🎯 How It Works

```
CSGCombiner3D (Container)
├── CSGBox3D (Solid cube)
└── CSGSphere3D × N (Subtract operation)
    ↓
Spheres placed along path
    ↓
CSG automatically carves holes!
```

**Key**: CSGSphere3D with `operation = 2` (SUBTRACTION) removes material

---

## 🔧 From Code

```gdscript
# Simple
var carver = preload("res://path/to/random_walk_carver.gd").new()
add_child(carver)
carver.walk_steps = 50
carver.sphere_radius = 0.5
carver.generate_carved_cube()

# Advanced with pattern
var adv = preload("res://path/to/advanced_carver.gd").new()
add_child(adv)
adv.pattern = 1  # Spiral
adv.spiral_turns = 5.0
adv.generate()
```

---

## 🐛 Troubleshooting

**Nothing appears**
- Wait a moment (CSG takes time to process)
- Check script is attached to CSGCombiner3D

**Path goes outside**
- Reduce `step_size`
- Increase `cube_size`

**Gets stuck**
- Set `avoid_self_crossing = false`
- Increase `cube_size`

**Too slow**
- Reduce `walk_steps` (try 30)
- Lower sphere detail in code

---

## ✨ Quick Examples

### Cave
```gdscript
pattern = 0  # Random Walk
walk_steps = 60
sphere_radius = 0.5
```

### DNA Helix
```gdscript
pattern = 1  # Spiral
spiral_turns = 8.0
sphere_radius = 0.3
```

### Worm Tunnels
```gdscript
pattern = 3  # Perlin
perlin_strength = 2.0
sphere_radius = 0.4
```

### Circuit Board
```gdscript
pattern = 4  # Grid
cube_size = Vector3(20, 2, 20)
sphere_radius = 0.2
```

---

## 🎬 Next Steps

1. **Play demo scenes** to see what's possible
2. **Adjust parameters** in Inspector
3. **Try different patterns** 
4. **Read README.md** for advanced techniques
5. **Create your own** patterns!

---

**Remember**:
- CSGCombiner3D is the container
- CSGSphere3D with SUBTRACTION carves
- More steps = longer path
- Bigger radius = wider tunnel

Happy carving! 🔮✨

