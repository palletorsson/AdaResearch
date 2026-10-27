extends Node3D
## Familiar constructions return as things: skull, empty cube, pocket-sized portal.
## One reusable editor part. Rigid bodies use the museum's desktop/XR pickup contract.
const Skull = preload("res://commons/artifacts/primitive_encounters/skull.gd")
const CubeLines = preload("res://commons/primitives/line/cube_lines.tscn")
const Piece = preload("res://commons/artifacts/primitive_encounters/piece.gd")
const Geometry = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const LIMIT := 6
const INTERVAL := 7.0
var ring_mesh: TorusMesh
var templates: Array[Array] = []
var arrivals: Array[RigidBody3D] = []
var emitted := 0
var cooldown := 0.0
var ready_to_emit := false
var preview: Node3D
var light: OmniLight3D
var sources: Array[Node3D] = []
var bake_frames := 0

func _ready() -> void:
	set_meta("editor_label","Portal arrivals / skull, open cube, ring")
	light=OmniLight3D.new();light.name="ArrivalLight"
	light.position=Vector3(-.4,1.4,0);light.light_color=Color("ffc4e6")
	light.light_energy=1.4;light.omni_range=3.2;light.shadow_enabled=false;add_child(light)
	_prepare()

func _prepare() -> void:
	var skull: Node3D=Skull.new();skull.scale=Vector3.ONE*.29
	# The carved skull in Melencolia looks toward +Z. Here it faces the approach.
	skull.rotation.y=-PI/2;sources.append(skull)
	var cube: Node3D=CubeLines.instantiate();cube.edge_labels=false
	cube.tint_override=Color("ffd9e9");cube.scale=Vector3.ONE*.46;sources.append(cube)
	var ring:=MeshInstance3D.new()
	var mesh:=ring_mesh.duplicate() as TorusMesh if ring_mesh!=null else TorusMesh.new()
	mesh.inner_radius=.17;mesh.outer_radius=.26;mesh.rings=32;mesh.ring_segments=12
	ring.mesh=mesh;ring.rotation.z=PI/2;ring.material_override=Geometry.material(Color("d5badf"));sources.append(ring)
	for source in sources:
		add_child(source);source.hide()
	# Frame-driven preparation can be freed during streaming or an editor copy;
	# it never leaves a suspended coroutine holding temporary geometry.
	bake_frames=3

func _process(_delta: float) -> void:
	if bake_frames<=0:return
	bake_frames-=1
	if bake_frames>0:return
	# CSG is evaluated once. Released skulls share the baked mesh, not live CSG.
	for source in sources:
		var parts: Array=[]
		_collect(source,Transform3D.IDENTITY,parts)
		templates.append(parts);source.free()
	sources.clear()
	ready_to_emit=templates.all(func(parts): return not parts.is_empty())
	_show_preview()
	var host:=get_parent()
	if host.has_method("_mesh_bounds") and host.get("part_defaults") is Dictionary and host.part_defaults.has(str(name)):
		var bounds: AABB=host._mesh_bounds(self,self)
		host.part_defaults[str(name)].bounds=[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]

func _collect(node: Node3D, parent_pose: Transform3D, parts: Array) -> void:
	var pose:=parent_pose*node.transform
	if node is CSGShape3D and node.is_root_shape():
		var baked: Array=node.get_meshes()
		if baked.size()==2: parts.append({"mesh":baked[1],"pose":pose*baked[0],"material":null})
		return
	if node is MeshInstance3D and node.mesh!=null:
		parts.append({"mesh":node.mesh,"pose":pose,"material":node.material_override})
	for child in node.get_children():
		if child is Node3D: _collect(child,pose,parts)

func _visuals(parent: Node3D, kind: int, collision: bool) -> void:
	for part in templates[kind]:
		var surface:=MeshInstance3D.new();surface.mesh=part.mesh
		surface.transform=part.pose;surface.material_override=part.material;parent.add_child(surface)
		if collision:
			# Convex pieces: the open cube retains twelve separate edge colliders.
			var shape:=ConvexPolygonShape3D.new();var points:=PackedVector3Array()
			var mesh: Mesh=part.mesh
			for index in mesh.get_surface_count():
				for vertex: Vector3 in mesh.surface_get_arrays(index)[Mesh.ARRAY_VERTEX]: points.append(part.pose*vertex)
			shape.points=points
			var contact:=CollisionShape3D.new();contact.shape=shape;parent.add_child(contact)

func _show_preview() -> void:
	if is_instance_valid(preview): preview.free()
	preview=Node3D.new();preview.name="NextArrival";preview.position=Vector3(.12,1.45,0)
	add_child(preview)
	if ready_to_emit: _visuals(preview,emitted%3,false)

func _physics_process(delta: float) -> void:
	if not ready_to_emit:return
	_prune(delta)
	var player:=get_tree().get_first_node_in_group("player_body") as Node3D
	var near:=player!=null and player.global_position.distance_to(global_position)<6.0
	light.light_energy=lerpf(light.light_energy,1.8 if near else .65,minf(delta*2,1))
	if not near:return
	cooldown=maxf(0,cooldown-delta)
	if cooldown<=0 and arrivals.size()<LIMIT: release_next()

func release_next() -> RigidBody3D:
	if not ready_to_emit or arrivals.size()>=LIMIT:return null
	var body:=Piece.new();body.name="Arrival_%02d"%emitted
	body.floats=false;body.freeze=false;body.release_mode=Piece.ReleaseMode.UNFROZEN
	# The hand can pick it up; it does not obstruct or push the visitor off the deck.
	body.collision_layer=6;body.collision_mask=7;body.mass=.35
	body.set_meta("arrival_kind",["skull","open_cube","ring"][emitted%3]);body.set_meta("arrival_age",0.0)
	_visuals(body,emitted%3,true)
	body.position=Vector3(.12,1.45,0)
	add_child(body)
	# XR's body mask includes pickup props, unlike the desktop walker. An arrival
	# can spawn above that body and eject it from the walkway unless excluded.
	var tower := get_tree().get_first_node_in_group("void_game")
	if tower!=null and tower.body is PhysicsBody3D:
		body.add_collision_exception_with(tower.body)
	body.linear_velocity=global_basis*Vector3(-.65,.1,.12 if emitted%2==0 else -.12)
	body.angular_velocity=global_basis*Vector3(.15,.25,.12)
	arrivals.append(body);emitted+=1;cooldown=INTERVAL
	_show_preview()
	return body

func _prune(delta: float) -> void:
	for i in range(arrivals.size()-1,-1,-1):
		if not is_instance_valid(arrivals[i]):arrivals.remove_at(i);continue
		var body: RigidBody3D=arrivals[i]
		# Never reclaim a held object, even when the visitor carries it far away.
		if body.held():continue
		var age:=float(body.get_meta("arrival_age",0.0))+delta;body.set_meta("arrival_age",age)
		var relative:=to_local(body.global_position)
		if relative.y< -10 or (age>120 and relative.length()>12):
			arrivals.remove_at(i);body.queue_free()
