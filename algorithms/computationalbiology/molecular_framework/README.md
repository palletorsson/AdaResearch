# Molecular Morphology Framework

A JSON-driven VR framework for assembling molecular structures, bodies, and furniture from floating grabbable parts. Inspired by chemical bonding and computational biology principles.

## Overview

This framework enables:
- **Floating Part Inventory**: Grabbable molecular "atoms" that drift in 3D space
- **JSON-Driven Assembly**: Define structures (VR bodies, furniture, molecules) in JSON
- **Dynamic Bonding**: Visual bonds connect parts with real-time updates
- **Hot Reload**: Edit JSON and see changes instantly
- **VR Integration Ready**: Compatible with XR-Tools grab systems

## Core Concept

Think of it as **molecular self-assembly** for VR:
1. Parts float like molecules in solution
2. Assembly signal triggers docking (like chemical attraction)
3. Parts spring into place forming a crystalline structure
4. Bonds visualize connections (like atomic bonds)

Perfect for:
- **VR Body Assembly**: Form your avatar from floating limbs
- **Furniture Design**: Build chairs, tables, lamps from components
- **Molecular Visualization**: Educational chemistry/biology demonstrations
- **Procedural Architecture**: Dynamic building assembly

---

## Quick Start

### 1. Open the Scene
```
Load: algorithms/computationalbiology/molecular_framework/MolecularDesigner.tscn
```

### 2. Controls
| Key | Action |
|-----|--------|
| **F** | Float Mode (parts drift freely) |
| **A** | Assemble current structure |
| **1** | Assemble VR Body |
| **2** | Assemble Chair |
| **R** | Reload JSON (hot reload) |

### 3. Watch It Work
- Parts spawn and float gently
- Press **1** to see them snap into a humanoid skeleton
- Press **F** to release them back to floating
- Press **2** to see chair assembly

---

## File Structure

```
molecular_framework/
├── assemblies.json           # Catalog & assembly definitions
├── Part.gd                   # Floating/docking component
├── Part.tscn                 # Part scene
├── MolecularDesigner.gd      # Main manager script
├── MolecularDesigner.tscn    # Complete demo scene
└── README.md                 # This file
```

---

## JSON Format

### Structure

```json
{
    "catalog": {
        "PartName": {
            "mesh": "sphere_small|sphere_med|cylinder|box",
            "radius": 0.08,  // for spheres
            "r": 0.05,       // for cylinder radius
            "h": 0.4,        // for cylinder height
            "size": [x, y, z], // for box
            "color": [r, g, b, a],
            "mass": 0.5
        }
    },
    "assemblies": {
        "AssemblyName": {
            "scale": 1.0,
            "nodes": [
                {
                    "id": "unique_id",
                    "part": "PartName",
                    "pos": [x, y, z]
                }
            ],
            "bonds": [
                ["id1", "id2"],
                ["id2", "id3"]
            ]
        }
    }
}
```

### Example: VR Body

```json
"VRBody": {
    "scale": 1.0,
    "nodes": [
        { "id": "torso",   "part": "SphereMed",   "pos": [0, 1.2, 0] },
        { "id": "head",    "part": "SphereSmall", "pos": [0, 1.55, 0] },
        { "id": "l_sh",    "part": "SphereSmall", "pos": [-0.25, 1.35, 0] },
        { "id": "r_sh",    "part": "SphereSmall", "pos": [ 0.25, 1.35, 0] }
    ],
    "bonds": [
        ["torso", "head"],
        ["torso", "l_sh"],
        ["torso", "r_sh"]
    ]
}
```

---

## Components

### Part.gd (Molecular Part)

Individual floating part that can dock to targets.

**Key Features:**
- **Float Behavior**: Gentle sine-wave floating motion
- **Docking**: Spring-based movement toward target
- **VR Grab**: Can be grabbed and manipulated
- **State Tracking**: Knows its ID and type

**Properties:**
```gdscript
idle_float_radius: float = 0.4
idle_float_speed: float = 0.6
dock_spring: float = 8.0
dock_damp: float = 0.85
part_id: String
part_type: String
grabbed: bool  # Set by XR system
```

