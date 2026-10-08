extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Finite horizontal supports, vertical gravity, and an actual rigid load.
## The hull forecasts the INITIAL static configuration, not dynamic stability.
const PRIVATE_LAYER := 1 << 21
const FOOT_HALF := 0.08
const START := Vector3(0,1.635,0) # 1 cm above the 1.5 m pad tops
const FEET := [Vector3(1.35,0,-1.35),Vector3(-1.35,0,-1.35),Vector3(-1.35,0,1.35),Vector3(1.35,0,1.35)]
var mode := 0
var shift_index := 0
var released := false
var parts := false
var rule := false
var clock_time := 0.0
var text_clock := 0.0
var body: RigidBody3D
var supports: Array[StaticBody3D] = []
var foot_meshes: Array[MeshInstance3D] = []
var banks: Array[Label3D] = []
var board: Label3D
var hull_mesh: MeshInstance3D
var wall_mesh: MeshInstance3D
var com_marker: MeshInstance3D
var projection: MeshInstance3D
var gravity_line: MeshInstance3D
var hull := PackedVector2Array()

func active_indices() -> Array:
	return [[0,1,2,3],[1,2,3],[2,3],[1,3]][mode]

func load_offset() -> Vector3:
	return [Vector3.ZERO,Vector3(-0.65,0,0.65),Vector3(0.65,0,-0.65)][shift_index]

func collider(host: CollisionObject3D, size: Vector3) -> void:
	var shape=CollisionShape3D.new();var box_shape=BoxShape3D.new();box_shape.size=size;shape.shape=box_shape;host.add_child(shape)

