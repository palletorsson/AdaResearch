# StudioVRInterface.gd — VR interaction layer for the Pokemon Studio
#
# Handles specimen selection, growth speed control, breeding interaction,
# release gestures, and the DNA inspector panel. Connects VR input to
# the studio's subsystems.
#
# Usage:
#   var vr_ui := StudioVRInterface.new()
#   vr_ui.studio = pokemon_studio_ref
#   add_child(vr_ui)

class_name StudioVRInterface
extends Node3D

# ─────────────────────────────────────────────────────────────
#  References (set by PokemonStudio)
# ─────────────────────────────────────────────────────────────

## The parent studio controller.
var studio: Node = null  # PokemonStudio — typed as Node to avoid circular dep

## Growth chamber reference.
var growth_chamber: GrowthChamber = null

## Breeding lab reference.
var breeding_lab: BreedingLab = null

## Release gate reference.
var release_gate: ReleaseGate = null

## Specimen collection.
var collection: SpecimenCollection = null


# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Distance at which the DNA inspector appears.
@export var inspect_distance: float = 3.0


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Player selected a specimen for inspection.
signal specimen_selected(entity: CritterEntity)

## Player requested breeding.
signal breed_requested()

## Player requested release of a specimen.
signal release_requested(dna: CritterDNA, specimen_id: String)

## Player changed growth speed.
signal growth_speed_changed(speed: float)


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## Currently inspected entity.
var _inspected_entity: CritterEntity = null

## DNA inspector panel node.
var _inspector_panel: Node3D = null

## Growth speed slider.
var _growth_slider: Node3D = null

## Breed button.
var _breed_button: Node3D = null


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_inspector_panel()
	_build_controls()


func _process(_delta: float) -> void:
	# Update inspector panel if tracking an entity
	if _inspected_entity and is_instance_valid(_inspected_entity) and _inspector_panel:
		_inspector_panel.visible = true
		_inspector_panel.global_position = _inspected_entity.global_position + Vector3(0, 1.5, 0)
		_update_inspector_display()
	elif _inspector_panel:
		_inspector_panel.visible = false


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Select a specimen for inspection.
func inspect(entity: CritterEntity) -> void:
	_inspected_entity = entity
	specimen_selected.emit(entity)


## Clear the current inspection.
func clear_inspection() -> void:
	_inspected_entity = null


## Get the currently inspected entity.
func get_inspected() -> CritterEntity:
	return _inspected_entity


## Trigger a breed action (delegates to breeding lab).
func trigger_breed() -> void:
	breed_requested.emit()
	if breeding_lab and breeding_lab.is_ready():
		breeding_lab.breed()


## Trigger a release action.
func trigger_release(dna: CritterDNA, specimen_id: String = "") -> void:
	release_requested.emit(dna, specimen_id)
	if release_gate:
		release_gate.release_specimen(dna, specimen_id)


## Set the growth speed (1x-20x).
func set_growth_speed(speed: float) -> void:
	var clamped: float = clampf(speed, 0.1, 20.0)
	if growth_chamber:
		growth_chamber.growth_speed = clamped
	growth_speed_changed.emit(clamped)


## Generate a random specimen and add it to the collection.
func generate_random(kingdom: int = -1) -> String:
	if not collection:
		return ""

	var dna: CritterDNA
	if kingdom >= 0 and kingdom <= 4:
		dna = CritterDNA.random_kingdom(kingdom)
	else:
		dna = CritterDNA.random()

	return collection.add(dna)


# ═══════════════════════════════════════════════════════════════
# INSPECTOR PANEL
# ═══════════════════════════════════════════════════════════════

## Build the floating inspector panel (Label3D nodes for VR readability).
func _build_inspector_panel() -> void:
	_inspector_panel = Node3D.new()
	_inspector_panel.name = "InspectorPanel"
	_inspector_panel.visible = false
	add_child(_inspector_panel)

	# Background panel
	var bg := MeshInstance3D.new()
	bg.name = "Background"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.6, 0.5)
	bg.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.1, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg.material_override = mat
	_inspector_panel.add_child(bg)

	# Title label
	var title := Label3D.new()
	title.name = "TitleLabel"
	title.text = "DNA Inspector"
	title.font_size = 32
	title.modulate = Color(0.9, 0.8, 1.0)
	title.position = Vector3(0, 0.2, 0.01)
	title.no_depth_test = true
	_inspector_panel.add_child(title)

	# Info label (updated dynamically)
	var info := Label3D.new()
	info.name = "InfoLabel"
	info.text = ""
	info.font_size = 20
	info.modulate = Color(0.8, 0.85, 0.9)
	info.position = Vector3(0, 0.0, 0.01)
	info.no_depth_test = true
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_inspector_panel.add_child(info)


## Update the inspector panel text.
func _update_inspector_display() -> void:
	if not _inspected_entity or not is_instance_valid(_inspected_entity):
		return

	var info_label: Label3D = _inspector_panel.get_node_or_null("InfoLabel") as Label3D
	if not info_label:
		return

	var info: Dictionary = _inspected_entity.get_info_dict()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Kingdom: %s" % info.get("kingdom", "?"))
	lines.append("Gen: %d | Hybrid: %.0f%%" % [info.get("generation", 0), info.get("hybridity", 0.0) * 100.0])
	lines.append("Energy: %.0f%%" % (info.get("energy_ratio", 0.0) * 100.0))
	lines.append("Bond: %.0f%%" % (info.get("bond_level", 0.0) * 100.0))
	lines.append("Mob:%.1f Agg:%.1f Soc:%.1f Cur:%.1f" % [
		info.get("mobility", 0), info.get("aggression", 0),
		info.get("sociality", 0), info.get("curiosity", 0),
	])

	info_label.text = "\n".join(lines)

	# Update title with kingdom name
	var title_label: Label3D = _inspector_panel.get_node_or_null("TitleLabel") as Label3D
	if title_label:
		title_label.text = "%s (Gen %d)" % [info.get("kingdom", "?").capitalize(), info.get("generation", 0)]


## Build VR control elements.
func _build_controls() -> void:
	# Growth speed slider placeholder (will be replaced with actual VR slider)
	_growth_slider = Node3D.new()
	_growth_slider.name = "GrowthSpeedControl"
	add_child(_growth_slider)

	# Breed button placeholder
	_breed_button = Node3D.new()
	_breed_button.name = "BreedButton"
	add_child(_breed_button)