**Methods:**
```gdscript
set_target(pos: Vector3, basis: Basis)
clear_target()
set_grabbed(is_grabbed: bool)
is_docked() -> bool
```

### MolecularDesigner.gd (Manager)

Main controller that loads JSON, spawns parts, and manages assemblies.

**Key Features:**
- **JSON Loading**: Parses catalog and assemblies
- **Part Spawning**: Creates floating inventory
- **Bond Visualization**: Cylinders between connected parts
- **Hot Reload**: Auto-reloads when JSON changes
- **Assembly Management**: Transitions between structures

**Properties:**
```gdscript
json_path: String
part_scene_path: String
inventory_count: int = 40
inventory_box: Vector3 = Vector3(3, 2, 3)
assemble_height: float = 0.0
bond_radius: float = 0.02
enable_hot_reload: bool = true
```

**Public API:**
```gdscript
assemble_structure(structure_name: String)
return_to_float_mode()
get_available_assemblies() -> Array
get_assembly_info(assembly_name: String) -> Dictionary
is_assembled() -> bool
get_current_assembly_name() -> String
```

---

## How It Works

### Float Mode

1. Parts spawn in random positions within `inventory_box`
2. Each part assigned random catalog type
3. Gentle floating motion applied (multi-frequency sine waves)
4. Can be grabbed in VR

### Assembly Mode

1. **JSON Parse**: Load assembly definition
2. **Part Assignment**: Assign nearest parts to required slots
3. **Mesh Application**: Apply correct mesh from catalog
4. **Target Setting**: Each part springs toward target position
5. **Bond Creation**: Create cylinder meshes between bonded nodes
6. **Live Update**: Bonds update every frame to follow parts

### Docking Physics

Parts use spring-damper system:
```gdscript
velocity = (velocity + to_target * spring * delta) * damp
position += velocity * delta
```

Parameters:
- `dock_spring = 8.0`: Stronger spring = faster docking
- `dock_damp = 0.85`: Higher damp = less oscillation

---

## Creating New Structures

### Example: DNA Helix

1. **Add to catalog** (if needed):
```json
"Nucleotide": {
    "mesh": "box",
    "size": [0.1, 0.05, 0.15],
    "color": [0.3, 0.8, 0.9, 1.0],
    "mass": 0.3
}
```

2. **Define assembly**:
```json
"DNAHelix": {
    "scale": 1.0,
    "nodes": [
        { "id": "base1", "part": "Nucleotide", "pos": [0, 0, 0] },
        { "id": "base2", "part": "Nucleotide", "pos": [0.2, 0.1, 0] },
        { "id": "base3", "part": "Nucleotide", "pos": [0, 0.2, 0] }
    ],
    "bonds": [
        ["base1", "base2"],
        ["base2", "base3"]
    ]
}
```

3. **Add keyboard shortcut** (in MolecularDesigner.gd):
```gdscript
KEY_3:
    _assemble("DNAHelix")
```

4. **Save JSON and press R** to reload!

---

## VR Integration

### XR-Tools Grab Support

The `Part.gd` script has a `grabbed` flag for VR integration:

```gdscript
# In your XR grab handler:
func _on_part_grabbed(part: MolecularPart):
    part.set_grabbed(true)

func _on_part_released(part: MolecularPart):
    part.set_grabbed(false)
```

### Making Parts Grabbable

Add to Part.tscn:
1. **CollisionShape3D**: For physics detection
2. **XRToolsPickable script**: If using XR-Tools
3. **Connect signals**: Link to MolecularPart methods

Example modification:
```gdscript
extends MolecularPart  # Instead of Node3D

# Now inherits XRToolsPickable behavior
func _on_picked_up(pickable):
    set_grabbed(true)

func _on_dropped(pickable):
    set_grabbed(false)
```

---

## Customization

### Visual Styling

**Bond Colors:**
```gdscript
bond_color = Color(0.9, 0.9, 1.0)  # Pale blue
```

