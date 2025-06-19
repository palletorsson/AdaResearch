# Spectral Analyzer Tutorial
## Real-Time Audio Analysis: Time Domain & Frequency Domain

### 🎯 **Overview**
This tutorial covers the implementation of a dual-display audio analyzer that visualizes sound in both time domain (sine waves) and frequency domain (spectrum analysis). Perfect for understanding how digital audio works and seeing the mathematical relationship between waveforms and frequencies.

---

## 📚 **Theory: Time vs Frequency Domain**

### **Spectral Sine Wave (Lower Display)**
- **What it shows**: Sine wave where amplitude is modulated by frequency spectrum values
- **Visual**: Smooth sine wave that "breathes" with audio content
- **X-axis**: Time position across display (2 sine wave cycles)
- **Y-axis**: Sine wave amplitude (modulated by spectral magnitude)
- **Use cases**: Seeing how frequency content changes over time in wave form

### **Frequency Domain (Spectrum)**
- **What it shows**: Which frequencies are present in the audio
- **Visual**: Vertical bars showing frequency content
- **X-axis**: Frequency (Hz - cycles per second)
- **Y-axis**: Magnitude (how strong each frequency is)
- **Use cases**: Seeing pitch content, harmonics, timbre

### **Mathematical Relationship**
```
Spectral Sine Wave: Frequency Magnitudes → Modulated Sine Wave

How it works:
- Frequency Domain: Vertical bars showing frequency content
- Spectral Sine Wave: sin(phase) × magnitude[frequency] - amplitude varies
- Time scrolling cycles through different frequency bands (0-8kHz)
- Strong frequencies = tall sine waves, weak frequencies = small sine waves
```

---

## 🏗️ **Code Architecture**

### **File Structure**
```
spectralanalysis/
├── spectral_analyzer.tscn          # Main scene with dual displays
├── GameSoundMeter.gd               # Frequency spectrum analyzer
├── SpectralMeter.gd                # Alternative spectrum display
├── WaveformDisplay.gd              # Time domain waveform display
├── SpectralDisplayController.gd    # Links viewports to materials
└── README_SpectralAnalyzer.md      # This tutorial
```

### **Component Hierarchy**
```
SpectralAnalyzer (Node3D)
├── AudioDisplay (SubViewport)          # Frequency spectrum rendering
│   ├── GameSoundMeter (Control)        # Main spectrum analyzer
│   └── SpectralDisplay (Control)       # Secondary spectrum display
├── WaveformViewport (SubViewport)      # Time domain rendering  
│   └── WaveformDisplay (Control)       # Waveform visualization
├── SpectrumDisplayMaterial (MeshInstance3D)  # Upper screen (green)
├── WaveformDisplayMaterial (MeshInstance3D)  # Lower screen (cyan)
└── Label3D                             # Title text
```

---

## 🎵 **Audio Processing Pipeline**

### **1. Audio Capture**
```gdscript
# Master bus monitoring - captures ALL game audio
var master_bus_index = AudioServer.get_bus_index("Master")
spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
AudioServer.add_bus_effect(master_bus_index, spectrum_analyzer)
```

### **2. Frequency Analysis (FFT)**
```gdscript
# Get frequency magnitude for each band
for i in range(bar_count):
    var freq_hz = (float(i) / float(bar_count)) * 8000.0  # Up to 8kHz
    var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
        freq_hz, freq_hz + 100.0
    ).length()
    
    # Convert to decibels and normalize
    var db = 20.0 * log(magnitude) / log(10.0)
    frequency_data[i] = clamp((db + 50.0) / 50.0, 0.0, 1.0)
```

### **3. Spectral Sine Wave Visualization**
```gdscript
# Create sine wave from spectral magnitude values over time
for i in range(sample_count):
    var time_position = float(i) / float(sample_count - 1)
    
    # Calculate which frequency to sample based on position + time offset
    var freq_index = int((time_position + time_offset * 0.5) * 64.0) % 64
    var freq_hz = (float(freq_index) / 64.0) * 8000.0  # Map to 0-8kHz range
    
    # Get the magnitude for this frequency band
    var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
        freq_hz, freq_hz + 125.0  # 125Hz bands
    ).length()
    
    # Convert to normalized amplitude and create modulated sine wave
    var normalized = clamp((db + 60.0) / 60.0, 0.0, 1.0)
    waveform_data[i] = sin(sine_phase + time_offset) * normalized * amplitude_scale
```

