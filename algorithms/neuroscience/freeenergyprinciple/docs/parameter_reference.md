# Parameter Reference: Customizing the Markov Blanket Visualization

## Core System Parameters

### Spatial Configuration

#### `base_radius: float = 1.0`
- **Description**: Defines the fundamental scale of the system  
- **Range**: 0.5 - 5.0  
- **Effect**: Controls the size of all boundary layers  
- **Usage**: Larger values create more expansive visualizations  

#### `sphere_resolution: int = 32`
- **Description**: Mesh detail level for all spherical components  
- **Range**: 8 - 64  
- **Effect**: Higher values = smoother surfaces, lower performance  
- **Recommended**: 16 (low-end), 32 (standard), 48 (high-quality)  

### Temporal Dynamics

#### `pulse_speed: float = 1.0`
- **Description**: Rate of membrane pulsation cycles  
- **Range**: 0.1 - 3.0  
- **Effect**: Controls breathing rhythm and biological authenticity  
- **Biological basis**: Reflects cellular metabolic rhythms (~1Hz natural)  

#### `max_amplitude: float = 0.3`
- **Description**: Maximum pulsation amplitude as fraction of base radius  
- **Range**: 0.1 - 0.8  
- **Effect**: Larger values create more dramatic membrane movement  

### Information Processing

#### `max_hotspots: int = 8`
- **Description**: Maximum simultaneous information sources  
- **Range**: 3 - 20  
- **Effect**: Higher values increase environmental complexity  
- **Performance impact**: Linear effect on computational load  

#### `hotspot_lifetime: float = 5.0`
- **Description**: Duration (seconds) before hotspot expiration  
- **Range**: 2.0 - 15.0  
- **Effect**: Longer lifetimes allow more interaction opportunities  

### Entropy Configuration

#### `inner_entropy: float = 0.5`
- **Description**: Initial internal system entropy  
- **Range**: 0.1 - 0.9  
- **Effect**: Starting confidence/organization level  
- **Interpretation**: Lower = more organized, Higher = more chaotic  

#### `outer_entropy: float = 0.5`
- **Description**: Initial external environment entropy  
- **Range**: 0.2 - 0.8  
- **Effect**: Environmental predictability  

## Visual Parameters

### Color Configuration

```gdscript
# System colors
inner_color = Color(0.2, 0.4, 0.8, 0.7)     # Blue - internal states
membrane_color = Color(0.9, 0.5, 0.2, 0.9)  # Orange - boundary
outer_color = Color(0.1, 0.7, 0.3, 0.3)     # Green - environment
info_color = Color(1.0, 0.9, 0.1, 0.8)      # Yellow - information
```

### Material Properties

#### `metallic: float = 0.1-0.5`
- **Effect**: Surface metallic reflection  
- **Biological realism**: Keep low (0.1-0.3) for organic appearance  

#### `roughness: float = 0.3-0.9`
- **Effect**: Surface texture roughness  
- **Biological realism**: Moderate values (0.5-0.7) for authenticity  

#### `emission_energy: float = 0.3-1.0`
- **Effect**: Self-illumination intensity  
- **Creates**: Biological glow effect  

## Performance Parameters

### Optimization Settings

#### `performance_mode: bool = false`
- **Effect**: Reduces visual quality for better frame rates  
- **Usage**: Enable for low-end hardware  

#### `trail_generation_probability: float = 0.2`
- **Range**: 0.0 - 1.0  
- **Effect**: Higher values = more visual effects, lower performance  

#### `particle_count: int = 20`
- **Range**: 5 - 50  
- **Performance impact**: Quadratic effect on GPU load  

### Quality Settings

#### `fog_depth_begin: float = 10.0`
- **Effect**: Distance where fog effects begin  
- **Adjustment**: Reduce for more intimate viewing  

#### `noise_scale: float = 0.3`
- **Range**: 0.1 - 1.0  
- **Effect**: Amplitude of organic membrane distortion  

## Preset Configurations

### Low-End Hardware
```gdscript
base_radius = 0.8
sphere_resolution = 16
max_hotspots = 5
particle_count = 10
trail_generation_probability = 0.1
```

### High-End Hardware
```gdscript
base_radius = 1.5
sphere_resolution = 48
max_hotspots = 15
particle_count = 35
trail_generation_probability = 0.4
```

### Scientific Presentation
```gdscript
pulse_speed = 0.7              # Slower for observation
max_amplitude = 0.2            # Subtle movement
noise_scale = 0.1              # Smooth boundaries
trail_generation_probability = 0.0  # Minimal distractions
```

### Educational Demonstration
```gdscript
pulse_speed = 1.2              # Rhythmic and noticeable
max_amplitude = 0.4            # Dramatic movement
noise_scale = 0.4              # Organic appearance
trail_generation_probability = 0.3  # Visual interest
```

## Usage Guidelines

1. **Start with defaults**: All parameters have biologically-inspired values
2. **Single parameter changes**: Modify one at a time to understand effects
3. **Performance monitoring**: Watch frame rate with visual complexity increases
4. **Biological plausibility**: Maintain realistic parameter relationships

## Common Configurations

### Quick Demo (30 seconds)
- `pulse_speed = 2.0`
- `hotspot_lifetime = 3.0`
- `max_hotspots = 12`

### Long Observation (5+ minutes)
- `pulse_speed = 0.5`
- `hotspot_lifetime = 10.0`
- `max_hotspots = 6`

### Research Accuracy
- Keep temporal parameters near biological norms
- Minimize distracting visual effects
- Enable data logging for quantitative analysis

This parameter system allows extensive customization while maintaining the theoretical integrity of the Free Energy Principle visualization. 