**Part Materials:**
Edit in `_apply_mesh_from_catalog()`:
```gdscript
mat.metallic = 0.7  # More metallic
mat.roughness = 0.2  # Shinier
mat.emission = color * 0.5  # Brighter glow
```

### Float Behavior

```gdscript
# In Part.gd
idle_float_speed = 1.2  # Faster floating
float_noise_scale = 0.05  # More chaotic
```

### Docking Speed

```gdscript
dock_spring = 12.0  # Faster snap
dock_damp = 0.9  # Less bounce
```

---

## Advanced Features

### Hot Reload

Edit `assemblies.json` while scene is running:
- Framework checks file every 1 second
- Automatically reloads on changes
- Re-assembles current structure

**Toggle hot reload:**
```gdscript
enable_hot_reload = false  # Disable for production
```

### Dynamic Scaling

Scale assemblies at runtime:
```json
"GiantChair": {
    "scale": 2.5,
    "nodes": [ ... ]
}
```

### Symmetry Helpers

Add symmetrical parts easily:
```python
# Python script to generate symmetric nodes
def mirror_x(node):
    return {
        "id": node["id"] + "_mirror",
        "part": node["part"],
        "pos": [-node["pos"][0], node["pos"][1], node["pos"][2]]
    }
```

---

## Example Assemblies

### Perovskite Lamp

```json
"PerovskiteLamp": {
    "scale": 1.0,
    "nodes": [
        { "id": "base", "part": "Cylinder", "pos": [0, 0.2, 0] },
        { "id": "shaft", "part": "Cylinder", "pos": [0, 0.8, 0] },
        { "id": "bulb", "part": "SphereMed", "pos": [0, 1.3, 0] }
    ],
    "bonds": [
        ["base", "shaft"],
        ["shaft", "bulb"]
    ]
}
```

### DNA Column

```json
"DNAColumn": {
    "scale": 1.0,
    "nodes": [
        { "id": "n0", "part": "SphereSmall", "pos": [0.1, 0, 0] },
        { "id": "n1", "part": "SphereSmall", "pos": [-0.1, 0.2, 0] },
        { "id": "n2", "part": "SphereSmall", "pos": [0.1, 0.4, 0] },
        { "id": "n3", "part": "SphereSmall", "pos": [-0.1, 0.6, 0] }
    ],
    "bonds": [
        ["n0", "n1"], ["n1", "n2"], ["n2", "n3"]
    ]
}
```

---

## Performance Notes

- **Part Count**: Default 40 parts runs smoothly
- **Bond Updates**: Only in assembled state (minimal cost)
- **Float Motion**: Computed per-part (distributable)
- **Hot Reload**: Only checks file every 1 second

**Optimization tips:**
- Reduce `inventory_count` for lower-end systems
- Disable `enable_hot_reload` in builds
- Use simpler meshes (fewer subdivisions)

---

## Troubleshooting

### Parts Don't Spawn
- Check `part_scene_path` is correct
- Verify `assemblies.json` path
- Check console for JSON parse errors

### Bonds Look Wrong
- Ensure node IDs in bonds match node definitions
- Check bond pairs reference valid nodes
- Try adjusting `bond_radius`

### Docking Too Fast/Slow
- Adjust `dock_spring` (higher = faster)
- Adjust `dock_damp` (higher = less bounce)
- Check part masses in catalog

### JSON Not Reloading
- Verify `enable_hot_reload = true`
- Check file path is absolute (`res://...`)
- Press **R** to manually reload

---

## Future Extensions

### Physics-Based Assembly
```gdscript
# Make parts RigidBody3D
# Add joints between bonded parts
# Enable soft-body dynamics
```

### Mutation System
```gdscript
# Random position offsets
# Color variations
# Scale mutations
# Procedural generation
```

### Save/Load Layouts
```gdscript
func save_current_layout() -> Dictionary:
    var layout = {}
    for part in parts:
        layout[part.part_id] = part.global_position
    return layout
```