---

## 🎨 **Visual Rendering System**

### **Dual Viewport Architecture**
```gdscript
# Frequency Spectrum (Upper Display)
AudioDisplay (SubViewport) → SpectrumDisplayMaterial
- Green emission material
- Vertical frequency bars
- Real-time FFT analysis

# Spectral Sine Wave (Lower Display)  
WaveformViewport (SubViewport) → WaveformDisplayMaterial
- Cyan emission material
- Sine wave modulated by spectral values
- Cycles through frequency bands over time
```

### **Material Properties**
```gdscript
# High-visibility emission materials
emission_enabled = true
emission_energy_multiplier = 6.0
unshaded = true                    # No lighting interference
cull_mode = 0                      # Visible from both sides
```

### **Real-Time Updates**
```gdscript
func _process(delta):
    time_offset += delta * time_scale     # Advance time
    _update_waveform_data()               # Calculate new waveform
    queue_redraw()                        # Trigger visual update
```

---

## 🔧 **Configuration & Customization**

### **Frequency Spectrum Settings**
```gdscript
@export var bar_count: int = 64              # Number of frequency bars
@export var height_multiplier: float = 300.0 # Vertical scaling
@export var line_width: float = 6.0          # Line thickness
@export var line_color: Color = Color(0,1,0,1) # Bright green
```

### **Waveform Display Settings**
```gdscript
@export var sample_count: int = 256          # Waveform resolution
@export var amplitude_scale: float = 80.0    # Vertical amplitude
@export var time_scale: float = 1.5          # Scrolling speed
@export var line_color: Color = Color(0,1,1,1) # Cyan color
```

### **Performance Optimization**
```gdscript
# Automatic performance scaling
@export var update_fps: float = 30.0         # Update rate
@export var enable_distance_culling: bool = false # Always active
@export var smoothing_factor: float = 0.8    # Visual smoothing
```

---

## 🎯 **Usage in AdaResearch Grid System**

### **Adding to Maps**
```json
// In map_data.json interactables layer:
"interactables": [
    [" ", " ", " ", " ", " ", " ", " "],
    [" ", "spectral_analyzer", " ", " ", " ", " ", " "]
]
```

### **Grid Artifacts Configuration**
```json
"spectral_analyzer": {
    "name": "Master Audio Analyzer",
    "scene": "res://algorithms/wavefunctions/spectralanalysis/spectral_analyzer.tscn",
    "artifact_type": "interactive_algorithm",
    "sequence": "wavefunction_exploration"
}
```

---

## 🧮 **Mathematical Foundations**

### **Spectral Sine Wave Concept**
```
Spectral Values → Modulated Sine Wave Visualization

Process:
1. Analyze audio frequency spectrum (FFT) → get magnitude[frequency]
2. Cycle through frequency bands over time (0Hz → 8kHz → 0Hz...)
3. Create sine wave: amplitude = magnitude[current_frequency]
4. Result: sine wave that "breathes" with audio frequency content

Examples:
- Strong bass (100Hz) → Tall sine wave when sampling bass range
- Weak treble (8kHz) → Small sine wave when sampling treble range
- Musical chord → Sine wave changes as it cycles through harmonics
```

### **Frequency Analysis**
```gdscript
// Convert magnitude to decibels (logarithmic scale)
var db = 20.0 * log10(magnitude)

// Human hearing range: ~20Hz to 20kHz
// Music fundamentals: ~80Hz to 4kHz  
// Harmonics and brightness: 4kHz to 20kHz
```

### **Spectral Sine Wave Implementation**
```gdscript
// Cycle through frequency bands over time
var freq_index = int((time_position + time_offset * 0.5) * 64.0) % 64
var freq_hz = (float(freq_index) / 64.0) * 8000.0

// Get magnitude for current frequency band
var magnitude = spectrum_instance.get_magnitude_for_frequency_range(freq_hz, freq_hz + 125.0)

// Create modulated sine wave
waveform(t) = sin(sine_phase + time_offset) × normalized_magnitude

// Result: Pure sine wave shape with amplitude varying by spectral content
```

---

## 🎓 **Educational Applications**

