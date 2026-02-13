## ada_palette.gd — Single source of truth for all AdaResearch UI colors & sizing
##
## Usage (from anywhere):
##   var c = AdaPalette.ACCENT_ORANGE
##   var mat = AdaPalette.make_material(AdaPalette.ACCENT_ORANGE, 0.3, 0.5, 0.4)
##
## Register as autoload "AdaPalette" in Project → Globals so every script can reach it.
## Alternatively, just preload: const P = preload("res://commons/ui/ada_palette.gd")
extends Node
class_name AdaPalette

# ───────────────────────────────────────────
#  PANEL / BACKGROUND  (light-to-dark ramp)
# ───────────────────────────────────────────
const PANEL_WHITE   := Color(0.96, 0.96, 0.97, 1.0)   # Near-white, main background
const PANEL_LIGHT   := Color(0.90, 0.90, 0.92, 1.0)   # Light gray, secondary panels
const PANEL_MEDIUM  := Color(0.60, 0.60, 0.64, 1.0)   # Mid gray, borders / separators
const PANEL_DARK    := Color(0.18, 0.18, 0.22, 1.0)   # Dark, screen bezels & slots
const PANEL_BLACK   := Color(0.06, 0.06, 0.08, 1.0)   # Near-black, display backgrounds

# ───────────────────────────────────────────
#  ACCENT COLORS  (high-chroma, pop on light)
# ───────────────────────────────────────────
const ACCENT_ORANGE := Color(0.95, 0.45, 0.15, 1.0)   # Primary — TE-inspired orange
const ACCENT_BLUE   := Color(0.20, 0.55, 0.95, 1.0)   # Info, links
const ACCENT_CYAN   := Color(0.00, 0.78, 0.85, 1.0)   # Displays, data
const ACCENT_GREEN  := Color(0.25, 0.78, 0.35, 1.0)   # Active, positive, go
const ACCENT_YELLOW := Color(0.95, 0.75, 0.10, 1.0)   # Warning, highlight
const ACCENT_RED    := Color(0.90, 0.22, 0.22, 1.0)   # Stop, danger, mute

# ───────────────────────────────────────────
#  TEXT
# ───────────────────────────────────────────
const TEXT_PRIMARY   := Color(0.12, 0.12, 0.14, 1.0)   # Main text on light bg
const TEXT_SECONDARY := Color(0.40, 0.40, 0.44, 1.0)   # Subtle labels
const TEXT_ON_DARK   := Color(0.92, 0.92, 0.94, 1.0)   # Text on dark panels
const TEXT_ACCENT    := Color(0.95, 0.45, 0.15, 1.0)   # Highlighted text = ACCENT_ORANGE

# ───────────────────────────────────────────
#  METAL / STRUCTURAL  (3D VR materials)
# ───────────────────────────────────────────
const METAL_DARK    := Color(0.10, 0.10, 0.13, 1.0)   # Knob bases, structure
const METAL_CHROME  := Color(0.70, 0.72, 0.74, 1.0)   # Shiny accents
const METAL_WARM    := Color(0.40, 0.38, 0.35, 1.0)   # Brushed metal

# ───────────────────────────────────────────
#  DISPLAY / SCREEN
# ───────────────────────────────────────────
const SCREEN_BG     := Color(0.02, 0.04, 0.08, 1.0)   # CRT/LCD dark
const SCREEN_GRID   := Color(0.10, 0.18, 0.22, 0.5)   # Grid overlay
const SCREEN_TRACE  := Color(0.00, 1.00, 0.85, 1.0)   # Oscilloscope trace

# ───────────────────────────────────────────
#  RACK MODULE SIZING  (meters, VR scale)
# ───────────────────────────────────────────
## Base grid unit = 0.08m (8cm) — all modules snap to multiples
const RACK_UNIT := 0.08

