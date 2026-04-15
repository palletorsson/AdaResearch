extends Node3D

## Request Note — floating text artifact for placing notes/requests in maps.
##
## Usage in map_data.json interactables layer:
##   "request_note:0:1.5#text:Fix the lighting here"
##   "request_note#text:Add a teleporter"
##   "request_note#key:bug_report_42"     ← reads from requests.json
##
## Short text: #text:your message (inline in map JSON)
## Long text:  #key:some_key (reads from commons/maps/{MapName}/requests.json)
##
## The note floats at placement height with gentle bob animation.

const COPPER := Color(0.75, 0.38, 0.13)
const CREAM := Color(0.90, 0.87, 0.80)
const WARM_DARK := Color(0.25, 0.23, 0.20)

var _text: String = "REQUEST"
var _label: Label3D
var _bg: MeshInstance3D
var _time: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	_build_note()


func _build_note() -> void:
	# Background card
	_bg = MeshInstance3D.new()
	_bg.name = "Card"
	var box := BoxMesh.new()
	box.size = Vector3(0.01, 0.01, 0.004)  # Will resize after text
	_bg.mesh = box
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = CREAM
	bg_mat.metallic = 0.05
	bg_mat.roughness = 0.75
	_bg.material_override = bg_mat
	add_child(_bg)

	# Dark frame behind card
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var fbox := BoxMesh.new()
	fbox.size = Vector3(0.01, 0.01, 0.002)
	frame.mesh = fbox
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = WARM_DARK
	fmat.metallic = 0.2
	fmat.roughness = 0.6
	frame.material_override = fmat
	frame.transform.origin.z = -0.002
	add_child(frame)

	# Copper accent strip at top
	var accent := MeshInstance3D.new()
	accent.name = "Accent"
	var abox := BoxMesh.new()
	abox.size = Vector3(0.01, 0.003, 0.002)
	accent.mesh = abox
	var amat := StandardMaterial3D.new()
	amat.albedo_color = COPPER
	amat.metallic = 0.6
	amat.roughness = 0.35
	amat.emission = COPPER
	amat.emission_energy_multiplier = 0.3
	accent.material_override = amat
	add_child(accent)

	# "REQUEST" header label
	var header := Label3D.new()
	header.name = "Header"
	header.text = "REQUEST"
	header.font_size = 14
	header.pixel_size = 0.0004
	header.modulate = COPPER
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.outline_size = 2
	header.outline_modulate = Color(0, 0, 0, 0.3)
	add_child(header)

	# Main text label
	_label = Label3D.new()
	_label.name = "Text"
	_label.text = _text
	_label.font_size = 18
	_label.pixel_size = 0.0005
	_label.modulate = Color(0.12, 0.12, 0.12)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.width = 400  # pixels before wrap
	_label.outline_size = 2
	_label.outline_modulate = Color(1, 1, 1, 0.3)
	add_child(_label)

	# Billboard — always face camera
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	header.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	# Size the card based on text length
	call_deferred("_resize_card")

	_base_y = transform.origin.y


func _resize_card() -> void:
	# Estimate card size from text
	var lines: int = max(1, ceili(_text.length() / 30.0))
	var card_w: float = min(0.4, max(0.15, _text.length() * 0.004))
	var card_h: float = 0.04 + lines * 0.02

	# Update card mesh
	var box := BoxMesh.new()
	box.size = Vector3(card_w, card_h, 0.004)
	_bg.mesh = box

	# Frame
	var frame: MeshInstance3D = get_node_or_null("Frame")
	if frame:
		var fbox := BoxMesh.new()
		fbox.size = Vector3(card_w + 0.006, card_h + 0.006, 0.002)
		frame.mesh = fbox

	# Accent strip
	var accent: MeshInstance3D = get_node_or_null("Accent")
	if accent:
		var abox := BoxMesh.new()
		abox.size = Vector3(card_w * 0.6, 0.003, 0.002)
		accent.mesh = abox
		accent.transform.origin.y = card_h / 2.0 + 0.002

	# Position header and text
	var header: Label3D = get_node_or_null("Header")
	if header:
		header.transform.origin = Vector3(0, card_h / 2.0 - 0.008, 0.004)

	_label.transform.origin = Vector3(0, -0.005, 0.004)


func _process(delta: float) -> void:
	_time += delta
	# Gentle bob animation
	transform.origin.y = _base_y + sin(_time * 1.5) * 0.01


func apply_grid_config(config_data: Dictionary) -> void:
	# Inline text
	if config_data.has("text"):
		_text = str(config_data["text"])

	# Key-based text (reads from requests.json in map folder)
	if config_data.has("key"):
		var key_name: String = str(config_data["key"])
		_text = _load_request_text(key_name)

	# Update label if already built
	if _label:
		_label.text = _text
		call_deferred("_resize_card")


func _load_request_text(key_name: String) -> String:
	# Try to find requests.json in the current map folder
	# The GridSystem sets map_name which we can read from the scene
	var grid_system: Node = get_tree().get_first_node_in_group("grid_system") if is_inside_tree() else null
	var map_name: String = ""
	if grid_system and "map_name" in grid_system:
		map_name = str(grid_system.map_name)

	if map_name != "":
		var json_path: String = "res://commons/maps/%s/requests.json" % map_name
		if ResourceLoader.exists(json_path):
			var file := FileAccess.open(json_path, FileAccess.READ)
			if file:
				var json := JSON.new()
				if json.parse(file.get_as_text()) == OK:
					var data: Dictionary = json.data
					if data.has(key_name):
						return str(data[key_name])

	return "[%s]" % key_name