### **Concepts Demonstrated**
1. **Spectral Analysis**: How audio can be broken down into frequency components
2. **Data Visualization**: Converting numerical frequency data into visual sine waves
3. **Time-based Sampling**: Cycling through different frequency ranges over time
4. **Amplitude Modulation**: How one signal (spectrum) can control another (sine wave)
5. **Real-time Processing**: Live audio analysis and visual feedback

### **Interactive Learning**
- **Play different sounds** and watch how the sine wave changes
- **Compare bass vs treble** - sine wave amplitude shifts as it cycles through frequencies
- **Watch rhythm patterns** reflected in sine wave breathing
- **Observe musical harmonics** create different amplitude patterns over time
- **See real-time frequency analysis** converted to smooth wave visualization

### **STEM Applications**
- **Physics**: Wave theory, acoustics, resonance
- **Mathematics**: Trigonometry, Fourier analysis, signal processing
- **Computer Science**: Real-time algorithms, graphics rendering
- **Music Theory**: Frequency relationships, harmony, timbre

---

## 🚀 **Advanced Features**

### **Real-Time Audio Synthesis**
```gdscript
// Generate test waveforms when no audio present
func _generate_test_waveform():
    for i in range(sample_count):
        var t = time_offset + float(i) / sample_count * 4.0
        var base_wave = sin(t * PI * 2.0) * 0.8          # Fundamental
        var harmonic = sin(t * PI * 4.0) * 0.3           # 2nd harmonic
        waveform_data[i] = (base_wave + harmonic) * amplitude_scale
```

### **Multi-Pass Glow Effects**
```gdscript
// Create glowing lines for better visibility
for glow_pass in range(3):
    var glow_width = line_width + (glow_pass * 2)
    var glow_alpha = 0.3 - (glow_pass * 0.1)
    draw_line(point1, point2, glow_color, glow_width)
```

### **Dynamic Frequency Boost**
```gdscript
// Enhance lower frequencies for better visibility
if i < bar_count * 0.3:  // First 30% (bass frequencies)
    normalized = normalized * 2.0  // Double amplitude
```

---

## 🔍 **Debugging & Troubleshooting**

### **Common Issues**
1. **Black screens**: Check viewport connections and material setup
2. **No audio response**: Verify master bus monitoring is enabled
3. **Performance issues**: Reduce update rate or bar count
4. **Incorrect display content**: Check viewport_node_path settings

### **Debug Output**
```gdscript
// Console messages help identify issues:
"WaveformDisplay: Initialized with 256 samples"
"SpectralDisplayController [SpectrumDisplayMaterial]: Found viewport: AudioDisplay"
"GameSoundMeter: Monitoring Master Bus - analyzing ALL game audio"
```

### **Performance Monitoring**
```gdscript
// Check system performance
func get_performance_stats() -> Dictionary:
    return {
        "update_fps": update_fps,
        "has_spectrum": spectrum_instance != null,
        "frame_skip_count": frame_skip_counter
    }
```

---

## 🎼 **Example Use Cases**

### **Music Education**
- Show how instruments produce different harmonic series
- Visualize chord progressions and dissonance
- Demonstrate filter effects and EQ changes

### **Game Audio Design**  
- Monitor audio mix balance in real-time
- See frequency conflicts between sounds
- Verify audio processing effects

### **STEM Demonstrations**
- Illustrate wave interference patterns
- Show Doppler effect in real-time
- Demonstrate digital signal processing

### **Interactive Art**
- Create responsive visual art based on audio
- Generate patterns from music structure
- Real-time audio-visual performances

---

## 📖 **Further Reading**

### **Signal Processing Concepts**
- Fourier Transform and FFT algorithms
- Digital filter design and implementation  
- Real-time audio processing techniques
- Psychoacoustics and human hearing

### **Godot Engine Resources**
- AudioServer and audio bus architecture
- Control drawing and custom visualizations
- SubViewport rendering techniques
- Real-time graphics optimization

### **Mathematical Background**
- Trigonometry and sine wave mathematics
- Logarithmic scales and decibel measurements
- Complex numbers and phase relationships
- Sampling theory and Nyquist frequency

---

*This spectral analyzer serves as both a practical audio tool and an educational demonstration of fundamental concepts in digital signal processing, acoustics, and real-time graphics programming.* 