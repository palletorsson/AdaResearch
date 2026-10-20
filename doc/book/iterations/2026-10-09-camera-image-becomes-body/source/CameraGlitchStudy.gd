extends Node3D
## One live museum camera, ten declared receivers. Display-only interventions.
const Forms = preload("res://commons/artifacts/camera_glitch_study/receivers.gd")
const Surface = preload("res://commons/artifacts/camera_glitch_study/camera_surface.gdshader")
const Channels = preload("res://commons/artifacts/camera_glitch_study/colour_plane.gdshader")
const CameraHandle = preload("res://commons/artifacts/spine_studies/witness_camera.gd")
const Console = preload("res://commons/ui/control_console.gd")
const SCREEN_LAYER := 1<<19
var forms=Forms.new()
var mode:=0
var amount:=.8
var paused:=false
var elapsed:=0.0
var captures:=0
var taking_snapshot:=false
var parked:=false
var held_texture: ImageTexture
var viewport: SubViewport
var source_camera: Camera3D
var handle: Node3D
var home_pose: Transform3D
var receivers: Array[MeshInstance3D]=[]
var reference: MeshInstance3D
var status: Label3D
var description: Label3D
var readout: Label3D
var slider: Node3D
var buttons: Dictionary={}

func _ready() -> void:
	name="CameraGlitchStudy"
	process_physics_priority=101
	viewport=SubViewport.new();viewport.size=Vector2i(640,360);viewport.world_3d=get_world_3d()
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(viewport)
	source_camera=Camera3D.new();viewport.add_child(source_camera);source_camera.current=true
	source_camera.fov=70;source_camera.near=.08;source_camera.far=70
	source_camera.cull_mask=0xFFFFF & ~SCREEN_LAYER & ~(1<<18)
	handle=CameraHandle.new();handle.channel="SOURCE";add_child(handle)
	handle.position=Vector3(-2.1,1.35,1.2);handle.look_at(to_global(Vector3(-.5,1.7,8)))
	home_pose=handle.transform
	box(Vector3(-2.1,.58,1.2),Vector3(.08,1.15,.08),Color("7f8b8a"),true)
	box(Vector3(-2.1,.025,1.2),Vector3(.4,.05,.4),Color("323b42"),true)
	box(Vector3(.55,.42,-.15),Vector3(3.8,.84,1.1),Color("e9e5dd"),true)
	box(Vector3(-2.2,2.35,-.12),Vector3(1.82,1.10,.12),Color("172c39"),true)
	reference=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(1.7,.95625);reference.mesh=quad
	reference.position=Vector3(-2.2,2.35,-.048);reference.layers=SCREEN_LAYER;add_child(reference)
	var reference_material:=StandardMaterial3D.new();reference_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	reference_material.albedo_texture=viewport.get_texture();reference.material_override=reference_material
	label("SOURCE / THE SAME ROOM",Vector3(-2.2,3.02,0),.0014)
	label("TAKE CAMERA / AIM / RELEASE",Vector3(-2.2,.85,1.4),.0010)
	status=label("",Vector3(0,3.76,0),.0018)
	description=label("",Vector3(0,3.39,0),.0011)
	readout=label("",Vector3(-2.2,1.65,0),.0010)
	var console=Console.new();console.auto_demo=false;console.face_to_origin=false;console.body_height=.6;console.board_width=2.8
	console.position=Vector3(.5,0,1.85);add_child(console);console.set_title("ONE CAMERA / TEN WAYS TO RECEIVE IT")
	slider=console.add_slider("AMOUNT / FROM FLAT TO TRANSFORMED","amount");slider.set_normalized_value(amount)
	slider.slider_moved.connect(_amount_changed)
	for id in ["PREVIOUS","NEXT","SNAP","LIVE / HOLD","HOME","RESET"]:
		var button=console.add_button(id);buttons[id]=button;button.pressed.connect(act.bind(id))
	rebuild();hide_from_source(self);sync_source()
	first_frame.call_deferred()

func first_frame() -> void:
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	if is_inside_tree(): await snapshot()
func hide_from_source(node: Node) -> void:
	if node is VisualInstance3D:node.layers=SCREEN_LAYER
	for child in node.get_children():hide_from_source(child)
func sync_source() -> void:source_camera.global_transform=handle.lens_pose()
func _physics_process(_delta:float)->void:
	if handle==null:return
	if handle.held_by_visitor():parked=false
	elif parked:handle.transform=home_pose
