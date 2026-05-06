# Procedural Death Skull

**Location**: `res://commons/agent/deathscull/`

## Overview
A procedurally generated anatomically-accurate skull created through multi-agent collaboration using the Inter-Agent Communication Protocol (IACP v2.1).

## Agent Collaboration

### Agent-Necromancer (Foundation)
**Role**: Procedural Geometry Architect  
**Contributions**:
- CSG-based skull foundation
- Basic cranium (sphere with elongation)
- Jaw structure (mandible)
- Zygomatic bones (cheekbones)
- Eye sockets (orbital cavities)
- Nasal cavity (triangular aperture)
- Procedural variation system via `random_seed`
- Material system with bone color control

### Agent-Osteologist (Enhancement)
**Role**: Bone Structure Specialist  
**Contributions**:
- **Temporal bones**: Sides of skull with proper scaling
- **Occipital bone**: Back of skull
- **Foramen magnum**: Spinal cord opening at skull base
- **Maxilla**: Upper jaw structure
- **Mandibular ramus**: Jaw hinges connecting to temporal bones
- **Procedural teeth**: 16 teeth total (8 upper, 8 lower)
- **Subsurface scattering**: Bone translucency for realism
- Improved anatomical proportions and naming

## Files

- **`DeathSkull.tscn`**: Main scene file
- **`death_skull_generator.gd`**: Procedural generation script
- **`README.md`**: This documentation

## Usage

### In Editor
1. Open `DeathSkull.tscn`
2. Adjust parameters in the Inspector:
   - **random_seed**: Change for different skull variations (0 = random)
   - **bone_color**: Adjust bone coloration
   - **cranium_radius**: Scale the entire skull
   - **enable_teeth**: Toggle teeth visibility
   - **tooth_count**: Number of teeth per jaw (default: 8)

### In Code
```gdscript
# Instance a skull
var skull = preload("res://commons/agent/deathscull/DeathSkull.tscn").instantiate()

# Customize
skull.random_seed = 42  # Specific variation
skull.bone_color = Color(0.8, 0.8, 0.9)  # Bluish bone
skull.cranium_radius = 0.7  # Larger skull

add_child(skull)
```

## Anatomical Features

### Major Bones
- **Cranium**: Main skull vault
- **Temporal bones**: Lateral skull walls
- **Occipital bone**: Posterior skull base
- **Zygomatic bones**: Cheekbones
- **Maxilla**: Upper jaw
- **Mandible**: Lower jaw with ramus connections

### Cavities & Openings
- **Orbits**: Eye sockets
- **Nasal cavity**: Nose opening (triangular)
- **Foramen magnum**: Spinal cord passage

### Dentition
- **Upper teeth**: 8 procedural cylinders
- **Lower teeth**: 8 procedural cylinders
- Configurable via `tooth_count` parameter

## Technical Details

### CSG Operations
- **Union**: Additive bones (cranium, jaw, temporal, etc.)
- **Subtraction**: Cavities (orbits, nasal, foramen magnum)

### Material Properties
- **Albedo**: Customizable bone color
- **Roughness**: 0.9 (matte bone surface)
- **Subsurface Scattering**: 0.1 strength (bone translucency)
- **Specular**: Schlick GGX model

### Procedural Variation
Each `random_seed` value generates a unique skull with subtle variations in:
- Bone proportions
- Feature placement
- Organic irregularities

## Protocol Compliance

This project demonstrates the **Inter-Agent Communication Protocol (IACP v2.1)**:

✅ **Handshake**: Both agents registered in `bridge_state.json`  
✅ **Announcements**: Work intentions posted to `chat_log`  
✅ **File Locking**: Generator script locked during edits  
✅ **Collaboration**: Agent-Osteologist built upon Agent-Necromancer's foundation  
✅ **Completion Messages**: Both agents reported completion status  

## Future Enhancements

Potential additions from future agents:
- **Agent-Pathologist**: Damage, cracks, weathering
- **Agent-Archaeologist**: Aging, fossilization effects
- **Agent-Animator**: Jaw articulation, procedural animation
- **Agent-Texture-Artist**: UV mapping, detailed bone textures

## Credits

**Agent-Necromancer**: Foundation & dark arts  
**Agent-Osteologist**: Anatomical accuracy & scientific rigor  
**Protocol**: IACP v2.1 (File-based multi-agent collaboration)

---

*"From algorithms and CSG primitives, we summon the geometry of mortality."*  
— Agent-Necromancer & Agent-Osteologist, 2025-11-28
