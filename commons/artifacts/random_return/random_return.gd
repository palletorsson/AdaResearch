extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## One seeded destination per excursion. The return is authored, not random.
## Grabbing retains the sphere's path and opts the player into collision-aware carry.
const POINT = preload("res://commons/artifacts/random_return/ride_point.gd")
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const ARROW = preload("res://commons/artifacts/force_halls/vector_arrow.gd")
const ADAPTER = preload("res://commons/artifacts/force_field_zone/field_carry_provider.gd")
const RACK = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const CENTRE = Vector3(0, 1.15, 0)
const LEG_SECONDS = 3.5
const WAIT_SECONDS = 1.5
const CYCLE_SECONDS = LEG_SECONDS * 2.0 + WAIT_SECONDS
const MAX_RADIUS = 2.2
@export var route_seed: int = 42
@export var route_link: String = ""
var coordinator: Node
var source_name := "CHOSEN NUMBER"
var pending_seed: Dictionary = {}
var chosen_direction := 0.0
var chosen_distance := 0.0
var direction_arrow: Node3D
var direction_label: Label3D
var own_panel: Node3D
var rng := RandomNumberGenerator.new()
var point: Node3D
var rider: CharacterBody3D
var rider_offset := Vector3.ZERO
var destination := Vector3.ZERO
var clock := 0.0
var trip := 0
var spoke: Node3D
var destination_mark: MeshInstance3D
var state_label: Label3D
var enabled_motion := true
var _carry: Dictionary = {}

func _ready() -> void:
	set_meta("em_keep_scale", true)
	set_meta("em_visibility_bounds", AABB(Vector3(-3.5,0,-3.5),Vector3(7,3.4,7)))
	add_to_group("ada_museum_carry")
	if not route_link.is_empty(): add_to_group("ada_seed_journeys")
	var dark := material("263443")
	var amber := material("f0b764",true)
	var cyan := material("5ce2d9",true)
	_ring(2.3,0.026,Vector3(0,0.045,0),dark)
	_ring(0.3,0.018,Vector3(0,0.05,0),amber)
	destination_mark = _ring(0.22,0.018,Vector3.ZERO,cyan)
	for i in range(24):
		var angle := TAU * i / 24.0
		box(Vector3(cos(angle)*2.3,0.025,sin(angle)*2.3),Vector3(0.035,0.018,0.035),amber)
	point = POINT.new()
	point.name = "ReturnPoint"
	point.position = CENTRE
	add_child(point)
	_ring(0.205,0.008,Vector3.ZERO,cyan,point)
	spoke = ARROW.new()
	add_child(spoke)
	spoke.build(amber,0.009,false)
	direction_arrow = ARROW.new()
	add_child(direction_arrow)
	direction_arrow.build(cyan,0.022,true)
	# The excursion remains in the room without an explanatory billboard.
	# Standalone instances retain their two functional controls.
	if route_link.is_empty():
		own_panel = RACK.create_panel("",[[{"type":"button","label":"REPLAY"},{"type":"button","label":"NEXT SEED"}]])
		own_panel.position = Vector3(-2.65,1.1,-1.9)
		own_panel.rotation.y = PI
		add_child(own_panel)
		own_panel.find_child("Btn_0",true,false).pressed.connect(act.bind("REPLAY"))
		own_panel.find_child("Btn_1",true,false).pressed.connect(act.bind("NEXT SEED"))
		box(Vector3(-2.65,0.48,-1.9),Vector3(0.23,0.96,0.23),dark,true)
	else:
		for tick in [[Vector3(2.65,0.06,0),"0° / +X"],[Vector3(0,0.06,2.2),"90° / +Z"],[Vector3(-2.65,0.06,0),"180°"],[Vector3(0,0.06,-2.2),"270°"]]:
			var mark := label(tick[1],tick[0],0.0012)
			mark.rotation_degrees.x = -90
	direction_label = label("",Vector3.ZERO,0.00125)
	direction_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	get_tree().node_added.connect(_on_node_added)
	install_adapter.call_deferred()
	restart(route_seed)
	HallSeed.bind(self)

func can_apply_hall_seed() -> bool:
	return not point.held()

func _apply_hall_seed(value: int, receipt: Dictionary) -> void:
	keep_seed(value,str(receipt.get("label", "HALL SEED")))

func _ring(radius: float, tube: float, at: Vector3, mat: Material, host: Node3D = self) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var shape := TorusMesh.new()
	shape.inner_radius = radius-tube
	shape.outer_radius = radius+tube
	shape.rings = 64
	shape.ring_segments = 8
	visual.mesh = shape
	visual.material_override = mat
	visual.position = at
	host.add_child(visual)
	return visual

func restart(seed_value: int) -> bool:
	if point.held():
		if readout != null: readout.text = "Release the sphere before replaying."
		return false
	route_seed = seed_value
	rng.seed = route_seed
	clock = 0.0
	trip = 0
	_choose_destination()
	_update_pose()
	return true

