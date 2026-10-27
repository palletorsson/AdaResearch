extends "res://commons/artifacts/random_return/random_return.gd"
## Floor 71 uses a full-size, seeded excursion around the open shaft rim.
## Two RNG draws per excursion are retained. Only their spatial mapping changes.
const RimMount = preload("res://commons/void/ceiling_display_mount.gd")
const RIM_LEG := 10.0
const RIM_CYCLE := RIM_LEG*2.0+WAIT_SECONDS
const RIM_HALF_X := 3.4
const RIM_HALF_Z := 4.0
var shaft_route := false

func apply_grid_config(config: Dictionary) -> void:
	if config.has("shaft_route"): shaft_route=bool(config.shaft_route)
	super.apply_grid_config(config)

## The shared mouse grip is an XRTools grabber, not a tracked XR controller.
func _ready() -> void:
	shaft_route=bool(get_meta("config_shaft_route",shaft_route))
	super._ready()
	point.picked_up.connect(_connect_mouse_receiver)
	point.dropped.connect(func(_body): point.desktop_pointer = null)
	if shaft_route:
		# Retire only the original round floor furniture, keeping the live point,
		# destination marker, controls, RNG and collision-aware carry provider.
		for child in get_children():
			if (child is MeshInstance3D and child != destination_mark) or child is StaticBody3D:
				remove_child(child); child.queue_free()
		own_panel.position=Vector3(-1.7,1.10,4.35)
		own_panel.rotation=Vector3.ZERO
		spoke.hide();direction_arrow.hide()
		var rail:=RimMount.material("28343b",.82,.3)
		var ink:=RimMount.material("d9d3b8",.9)
		for x in [-RIM_HALF_X,RIM_HALF_X]:
			RimMount.box(self,"RimLine",Vector3(x,.025,0),Vector3(.045,.025,RIM_HALF_Z*2),ink)
			RimMount.box(self,"OverheadRail",Vector3(x,4.65,0),Vector3(.11,.13,RIM_HALF_Z*2+.1),rail)
			for z in [-RIM_HALF_Z,RIM_HALF_Z]:
				RimMount.box(self,"RoofTie",Vector3(x,5.145,z),Vector3(.09,.99,.09),rail)
				RimMount.box(self,"RoofPlate",Vector3(x,5.60,z),Vector3(.34,.08,.34),rail)
		for z in [-RIM_HALF_Z,RIM_HALF_Z]:
			RimMount.box(self,"RimLine",Vector3(0,.025,z),Vector3(RIM_HALF_X*2,.025,.045),ink)
			RimMount.box(self,"OverheadRail",Vector3(0,4.65,z),Vector3(RIM_HALF_X*2,.13,.11),rail)
		set_meta("em_visibility_bounds",AABB(Vector3(-3.6,0,-4.6),Vector3(7.2,5.64,9.2)))
		_update_pose()

func _choose_destination() -> void:
	super._choose_destination()
	if shaft_route:
		chosen_distance *= 5.0
		destination=_rim_point(chosen_distance)

func _rim_point(distance: float) -> Vector3:
	var direction := 1.0 if chosen_direction<180.0 else -1.0
	var vertices: Array[Vector3]=[Vector3(0,1.15,RIM_HALF_Z),Vector3(direction*RIM_HALF_X,1.15,RIM_HALF_Z),Vector3(direction*RIM_HALF_X,1.15,-RIM_HALF_Z),Vector3(-direction*RIM_HALF_X,1.15,-RIM_HALF_Z),Vector3(-direction*RIM_HALF_X,1.15,RIM_HALF_Z),Vector3(0,1.15,RIM_HALF_Z)]
	var remaining := maxf(0,distance)
	for i in range(vertices.size()-1):
		var length := vertices[i].distance_to(vertices[i+1])
		if remaining<=length: return vertices[i].lerp(vertices[i+1],remaining/length)
		remaining-=length
	return vertices[0]

func route_position(at_time: float) -> Vector3:
	if not shaft_route: return super.route_position(at_time)
	var t:=fposmod(at_time,RIM_CYCLE)
	if t<WAIT_SECONDS: return _rim_point(0)
	t-=WAIT_SECONDS
	var u:=t/RIM_LEG if t<=RIM_LEG else 2.0-t/RIM_LEG
	return _rim_point(chosen_distance*(.5-.5*cos(PI*clampf(u,0,1))))

func advance(delta: float) -> void:
	if not shaft_route: super.advance(delta);return
	clock+=maxf(delta,0)
	while clock>=RIM_CYCLE:
		clock-=RIM_CYCLE;_choose_destination()
	_update_pose()

func _update_pose() -> void:
	if not shaft_route: super._update_pose();return
	point.position=route_position(clock)
	point.freeze=true
	point.force_update_transform()
	PhysicsServer3D.body_set_state(point.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,point.global_transform)
	destination_mark.position=Vector3(destination.x,.05,destination.z)
	direction_label.position=Vector3(destination.x,.45,destination.z)
	direction_label.text="%s / %.2f m / RETURN" % ["CW" if chosen_direction<180 else "CCW",chosen_distance]

func _connect_mouse_receiver(_body: Node3D) -> void:
	if point.get_picked_up_by_controller() == null:
		point.desktop_pointer = point.get_picked_up_by()

func prepare_editor_preview() -> void:
	# The editor exports the same geometry at its reachable boarding position.
	enabled_motion=false
	restart(route_seed)
