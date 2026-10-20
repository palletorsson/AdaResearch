extends Node3D
## Procedural boned creature; an experiment inspired by Omoss, not his rig.
## Skeleton animation, not physics ragdoll. No imported mesh, rig, texture or clip.
const Creature = preload("res://algorithms/randomness/proceduralrandomness/geometrybased/omoss/pivot_creature.gd")
const Console = preload("res://algorithms/randomness/proceduralrandomness/geometrybased/omoss/pivot_console.gd")
const Handle = preload("res://algorithms/randomness/proceduralrandomness/geometrybased/omoss/pivot_handle.gd")
const BODY_ORIGIN := Vector3(0,2.35,-.45)
const HANDLE_ORIGIN := Vector3(0,1.18,1.00)
var creature: Node3D
var panel: Node3D
var handle: RigidBody3D
var centre_marker: MeshInstance3D
var tether: MeshInstance3D
var readout: Label3D
var pivot := Vector3.ZERO
var turn := 0.0
var body_scale := 1.0
var limbs := .38
var clock := 0.0
var running := true
var bones_visible := false
var syncing := false

func _ready() -> void:
	creature=Creature.new();creature.name="BonedCreature";add_child(creature)
	panel=Console.new();panel.position=Vector3(0,0,1.75);add_child(panel)
	panel.turn_dial.hinge_moved.connect(func(_v):control_changed())
	panel.scale_dial.hinge_moved.connect(func(_v):control_changed())
	panel.limb_dial.hinge_moved.connect(func(_v):control_changed())
	for id in panel.buttons:
		panel.buttons[id].pressed.connect(act.bind(id))
	# A bounded proxy makes the elevated pivot reachable from the same station.
	handle=Handle.new();handle.name="PivotGrabPoint";handle.freeze=true;handle.gravity_scale=0
	handle.release_mode=XRToolsPickable.ReleaseMode.FROZEN
	handle.collision_layer=(1<<2)|(1<<18);handle.collision_mask=0
	var shape:=CollisionShape3D.new();var sphere:=SphereShape3D.new();sphere.radius=.085;shape.shape=sphere;handle.add_child(shape)
	var orb:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=.075;mesh.height=.15;orb.mesh=mesh
	orb.material_override=panel.material(Color("d95d96"));handle.add_child(orb)
	add_child(handle);handle.position=HANDLE_ORIGIN
	centre_marker=MeshInstance3D.new();var point:=SphereMesh.new();point.radius=.045;point.height=.09
	centre_marker.mesh=point;centre_marker.material_override=panel.material(Color("d95d96"));add_child(centre_marker)
	tether=MeshInstance3D.new();var rod:=CylinderMesh.new();rod.height=1;rod.top_radius=.006;rod.bottom_radius=.006
	tether.mesh=rod;tether.material_override=panel.material(Color("d95d96"));add_child(tether)
	var stage:=CylinderMesh.new();stage.top_radius=1.87;stage.bottom_radius=1.87;stage.height=.045;stage.radial_segments=64
	var base:=MeshInstance3D.new();base.mesh=stage;base.position=Vector3(0,.025,-.45);base.material_override=panel.material(Color("242b2e"));add_child(base)
	var ring:=TorusMesh.new();ring.inner_radius=1.85;ring.outer_radius=1.865;ring.rings=64;ring.ring_segments=6
	var edge:=MeshInstance3D.new();edge.mesh=ring;edge.position=Vector3(0,.05,-.45);edge.material_override=panel.material(Color("d95d96"));add_child(edge)
	readout=panel.text(self,"",Vector3(0,.52,1.81),.0008,Color("eee8dc"))
	panel.text(self,"ENDLESS MUSEUM",Vector3(0,4.6,-.5),.0021,Color("20282d"))
	panel.text(self,"always another room",Vector3(0,4.36,-.5),.0008,Color("20282d"))
	sync_controls();update_body()

func control_changed() -> void:
	if syncing:return
	turn=lerpf(-PI,PI,panel.turn_dial.get_normalized_value())
	body_scale=lerpf(.55,1.3,panel.scale_dial.get_normalized_value())
	limbs=panel.limb_dial.get_normalized_value()
	update_body()

func act(id: String) -> void:
	match id:
		"RUN":running=not running
		"BONES":bones_visible=not bones_visible;creature.show_bones(bones_visible)
		"CENTRE":set_pivot(Vector3.ZERO)
		"RESET":
			clock=0;turn=0;body_scale=1;limbs=0;running=false;bones_visible=false
			creature.show_bones(false);set_pivot(Vector3.ZERO)
	sync_controls();update_body()

func sync_controls() -> void:
	syncing=true
	panel.turn_dial.set_normalized_value((turn+PI)/TAU)
	panel.scale_dial.set_normalized_value((body_scale-.55)/.75)
	panel.limb_dial.set_normalized_value(limbs)
	panel.buttons["RUN"].set_selected(running)
	panel.buttons["BONES"].set_selected(bones_visible)
	for id in panel.buttons:
		panel.buttons[id].get_node("Button/Legend").modulate=Console.PAPER if panel.buttons[id].is_selected() else Console.INK
	syncing=false

func set_pivot(value: Vector3) -> void:
	pivot=value.limit_length(.65)
	handle.position=HANDLE_ORIGIN+pivot*.7

func _process(delta: float) -> void:
	if running:clock+=minf(delta,.05)
	var value: Vector3=(handle.position-HANDLE_ORIGIN)/.7
	pivot=value.limit_length(.65)
	if not handle.is_picked_up():handle.position=HANDLE_ORIGIN+pivot*.7
	update_body()

func update_body() -> void:
	var angle:=turn+clock*.19
	var rotation_basis:=Basis(Vector3.UP,angle)
	var transform_basis:=rotation_basis.scaled_local(Vector3.ONE*body_scale)
	creature.transform=Transform3D(transform_basis,BODY_ORIGIN+pivot-transform_basis*pivot)
	creature.pose(clock,limbs,pivot)
	centre_marker.position=BODY_ORIGIN+pivot
	var delta:=centre_marker.position-handle.position
	tether.position=(centre_marker.position+handle.position)*.5
	tether.basis=Basis(Quaternion(Vector3.UP,delta.normalized())).scaled_local(Vector3(1,delta.length(),1))
	readout.text="PIVOT  %.2f / %.2f / %.2f m\nROTATE  %d deg   SCALE  %.2f   LIMBS  %d%%"%[pivot.x,pivot.y,pivot.z,roundi(rad_to_deg(angle)),body_scale,roundi(limbs*100)]

func apply_grid_config(_config: Dictionary) -> void:
	pass
