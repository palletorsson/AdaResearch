# Physics Simulations - Setup Instructions

## ⚠️ Important: Making Static Scenes Interactive

Several physics simulation scenes have scripts written but not attached. Here's how to make them work:

---

## Quick Fix - Attach Scripts in Godot

### Scenes That Need Scripts Attached:

#### 1. **Cloth Simulation** (`clothsimulation.tscn`)
**Status**: ❌ Script exists but not attached
**Script**: `ClothSimulation.gd`

**How to Fix:**
1. Open `clothsimulation.tscn` in Godot
2. Select the root node "ClothSimulation" in the Scene tree
3. In the Inspector, click the script icon (📜) next to "Node3D"
4. Click "Load" and select `ClothSimulation.gd`
5. Save the scene (Ctrl+S)
6. **Run the scene** - You should now see physics simulation!

**What You'll Get:**
- Interactive VR cloth grabbing
- Wind forces affecting fabric
- Spring-mass physics
- Collision detection

---

#### 2. **FEM Simulation** (`fem.tscn`)
**Status**: ❌ Script exists but not attached
**Script**: `FEM.gd`

**How to Fix:**
1. Open `fem.tscn` in Godot
2. Select the root node "FEM"
3. Attach `FEM.gd` script
4. Save and run

**What You'll Get:**
- Beam bending deformation
- Membrane wave simulation
- Sphere radial waves
- Animated force points

---

#### 3. **Particle Systems** (`particlesystems.tscn`)
**Status**: ❌ Script exists but not attached
**Script**: `ParticleSystems.gd`

**How to Fix:**
1. Open `particlesystems.tscn` in Godot
2. Select the root node "ParticleSystems"
3. Attach `ParticleSystems.gd` script
4. Save and run

**What You'll Get:**
- Smoke, fire, sparks, weather particles
- Physics-based motion (gravity, wind, turbulence)
- Vibrant colors and effects
- Automatic particle lifecycle

---

#### 4. **Mass-Spring-Damper** (`massspringdamper.tscn`)
**Status**: ❌ Script exists but not attached
**Script**: `MassSpringDamper.gd`

**How to Fix:**
1. Open `massspringdamper.tscn` in Godot
2. Select the root node "MassSpringDamper"
3. Attach `MassSpringDamper.gd` script
4. Save and run

