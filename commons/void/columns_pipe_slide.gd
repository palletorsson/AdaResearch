extends "res://commons/void/ignorance_descent_pipe.gd"
## Columns -> Profiles: the circular section becomes a traversable swept space.
## Guided slide velocity uses the normal collision solver, never a camera tween.
const Adapter := preload("res://commons/void/pipe_slide_provider.gd")
const MAX_SPEED := 3.0
var lengths := PackedFloat32Array()
var riders: Dictionary = {}

func _ready() -> void:
	super._ready()
	lengths.append(0.0)
	for i in range(1, deck_path.size()):
		lengths.append(lengths[-1] + deck_path[i].distance_to(deck_path[i-1]))
	# Light strips read the curve without adding five dynamic lights per pipe.
	for child in get_children():
		if child is OmniLight3D: child.queue_free()
	for side in [-1.0, 1.0]:
		var line := PackedVector3Array()
		for i in deck_path.size():
			var tangent := deck_path[mini(i+1, deck_path.size()-1)] - deck_path[maxi(0,i-1)]
			line.append(deck_path[i] + Vector3.UP*.06 + Vector3.UP.cross(tangent).normalized()*.59*side)
		var strip := MeshInstance3D.new()
		strip.mesh = Tube.build(line,.025,6).mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("fff1cf")
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		strip.material_override = material
		add_child(strip)
	var label := Label3D.new()
	label.text = "SLIDE\nPROFILES"
	label.position = deck_path[0]+Vector3(0,2.85,-.12)
	label.rotation.y = PI
	label.font_size = 42
	label.pixel_size = .004
	add_child(label)
	add_to_group("ada_museum_carry")
	add_to_group("ada_pipe_slide")
	get_tree().node_added.connect(_node_added)
	_install_adapter.call_deferred()

func _node_added(node: Node) -> void:
	if node is XRToolsPlayerBody: _install_adapter.call_deferred()

func _install_adapter() -> void:
	if not is_inside_tree(): return
	for body in get_tree().get_nodes_in_group("player_body"):
		if not body is XRToolsPlayerBody or body.has_node("PipeSlideAdapter"): continue
		var adapter := Adapter.new()
		adapter.name = "PipeSlideAdapter"
		adapter.receiver = body
		body.add_child(adapter)
		if adapter not in body._movement_providers: body._movement_providers.append(adapter)
		body._movement_providers.sort_custom(body.sort_by_order)

func nearest(local_point: Vector3) -> Dictionary:
	var best := INF
	var result := {"point": Vector3.ZERO, "distance": INF, "along": 0.0}
	for i in deck_path.size()-1:
		var edge := deck_path[i+1]-deck_path[i]
		var t := clampf((local_point-deck_path[i]).dot(edge)/edge.length_squared(),0,1)
		var point := deck_path[i]+edge*t
		var distance := local_point.distance_squared_to(point)
		if distance < best:
			best = distance
			result = {"point":point,"distance":sqrt(distance),"along":lerpf(lengths[i],lengths[i+1],t)}
	return result

func point_at(along: float) -> Vector3:
	for i in lengths.size()-1:
		if along <= lengths[i+1]:
			return deck_path[i].lerp(deck_path[i+1],clampf((along-lengths[i])/(lengths[i+1]-lengths[i]),0,1))
	return deck_path[-1]

func _point_inside(world_point: Vector3) -> bool:
	if not can_process() or lengths.is_empty(): return false
	var p := to_local(world_point)
	var n := nearest(p)
	# The last metre is a normal walking landing; entering it cannot restart a ride.
	return n.along > .45 and n.along < lengths[-1]-1.0 and n.distance < .78 and p.y-n.point.y < .45

func carry_velocity(body: CharacterBody3D, delta: float, incoming: Vector3) -> Vector3:
	if not body.enabled or not _point_inside(body.global_position): return incoming
	var n := nearest(to_local(body.global_position))
	var remaining: float = lengths[-1]-n.along
	var desired := lerpf(.8,MAX_SPEED,clampf((remaining-1.0)/3.0,0,1))
	var speed := move_toward(float(riders.get(body.get_instance_id(),.8)),desired,1.2*delta)
	riders[body.get_instance_id()] = speed
	var target := to_global(point_at(n.along+.5)+Vector3.UP*.025)
	return (target-body.global_position).normalized()*speed

func record_carry(_body: CharacterBody3D) -> void:
	pass

func release_carry(body: CharacterBody3D) -> void:
	riders.erase(body.get_instance_id())
