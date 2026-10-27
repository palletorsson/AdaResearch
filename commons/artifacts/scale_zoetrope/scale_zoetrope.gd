extends Node3D
## Twenty-four permanently sized ivory cubes on an open black-steel disk.
## A real optional sector shutter gives COUNT brief views per disk revolution.
## No cube is swapped, resized, hidden by script or animated on an independent clock.
## Ideal gearing maps the hand angle to the disk and shutter; forces are not solved.
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const HandWheel = preload("res://commons/artifacts/sine_yoke/hand_wheel.gd")
const ServiceHandle = preload("res://commons/artifacts/scale_zoetrope/service_handle.gd")
const MachineFinish = preload("res://commons/artifacts/machine_finish.gd")
const COUNT := 24
const RADIUS := 2.22
const PLATE_RADIUS := 2.5
const CONTROL_Z := 3.05
const DROP_Z := 2.75
const DECK_Y := 2.0
const OPEN_ANGLE := 95.0
const POINTER_LAYERS := (1 << 20) | (1 << 22)
const SAMPLE_CLOCKS := [0.0,6.0,12.0,24.0,30.0,60.0,90.0,120.0]
const MAX_RPM := 3600.0
@export var initial_angle := 0.0
@export var auto_run := true
@export var motor_rpm := 60.0
@export var sample_hz := 0.0 # Zero follows the display's process frames.
@export var shutter_enabled := false
signal state_changed(state: Dictionary)
var part_defaults: Dictionary = {}
var shell: Node3D
var drive: Node3D
var panel: Node3D
var panel_leaf: AnimatableBody3D
var wheel: Node3D
var disk: Node3D
var shutter: MeshInstance3D
var cubes: Array[MeshInstance3D] = []
var frame_edges: Array[float] = []
var service_handle: StaticBody3D
var service_open := false
var door_motion: Tween
var angle_degrees := 0.0
var wood: StandardMaterial3D
var steel: StandardMaterial3D
var brass: StandardMaterial3D
var black: StandardMaterial3D
var ivory: StandardMaterial3D
var pink: StandardMaterial3D
var controls: Node3D
var console: Node3D
var reverse := false
var manual_cooldown := 0.0
var sample_elapsed := 0.0
var reading_elapsed := 0.0
var motor_phase := 0.0

@export var frame_count := COUNT
@export var orbit_radius := RADIUS
@export var plate_radius := PLATE_RADIUS
@export var deck_y := DECK_Y
@export var control_z := CONTROL_Z
@export var drop_z := DROP_Z
@export var rpm_limit := MAX_RPM
@export var fixed_cube_edge := -1.0
@export var open_frame := false

func _ready() -> void:
	wood = Timber.material()
	steel = MachineFinish.steel()
	ivory = MachineFinish.ivory();pink = MachineFinish.pink()
	brass = ivory
	black = finish("080b0e", 0, 1)
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not open_frame:
		shell = Node3D.new();shell.name = "RoomShell";add_child(shell)
	drive = Node3D.new();drive.name = "DiskAndCrank"
	if not open_frame:
		panel = Node3D.new();panel.name = "ServicePanel";panel.position = Vector3(2,.2,-1)
		build_shell()
	build_disk()
	build_crank()
	build_shutter()
	add_child(drive)
	if not open_frame:
		build_panel()
		add_child(panel)
	build_controls()
	wheel.hinge_moved.connect(_on_turn)
	wheel.set_angle_degrees(initial_angle);_on_turn(initial_angle)
	motor_phase = initial_angle;set_shutter(shutter_enabled);refresh_controls()
	for child: Node3D in [shell, drive, panel, controls]:
		if not is_instance_valid(child):continue
		var b := mesh_bounds(child)
		part_defaults[str(child.name)] = {"position":[child.position.x,child.position.y,child.position.z],"rotation":[0,0,0],"bounds":[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]}
	part_defaults.DiskAndCrank.bounds = [-plate_radius-.02,0,-plate_radius-.02,plate_radius+.02+maxf(plate_radius+.02,1.5),maxf(deck_y+1.75,2.0),plate_radius+.02+control_z+.3]
	if part_defaults.has("ServicePanel"):part_defaults.ServicePanel.bounds = [-.1,0,-.1,2.2,3.65,2.2]
	set_meta("void_preview_kind", "Static source geometry: fixed cubes, disk, optional sector shutter, service panel and playback controls. Motor and hand input run in Godot.")
	set_process(true)