### Chemical Reactions
```gdscript
# Define transformation rules
# Convert one assembly to another
# Animate transitions
```

---

## API Reference

### MolecularDesigner

**Methods:**
- `assemble_structure(name: String)` - Assemble named structure
- `return_to_float_mode()` - Clear assembly, return to float
- `get_available_assemblies() -> Array` - List assembly names
- `get_assembly_info(name: String) -> Dictionary` - Get assembly data
- `is_assembled() -> bool` - Check if assembled
- `get_current_assembly_name() -> String` - Get current assembly

**Signals:**
None (add as needed)

### MolecularPart

**Methods:**
- `set_target(pos: Vector3, basis: Basis)` - Set dock target
- `clear_target()` - Return to float mode
- `set_grabbed(grabbed: bool)` - VR grab state
- `is_docked() -> bool` - Check if at target
- `get_part_id() -> String` - Get part ID
- `get_part_type() -> String` - Get catalog type

**Properties:**
- `part_id: String` - Unique identifier
- `part_type: String` - Catalog key
- `part_mass: float` - Mass value
- `grabbed: bool` - Grab state

---

## Credits

Part of the AdaResearch educational VR platform.

Inspired by:
- Molecular self-assembly
- Perovskite crystal structures
- Fullerene chemistry
- Computational biology visualization

---

## 🎨 Complete Assembly Library (11 Forms)

### Bodies & Creatures

**VRBody** - Humanoid (13 parts)
- Head, torso, pelvis
- L/R arms: shoulder → elbow → hand
- L/R legs: hip → knee → foot
- Bilateral symmetry

**Insect** - Six-legged (11 parts)
- Head, thorax, abdomen (segmented)
- 6 legs in 3 pairs (bilateral)
- 2 wings (dorsal)
- Green/brown coloring

**Spider** - Eight-legged (10 parts)
- Body + head
- 8 legs (4 pairs, radial)
- Arachnid morphology

**Octopus** - Radial cephalopod (9 parts)
- Central mantle
- 8 arms (45° radial spacing)
- Radial symmetry

### Biological Structures

**DNAHelix** - Double helix (8 parts)
- Cyan nucleotides
- Alternating left/right positions
- Rising 0.2m per base
- Classic Watson-Crick structure

**Molecule** - Octahedral (7 parts)
- Central atom (medium sphere)
- 6 bonded atoms (small spheres)
- Octahedral geometry
- Chemical compound model

### Alien Forms

**AlienTree** - Fractal organism (10 parts)
- Purple alien nodes
- 3-way branching
- Each branch → 2 leaves
- Fractal-like growth

**CrystalTree** - Crystalline plant (7 parts)
- Cyan crystal prisms
- 3 branches from trunk
- Purple crystal "fruits"
- Alien flora

### Furniture Collection

**Chair** - Four-leg (6 parts)
- Seat panel (50cm × 50cm)
- Backrest (angled 110°)
- 4 legs at corners
- 50cm seat height

**Table** - Classic (5 parts)
- Large top (80cm × 80cm)
- 4 thick legs
- 75cm table height
- Stable base

**Lamp** - Standing (4 parts)
- Base platform
- Thin shaft
- Bulb (glowing sphere)
- Shade cylinder

**Shelf** - Wall-mount (4 parts)
- Tall back panel
- 3 horizontal shelves
- 50cm spacing
- Modular storage

---

## Assembly Cycling

The auto-cycle mode rotates through all 11 assemblies:
```
Float (10s) → VRBody (10s) → Float (10s) → Chair (10s) →
Float (10s) → Table (10s) → ... [continues through all]
```

Each assembly demonstrates different bonding patterns:
- **Linear chains**: DNAHelix
- **Bilateral symmetry**: VRBody, Insect, Spider
- **Radial symmetry**: Octopus, Molecule
- **Hierarchical branching**: AlienTree, CrystalTree
- **Corner attachment**: Chair, Table
- **Vertical stacking**: Lamp, Shelf

## License

Same as parent AdaResearch project.
