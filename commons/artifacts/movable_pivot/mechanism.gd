extends Node3D
## Ideal constrained yaw linkage: sliding the bearing changes the centre of
## rotation. The deck has real collision; no simulated bearing friction/torque.
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Finish = preload("res://commons/artifacts/machine_finish.gd")
const Grip = preload("res://commons/artifacts/movable_pivot/pivot_grip.gd")
const LENGTH := 6.0
const WIDTH := 1.1
const DECK_Y := .64
var pivot_x := 0.0
var angle_degrees := 0.0
var target_pivot := 0.0
var target_angle := 0.0
var deck: AnimatableBody3D
var carriage: Node3D
var pivot_cap: Node3D
var turn_cap: Node3D
var pivot_grip: RigidBody3D
var turn_grip: RigidBody3D
var reading: Label3D
var preview := false
signal state_changed(state: Dictionary)

func _ready() -> void:
	var steel := Finish.steel(); var pink := Finish.pink(); var ivory := Finish.ivory()
	# Rail, feet and exposed end stops are attached to this same editable part.
	box(self, "Rail", Vector3(4.1,.14,.28), Vector3(0,.20,0), steel, true)
	for x in [-1.9,1.9]:
		box(self,"Foot",Vector3(.45,.15,.85),Vector3(x,.075,0),steel,true)
		box(self,"Stop",Vector3(.08,.28,.4),Vector3(x,.32,0),ivory)
	for i in range(-6,7):
		box(self,"RailTick",Vector3(.015,.008,.11 if i%2 else .19),Vector3(i*.25,.275,.055),ivory)
	carriage=Node3D.new();carriage.name="SlidingBearing";add_child(carriage)
	box(carriage,"BearingShoe",Vector3(.36,.16,.42),Vector3(0,.35,0),pink)
	cylinder(carriage,"ExposedAxle",.095,.25,Vector3(0,.52,0),steel)
	cylinder(carriage,"PivotWasher",.14,.025,Vector3(0,.735,0),pink)
	cylinder(carriage,"PivotPin",.045,.06,Vector3(0,.765,0),ivory)
	# A low front-side grip remains reachable without reaching through timber.
	box(carriage,"GripStem",Vector3(.055,.62,.055),Vector3(0,.68,.78),steel)
	box(carriage,"GripLink",Vector3(.07,.07,.78),Vector3(0,.40,.39),steel)
	pivot_cap=box(carriage,"PinkPivotGrip",Vector3(.27,.09,.12),Vector3(0,1.02,.78),pink)
	pivot_grip=make_grip("PivotGrip","pivot",Vector3(.30,.14,.18))
	deck=AnimatableBody3D.new();deck.name="WalkableTimber";deck.sync_to_physics=false
	deck.collision_layer=1;deck.collision_mask=0;add_child(deck)
	var hit:=CollisionShape3D.new();hit.name="DeckCollision";hit.shape=BoxShape3D.new();hit.shape.size=Vector3(LENGTH,.16,WIDTH);deck.add_child(hit)
	# Three timber boards retain the construction finish and nominal envelope.
	for z in [-.367,0,.367]:
		box(deck,"TimberBoard",Vector3(LENGTH,.16,.358),Vector3(0,0,z),Timber.material())
	for x in [-2.82,2.82]:
		box(deck,"EndBinding",Vector3(.065,.018,WIDTH),Vector3(x,.09,0),steel)
		for z in [-.4,.4]: cylinder(deck,"FlushBolt",.023,.022,Vector3(x,.105,z),ivory)
	# An off-white centre line makes the changed trajectory readable.
	box(deck,"CentreInlay",Vector3(LENGTH-.3,.006,.022),Vector3(0,.083,0),ivory)
	box(deck,"TurnStem",Vector3(.05,.33,.05),Vector3(2.5,.24,.72),steel)
	box(deck,"TurnLink",Vector3(.05,.05,.24),Vector3(2.5,.11,.6),steel)
	turn_cap=box(deck,"PinkTurningGrip",Vector3(.27,.09,.12),Vector3(2.5,.38,.72),pink)
	turn_grip=make_grip("TurnGrip","turn",Vector3(.30,.15,.18))
	reading=Label3D.new();reading.name="BearingReadout";reading.font_size=36;reading.pixel_size=.0025
	reading.modulate=Color("20232a");reading.outline_size=0;reading.position=Vector3(0,.015,1.65);reading.rotation.x=-PI/2;add_child(reading)
	apply_pose()

func make_grip(title: String, role: String, size: Vector3) -> RigidBody3D:
	var grip:=RigidBody3D.new();grip.name=title;grip.set_script(Grip);grip.mechanism=self;grip.role=role
	grip.freeze=true;grip.collision_layer=(1<<18)|(1<<20)|(1<<22);grip.collision_mask=0
	grip.picked_up_layer=0;grip.release_mode=XRToolsPickable.ReleaseMode.FROZEN
	grip.ranged_grab_method=XRToolsPickable.RangedMethod.NONE
	var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=size;grip.add_child(shape);add_child(grip)
	return grip

func _physics_process(delta: float) -> void:
	if preview: return
	pivot_grip.update_held();turn_grip.update_held()
	var old_p:=pivot_x;var old_a:=angle_degrees
	pivot_x=move_toward(pivot_x,clampf(target_pivot,-1.5,1.5),delta*1.4)
	angle_degrees=move_toward(angle_degrees,clampf(target_angle,-22,22),delta*28)
	if not is_equal_approx(old_p,pivot_x) or not is_equal_approx(old_a,angle_degrees):
		apply_pose();state_changed.emit({"pivot":pivot_x,"angle":angle_degrees})
	# XRTools' free proxy is put back on its constraint when the hand lets go.
	pivot_grip.rest_at(Vector3(pivot_x,1.02,.78))
	turn_grip.rest_at(to_local(turn_cap.global_position))

func apply_pose() -> void:
	var basis:=Basis(Vector3.UP,deg_to_rad(angle_degrees))
	deck.transform=Transform3D(basis,Vector3(pivot_x,DECK_Y,0)-basis*Vector3(pivot_x,0,0))
	carriage.position.x=pivot_x
	pivot_grip.rest_at(Vector3(pivot_x,1.02,.78));turn_grip.rest_at(to_local(turn_cap.global_position))
	reading.text="PIVOT %+.2f m     TURN %+.0f°" % [pivot_x,angle_degrees]

func configure(pivot: float, angle: float) -> void:
	pivot_x=clampf(pivot,-1.5,1.5);target_pivot=pivot_x
	angle_degrees=clampf(angle,-22,22);target_angle=angle_degrees
	if is_instance_valid(deck): apply_pose()

func prepare_editor_preview() -> void:
	preview=true

static func box(parent: Node3D, title: String, size: Vector3, at: Vector3, material: Material, solid:=false) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=title;mesh.position=at
	mesh.mesh=Timber.mesh(size) if material==Timber.material() else BoxMesh.new()
	if mesh.mesh is BoxMesh:mesh.mesh.size=size
	mesh.material_override=material;parent.add_child(mesh)
	if solid:
		var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=size
		body.position=at;body.add_child(shape);parent.add_child(body)
	return mesh

static func cylinder(parent: Node3D, title: String, radius: float, height: float, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=title;mesh.position=at;mesh.mesh=CylinderMesh.new()
	mesh.mesh.top_radius=radius;mesh.mesh.bottom_radius=radius;mesh.mesh.height=height;mesh.mesh.radial_segments=24
	mesh.material_override=material;parent.add_child(mesh);return mesh