func build_shell() -> void:
	box(shell,Vector3(0,.08,0),Vector3(4.12,.16,4.12),wood,true)
	box(shell,Vector3(0,3.94,0),Vector3(4.12,.12,4.12),wood,true)
	box(shell,Vector3(-2,2,0),Vector3(.12,3.8,4),wood,true)
	box(shell,Vector3(0,2,-2),Vector3(4,3.8,.12),wood,true)
	# Fixed ends of the right wall leave a two-metre service opening.
	for z in [-1.5,1.5]:box(shell,Vector3(2,2,z),Vector3(.12,3.8,1),wood,true)
	for y in [.18,3.88]:box(shell,Vector3(2,y,0),Vector3(.14,.16,2),steel,true)
	# Single front viewing opening, 0.74 wide and 0.80 high, facing +Z.
	for x in [-1.185,1.185]:box(shell,Vector3(x,2,2),Vector3(1.63,3.8,.12),wood,true)
	box(shell,Vector3(0,.54,2),Vector3(.74,.8,.12),wood,true)
	box(shell,Vector3(0,2.87,2),Vector3(.74,2.14,.12),wood,true)
	# Black liner and internal cheek pieces suppress stray neighbouring views.
	box(shell,Vector3(0,2,-1.93),Vector3(3.88,3.65,.025),black)
	box(shell,Vector3(-1.93,2,0),Vector3(.025,3.65,3.88),black)
	for z in [-1.5,1.5]:box(shell,Vector3(1.93,2,z),Vector3(.025,3.65,1),black)
	for x in [-.45,.45]:box(shell,Vector3(x,1.34,1.77),Vector3(.16,.9,.38),black)
	for x in [-2.04,2.04]:
		for z in [-2.04,2.04]:box(shell,Vector3(x,2,z),Vector3(.09,4,.09),steel)
	for y in [.25,3.75]:box(shell,Vector3(0,y,2.075),Vector3(4.05,.05,.035),steel)
	for x in [-.405,.405]:box(shell,Vector3(x,1.34,2.08),Vector3(.045,.91,.045),brass)
	for y in [.915,1.765]:box(shell,Vector3(0,y,2.08),Vector3(.85,.045,.045),brass)
	words(shell,"LOOK THROUGH",Vector3(0,1.94,2.08),0)
	words(shell,"TAKE OVER BY HAND",Vector3(1.03,.65,2.09),0)
	box(shell,Vector3(.7,1.45,1.85),Vector3(.15,.15,.1),steel)
	# Both lights remain inside the enclosure; no room-wide flashing light.
	for x in [-.65,.65]:
		var lamp := OmniLight3D.new();lamp.position = Vector3(x,2.1,1.0)
		lamp.light_color = Color("fff3dc");lamp.light_energy = 1.4;lamp.omni_range = 2.5
		shell.add_child(lamp)