func _process(delta: float) -> void:
	sync_source();elapsed+=delta
	var viewer:=get_viewport().get_camera_3d()
	var active:=is_visible_in_tree() and viewer!=null and viewer.global_position.distance_to(global_position)<25
	if active and not paused and elapsed>=.05:
		elapsed=0;captures+=1;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	readout.text="%s / frame %d\n640 x 360 / max 20 captures/s\nSNAP keeps one frame"%["HELD" if paused else ("LIVE" if active else "OUT OF RANGE"),captures]
func input_texture() -> Texture2D:
	return held_texture if paused and held_texture!=null else viewport.get_texture()
func bind_images() -> void:
	reference.material_override.albedo_texture=input_texture()
	for receiver in receivers:
		var mat: ShaderMaterial=receiver.material_override;mat.set_shader_parameter("camera_frame",input_texture())
		if mode!=2:
			mat.set_shader_parameter("held_frame",held_texture if held_texture!=null else viewport.get_texture())
			mat.set_shader_parameter("has_held",held_texture!=null)
func snapshot() -> void:
	if taking_snapshot:return
	taking_snapshot=true
	# Read once on demand; never feed the output back into the source camera.
	await RenderingServer.frame_post_draw
	var image:=viewport.get_texture().get_image()
	if image!=null and not image.is_empty():held_texture=ImageTexture.create_from_image(image)
	taking_snapshot=false;bind_images()
func rebuild() -> void:
	for receiver in receivers:remove_child(receiver);receiver.queue_free()
	receivers.clear()
	var mesh:=forms.build(mode,amount)
	for channel in (3 if mode==2 else 1):
		var receiver:=MeshInstance3D.new();receiver.name="Receiver"+str(channel);receiver.mesh=mesh;receiver.layers=SCREEN_LAYER
		receiver.position=Vector3(.55,2.1,-.2)
		var mat:=ShaderMaterial.new();mat.shader=Channels if mode==2 else Surface
		if mode==2:
			var colour:=Vector3.ZERO;colour[channel]=1;mat.set_shader_parameter("channel",colour)
			receiver.position+=Vector3((channel-1)*amount*.25,0,channel*amount*.32)
		else:mat.set_shader_parameter("mode",mode);mat.set_shader_parameter("amount",amount)
		receiver.material_override=mat;receiver.custom_aabb=AABB(Vector3(-2.5,-1.3,-1.4),Vector3(5,2.6,3.1))
		add_child(receiver);receivers.append(receiver)
	status.text=Forms.TITLES[mode];description.text=Forms.NOTES[mode]
	bind_images()
func _amount_changed(_value: Variant) -> void:
	amount=slider.get_normalized_value();rebuild()
func select(index: int) -> void:
	mode=posmod(index,10);rebuild()
func act(id: String) -> void:
	match id:
		"PREVIOUS":select(mode-1)
		"NEXT":select(mode+1)
		"SNAP":snapshot()
		"LIVE / HOLD":
			if held_texture!=null:paused=not paused;bind_images()
		"HOME":
			home_camera()
		"RESET":
			mode=0;amount=.8;paused=false;slider.set_normalized_value(amount);rebuild()
			home_camera()
func home_camera() -> void:
	if handle.held_by_visitor():return
	parked=true
	# The map can translate/rotate this artifact after _ready; home belongs to it.
	handle.transform=home_pose;handle.linear_velocity=Vector3.ZERO;handle.angular_velocity=Vector3.ZERO
	# Synchronise the frozen rigid body's physics pose as well as its Node3D pose.
	PhysicsServer3D.body_set_state(handle.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,global_transform*home_pose)
	handle.reset_physics_interpolation()
func material(colour: Color) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=.5;return mat
func box(at: Vector3,size: Vector3,colour: Color,solid:=false) -> void:
	var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.position=at;mesh.material_override=material(colour);add_child(mesh)
	if solid:
		var body:=StaticBody3D.new();body.position=at;add_child(body)
		var collision:=CollisionShape3D.new();var boxshape:=BoxShape3D.new();boxshape.size=size;collision.shape=boxshape;body.add_child(collision)
func label(text: String,at: Vector3,pixels: float) -> Label3D:
	var l:=Label3D.new();l.text=text;l.position=at;l.font_size=40;l.pixel_size=pixels;l.modulate=Color("fff0e8");add_child(l);return l
