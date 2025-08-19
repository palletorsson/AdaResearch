# Resonance Frequencies Visualizer - 3D Wave Physics Simulation

A comprehensive 3D visualization system for exploring resonance frequencies, standing waves, and harmonic patterns in strings, membranes, and 3D field spaces.

## Features

### 🌊 **Wave Physics Simulation**
- **Standing Wave Generation**: Mathematical modeling of stationary wave patterns
- **Harmonic Series**: Multiple frequencies with customizable decay factors
- **Real-time Animation**: Dynamic wave evolution with adjustable time scaling
- **Multiple Visualization Modes**: String, membrane, and 3D field representations

### 📐 **Visualization Modes**

#### **String Mode (1D)**
- **Linear String Simulation**: Classic standing wave on a vibrating string
- **Node Visualization**: Optional display of wave nodes (zero-amplitude points)
- **Harmonic Overtones**: Multiple frequencies creating complex interference patterns
- **Real-time Line Rendering**: Smooth animated string with color-coded amplitude

#### **Membrane Mode (2D)**
- **2D Standing Waves**: Circular or rectangular membrane vibration patterns
- **Chladni Pattern Simulation**: Visual patterns similar to sand vibration experiments
- **Cross-Modal Harmonics**: Multiple 2D wave modes simultaneously
- **Surface Deformation**: 3D mesh deformation showing membrane displacement

#### **3D Field Mode**
- **Volumetric Resonance**: Three-dimensional standing wave fields
- **Particle System**: Visual representation of pressure/displacement fields
- **Isosurface Rendering**: 3D surfaces of constant amplitude
- **Multi-dimensional Harmonics**: Complex 3D interference patterns

### ⚙️ **Simulation Parameters**
- `base_frequency`: Fundamental resonant frequency (default: 1.0 Hz)
- `num_harmonics`: Number of harmonic overtones (default: 5)
- `amplitude`: Wave amplitude scaling (default: 1.0)
- `decay_factor`: Harmonic amplitude decay (default: 0.7)
- `time_scale`: Animation speed multiplier (default: 1.0)

### 🎨 **Visualization Controls**
- `color_by_amplitude`: Dynamic color mapping based on wave amplitude
- `wave_color`: Base color for wave visualization (default: blue)
- `line_thickness`: Visual thickness for string/line rendering
- `show_node_positions`: Toggle display of resonant nodes
- `draw_debug_info`: Real-time parameter display

## Usage

### Quick Start
1. **Load Scene**: Open `resonance_frequencies_visualizer.tscn`
2. **Select Mode**: Choose visualization mode in inspector (0=String, 1=Membrane, 2=3D)
3. **Adjust Parameters**: Modify frequency, harmonics, and amplitude settings
4. **Run Simulation**: Play scene to see animated resonance patterns

### Advanced Configuration
1. **Multiple Harmonics**: Increase `num_harmonics` for complex interference
2. **Frequency Scaling**: Adjust `base_frequency` for different resonant behaviors
3. **Visual Tuning**: Experiment with colors and display options
4. **Grid Resolution**: Modify grid sizes for higher/lower detail

## Mathematical Foundation

### Standing Wave Equation
For a 1D string with fixed endpoints:
```
y(x,t) = Σ An * sin(nπx/L) * cos(ωnt + φn)
```
Where:
- `An` = amplitude of nth harmonic
- `L` = string length
- `ωn` = angular frequency of nth mode
- `φn` = phase offset

### 2D Membrane Modes
For rectangular membranes:
```
z(x,y,t) = Σ Σ Amn * sin(mπx/Lx) * sin(nπy/Ly) * cos(ωmnt + φmn)
```

### 3D Field Patterns
For cubic resonant cavities:
```
p(x,y,z,t) = Σ Σ Σ Almnp * sin(lπx/Lx) * sin(mπy/Ly) * sin(nπz/Lz) * cos(ωlmnt + φlmn)
```

## Development Roadmap

### 🔬 **Physics Extensions**
- [ ] **Damping Effects**: Energy dissipation and amplitude decay over time
- [ ] **Boundary Conditions**: Variable endpoint conditions (fixed, free, mixed)
- [ ] **Material Properties**: Tension, density, and elasticity parameters
- [ ] **Non-linear Effects**: Large amplitude behavior and chaos theory
- [ ] **Coupling Systems**: Multiple resonators with energy transfer

### 🎵 **Audio Integration**
- [ ] **Sonification**: Audio synthesis matching visual wave patterns
- [ ] **Frequency Analysis**: Real-time FFT display of harmonic content
- [ ] **Musical Tuning**: Harmonic ratios based on musical intervals
- [ ] **Interactive Audio**: User input affecting both visual and audio

### 🎮 **Interactive Features**
- [ ] **VR Support**: Immersive 3D wave field exploration
- [ ] **Touch Interface**: Direct manipulation of wave parameters
- [ ] **Real-time Controls**: Sliders and knobs for live parameter adjustment
- [ ] **Preset Library**: Saved configurations for different resonant systems

### 📊 **Analysis Tools**
- [ ] **Spectrum Analyzer**: Frequency domain visualization
- [ ] **Phase Portraits**: Phase space representation of oscillations
- [ ] **Energy Distribution**: Spatial energy density mapping
- [ ] **Modal Analysis**: Individual mode isolation and study

### 🔧 **Technical Improvements**
- [ ] **GPU Acceleration**: Shader-based wave calculation for performance
- [ ] **LOD System**: Adaptive detail based on viewing distance
- [ ] **Export Functions**: Save animations as video or image sequences
- [ ] **Performance Profiler**: Real-time performance monitoring

## Educational Applications

### 🎓 **Physics Education**
- **Wave Mechanics**: Visual demonstration of standing wave principles
- **Resonance Theory**: Interactive exploration of resonant frequencies
- **Harmonic Analysis**: Decomposition of complex waves into simple components
- **Boundary Effects**: How constraints affect wave behavior

### 🎼 **Music Theory**
- **Overtone Series**: Visual representation of musical harmonics
- **Timbre Analysis**: How harmonic content affects instrument sound
- **Room Acoustics**: 3D visualization of acoustic resonances
- **String Instruments**: Physics of guitars, violins, and pianos

### 🔬 **Engineering Applications**
- **Structural Dynamics**: Building and bridge resonance visualization
- **Mechanical Design**: Avoiding destructive resonance in machinery
- **Acoustic Engineering**: Speaker and microphone design principles
- **Signal Processing**: Understanding of filters and frequency response

## Scene Files

- `resonance_frequencies_visualizer.gd` - Main visualization and physics engine
- `resonance_frequencies_visualizer_setup.gd` - Configuration and setup utilities
- `resonance_frequencies_visualizer.tscn` - Complete 3D scene
- `resonance_frequencies_visualizer_setup.tscn` - Setup and configuration scene

## Performance Notes

- **Grid Resolution**: Higher subdivisions increase visual quality but reduce performance
- **Harmonic Count**: More harmonics create richer patterns but require more computation
- **Update Rate**: 60 FPS targeting for smooth animation
- **Memory Usage**: Scales with grid resolution and harmonic complexity

## Scientific Accuracy

This visualizer implements physically accurate wave equations and can be used for:
- **Research Visualization**: Publication-quality scientific animations
- **Educational Demonstrations**: Classroom and laboratory instruction
- **Engineering Analysis**: Preliminary resonance behavior studies
- **Artistic Expression**: Scientifically-grounded visual art creation 