func build_disk() -> void:
	disk = Node3D.new();disk.name = "FixedSizeFrames";drive.add_child(disk)
	rod(drive,Vector3(0,.16,0),Vector3(0,deck_y-.05,0),.18,steel).name = "CentralSupport"
	box(drive,Vector3(0,.23,0),Vector3(.95,.14,.95),steel)
	var platter := MeshInstance3D.new();platter.name = "TimberDisk"
	var cylinder := CylinderMesh.new();cylinder.top_radius = plate_radius;cylinder.bottom_radius = plate_radius
	cylinder.height = .10;cylinder.radial_segments = 96;platter.mesh = cylinder
	platter.material_override = steel;platter.position.y = deck_y-.05;disk.add_child(platter)
	var rim := MeshInstance3D.new();rim.name = "IvoryPlateOutline"
	var bead := TorusMesh.new();bead.inner_radius = plate_radius-.018;bead.outer_radius = plate_radius
	bead.rings = 128;bead.ring_segments = 8;rim.mesh = bead;rim.position.y = deck_y-.005
	rim.material_override = ivory;disk.add_child(rim)
	for i in frame_count:
		var angle := i*TAU/frame_count
		var edge := fixed_cube_edge if fixed_cube_edge>0 else .16+.34*(.5-.5*cos(angle))
		var cube := box(disk,Vector3(sin(angle)*orbit_radius,deck_y+edge*.5,cos(angle)*orbit_radius),Vector3.ONE*edge,ivory)
		cube.name = "FixedCube%02d" % i;cube.rotation.y = angle
		MachineFinish.outline(cube,edge)
		cubes.append(cube);frame_edges.append(edge)
		# Each cube keeps its authored size and pose on the disk. Leave the
		# space between frames open as they travel around the repeating loop.
		var marker := box(disk,Vector3(sin(angle)*(orbit_radius-.19),deck_y+.008,cos(angle)*(orbit_radius-.19)),Vector3(.02,.01,.055),pink)
		marker.rotation.y = angle

func build_crank() -> void:
	wheel = HandWheel.new();wheel.name = "HandWheel";wheel.assemble()
	wheel.position = Vector3(1.03,1.18,control_z);wheel.scale = Vector3.ONE*.65
	var rotor: Node3D = wheel.get_node("HingeOrigin/InteractableHinge")
	var rim := MeshInstance3D.new();var torus := TorusMesh.new()
	torus.inner_radius = .435;torus.outer_radius = .485;torus.rings = 48;torus.ring_segments = 10
	rim.mesh = torus;rim.rotation.z = PI/2;rim.position.x = .04;rim.material_override = steel;rotor.add_child(rim)
	for i in 3:
		var angle := i*TAU/3
		rod(rotor,Vector3(.04,0,0),Vector3(.04,sin(angle)*.45,-cos(angle)*.45),.025,steel)
	rod(rotor,Vector3(-.18,0,0),Vector3(.11,0,0),.07,brass)
	rod(rotor,Vector3(.04,0,-.48),Vector3(.32,0,-.48),.027,brass)
	rod(rotor,Vector3(.22,0,-.48),Vector3(.34,0,-.48),.045,pink).name = "PinkGrip"
	drive.add_child(wheel)
	# Exposed right-angle axle and belt-like gearing housing, visible in service.
	rod(drive,Vector3(1.03,1.18,control_z-.05),Vector3(1.03,1.18,drop_z),.035,steel).name = "InputShaftFront"
	rod(drive,Vector3(1.03,1.18,drop_z),Vector3(1.03,.45,drop_z),.035,steel).name = "InputShaftDrop"
	box(drive,Vector3(.65,.45,0),Vector3(.65,.22,.28),steel)
	rod(drive,Vector3(0,.45,0),Vector3(1.03,.45,0),.045,brass).name = "UnderDeckAxle"
	rod(drive,Vector3(1.03,.45,0),Vector3(1.03,.45,drop_z),.035,steel).name = "UnderDeckDrive"

func build_shutter() -> void:
	shutter = MeshInstance3D.new();shutter.name = "PhysicalSectorShutter"
	var surface := SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A 120-degree missing sector points towards the aperture when angle is zero.
	for i in 72:
		var a := i*TAU/72;var b := (i+1)*TAU/72
		if absf(wrapf((a+b)*.5-PI,-PI,PI))<PI/3:continue
		for point in [Vector3.ZERO,Vector3(cos(a)*1.27,sin(a)*1.27,0),Vector3(cos(b)*1.27,sin(b)*1.27,0)]:
			surface.set_normal(Vector3.BACK);surface.add_vertex(point)
	shutter.mesh = surface.commit()
	var mat := black.duplicate() as StandardMaterial3D;mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shutter.material_override = mat;shutter.position = Vector3(.7,deck_y+.45,control_z-.22);drive.add_child(shutter)
	# This axle belongs to the optional shutter, so it is absent from the
	# open view too instead of leaving a floating stub over the platter.
	rod(shutter,Vector3(0,0,-.16),Vector3(0,0,.03),.045,steel)