## Standard module sizes  (width × height in RACK_UNITs)
const MODULE_1x1 := Vector2(1, 1)     #  8cm ×  8cm — button, small knob
const MODULE_1x2 := Vector2(1, 2)     #  8cm × 16cm — vertical slider, meter
const MODULE_2x1 := Vector2(2, 1)     # 16cm ×  8cm — horizontal slider
const MODULE_2x2 := Vector2(2, 2)     # 16cm × 16cm — joystick, XY pad
const MODULE_3x2 := Vector2(3, 2)     # 24cm × 16cm — monitor, display (standard)
const MODULE_4x2 := Vector2(4, 2)     # 32cm × 16cm — wide display
const MODULE_4x3 := Vector2(4, 3)     # 32cm × 24cm — large display

## Control-type to module-size mapping
const CONTROL_MODULES := {
	"button":     MODULE_1x1,
	"knob":       MODULE_1x1,
	"dial":       MODULE_1x1,
	"slider":     MODULE_1x2,
	"slv":        MODULE_1x2,
	"slh":        MODULE_2x1,
	"sls":        MODULE_2x1,
	"slz":        MODULE_2x1,
	"meter":      MODULE_1x2,
	"lever":      MODULE_1x2,
	"wheel":      MODULE_2x2,
	"joystick":   MODULE_2x2,
	"xy":         MODULE_2x2,
	"monitor":    MODULE_3x2,
	"waveform":   MODULE_3x2,
	"spectrum":   MODULE_3x2,
	"lissajous":  MODULE_3x2,
	"simple_waveform": MODULE_3x2,
}

## Gap between modules (meters)
const MODULE_GAP := 0.006  # 6mm

## Panel depth / thickness (meters)
const PANEL_DEPTH := 0.012

# ───────────────────────────────────────────
#  EMISSION PRESETS  (for VR readability)
# ───────────────────────────────────────────
const EMISSION_NONE    := 0.0
const EMISSION_SUBTLE  := 0.3    # Labels, gentle glow
const EMISSION_MEDIUM  := 0.6    # Active indicators
const EMISSION_BRIGHT  := 1.2    # Screens, strong accents
const EMISSION_HOT     := 2.0    # Attention-grabbing

# ───────────────────────────────────────────
#  2D THEME CONSTANTS
# ───────────────────────────────────────────
const CORNER_RADIUS     := 6      # px — button/panel rounding
const CORNER_RADIUS_SM  := 3      # px — small elements
const BORDER_WIDTH      := 2      # px — outlines
const FONT_SIZE_LABEL   := 14
const FONT_SIZE_HEADING := 20
const FONT_SIZE_SMALL   := 11
const FONT_SIZE_DISPLAY := 32     # Readout values

# ═══════════════════════════════════════════
#  HELPER: create a StandardMaterial3D
# ═══════════════════════════════════════════
static func make_material(
	color: Color,
	metallic: float = 0.0,
	roughness: float = 0.8,
	emission_strength: float = 0.0
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_strength
	return mat

# Convenience factories for common materials
static func panel_material(shade: Color = PANEL_LIGHT) -> StandardMaterial3D:
	return make_material(shade, 0.05, 0.75)

static func accent_material(color: Color = ACCENT_ORANGE) -> StandardMaterial3D:
	return make_material(color, 0.25, 0.45, EMISSION_MEDIUM)

static func metal_material(color: Color = METAL_DARK) -> StandardMaterial3D:
	return make_material(color, 0.7, 0.35)

static func screen_material() -> StandardMaterial3D:
	return make_material(SCREEN_BG, 0.0, 0.95, EMISSION_NONE)

static func handle_glow_material(color: Color = ACCENT_ORANGE) -> StandardMaterial3D:
	return make_material(color, 0.3, 0.4, EMISSION_BRIGHT)

# ═══════════════════════════════════════════
#  HELPER: module size in meters
# ═══════════════════════════════════════════
static func module_size_meters(control_type: String) -> Vector2:
	var units: Vector2 = CONTROL_MODULES.get(control_type, MODULE_1x1)
	return units * RACK_UNIT

static func module_size_with_gap(control_type: String) -> Vector2:
	return module_size_meters(control_type) + Vector2(MODULE_GAP, MODULE_GAP)
