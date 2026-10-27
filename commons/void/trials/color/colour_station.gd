extends "res://commons/artifacts/chroma_stack/chroma_stack.gd"
## The original five solids and colour functions, with a repeatable experiment.
## A rule change repaints existing materials; it never rebuilds the geometry.
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
const PALETTE: Array[Color] = [
	Color(0.80,0.16,0.16), Color(0.16,0.36,0.80), Color(0.92,0.78,0.18),
	Color(0.78,0.60,0.30), Color("#e854a6"), Color("#1a8888")
]
const TITLES := {
	"one":"ONE COLOUR", "by_shape":"BY SHAPE",
	"by_height":"BY HEIGHT", "by_neighbour":"BY NEIGHBOUR"
}
const STUDY_RULES := ["one","by_shape","by_height","by_neighbour"]
var initial_rule := "one"
var selected_part := 2
var paint_override := false
var controls: Node3D
var rule_button: Node3D
var part_button: Node3D
var paint_button: Node3D
var reset_button: Node3D
var readout: Label
var explanation: Node3D

func _ready() -> void:
	super._ready()
	initial_rule = rule

func _build() -> void:
	super._build()
	selected_part = mini(selected_part, elements().size()-1)
	paint_override = false
	# Matched local white lights and the trial's white ambient fill illuminate
	# the study layer. The tinted sun excludes it; paint is matte, non-emissive.
	for part in elements():
		part.layers = 2
		var material: StandardMaterial3D = part.get_surface_override_material(0)
		material.metallic_specular = 0.0
	for z in [1.5,-1.5]:
		var lamp := OmniLight3D.new()
		lamp.name = "WhiteStudyLightFront" if z>0 else "WhiteStudyLightBack"
		lamp.position = Vector3(0,2.2,z)
		lamp.light_color = Color.WHITE
		lamp.light_energy = 2.0 if z>0 else 1.0
		lamp.omni_range = 3.0
		lamp.light_cull_mask = 2
		lamp.shadow_enabled = false
		add_child(lamp)
	refresh()

func _add_plate(body: StaticBody3D) -> void:
	var mount := BoxMesh.new()
	mount.size = Vector3(1.25,.08,.08)
	_add_mesh(mount,Vector3(-.6,1.2,.5),MOUNT_COLOR,"PlateMount")
	controls = ControlPanelScript.new()
	controls.name = "ColourControls"
	controls.position = Vector3(-1.2,1.2,.88)
	controls.spacing = .32
	controls.title = TITLES.get(rule,rule.to_upper())
	controls.panel_color = Color(.8,.8,.8)
	controls.accent_color = Color.WHITE
	add_child(controls)
	rule_button = controls.add_button("RULE")
	part_button = controls.add_button("PART +")
	paint_button = controls.add_button("PAINT")
	reset_button = controls.add_button("RESET")
	readout = controls.add_readout("")
	rule_button.pressed.connect(next_rule)
	part_button.pressed.connect(next_part)
	paint_button.pressed.connect(paint_selected)
	reset_button.pressed.connect(restore)
	explanation = TextScreenScript.new()
	explanation.name = "Explanation"
	explanation.mode = 0
	explanation.width_m = 1.35
	explanation.position = Vector3(-1.2,.64,.9)
	add_child(explanation)
	_add_box_shape(body,Vector3(-1.2,1.2,.84),Vector3(1.4,.45,.04))

func elements() -> Array[MeshInstance3D]:
	var parts: Array[MeshInstance3D] = []
	for child in get_children():
		if child is MeshInstance3D and str(child.name).begins_with("Element_"):
			parts.append(child)
	return parts

func next_rule() -> void:
	set_rule(STUDY_RULES[(STUDY_RULES.find(rule)+1)%STUDY_RULES.size()])

func set_rule(value: String) -> void:
	assert(value in STUDY_RULES)
	rule = value
	var colours: Array = _colours_for(STACKS[stack])
	var parts := elements()
	for i in parts.size():
		parts[i].get_surface_override_material(0).albedo_color = colours[i]
	paint_override = false
	refresh()

func next_part() -> void:
	selected_part = (selected_part+1)%elements().size()
	refresh()

func paint_selected() -> void:
	var material: StandardMaterial3D = elements()[selected_part].get_surface_override_material(0)
	var index := -1
	for i in PALETTE.size():
		if material.albedo_color.is_equal_approx(PALETTE[i]): index = i
	material.albedo_color = PALETTE[(index+1)%PALETTE.size()]
	paint_override = true
	refresh()

func restore() -> void:
	selected_part = 2
	set_rule(initial_rule)

func refresh() -> void:
	if not is_instance_valid(readout): return
	var colour: Color = elements()[selected_part].get_surface_override_material(0).albedo_color
	readout.text = "[%d] RGB %.2f %.2f %.2f" % [selected_part,colour.r,colour.g,colour.b]
	controls.title = TITLES.get(rule,rule.to_upper()) + (" + PAINT" if paint_override else "")
	explanation.set_text("SAME FIVE PIECES",PLATE_BODY[rule]+"\nPART: 0 at the foot, 4 at the top.\nPAINT changes that part.")

func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	initial_rule = rule
