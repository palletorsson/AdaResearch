extends Node3D
## Companion control stand. A separate editable artifact, linked by placement ID.
const ControlPanel = preload("res://commons/ui/control_panel.gd")
var target_id := "variation"
var target: Node3D
var panel: Node3D
var sliders: Dictionary = {}
var readout: Label
var _refresh := 0.0
var _syncing := false

func apply_grid_config(config: Dictionary) -> void:
	target_id=str(config.get("target_id",target_id))

func _ready() -> void:
	panel=ControlPanel.new();panel.name="FractalControls";panel.title="FIVE CHILDREN / ONE RULE"
	panel.tilt_degrees=-18;panel.layout_columns=3
	panel.position=Vector3(0,1.1,0);add_child(panel)
	readout=panel.add_readout("CONNECTING TO STUDY")
	for entry in [["speed","SPEED / DEG S",0.0,45.0,1],["size","SIZE / METRES",.4,1.8,2],["depth","LEVELS / 1-4",1.0,4.0,0]]:
		var slider: Node3D=panel.add_slider(entry[1]);slider.name=str(entry[0]).capitalize()
		slider.set_range(entry[2],entry[3]);slider.decimal_places=entry[4]
		sliders[entry[0]]=slider
		slider.slider_moved.connect(_slider_changed.bind(str(entry[0]),float(entry[2]),float(entry[3])))
	# A plain black steel stand leaves the form visible above the controls.
	var material:=StandardMaterial3D.new();material.albedo_color=Color("303039");material.roughness=.6;material.metallic=.6
	_box("Foot",Vector3(0,.035,0),Vector3(.7,.07,.48),material)
	_box("Stem",Vector3(0,.56,-.05),Vector3(.07,1.05,.07),material)
	_find_target.call_deferred()

func _slider_changed(_value: float,key: String,low: float,high: float) -> void:
	if _syncing or not is_instance_valid(target):return
	var slider: Node3D=sliders[key]
	var normalized: float=slider.get_normalized_value()
	# A small end stop makes zero speed easy to reach with a mouse or hand.
	var snapped: float=0.0 if normalized<.015 else 1.0 if normalized>.985 else normalized
	if snapped!=normalized:
		_syncing=true;slider.set_normalized_value(snapped);_syncing=false
	target.set_parameter(key,lerpf(low,high,snapped))

func _box(label: String,at: Vector3,size_value: Vector3,material: Material) -> void:
	var mesh:=MeshInstance3D.new();mesh.name=label;mesh.mesh=BoxMesh.new();mesh.mesh.size=size_value
	mesh.material_override=material;mesh.position=at;add_child(mesh)
	var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=1;mesh.add_child(body)
	var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=size_value;body.add_child(shape)

func _find_target() -> void:
	# Artifact -> placement root -> floor root; never bind another floor's study.
	var floor_node: Node=get_parent().get_parent() if get_parent()!=null else null
	if floor_node==null:return
	var placement:=floor_node.get_node_or_null(NodePath(target_id))
	if placement!=null:target=placement.get_node_or_null("Artifact")
	if not is_instance_valid(target) or not target.has_method("is_live_study"):
		target=null;return
	for entry in [["speed",target.runtime_speed,0.0,45.0],["size",target.runtime_size,.4,1.8],["depth",float(target.runtime_depth),1.0,4.0]]:
		sliders[entry[0]].set_normalized_value(inverse_lerp(entry[2],entry[3],entry[1]))

func _process(delta: float) -> void:
	_refresh+=delta
	if _refresh<.2:return
	_refresh=0
	if not is_instance_valid(target):_find_target();return
	# Also follow live editor/config reloads, not only this panel's last drag.
	_syncing=true
	for entry in [["speed",target.runtime_speed,0.0,45.0],["size",target.runtime_size,.4,1.8],["depth",float(target.runtime_depth),1.0,4.0]]:
		sliders[entry[0]].set_normalized_value(inverse_lerp(entry[2],entry[3],entry[1]))
	_syncing=false
	readout.text="%.1f DEG/S | %.2f M | %d LEVELS\n%d PARTS / SPEED ZERO HOLDS THE POSE"%[target.runtime_speed,target.runtime_size,target.runtime_depth,target._members.size()]

func prepare_editor_preview() -> void:
	set_process(false)
	readout.text="SPEED / SIZE / LEVELS\nDRAG A SLIDER TO CHANGE THE LIVING FORM"
	await get_tree().process_frame