func build_panel() -> void:
	panel_leaf = AnimatableBody3D.new();panel_leaf.name = "HingedServiceLeaf"
	panel_leaf.sync_to_physics = false;panel.add_child(panel_leaf)
	box(panel_leaf,Vector3(0,1.8,1),Vector3(.12,3.6,2),wood)
	box(panel_leaf,Vector3(-.071,1.8,1),Vector3(.025,3.55,1.95),black)
	var leaf_collision := CollisionShape3D.new();leaf_collision.position = Vector3(0,1.8,1)
	leaf_collision.shape = BoxShape3D.new();leaf_collision.shape.size = Vector3(.12,3.6,2)
	panel_leaf.add_child(leaf_collision)
	for z in [.08,1.92]:box(panel_leaf,Vector3(.071,1.8,z),Vector3(.03,3.5,.055),steel)
	for y in [.16,3.44]:box(panel_leaf,Vector3(.071,y,1),Vector3(.03,.055,1.9),steel)
	service_handle = StaticBody3D.new();service_handle.name = "ServiceLatch"
	service_handle.set_script(ServiceHandle);service_handle.exhibit = self
	service_handle.collision_layer = POINTER_LAYERS;service_handle.collision_mask = 0
	service_handle.position = Vector3(.16,1.4,1.7)
	var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(.22,.3,.22)
	service_handle.add_child(shape);panel_leaf.add_child(service_handle)
	rod(service_handle,Vector3(0,-.1,0),Vector3(0,.1,0),.028,brass)
	words(panel_leaf,"OPEN / SERVICE",Vector3(.09,1.8,1.5),PI/2)

func _on_turn(degrees: float) -> void:
	angle_degrees = degrees
	disk.rotation.y = deg_to_rad(degrees)
	shutter.rotation.z = -deg_to_rad(degrees*frame_count)
	state_changed.emit({"angle":degrees,"frame_phase":fposmod(degrees,360.0/frame_count)})

func build_controls() -> void:
	controls = Node3D.new();controls.name = "PlaybackControls"
	controls.position = Vector3(1.03,1.98,control_z)
	# The crank and console keep their reachable heights when the enclosure
	# is omitted. Their narrow steel stand ends on the floor, behind the rim.
	rod(controls,Vector3(0,-1.94,-.12),Vector3(0,.31,-.12),.04,steel).name = "ControlStand"
	box(controls,Vector3(0,-1.94,-.12),Vector3(.55,.08,.42),steel,true).name = "ControlStandFoot"
	console = load("res://commons/ui/physical_parameter_console.gd").new()
	console.name = "PlaybackConsole";console.title = "CUBES / CLOCK"
	var parameters: Array[Dictionary] = [{"label":"RPM","continuous":true,"value":sqrt(motor_rpm/rpm_limit)},
		{"label":"CLOCK","continuous":false,"steps":8,"value":float(clock_index())/7.0}]
	console.parameters = parameters
	console.actions = PackedStringArray(["RUN","SHUTTER","MATCH","REVERSE"])
	controls.add_child(console);add_child(controls)
	MachineFinish.console_finish(console)
	console.parameter_changed.connect(_on_parameter)
	console.action_pressed.connect(_on_action)
	words(controls,"MATCH: 1 CUBE / SAMPLE",Vector3(0,.41,.018),0)
	words(controls,"CLOCK: DISPLAY / 6 / 12 / 24\n30 / 60 / 90 / 120 Hz",Vector3(0,-.41,.018),0)