func _ready() -> void:
	var steel=material("233d49");var gold=material("eabe6b",true)
	box(Vector3(0,0.035,0),Vector3(10.5,0.07,10.5),material("344e5c"))
	var floor_body=StaticBody3D.new();floor_body.collision_layer=PRIVATE_LAYER;floor_body.collision_mask=PRIVATE_LAYER;floor_body.position.y=-0.12;add_child(floor_body);collider(floor_body,Vector3(10.5,0.24,10.5))
	for x in range(-5,6):
		box(Vector3(x,0.077,0),Vector3(0.014,0.014,10),steel)
		box(Vector3(0,0.077,x),Vector3(10,0.014,0.014),steel)
	for i in 4:
		var foot=StaticBody3D.new();foot.position=FEET[i]+Vector3(0,0.75,0);foot.collision_layer=PRIVATE_LAYER;foot.collision_mask=PRIVATE_LAYER;add_child(foot);collider(foot,Vector3(FOOT_HALF*2,1.5,FOOT_HALF*2));supports.append(foot)
		foot_meshes.append(box(foot.position,Vector3(0.16,1.5,0.16),material("73cbb6")))
		var caption=label(str(i+1),FEET[i]+Vector3(0,0.15,-0.25),0.0015);caption.rotation_degrees.x=-90
	body=RigidBody3D.new();body.name="PhysicalLoad";body.mass=10;body.freeze=true;body.collision_layer=PRIVATE_LAYER;body.collision_mask=PRIVATE_LAYER;body.can_sleep=false
	body.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;body.linear_damp=0;body.angular_damp=0
	body.gravity_scale=1;body.center_of_mass_mode=RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM;body.inertia=Vector3(12,20,12)
	var pm=PhysicsMaterial.new();pm.friction=0.8;pm.bounce=0;body.physics_material_override=pm
	floor_body.physics_material_override=pm
	for support in supports:support.physics_material_override=pm
	add_child(body);collider(body,Vector3(3.4,0.25,3.4));box(Vector3.ZERO,Vector3(3.4,0.25,3.4),material("d99dbb"),false,body)
	var xray=material("eabe6b",true);xray.no_depth_test=true
	com_marker=box(Vector3.ZERO,Vector3(0.18,0.18,0.18),xray,false,body)
	projection=box(Vector3(0,0.13,0),Vector3(0.18,0.035,0.18),gold)
	gravity_line=MeshInstance3D.new();gravity_line.mesh=ImmediateMesh.new();gravity_line.material_override=gold;add_child(gravity_line)
	for side in 2:
		var panel=preload("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(panel);panel.position=Vector3(-2.25 if side==0 else 2.25,0,-4.4);panel.rotation.y=PI
		panel.console(["FEET","SHIFT","RELEASE","RESET"] if side==0 else ["PARTS","RULE"],0,"A BODY WAITING FOR CONTACT")
		banks.append(panel.readout)
		for id in panel.buttons:buttons[id]=panel.buttons[id];buttons[id].pressed.connect(act.bind(id))
	box(Vector3(0,3.1,4.9),Vector3(10.4,4.8,0.1),steel)
	board=label("",Vector3(0,4.3,4.82),0.0021);board.rotation.y=PI
	hull_mesh=MeshInstance3D.new();hull_mesh.mesh=ImmediateMesh.new();hull_mesh.material_override=material("72d7bd",true);add_child(hull_mesh)
	wall_mesh=MeshInstance3D.new();wall_mesh.mesh=ImmediateMesh.new();wall_mesh.material_override=material("72d7bd",true);add_child(wall_mesh)
	reset_experiment()

func reset_experiment() -> void:
	released=false;clock_time=0;body.freeze=true;body.transform=Transform3D(Basis.IDENTITY,START);body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO
	body.center_of_mass=load_offset();com_marker.position=load_offset()
	var corners=PackedVector2Array()
	for i in 4:
		var active: bool=i in active_indices();supports[i].collision_layer=PRIVATE_LAYER if active else 0;foot_meshes[i].visible=active
		if active:
			for dx in [-FOOT_HALF,FOOT_HALF]:
				for dz in [-FOOT_HALF,FOOT_HALF]:corners.append(Vector2(FEET[i].x+dx,FEET[i].z+dz))
	hull=Geometry2D.convex_hull(corners)
	update_visuals();update_text()

func margin() -> float:
	var point=Vector2(load_offset().x,load_offset().z);var nearest:=INF
	for i in range(hull.size()-1):nearest=minf(nearest,point.distance_to(Geometry2D.get_closest_point_to_segment(point,hull[i],hull[i+1])))
	return nearest if Geometry2D.is_point_in_polygon(point,hull) else -nearest

func tilt_degrees() -> float:
	return rad_to_deg(acos(clampf(body.basis.y.normalized().dot(Vector3.UP),-1,1)))

func act(id: String) -> void:
	match id:
		"FEET":mode=(mode+1)%4;reset_experiment()
		"SHIFT":shift_index=(shift_index+1)%3;reset_experiment()
		"RELEASE":
			if not released:released=true;body.freeze=false;body.sleeping=false
		"RESET":reset_experiment()
		"PARTS":parts=not parts
		"RULE":rule=not rule
	update_visuals();update_text()

func _physics_process(delta: float) -> void:
	if released:clock_time+=delta
	update_visuals();text_clock+=delta
	if text_clock>=0.1:text_clock=0;update_text()

func update_visuals() -> void:
	var centre: Vector3=body.position+body.basis*body.center_of_mass
	projection.position=Vector3(centre.x,0.13,centre.z);projection.visible=parts;gravity_line.visible=parts;com_marker.visible=parts
	var line: ImmediateMesh=gravity_line.mesh;line.clear_surfaces()
	if parts:
		line.surface_begin(Mesh.PRIMITIVE_LINES);line.surface_add_vertex(centre);line.surface_add_vertex(projection.position);line.surface_end()
	for wall in [false,true]:
		var target: MeshInstance3D=wall_mesh if wall else hull_mesh;target.visible=parts;var mesh: ImmediateMesh=target.mesh;mesh.clear_surfaces()
		if not parts:continue
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for p in hull:mesh.surface_add_vertex(Vector3(p.x,2.0-p.y*0.6,4.8) if wall else Vector3(p.x,0.105,p.y))
		mesh.surface_end()
		if wall:
			mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			var at=Vector3(centre.x,2.0-centre.z*0.6,4.79)
			mesh.surface_add_vertex(at-Vector3(0.1,0,0));mesh.surface_add_vertex(at+Vector3(0.1,0,0));mesh.surface_add_vertex(at-Vector3(0,0.1,0));mesh.surface_add_vertex(at+Vector3(0,0.1,0));mesh.surface_end()

func update_text() -> void:
	banks[0].text="%s / %.1f s\n%d supports / load X %.2f Z %.2f"%["RELEASED" if released else "HELD",clock_time,active_indices().size(),load_offset().x,load_offset().z]
	banks[1].text="Measured tilt %.1f degrees\nInitial support margin %+.3f m"%[tilt_degrees(),margin()] if parts else "Predict, RELEASE, then reveal.\nWhich beginning can stay level?"
	board.text="Remove a support. Move the load. Then RELEASE.\nFEET and SHIFT reset the experiment; RESET retains your choices.\nThe seven walkers beyond this floor prescribe motion. This load can fall."
	if rule:board.text="Initial footprint = convex hull of finite 0.16 m support squares.\nPositive margin: projected mass centre is inside this initial footprint.\nVertical gravity, horizontal pads, no commanded motion; dynamic balance asks more.\n10 kg rigid body; custom centre and fixed inertia; friction 0.8, bounce 0."
	if parts:board.text+="\nGold: X-ray mass centre. Wall: initial footprint and LIVE projection; not a contact sensor."
