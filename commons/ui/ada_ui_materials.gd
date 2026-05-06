## ada_ui_materials.gd — Preloaded material references for VR components
##
## Use instead of inline sub_resources or scattered .tres files.
## Every VR control scene should reference materials from here.
##
## Usage:
##   const UI = preload("res://commons/ui/ada_ui_materials.gd")
##   mesh.material_override = UI.PANEL_LIGHT
##
## Or register as autoload "AdaMaterials" and use:
##   mesh.material_override = AdaMaterials.PANEL_LIGHT
extends Node

# ── Panels / Backgrounds ──
const PANEL_WHITE  : StandardMaterial3D = preload("res://commons/ui/materials/panel_white.tres")
const PANEL_LIGHT  : StandardMaterial3D = preload("res://commons/ui/materials/panel_light.tres")
const PANEL_MEDIUM : StandardMaterial3D = preload("res://commons/ui/materials/panel_medium.tres")
const PANEL_DARK   : StandardMaterial3D = preload("res://commons/ui/materials/panel_dark.tres")

# ── Accents (with emission for VR readability) ──
const ACCENT_ORANGE : StandardMaterial3D = preload("res://commons/ui/materials/accent_orange.tres")
const ACCENT_BLUE   : StandardMaterial3D = preload("res://commons/ui/materials/accent_blue.tres")
const ACCENT_CYAN   : StandardMaterial3D = preload("res://commons/ui/materials/accent_cyan.tres")
const ACCENT_GREEN  : StandardMaterial3D = preload("res://commons/ui/materials/accent_green.tres")
const ACCENT_YELLOW : StandardMaterial3D = preload("res://commons/ui/materials/accent_yellow.tres")
const ACCENT_RED    : StandardMaterial3D = preload("res://commons/ui/materials/accent_red.tres")

# ── Metal / Structural ──
const METAL_DARK   : StandardMaterial3D = preload("res://commons/ui/materials/metal_dark.tres")
const METAL_CHROME : StandardMaterial3D = preload("res://commons/ui/materials/metal_chrome.tres")
const METAL_WARM   : StandardMaterial3D = preload("res://commons/ui/materials/metal_warm.tres")

# ── Screens / Displays ──
const SCREEN_BG    : StandardMaterial3D = preload("res://commons/ui/materials/screen_bg.tres")
const SCREEN_BEZEL : StandardMaterial3D = preload("res://commons/ui/materials/screen_bezel.tres")

# ── Interactive ──
const HANDLE_GLOW  : StandardMaterial3D = preload("res://commons/ui/materials/handle_glow.tres")
const TRACK_GROOVE : StandardMaterial3D = preload("res://commons/ui/materials/track_groove.tres")
const TRACK_FILL   : StandardMaterial3D = preload("res://commons/ui/materials/track_fill.tres")

# ── Theme ──
const THEME_2D : Theme = preload("res://commons/ui/ada_theme.tres")

# ═══════════════════════════════════════════
#  MIGRATION MAP: old material → new material
#  Use this when porting existing scenes
# ═══════════════════════════════════════════

## Maps old .tres paths to new ones for automated migration
const MIGRATION_MAP := {
	# Old interactables/materials → new ui/materials
	"res://commons/interactables/materials/rack_panel.tres":         "res://commons/ui/materials/panel_white.tres",
	"res://commons/interactables/materials/rack_panel_dark.tres":    "res://commons/ui/materials/panel_dark.tres",
	"res://commons/interactables/materials/rack_accent.tres":        "res://commons/ui/materials/handle_glow.tres",
	"res://commons/interactables/materials/rack_metal.tres":         "res://commons/ui/materials/metal_dark.tres",
	"res://commons/interactables/materials/slider_handle_glow.tres": "res://commons/ui/materials/handle_glow.tres",
	"res://commons/interactables/materials/slider_track_dark.tres":  "res://commons/ui/materials/track_groove.tres",
	
	# Old interfaces/materials → new ui/materials
	"res://commons/audio/interfaces/materials/te_rack_material.tres":  "res://commons/ui/materials/panel_white.tres",
	"res://commons/audio/interfaces/materials/te_accent_orange.tres":  "res://commons/ui/materials/accent_orange.tres",
	"res://commons/audio/interfaces/materials/te_accent_blue.tres":    "res://commons/ui/materials/accent_blue.tres",
	"res://commons/audio/interfaces/materials/te_accent_green.tres":   "res://commons/ui/materials/accent_green.tres",
	"res://commons/audio/interfaces/materials/te_accent_yellow.tres":  "res://commons/ui/materials/accent_yellow.tres",
	"res://commons/audio/interfaces/materials/te_slot_dark.tres":      "res://commons/ui/materials/track_groove.tres",
}

## Apply the 2D theme to a Control node and all its children
static func apply_theme(control: Control) -> void:
	control.theme = THEME_2D
