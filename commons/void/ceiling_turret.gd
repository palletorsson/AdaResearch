extends StaticBody3D
## Floor-local sentry: warning chirp -> three separated pulses -> quiet cooldown.
const FX := preload("laser_fx.gd")
const Supply := preload("hardware_supply.gd")
enum State { SEARCH, WARNING, COOLDOWN, DESTROYED, BURST }
@export var detection_range := 7.0
@export var warning_seconds := 1.15
@export var cooldown_seconds := 2.5
@export var discharge := 10.0
var state := State.SEARCH
var integrity := 3
var shots := 0
var warning_left := 0.0
var cooldown_left := 0.0
var burst_left := 0
var pulse_wait := 0.0
var pulse_visible := 0.0
var sound_count := 0
var head: Node3D
var lens: MeshInstance3D
var targeting: MeshInstance3D
var world: Node3D
var muzzle := Vector3(0,4.86,0)
signal destroyed()
signal fired()

func _ready() -> void:
	add_to_group("void_ceiling_turret")
	collision_layer = 2; collision_mask = 0
	world = get_tree().get_first_node_in_group("void_game") as Node3D
	_build()
	Supply.connect_unit(self,Vector3(0.63,5.57,0))

func _build() -> void:
	var cream := FX.finish(Color("dedbc9"))
	var dark := FX.finish(Color("292d30"))
	var yellow := FX.finish(Color("d3ac4d"))
	FX.box(self,Vector3(0,5.57,0),Vector3(1.45,0.12,1.45),cream,"CeilingPlate")
	for i in range(7):
		FX.box(self,Vector3(-0.6+i*0.2,5.495,0),Vector3(0.09,0.012,1.28),yellow,"CautionStripe")
	for x in [-0.62,0.62]:
		for z in [-0.62,0.62]: FX.box(self,Vector3(x,5.48,z),Vector3.ONE*0.065,dark,"Anchor")
	var marking := Label3D.new()
	marking.name="WarningStencil"; marking.text="DANGER / LIVE"; marking.font_size=40
	marking.pixel_size=0.002; marking.outline_size=0; marking.modulate=Color("b93228")
	marking.position=Vector3(0,5.48,0.54); marking.rotation_degrees.x=90
	add_child(marking)
	FX.rod(self,Vector3(0,5.5,0),Vector3(0,5.12,0),0.17,dark)
	head = Node3D.new(); head.name = "Gimbal"; head.position.y = 5.12; add_child(head)
	FX.rod(head,Vector3(0,-0.22,0),Vector3(0,0.13,0),0.32,dark).name="OuterCasing"
	FX.rod(head,Vector3(0,-0.24,0),Vector3(0,-0.20,0),0.35,cream).name="CasingRing"
	FX.rod(head,Vector3(0,-0.2,0),Vector3(0,0.16,0),0.12,dark).name="InnerCore"
	lens = FX.box(head,Vector3(0,-0.26,0),Vector3(0.17,0.07,0.17),FX.finish(Color("fa493e"),true),"Optic")
	for x in [-0.22,0.22]: FX.box(head,Vector3(x,-0.24,0.12),Vector3(0.08,0.025,0.08),FX.finish(Color("6dced4"),true),"Status_"+str(x))
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new(); shape.radius = 0.40
	collision.shape = shape; collision.position.y = 5.10; add_child(collision)
	targeting = FX.rod(self, muzzle, muzzle+Vector3.DOWN,0.015,FX.finish(Color("f14e48"),true))
	targeting.name = "TargetingBeam"; targeting.visible = false

func _available() -> bool:
	if not is_instance_valid(world) or not world.ready_for_play or world.recovering or world.returning: return false
	if world.charge.suspended or world.charge.get_charge() <= 0: return false
	# Shaft previews must never attack a visitor above or below their own slab.
	var relative_y: float = world.body.global_position.y-global_position.y
	return relative_y >= -0.25 and relative_y < 4.3

func sight() -> Dictionary:
	if not _available(): return {}
	var target: Vector3 = world.camera.global_position-Vector3.UP*0.12
	var start := to_global(muzzle)
	if start.distance_to(target) > detection_range: return {}
	for cloud in get_tree().get_nodes_in_group("void_smoke_cloud"):
		if cloud.blocks_segment(start,target): return {}
	var ray := PhysicsRayQueryParameters3D.create(start,target,1 | 2)
	ray.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and hit.collider != world.body: return {}
	return {"target":target}

func _physics_process(delta: float) -> void:
	if state == State.DESTROYED: return
	pulse_visible=maxf(0,pulse_visible-delta)
	targeting.visible=pulse_visible>0
	var seen := sight()
	if state == State.COOLDOWN:
		cooldown_left -= delta
		if cooldown_left <= 0: state = State.SEARCH
		targeting.visible = false
		return
	if seen.is_empty():
		# Cover stops the next pulse; an interrupted burst still pays its cooldown.
		state = State.COOLDOWN if state==State.BURST else State.SEARCH
		cooldown_left=cooldown_seconds; warning_left=0; targeting.visible=false; pulse_visible=0
		return
	if state == State.SEARCH:
		state = State.WARNING; warning_left = warning_seconds
		FX.sound(self,to_global(muzzle),"warning")
	var end: Vector3 = to_local(seen.target)
	head.rotation.y = atan2(end.x,end.z)
	if state==State.WARNING:
		warning_left-=delta
		if warning_left>0: return
		state=State.BURST; burst_left=3; pulse_wait=0
	pulse_wait-=delta
	if state!=State.BURST or pulse_wait>0: return
	if burst_left==0:
		state=State.COOLDOWN; cooldown_left=cooldown_seconds; targeting.visible=false
		return
	# Ten charge per complete burst preserves the previous encounter balance.
	world.charge.discharge(discharge/3.0,"ceiling laser")
	shots+=1; burst_left-=1; pulse_wait=0.24; pulse_visible=0.065
	targeting.visible=true
	targeting.position=(muzzle+end)*0.5
	targeting.mesh.height=muzzle.distance_to(end)
	targeting.quaternion=Quaternion(Vector3.UP,(end-muzzle).normalized())
	FX.sound(self,to_global(muzzle),"shot"); sound_count+=1; fired.emit()

func hit_by_catalyst_mode(_colour: Color, _mode := "primitives") -> void:
	if state == State.DESTROYED: return
	integrity -= 1
	var host: Node3D = world if is_instance_valid(world) else get_parent()
	FX.sparks(host,to_global(muzzle),integrity <= 0)
	if integrity > 0: return
	FX.confetti(host,to_global(muzzle))
	FX.sound(host,to_global(muzzle),"break")
	state = State.DESTROYED
	targeting.visible = false
	collision_layer = 0
	lens.material_override = FX.finish(Color("17191a"))
	for child in head.get_children():
		if child is MeshInstance3D and str(child.name).begins_with("Status"):
			child.material_override = lens.material_override
	# Leave the bolted mounting plate and a visibly failed head, no live collision.
	head.rotation.z = 0.4
	head.get_node("OuterCasing").hide()
	head.get_node("CasingRing").hide()
	destroyed.emit()
	if is_instance_valid(world): world._notice("CEILING UNIT DISABLED / path clear")