func clock_index() -> int:
	var best := 0
	for i in SAMPLE_CLOCKS.size():
		if absf(sample_hz-SAMPLE_CLOCKS[i])<absf(sample_hz-SAMPLE_CLOCKS[best]):best = i
	return best

func _on_parameter(index: int,value: float) -> void:
	if index==0:set_rpm(value*value*rpm_limit)
	else:set_sample_hz(SAMPLE_CLOCKS[clampi(roundi(value*7),0,7)])

func _on_action(index: int) -> void:
	match index:
		0:auto_run = not auto_run;sample_elapsed = 0;motor_phase = angle_degrees
		1:set_shutter(not shutter_enabled)
		2:match_clock()
		3:reverse = not reverse
	refresh_controls()

func set_rpm(value: float) -> void:
	motor_rpm = clampf(value,0,rpm_limit)
	refresh_controls()

func set_sample_hz(value: float) -> void:
	sample_hz = maxf(0,value);sample_elapsed = 0
	refresh_controls()

func set_shutter(value: bool) -> void:
	shutter_enabled = value
	if is_instance_valid(shutter):shutter.visible = value
	refresh_controls()

func match_clock() -> void:
	# A fixed local sampling clock is repeatable. Display matching is a measured
	# starting speed and deliberately drifts if the actual frame rate changes.
	var rate := sample_hz if sample_hz>0 else maxf(1,Engine.get_frames_per_second())
	set_rpm(rate*60.0/frame_count)
	if is_instance_valid(wheel):wheel.set_angle_degrees(snappedf(angle_degrees,360.0/frame_count))
	motor_phase = angle_degrees;sample_elapsed = 0;auto_run = true
	refresh_controls()

func hand_active() -> bool:
	return is_instance_valid(wheel) and (is_instance_valid(wheel._pointer) or not wheel.hinge.grabbed_handles.is_empty())

func advance_motion(delta: float) -> void:
	if not is_instance_valid(wheel):return
	if hand_active():
		manual_cooldown = .65;motor_phase = angle_degrees;sample_elapsed = 0;return
	if manual_cooldown>0:
		manual_cooldown = maxf(0,manual_cooldown-delta)
		motor_phase = angle_degrees;sample_elapsed = 0;return
	if not auto_run:
		motor_phase = angle_degrees;sample_elapsed = 0;return
	var elapsed := delta
	if sample_hz>0:
		sample_elapsed += delta
		var steps := floori((sample_elapsed+.00000001)*sample_hz)
		if steps<=0:return
		elapsed = float(steps)/sample_hz;sample_elapsed = maxf(0,sample_elapsed-elapsed)
	motor_phase = fposmod(motor_phase+elapsed*motor_rpm*6.0*(-1 if reverse else 1),360.0)
	wheel.set_angle_degrees(motor_phase)

func _process(delta: float) -> void:
	advance_motion(delta)
	reading_elapsed += delta
	if reading_elapsed>=.2:
		reading_elapsed = 0;refresh_controls()

func refresh_controls() -> void:
	if not is_instance_valid(console) or not console.is_node_ready():return
	console.set_parameter(0,sqrt(motor_rpm/rpm_limit));console.set_parameter(1,float(clock_index())/7.0)
	console.set_action_selected(0,auto_run);console.set_action_selected(1,shutter_enabled);console.set_action_selected(3,reverse)
	var display_fps := Engine.get_frames_per_second()
	var clock := "DISPLAY" if sample_hz<=0 else "%.0f Hz LOCAL"%sample_hz
	var state := "HAND" if hand_active() or manual_cooldown>0 else ("AUTO" if auto_run else "STOP")
	var rate := sample_hz if sample_hz>0 else maxf(1,display_fps)
	console.set_reading("%s | %.1f RPM | %.1f CUBES/s\n%s | %.1f FPS | %.2f CUBE/SAMPLE\nSHUTTER %s | %s"%[state,motor_rpm,motor_rpm*frame_count/60.0,clock,display_fps,motor_rpm*frame_count/(60.0*rate),"ON" if shutter_enabled else "OFF","REVERSE" if reverse else "FORWARD"])