func apply_grid_config(config: Dictionary) -> void:
	if config.has("hall_seed"): set_meta("config_hall_seed",config.hall_seed)
	if config.has("route_link"): route_link = str(config.route_link)

## Never teleport a rider when another hand changes the shared seed.
## The latest kept seed becomes active after release.
func keep_seed(value: int, source: String) -> void:
	if point.held():
		pending_seed = {"value":value,"source":source}
		_update_pose()
		return
	pending_seed.clear()
	source_name = source
	restart(value)

func _choose_destination() -> void:
	var angle := rng.randf_range(0.0,TAU)
	var radius := rng.randf_range(1.1,MAX_RADIUS)
	chosen_direction = rad_to_deg(angle)
	chosen_distance = radius
	destination = Vector3(cos(angle)*radius,0,sin(angle)*radius)
	trip += 1

func route_position(at_time: float) -> Vector3:
	var t := fposmod(at_time,CYCLE_SECONDS)
	if t < WAIT_SECONDS: return CENTRE
	t -= WAIT_SECONDS
	var u := t / LEG_SECONDS if t <= LEG_SECONDS else 2.0-t/LEG_SECONDS
	var eased := 0.5-0.5*cos(PI*clampf(u,0,1))
	return CENTRE + destination*eased

func advance(delta: float) -> void:
	clock += maxf(delta,0)
	while clock >= CYCLE_SECONDS:
		clock -= CYCLE_SECONDS
		_choose_destination()
	_update_pose()

func _physics_process(delta: float) -> void:
	if enabled_motion: advance(delta)
	if point.held():
		var body: CharacterBody3D = point.receiver()
		if is_instance_valid(body) and body != rider:
			rider = body
			rider_offset = body.global_position - point.global_position
		if is_instance_valid(rider) and rider.global_position.distance_to(point.global_position) > 3.0:
			point.release_rider()
	elif is_instance_valid(rider):
		# Letting go ends the ride immediately. Gravity remains the body's own.
		rider.velocity.x = 0
		rider.velocity.z = 0
		rider = null
		_carry.clear()
	if not point.held() and not pending_seed.is_empty():
		var next := pending_seed.duplicate()
		keep_seed(int(next.value),str(next.source))

func _update_pose() -> void:
	point.position = route_position(clock)
	point.freeze = true
	PhysicsServer3D.body_set_state(point.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,point.global_transform)
	point.force_update_transform()
	destination_mark.position = destination + Vector3.UP*0.05
	spoke.set_ends(CENTRE,point.position)
	direction_arrow.set_ends(Vector3(0,0.065,0),destination+Vector3.UP*0.065)
	direction_label.position = destination+Vector3.UP*0.42
	direction_label.text = "%.0f°  /  %.2f m" % [chosen_direction,chosen_distance]

func act(id: String) -> void:
	if HallSeed.enabled(self):
		if id == "REPLAY": HallSeed.choose(self,HallSeed.current(self),HallSeed.state(self).receipt)
		elif id == "NEXT SEED": HallSeed.next(self)
		return
	if is_instance_valid(coordinator):
		if id == "REPLAY": coordinator.bench.replay()
		return
	if id == "REPLAY": restart(route_seed)
	elif id == "NEXT SEED": restart(route_seed+1)

func _point_inside(world: Vector3) -> bool:
	return is_instance_valid(rider) and point.held() and world.distance_to(rider.global_position)<0.2

func carry_velocity(body: CharacterBody3D,delta: float,incoming: Vector3) -> Vector3:
	if body != rider or not point.held(): return incoming
	var error := point.global_position+rider_offset-body.global_position
	var v := (error/maxf(delta,0.001)).limit_length(1.8)
	# This excursion is horizontal. Keep feet on the actual collision surface.
	v.y = minf(incoming.y,0.0) if body.is_on_floor() else maxf(incoming.y-9.8*delta,-8)
	return v

func record_carry(body: CharacterBody3D) -> void: _carry[body.get_instance_id()] = body.velocity
func release_carry(body: CharacterBody3D) -> void: _carry.erase(body.get_instance_id())

func _on_node_added(node: Node) -> void:
	if node is XRToolsPlayerBody: install_adapter.call_deferred()

func install_adapter() -> void:
	for body in get_tree().get_nodes_in_group("player_body"):
		if not body is XRToolsPlayerBody or body.get_node_or_null("FieldCarryAdapter") != null: continue
		var adapter = ADAPTER.new()
		adapter.name = "FieldCarryAdapter"
		adapter.receiver = body
		body.add_child(adapter)
		if adapter not in body._movement_providers: body._movement_providers.append(adapter)
		body._movement_providers.sort_custom(body.sort_by_order)
