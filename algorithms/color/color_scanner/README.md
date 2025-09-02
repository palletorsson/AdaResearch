# Color Scanner

A handheld ray-tracing color detection device that scans surfaces and displays the detected colors on a built-in screen.

## Features

### Ray Tracing Scanner
- **Real-time color detection**: Uses physics ray casting to detect surface colors
- **Adjustable scan range**: Configure maximum scanning distance (default: 10 units)
- **High-frequency scanning**: Up to 60 scans per second for responsive detection
- **Material color extraction**: Intelligently extracts colors from various material types

### Visual Display System
- **Built-in LCD screen**: 2x1.5 unit display with configurable resolution (128x96 pixels)
- **Multiple display modes**:
  - **Color Display**: Shows detected color with history strip
  - **Debug Info**: Shows hit detection and distance information
  - **Scan Pattern**: Radar-like visualization of scanning activity
- **Color history**: Tracks last 10 detected colors
- **Glowing display**: Optional screen glow effect for better visibility

### Scanner Hardware
- **Handheld design**: Compact scanner body with mounted display
- **Scanning beam visualization**: Optional red laser-like beam showing scan direction
- **Professional appearance**: Metallic body with integrated lens/sensor
- **Animated operation**: Subtle bobbing motion and beam pulsing effects

### Detection Capabilities
- **Multi-material support**: Works with StandardMaterial3D and ShaderMaterial
- **Color palette detection**: Optimized for scanning color sheets and palettes
- **Sensitivity adjustment**: Configurable color detection sensitivity
- **Distance-aware**: Beam length adjusts based on detected surface distance

## Usage

### Basic Operation
1. Point the scanner at any colored surface
2. The device automatically scans at the configured frequency
3. Detected colors appear immediately on the built-in display
4. Color history shows recent detections at the bottom of the screen

### Public API

```gdscript
# Control scanning
scanner.set_scanning_enabled(true/false)

# Change display mode
scanner.set_display_mode("color_display")  # or "debug_info", "scan_pattern"

# Get detection results
var current_color = scanner.get_current_color()
var scan_data = scanner.get_scan_data()

# Calibrate device
scanner.calibrate_scanner()
```

### Configuration

#### Scanner Settings
- `scan_range`: Maximum scanning distance (default: 10.0)
- `scan_beam_width`: Width of the scanning beam (default: 0.1)
- `scan_frequency`: Scans per second (default: 60.0)
- `scanner_sensitivity`: Color detection sensitivity (default: 1.0)

#### Display Settings
- `screen_size`: Physical screen dimensions (default: 2.0 x 1.5)
- `screen_resolution`: Pixel resolution (default: 128 x 96)
- `display_brightness`: Screen brightness multiplier (default: 1.0)
- `show_debug_info`: Enable debug information overlay

#### Visual Effects
- `emit_scanning_beam`: Show visible scanning beam (default: true)
- `beam_intensity`: Brightness of scanning beam (default: 0.5)
- `screen_glow`: Enable screen glow effect (default: true)
- `scanner_animation`: Enable subtle device animations (default: true)

## Scene Setup

The scanner comes with a pre-configured test scene featuring:

### Wall-Mounted Color Sheets
- 6 different colored panels mounted on a wall
- Pride flag colors: Red, Orange, Yellow, Green, Blue, Purple
- Each panel has emission for better visibility

### Table-Top Color Palettes
- 3 color palette squares on a wooden table surface
- Hot Pink, Lime Green, and Cyan palettes
- Compact design for close-range scanning

### Environment
- Proper lighting setup with directional light and shadows
- Camera positioned for optimal viewing of scanner operation
- Neutral background to emphasize color detection

## Technical Details

### Color Extraction Methods
1. **Material Override**: First checks for material_override on MeshInstance3D
2. **Surface Materials**: Falls back to mesh surface materials
3. **Shader Parameters**: Extracts colors from shader parameters (albedo, color, base_color)
4. **Custom Color Methods**: Supports objects with get_color() method

### Display Rendering
- Uses Godot's Image class for pixel-level control
- Real-time texture updates for smooth display
- Efficient drawing algorithms for UI elements
- Support for custom drawing functions (circles, lines, borders)

### Performance Optimization
- Configurable scan frequency to balance responsiveness and performance
- Efficient ray casting with proper collision masking
- Smart beam visualization that adjusts to detected surfaces
- Minimal texture updates to reduce GPU overhead

## Installation

1. Copy the `color_scanner` folder to your `algorithms/color/` directory
2. Open the `color_scanner.tscn` scene in Godot
3. Run the scene to test the scanner functionality
4. Integrate into your project by instantiating the ColorScanner node

## Customization

### Creating Custom Color Sheets
Add new color targets by creating MeshInstance3D nodes with colored materials:

```gdscript
var color_sheet = MeshInstance3D.new()
var mesh = BoxMesh.new()
mesh.size = Vector3(2, 2, 0.1)
color_sheet.mesh = mesh

var material = StandardMaterial3D.new()
material.albedo_color = Color.RED
color_sheet.material_override = material
```

### Custom Display Modes
Extend the scanner by adding new display modes:

```gdscript
func draw_custom_display():
    screen_image.fill(Color.BLACK)
    # Add your custom visualization here
    # ...
```

Then add your mode to the display_mode handling in `update_display()`.

## Future Enhancements

- **Color calibration**: Automatic white balance and color correction
- **Color matching**: Database lookup for named colors
- **Export functionality**: Save detected colors to files
- **Network connectivity**: Share colors between multiple scanners
- **Audio feedback**: Sound effects for successful color detection
- **Texture analysis**: Pattern and texture recognition beyond just color