func toggle_service() -> void:set_service_open(not service_open)
func set_service_open(value: bool, immediate := false) -> void:
	service_open = value
	if not is_instance_valid(panel_leaf):return
	if door_motion != null:door_motion.kill()
	var angle := deg_to_rad(OPEN_ANGLE) if value else 0.0
	if immediate:panel_leaf.rotation.y = angle
	else:
		door_motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		door_motion.tween_property(panel_leaf,"rotation:y",angle,.65).set_trans(Tween.TRANS_SINE)

func apply_grid_config(config: Dictionary) -> void:
	if not is_node_ready():return
	if config.has("initial_angle") and is_instance_valid(wheel):wheel.set_angle_degrees(float(config.initial_angle))
	if config.has("service_open"):set_service_open(bool(config.service_open),true)
	if config.has("auto_run"):auto_run = bool(config.auto_run)
	if config.has("motor_rpm"):set_rpm(float(config.motor_rpm))
	if config.has("sample_hz"):set_sample_hz(float(config.sample_hz))
	if config.has("shutter_enabled"):set_shutter(bool(config.shutter_enabled))
	if config.has("reverse"):reverse = bool(config.reverse)
	motor_phase = angle_degrees;refresh_controls()
	for child: Node3D in [shell,drive,panel,controls]:
		if not is_instance_valid(child):continue
		var id := str(child.name)
		if config.has("only_parts") and id not in config.only_parts:
			part_defaults.erase(id);child.free();continue
		var pose: Dictionary = config.get("parts",{}).get(id,part_defaults[id])
		var p: Array = pose.get("position",part_defaults[id].position)
		var r: Array = pose.get("rotation",part_defaults[id].rotation)
		child.position = Vector3(p[0],p[1],p[2]);child.rotation_degrees = Vector3(r[0],r[1],r[2])
		sync_bodies(child)

func finish(hex: String,metal: float,rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new();mat.albedo_color = Color(hex);mat.metallic = metal;mat.roughness = rough;return mat
func box(host: Node3D,p: Vector3,size: Vector3,mat: Material,solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new();mesh.mesh = Timber.mesh(size) if mat==wood else BoxMesh.new()
	if mesh.mesh is BoxMesh:mesh.mesh.size = size
	mesh.material_override = mat;mesh.position = p;host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new();var hit := CollisionShape3D.new();hit.shape = BoxShape3D.new();hit.shape.size = size
		body.add_child(hit);mesh.add_child(body)
	return mesh
func rod(host: Node3D,a: Vector3,b: Vector3,radius: float,mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new();var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius;cylinder.bottom_radius = radius;cylinder.height = a.distance_to(b);cylinder.radial_segments = 24
	mesh.mesh = cylinder;mesh.material_override = mat;mesh.position = (a+b)*.5
	mesh.quaternion = Quaternion(Vector3.UP,(b-a).normalized());host.add_child(mesh);return mesh
func words(host: Node3D,text: String,p: Vector3,yaw: float) -> void:
	var label := Label3D.new();label.text = text;label.position = p;label.rotation.y = yaw
	label.font_size = 44;label.pixel_size = .0012;label.outline_size = 0;label.modulate = Color("ded8c7");host.add_child(label)
func mesh_bounds(node: Node3D) -> AABB:
	var result := AABB();var first := true
	for child in node.find_children("*","MeshInstance3D",true,false):
		if child.mesh == null:continue
		var b: AABB = node.global_transform.affine_inverse()*child.global_transform*child.get_aabb()
		result = b if first else result.merge(b);first = false
	return result
func sync_bodies(node: Node) -> void:
	if node is RigidBody3D:PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
	for child in node.get_children():sync_bodies(child)

func prepare_editor_preview() -> void:
	# The web editor receives a stable source pose, not a phase captured at a
	# machine-dependent instant during the export job.
	set_process(false)
	if is_instance_valid(wheel):wheel.set_angle_degrees(initial_angle)
	refresh_controls()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
