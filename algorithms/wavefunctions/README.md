# Wave Functions & Spectral Analysis

This directory contains 3D visualizations of wave functions, signal processing algorithms, and spectral analysis techniques used in audio processing, signal analysis, and mathematical visualization.

## Algorithms

### 1. Fourier Transform (`fouriertransform/`)
- **Description**: Decomposes a function of time into its constituent frequencies
- **Inventor**: Joseph Fourier (1822), Cooley & Tukey FFT (1965)
- **Features**:
  - Time domain signal generation (Sine, Square, Triangle, Sawtooth)
  - Real-time frequency domain analysis
  - Harmonic addition and visualization
  - Interactive signal parameters
  - FFT computation visualization
- **Use Cases**: Audio processing, image compression, data analysis, signal decomposition

### 2. Spectral Analysis (Existing implementations)
- **Spectrum Display**: Real-time frequency spectrum visualization
- **Spectral Analyzer**: Advanced spectral analysis with multiple display modes
- **Waveform Display**: Time-domain signal visualization
- **Game Sound Meter**: Audio level monitoring and visualization

## Technical Details

### Signal Types
- **Sine Wave**: Pure sinusoidal signal with fundamental frequency
- **Square Wave**: Digital signal with sharp transitions
- **Triangle Wave**: Linear ramp signal with smooth transitions
- **Sawtooth Wave**: Linear ramp with sharp reset

### Harmonic Analysis
- **Fundamental Frequency**: Base frequency of the signal
- **Harmonics**: Integer multiples of the fundamental frequency
- **Harmonic Content**: Varies by signal type:
  - Sine: Pure fundamental only
  - Square: Odd harmonics only
  - Triangle: Odd harmonics only
  - Sawtooth: All harmonics

### FFT Implementation
- **Time Domain Sampling**: Discrete signal points over time
- **Frequency Domain**: Magnitude spectrum of frequency components
- **Real-time Updates**: Continuous signal generation and analysis
- **Visual Feedback**: Color-coded signal values and frequency bars

## Usage

Each algorithm scene can be:
1. **Opened independently** in Godot 4
2. **Integrated into audio projects** for real-time analysis
3. **Used for educational purposes** to understand signal processing
4. **Extended** with additional signal types or analysis methods

## Controls

### Signal Generation
- **Signal Type**: Choose between different waveform types
- **Frequency**: Adjust the fundamental frequency (0.1 - 5.0 Hz)
- **Amplitude**: Control signal intensity (0.1 - 3.0)
- **Harmonics**: Add harmonic content (1 - 8 harmonics)

### Analysis
- **Compute FFT**: Perform frequency domain analysis
- **Reset Signal**: Return to initial state
- **Real-time Updates**: Continuous signal generation and display

## File Structure

```
wavefunctions/
├── fouriertransform/
│   ├── fouriertransform.tscn
│   ├── FourierTransform.gd
│   └── SignalGenerator.gd
├── spectralanalysis/
│   ├── spectrum_display.tscn
│   ├── spectral_analyzer.tscn
│   ├── spectral_sine_wave.tscn
│   ├── dual_display_test.tscn
│   ├── SpectralAnalyzerController.gd
│   ├── SpectralDisplayController.gd
│   ├── WaveformDisplay.gd
│   ├── GameSoundMeter.gd
│   └── SpectralMeter.gd
└── README.md
```

## Dependencies

- **Godot 4.4+**: Required for all scenes
- **Standard 3D nodes**: CSGSphere3D, CSGBox3D, Camera3D, DirectionalLight3D
- **Math functions**: Built-in trigonometric and mathematical functions
- **Audio system**: For existing spectral analysis implementations

## Mathematical Concepts

### Fourier Transform
The Fourier Transform decomposes a time-domain signal into its frequency components:

```
X(f) = ∫ x(t) e^(-j2πft) dt
```

### Signal Generation
- **Sine Wave**: `y(t) = A * sin(2πft)`
- **Square Wave**: `y(t) = A * sign(sin(2πft))`
- **Triangle Wave**: `y(t) = A * (2|2(ft - ⌊ft + 0.5⌋)| - 1)`
- **Sawtooth Wave**: `y(t) = A * (2(ft - ⌊ft + 0.5⌋))`

### Harmonics
Harmonic addition follows the principle of superposition:
```
y_total(t) = Σ A_n * sin(2πnf*t)
```

## Future Enhancements

- [ ] Implement proper FFT algorithm using Godot's FFT library
- [ ] Add more signal types (Pulse, Gaussian, etc.)
- [ ] Create 3D surface plots of frequency responses
- [ ] Add audio input/output capabilities
- [ ] Implement inverse FFT for signal reconstruction
- [ ] Add filter visualization and design tools

## References

- Fourier, J. "Théorie analytique de la chaleur." Paris (1822)
- Cooley, James W., and John W. Tukey. "An algorithm for the machine calculation of complex Fourier series." Mathematics of computation 19.90 (1965): 297-301
- Various signal processing and harmonic analysis references
