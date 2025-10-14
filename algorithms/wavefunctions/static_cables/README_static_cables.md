# Static Running Cables

A static cable system using the same line generation technique as ColoredLinesVR, but optimized for creating realistic running cables and wires.

## Features

- **Multiple Cable Patterns**: Straight, sag, wave, spiral, and random patterns
- **Realistic Materials**: Metallic cables with proper lighting and shadows
- **Configurable Geometry**: Adjustable cable count, length, spacing, and radius
- **Color Variation**: Subtle color differences between cables for realism
- **Environment Setup**: Atmospheric lighting and fog for industrial feel

## Cable Patterns

### Straight Cables
- Simple straight lines running horizontally
- Perfect for clean, organized installations

### Sag Cables
- Cables that sag naturally under their own weight
- Realistic catenary curve simulation
- Adjustable sag amount

### Wave Cables
- Sinusoidal wave pattern along the length
- Great for decorative or dynamic installations
- Configurable amplitude and frequency

### Spiral Cables
- Helical spiral pattern around the main axis
- Creates interesting 3D cable arrangements
- Adjustable number of turns

### Random Cables
- Organic, irregular cable paths
- Multiple sine/cosine waves combined
- Perfect for chaotic, industrial environments

## Visual Properties

- **Metallic Materials**: Realistic metal cable appearance
- **Shadow Casting**: Full shadow support for realistic lighting
- **Color Variation**: Subtle hue shifts between cables
- **Emission**: Optional subtle glow for night scenes

## Controls

- **Space**: Add a new cable
- **Escape**: Remove the last cable
- **Enter**: Regenerate all cables
- **Home**: Switch to straight pattern
- **End**: Switch to random pattern

## Configuration

All parameters are exposed as export variables:

### Cable Geometry
- `cable_count`: Number of cables (default: 15)
- `cable_length`: Length of each cable (default: 40.0)
- `cable_spacing`: Vertical spacing between cables (default: 2.5)
- `cable_radius`: Thickness of cables (default: 0.08)
- `ring_segments`: Detail level for cable cross-section (default: 8)
- `points_per_cable`: Number of points along each cable (default: 80)

### Pattern Settings
- `pattern_type`: Current pattern ("Straight", "Sag", "Wave", "Spiral", "Random")
- `sag_amount`: How much cables sag (default: 1.5)
- `wave_amplitude`: Wave pattern amplitude (default: 2.0)
- `wave_frequency`: Wave pattern frequency (default: 1.2)
- `spiral_turns`: Number of spiral turns (default: 3.0)
- `random_variation`: Random pattern intensity (default: 0.8)

### Visual Settings
- `cable_color`: Base color for cables (default: light gray)
- `cable_metallic`: Metallic factor (default: 0.3)
- `cable_roughness`: Surface roughness (default: 0.4)
- `cable_emission`: Glow strength (default: 0.1)
- `use_vertex_colors`: Enable color variation (default: true)
- `color_variation`: Amount of color variation (default: 0.3)

## Usage in VR

Perfect for creating realistic industrial environments:
- Power line installations
- Data center cable management
- Industrial facility wiring
- Decorative cable arrangements
- Atmospheric lighting setups

## Technical Details

- Uses the same mesh generation technique as ColoredLinesVR
- Optimized for static geometry (no animation overhead)
- Efficient rendering with proper LOD support
- Full physics collision support
- Compatible with VR interaction systems
