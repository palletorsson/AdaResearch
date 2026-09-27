extends Node3D
## A short record of the visitor's supported walk, laid on the same terrain mesh.
## Empty without a player. No generated motion and no additional control.
const INTERVAL := 0.08
const SPACING := 0.06
const MAX_POINTS := 384
const MAX_JOIN := 0.75
const HALF_WIDTH := 0.022
const LIFT := 0.035
var ground: Node3D
var points := PackedVector3Array()
var joins := PackedByteArray()
var surface: MeshInstance3D
var revision: int = 0
var _body_scale: float = 1.0
var _elapsed: float = 0.0
var _inside: bool = false
var _body_id: int = 0
var _break_next: bool = true

func build(owner_ground: Node3D) -> void:
	name = "WalkedTrail"
	ground = owner_ground
	surface = MeshInstance3D.new()
	surface.name = "RememberedWalk"
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.55)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)

func clear() -> void:
	points.clear()
	joins.clear()
	_inside = false
	_body_id = 0
	_break_next = true
	if surface != null: surface.mesh = null
	revision += 1

func _physics_process(delta: float) -> void:
	if ground == null: return
	_elapsed += delta
	if _elapsed < INTERVAL: return
	_elapsed = fmod(_elapsed, INTERVAL)
	var body := _visitor()
	if body == null:
		_inside = false
		_body_id = 0
		_break_next = true
		return
	if not _inside or _body_id != body.get_instance_id():
		clear()
		_inside = true
		_body_id = body.get_instance_id()
	_body_scale = float(body.get_meta("ada_body_scale",1.0))
	var p: Vector3 = ground.to_local(body.global_position)
	var height: float = ground.walk_height_at(Vector2(p.x,p.z))
	# The trace names supported movement; jumping leaves a break on landing.
	if not body.is_on_floor() or absf(p.y-height) > 0.45*_body_scale:
		_break_next = true
		return
	var horizontal := Vector2(p.x,p.z)
	var distance: float = INF if points.is_empty() else horizontal.distance_to(Vector2(points[-1].x,points[-1].z))
	if distance < SPACING*_body_scale: return
	points.append(Vector3(p.x,height,p.z))
	joins.append(0 if _break_next or distance > MAX_JOIN*_body_scale else 1)
	_break_next = false
	if points.size() > MAX_POINTS:
		points.remove_at(0)
		joins.remove_at(0)
		joins[0] = 0
	_redraw()

func _visitor() -> CharacterBody3D:
	var bodies: Array = get_tree().get_nodes_in_group("em_walker")
	bodies.append_array(get_tree().get_nodes_in_group("player_body"))
	for body in bodies:
		if not body is CharacterBody3D: continue
		var p: Vector3 = ground.to_local(body.global_position)
		if absf(p.x)<4.0 and absf(p.z)<4.0 and p.y>-.2 and p.y<5.0:
			return body
	return null

func _on_ground(p: Vector2) -> Vector3:
	p = p.clamp(Vector2.ONE*-4.0,Vector2.ONE*4.0)
	return Vector3(p.x,ground.walk_height_at(p)+LIFT*_body_scale,p.y)

func _redraw() -> void:
	var vertices := PackedVector3Array()
	for i in range(1,points.size()):
		if joins[i] == 0: continue
		var a := Vector2(points[i-1].x,points[i-1].z)
		var b := Vector2(points[i].x,points[i].z)
		var direction := (b-a).normalized()
		var side := Vector2(-direction.y,direction.x)*HALF_WIDTH*_body_scale
		# Drape the drawing over the existing triangles between measured positions.
		# These extra ribbon vertices are rendering samples, not extra body readings.
		var pieces: int = maxi(1,ceili(a.distance_to(b)/(0.04*_body_scale)))
		for part in range(pieces):
			var start: Vector2 = a.lerp(b,float(part)/pieces)
			var end: Vector2 = a.lerp(b,float(part+1)/pieces)
			var p := _on_ground(start-side)
			var q := _on_ground(start+side)
			var r := _on_ground(end-side)
			var s := _on_ground(end+side)
			vertices.append_array(PackedVector3Array([p,q,r,q,s,r]))
	if vertices.is_empty():
		surface.mesh = null
	else:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		surface.mesh = mesh
	revision += 1