**What You'll Get:**
- Grid, chain, and cloth spring systems
- Spring forces (Hooke's Law)
- Gravity and wind simulation
- Visual spring connections

---

#### 5. **Newton's Laws** (`newtonslaws.tscn`)
**Status**: ⚠️ Wrong script attached
**Current**: Has `ForceVector.gd` attached to root
**Needed**: `NewtonsLaws.gd`

**How to Fix:**
1. Open `newtonslaws.tscn` in Godot
2. Select the root node "NewtonsLaws"
3. In Inspector, remove current script
4. Attach `NewtonsLaws.gd` instead
5. Keep `ForceVector.gd` on the ForceVector children nodes
6. Save and run

**What You'll Get:**
- Three balls with different force scenarios
- F = ma demonstration
- Collision and bounce physics
- Friction effects

---

## Already Working ✅

These scenes already have scripts attached and work correctly:

- ✅ **Collision Detection** - Working!
- ✅ **Constraints** - Working!
- ✅ **Numerical Integration** - Working!
- ✅ **Three Body Problem** - Working!
- ✅ **Magnetic Simulation** - Working!

---

## Alternative: Use Godot's Scene Override

If you want to keep original scenes intact, create new instances:

### Method 1: Duplicate and Fix
```bash
# In each folder, create a working copy:
cp clothsimulation.tscn clothsimulation_working.tscn
# Then attach script in Godot
```

### Method 2: Create New Scene
1. Create new Scene in Godot (Ctrl+N)
2. Set root node as Node3D
3. Rename root to match simulation name
4. Attach the appropriate script
5. Save as `[name]_interactive.tscn`

---

## Detailed Step-by-Step Example: Cloth Simulation

### Complete Setup for Cloth Simulation:

**Step 1**: Open Godot and navigate to:
```
res://algorithms/physicssimulation/clothsimulation/
```

**Step 2**: Double-click `clothsimulation.tscn` to open it

**Step 3**: You'll see a static scene with:
- Camera3D
- DirectionalLight3D
- ClothPieces (static boxes)
- WindSources (static spheres)
- CollisionObjects (static spheres)

**Step 4**: Select the ROOT node "ClothSimulation" (top of scene tree)

**Step 5**: Look at the Inspector panel on the right
- You'll see "Node3D" at the top
- Below it should be a script section (might say "empty")

**Step 6**: Click the script icon (📜) or the "Attach Script" button

**Step 7**: In the dialog:
- Click "Load"
- Navigate to `ClothSimulation.gd` in the same folder
- Click "Open"

**Step 8**: Save the scene (Ctrl+S or Scene > Save Scene)

**Step 9**: Run the scene (F6 or press Play Scene button)

**Step 10**: You should now see:
- Cloth nodes appearing as small spheres
- Spring connections between nodes
- Cloth responding to physics
- Wind effects
- Pins holding top of cloth

**Step 11**: In VR:
- Grab cloth with controllers
- Pull and manipulate fabric
- Watch physics respond!

---

## Verification Checklist

After attaching scripts, verify each scene works:

### ✅ Cloth Simulation
- [ ] Small spheres appear representing cloth nodes
- [ ] Cloth moves and deforms
- [ ] Spring lines visible between nodes
- [ ] Wind affects motion
- [ ] Can grab with VR controllers

### ✅ FEM
- [ ] Beam bends back and forth
- [ ] Membrane waves undulate
- [ ] Sphere pulses radially
- [ ] Force points move
- [ ] Grid lines visible

### ✅ Particle Systems
- [ ] Particles emit from sources
- [ ] Different colors and behaviors (smoke, fire, sparks, weather)
- [ ] Particles move with physics
- [ ] Particles fade out over time
- [ ] Emitters animate

### ✅ Mass-Spring-Damper
- [ ] Mass spheres visible
- [ ] Spring lines connect masses
- [ ] Grid structure moves
- [ ] Chain swings
- [ ] Cloth section responds to forces

### ✅ Newton's Laws
- [ ] Three balls visible
- [ ] Balls fall with gravity
- [ ] Balls respond to forces
- [ ] Balls bounce off ground
- [ ] Balls collide with walls

---

## Troubleshooting

### Problem: Script won't attach
**Solution**: Make sure you're selecting the ROOT node of the scene (the very top node in the scene tree)

### Problem: Script attached but scene doesn't work
**Solution**: Check the Output console (bottom panel) for errors. Common issues:
- Missing child nodes that script expects
- Scene structure doesn't match what script expects
- Export variables need to be set

### Problem: Errors about missing nodes
**Solution**: The script expects specific node paths. Check that scene structure matches:
```
ClothSimulation (root - with script)
├── ClothPieces
│   ├── HangingCloth
│   │   └── HangingClothNodes
│   ├── FloatingCloth
│   │   └── FloatingClothNodes
│   └── DrapedCloth
│       └── DrapedClothNodes
├── WindSources
├── CollisionObjects
└── WindStreams
```

### Problem: Physics runs but looks wrong
**Solution**: Check export variables in Inspector after attaching script:
- Adjust `cloth_resolution` (lower for better performance)
- Adjust force strengths
- Modify damping values

---

## Quick Test Script

To quickly test if a scene has a script attached:

1. Open the scene in Godot
2. Look at the Scene tree
3. Click the root node
4. Look at Inspector panel
5. If you see "Script" section with a script path → ✅ Has script
6. If you see "empty" or no script section → ❌ Needs script

---

## Performance Tips

After attaching scripts, if simulations run slowly:

### Cloth Simulation:
```gdscript
@export var cloth_width: int = 15  # Reduce from 20
@export var cloth_height: int = 15  # Reduce from 20
```

### Particle Systems:
```gdscript
@export var max_particles: int = 100  # Reduce from 200
```

### Mass-Spring-Damper:
```gdscript
@export var grid_size: int = 4  # Reduce from 5
```

### Magnetic Simulation:
```gdscript
@export var resolution := 8  # Reduce from 16
```

---

## VR-Specific Notes

### Controllers Not Working?
Make sure you have:
1. XROrigin node in your main scene
2. XROrigin is in the "XROrigin" group
3. LeftController and RightController as children
4. Controllers have proper button mappings

### Can't Grab Objects?
Check:
1. Controllers have trigger/grip buttons mapped
2. Script successfully connects to button signals
3. Grab radius is large enough (`grab_radius` export variable)
4. Objects are within reach (check VR scale = 0.8)

---

## Creating Your Own Interactive Simulations

Want to modify or create new simulations?

### Template Structure:
```gdscript
extends Node3D

# Export variables for easy tuning
@export var simulation_speed: float = 1.0
@export var particle_count: int = 100

# VR interaction
var left_controller: XRController3D
var right_controller: XRController3D

func _ready():
    # Always scale for VR
    scale = Vector3(0.8, 0.8, 0.8)

    # Setup simulation
    create_simulation_objects()
    setup_vr_controllers()

func _process(delta):
    # Update simulation
    update_physics(delta)
    update_vr_interaction()

func setup_vr_controllers():
    var xr_origin = get_tree().get_first_node_in_group("XROrigin")
    if xr_origin:
        left_controller = xr_origin.get_node_or_null("LeftController")
        right_controller = xr_origin.get_node_or_null("RightController")
```

---

## Next Steps

1. **Attach scripts to all static scenes** (see instructions above)
2. **Test each simulation** (press F6 in Godot)
3. **Adjust export variables** for your hardware
4. **Try in VR** to test interactivity
5. **Experiment and modify** to create your own simulations!

---

## Summary Table

| Scene | Script | Status | Action Needed |
|-------|--------|--------|---------------|
| Cloth Simulation | ClothSimulation.gd | ❌ Not Attached | Attach script to root node |
| FEM | FEM.gd | ❌ Not Attached | Attach script to root node |
| Particle Systems | ParticleSystems.gd | ❌ Not Attached | Attach script to root node |
| Mass-Spring-Damper | MassSpringDamper.gd | ❌ Not Attached | Attach script to root node |
| Newton's Laws | NewtonsLaws.gd | ⚠️ Wrong Script | Replace with correct script |
| Collision Detection | CollisionDetection.gd | ✅ Working | None |
| Constraints | Constraints.gd | ✅ Working | None |
| Numerical Integration | NumericalIntegration.gd | ✅ Working | None |
| Three Body Problem | ThreeBodyProblem.gd | ✅ Working | None |
| Magnetic Simulation | magnetic_simulation_main.gd | ✅ Working | None |

---

## Support

If you encounter issues:
1. Check Godot's Output panel for error messages
2. Verify scene structure matches script expectations
3. Check that all export variables are set reasonably
4. Try reducing complexity (particle counts, resolutions, etc.)

**All scripts are ready and functional** - they just need to be connected to the scenes!

---

*Once scripts are attached, all simulations will be fully interactive and VR-ready!*
