extends Node3D
## Optional museum basin around the existing terrain and its three authored resources.
## The original full-size scene is unchanged unless stand:basin is requested.
var basin: bool = false
var terrain: MeshInstance3D
var plate: Label3D
var layer_index: int = 0
const WEIGHTS := Vector3(12.0, 6.0, 1.5)
const NAMES := ["SUM", "LOW", "MIDDLE", "HIGH"]

func _enter_tree() -> void:
	basin = str(get_meta("config_stand", "")) == "basin"
	if not basin: return
	rotation.x = 0.0
	terrain = get_node("MeshInstance3D")
	# A table model needs one stable mesh. Legacy LOD meshes bypass the erosion pass.
	terrain.set("enable_lod", false)
	terrain.set("enable_collision_optimization", false)
	var model := Node3D.new()
	model.name = "Model"
	var original: Array[Node] = get_children()
	add_child(model)
	for child in original:
		remove_child(child)
		if child is WorldEnvironment or child is Camera3D or child is DirectionalLight3D:
			child.queue_free()
		else:
			model.add_child(child)
	model.scale = Vector3.ONE * 0.02
	# Keep the authored coordinate frame, with a quieter density at model scale.
	for child in model.get_children():
		if child is MeshInstance3D and str(child.name).begins_with("GridStructure"):
			var mat: ShaderMaterial=child.material_override.duplicate()
			mat.set_shader_parameter("minor_cells",30.0)
			mat.set_shader_parameter("minor_line_color",Color(0.20,0.78,1.0,0.05))
			mat.set_shader_parameter("major_line_color",Color(0.82,0.98,1.0,0.13))
			mat.set_shader_parameter("emission_strength",0.15)
			child.material_override=mat

func _ready() -> void:
	if not basin: return
	var kit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.045,0.075,0.09)
	dark.roughness = 0.7
	add_child(kit.box(Vector3(0,-0.63,0),Vector3(4.5,0.1,4.5),dark))
	for x in [-2.24,2.24]:
		add_child(kit.box(Vector3(x,-0.34,0),Vector3(0.06,0.55,4.5),dark))
	var panel := load("res://commons/audio/rack_templates/RackTemplates.gd").create_panel("",[[{"type":"button","label":"SUM"},{"type":"button","label":"LOW"}],[{"type":"button","label":"MIDDLE"},{"type":"button","label":"HIGH"}]],true) as Node3D
	panel.name = "LayerPanel"
	panel.set_meta("em_local_instrument",true)
	panel.position=Vector3(0.8,0.22,2.30)
	panel.rotation_degrees.x=-25
	panel.scale=Vector3.ONE*1.5
	add_child(panel)
	for i in range(4):
		var area: Node=panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton")
		area.button_pressed.connect(func(_b): choose_layer(i))
	var case_ := Node3D.new()
	case_.name="LayerReadout";case_.position=Vector3(-0.55,0.26,2.23);case_.rotation_degrees.x=-18
	case_.set_meta("em_local_instrument",true);add_child(case_)
	case_.add_child(kit.box(Vector3.ZERO,Vector3(1.35,0.27,0.025),dark))
	plate=Label3D.new();plate.name="Text";plate.font_size=22;plate.pixel_size=0.0014;plate.position.z=0.02
	plate.modulate=Color(0.78,0.94,0.91);case_.add_child(plate)
	update_plate()

func choose_layer(index: int) -> void:
	if not basin or index==layer_index: return
	layer_index=clampi(index,0,3)
	terrain.set("low_freq_amplitude",WEIGHTS.x if index in [0,1] else 0.0)
	terrain.set("med_freq_amplitude",WEIGHTS.y if index in [0,2] else 0.0)
	terrain.set("high_freq_amplitude",WEIGHTS.z if index in [0,3] else 0.0)
	for child in terrain.get_children():
		if child is StaticBody3D:
			terrain.remove_child(child);child.queue_free()
	terrain.call("generate_terrain")
	terrain.call("setup_collision")
	update_plate()

func update_plate() -> void:
	plate.text="%s | three fields, one height\nweights %.1f / %.1f / %.1f\n1:50 model | 101 x 101 samples\nsame three-pass slope lowering" % [NAMES[layer_index],terrain.get("low_freq_amplitude"),terrain.get("med_freq_amplitude"),terrain.get("high_freq_amplitude")]

func apply_grid_config(_config: Dictionary) -> void:
	pass # Stand mode is read before the authored children enter the tree.
