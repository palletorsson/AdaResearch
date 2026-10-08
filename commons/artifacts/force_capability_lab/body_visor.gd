extends Node3D
## A read-only head-worn instrument. Movement remains owned by the court/provider.
## Arrows are world vectors expressed in the eye frame; numbers stay world XYZ.
const ACCENT := Color("f0a2c4")
var court: Node3D
var body: CharacterBody3D
var eye: Camera3D
var overlay: Node3D
var worn := false
var channels: Dictionary = {}
var state_line: Label3D
var last_sample: Dictionary = {}
var elapsed := 0.0

func attach(receiver: CharacterBody3D, camera: Camera3D) -> void:
	if receiver==body and camera==eye and is_instance_valid(overlay):return
	clear_overlay()
	body=receiver;eye=camera
	if body==null or eye==null:return
	overlay=Node3D.new();overlay.name="BodyVectorVisor"
	eye.add_child(overlay);overlay.position=Vector3(0,-0.36,-1.4)
	var panel=MeshInstance3D.new();var plane=QuadMesh.new();plane.size=Vector2(1.03,0.25)
	panel.mesh=plane;panel.material_override=ink(Color(0.045,0.055,0.07,0.8));panel.position.z=-0.025
	overlay.add_child(panel)
	var look=text("+\nLOOK",Vector3(0,0.35,0),0.00035,Color("dedbd4"));overlay.add_child(look)
	var configs=[['velocity','VELOCITY / m/s',Color("f3eee5")],['thrust','THRUST F/m / m/s²',ACCENT],['gravity','GRAVITY / m/s²',Color("a7cbd0")]]
	for i in configs.size():
		var root=Node3D.new();root.position=Vector3((i-1)*0.34,0,0);overlay.add_child(root)
		var title=text(configs[i][1],Vector3(0,0.09,0),0.00049,configs[i][2]);root.add_child(title)
		var arrow=Node3D.new();arrow.position=Vector3(-0.105,-0.005,0.02);root.add_child(arrow)
		var shaft=MeshInstance3D.new();var tube=CylinderMesh.new()
		tube.top_radius=0.003;tube.bottom_radius=0.003;tube.height=0.09;tube.radial_segments=8
		shaft.mesh=tube;shaft.position.y=0.045;shaft.material_override=ink(configs[i][2]);shaft.material_override.render_priority=112;arrow.add_child(shaft)
		var tip=MeshInstance3D.new();var cone=CylinderMesh.new()
		cone.top_radius=0;cone.bottom_radius=0.012;cone.height=0.035;cone.radial_segments=8
		tip.mesh=cone;tip.position.y=0.1;tip.material_override=shaft.material_override;arrow.add_child(tip)
		var value=text("0.00",Vector3(0.035,0.02,0),0.00075,configs[i][2]);root.add_child(value)
		var components=text("(0.0, 0.0, 0.0)",Vector3(0.03,-0.035,0),0.00043,configs[i][2]);root.add_child(components)
		channels[configs[i][0]]={"arrow":arrow,"value":value,"components":components}
	state_line=text("WORLD X Y Z  /  LOOKING IS NOT MOVING",Vector3(0,-0.092,0),0.0004,Color("d0c7cb"));overlay.add_child(state_line)
	overlay.visible=false

func ink(colour: Color) -> StandardMaterial3D:
	var mat=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=colour;mat.no_depth_test=true
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	# Keep all HUD surfaces in the same ordered transparent pass.
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.render_priority=110
	return mat

func text(words: String, at: Vector3, pixels: float, colour: Color) -> Label3D:
	var label=Label3D.new();label.text=words;label.position=at;label.font_size=40
	label.pixel_size=pixels;label.modulate=colour;label.outline_size=0
	label.no_depth_test=true;label.render_priority=115
	return label

func set_worn(value: bool) -> void:
	worn=value
	if is_instance_valid(overlay):overlay.visible=false
	update_reading()

func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed<0.04:return
	elapsed=0
	update_reading()

func update_reading() -> void:
	if not is_instance_valid(overlay) or not is_instance_valid(body) or not is_instance_valid(eye):return
	var active: bool=worn and is_instance_valid(court) and court._point_inside(body.global_position)
	var navigator=get_tree().get_first_node_in_group("museum_portal_navigation")
	if navigator!=null and navigator.busy:active=false
	overlay.visible=active
	if not active:return
	last_sample=court.body_reading(body)
	var view=eye.global_basis.orthonormalized().inverse()
	for key in channels:
		var value: Vector3=last_sample[key]
		var reading: Dictionary=channels[key]
		reading.value.text="%.2f" % value.length()
		reading.components.text="(%+.1f, %+.1f, %+.1f)" % [value.x,value.y,value.z]
		reading.arrow.visible=value.length_squared()>0.000001
		if reading.arrow.visible:
			reading.arrow.basis=Basis(Quaternion(Vector3.UP,(view*value).normalized()))
			# Bounded display length, labelled magnitude carries the actual value.
			reading.arrow.scale=Vector3.ONE*clampf(value.length()/10.0,0.25,1.0)
	state_line.text="WORLD X Y Z / CONTACTS NOT INCLUDED IN F/m"
	if last_sample.get("launch_recent",false):state_line.text="PAD: INITIAL VELOCITY SET / NOT A CONTINUOUS FORCE"

func clear_overlay() -> void:
	if is_instance_valid(overlay):overlay.queue_free()
	overlay=null;channels.clear();last_sample.clear()

func _exit_tree() -> void:
	clear_overlay()
