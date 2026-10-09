@tool
extends Node3D
## Proximity reduces graded health; four healthy axial neighbours allow recovery.
## Support, appearance and participation have separately visible thresholds.
@export_category("Bridge Settings")
@export var length: int = 20
@export var width: int = 4
@export var cell_size: float = 1.0
@export var decay_speed: float = 0.1
@export var regrow_speed: float = 2.0
@export var decay_radius: float = 2.0
@export_category("Visuals")
@export var color_healthy: Color = Color(0.2,0.8,0.2)
@export var color_decayed: Color = Color(0.2,0.2,0.2)
@export var color_dead: Color = Color(0,0,0,0)
var grid: Dictionary = {}
var mesh_instances: Dictionary = {}
var colliders: Dictionary = {}
var materials: Dictionary = {}
var player_position: Vector3 = Vector3.ZERO
var time_accumulator: float = 0.0
var static_body: StaticBody3D
var synchronous_updates: bool = false
var reverse_scan: bool = false
var has_visitor: bool = false
var _study_requested: bool = false
var _built: bool = false
const DIRECTIONS := [Vector2i(0,1),Vector2i(0,-1),Vector2i(1,0),Vector2i(-1,0)]

func _ready() -> void:
	_study_requested = _study_requested or str(get_meta("config_study","")) == "proximity"
	if _study_requested: _study_dimensions()
	static_body = get_node_or_null("StaticBody3D")
	if static_body == null:
		static_body = StaticBody3D.new();static_body.name="StaticBody3D";add_child(static_body)
	_initialize_bridge();_built=true
	if _study_requested and not Engine.is_editor_hint(): _mount_study()

func _study_dimensions() -> void:
	length=16;width=5;cell_size=0.6
	decay_speed=0.08;regrow_speed=1.0;decay_radius=1.35
	synchronous_updates=true
	color_healthy=Color("8cd9be");color_dead=Color("a86c88")

func _mount_study() -> void:
	if not _built or has_node("ProximityStudy"):return
	set_process(false)
	var study:Node3D=load("res://algorithms/cellularautomata/living_architecture/proximity_study.gd").new()
	study.name="ProximityStudy";add_child(study)

func resolve_visitor() -> Node3D:
	# A real player camera identifies its own body, not an unrelated first group member.
	var camera:Camera3D=get_viewport().get_camera_3d()
	if camera is XRCamera3D:
		var body:Node3D=XRToolsPlayerBody.find_instance(camera)
		if is_instance_valid(body):return body
	var ancestor:Node=camera
	while is_instance_valid(ancestor):
		if ancestor is CharacterBody3D and (ancestor.is_in_group("player_body") or ancestor.is_in_group("em_walker") or ancestor.is_in_group("player")):
			return ancestor
		ancestor=ancestor.get_parent()
	for group in ["em_walker","player_body","player"]:
		for node in get_tree().get_nodes_in_group(group):
			if node is Node3D:return node
	return null

func _process(delta:float) -> void:
	if Engine.is_editor_hint():return
	var visitor:Node3D=resolve_visitor()
	has_visitor=is_instance_valid(visitor)
	if has_visitor:player_position=visitor.global_position
	time_accumulator+=delta
	if time_accumulator>=0.1:
		time_accumulator=0.0;_update_simulation(0.1)

func cell_position(coord:Vector2i) -> Vector3:
	if _study_requested:return Vector3((coord.x-(width-1)/2.0)*cell_size,-0.1,coord.y*cell_size)
	return Vector3(coord.x*cell_size-width*cell_size/2.0,0,coord.y*cell_size)

func _initialize_bridge() -> void:
	for child in static_body.get_children():static_body.remove_child(child);child.queue_free()
	for mesh in mesh_instances.values():remove_child(mesh);mesh.queue_free()
	grid.clear();mesh_instances.clear();colliders.clear();materials.clear()
	for z in range(length):
		for x in range(width):
			var coord:=Vector2i(x,z);grid[coord]=1.0
			var visual:=MeshInstance3D.new();var box:=BoxMesh.new()
			box.size=Vector3(cell_size*0.95,0.2,cell_size*0.95);visual.mesh=box
			visual.position=cell_position(coord);add_child(visual);mesh_instances[coord]=visual
			var material:=StandardMaterial3D.new();visual.material_override=material;materials[coord]=material
			var col:=CollisionShape3D.new();var shape:=BoxShape3D.new()
			shape.size=Vector3(cell_size,0.2,cell_size);col.shape=shape
			col.position=visual.position;static_body.add_child(col);colliders[coord]=col
	_update_visuals()

func healthy_neighbors(coord:Vector2i, states:Dictionary) -> int:
	var count:int=0
	for direction in DIRECTIONS:
		var other:Vector2i=coord+direction
		if states.has(other) and float(states[other])>0.5:count+=1
	return count

func _count_healthy_neighbors(coord:Vector2i) -> int:
	return healthy_neighbors(coord,grid)

func calculate_next(previous:Dictionary, dt:float, local_visitor:Vector3, present:bool, snapshot_reads:bool, backwards:bool=false) -> Dictionary:
	var next:Dictionary=previous.duplicate()
	var read_states:Dictionary=previous if snapshot_reads else next
	var order:Array=previous.keys()
	if backwards:order.reverse()
	for coord:Vector2i in order:
		var health:float=previous[coord]
		if present and cell_position(coord).distance_to(local_visitor)<decay_radius:
			next[coord]=maxf(0.0,health-decay_speed*dt*5.0)
		else:
			var neighbours:int=healthy_neighbors(coord,read_states)
			next[coord]=minf(1.0,health+regrow_speed*dt*0.1*neighbours)
	return next

func _update_simulation(dt:float) -> void:
	grid=calculate_next(grid,dt,to_local(player_position),has_visitor,synchronous_updates,reverse_scan)
	_update_visuals()

func _update_visuals() -> void:
	for coord:Vector2i in grid:
		var health:float=grid[coord]
		var material:StandardMaterial3D=materials[coord]
		material.albedo_color=color_dead.lerp(color_healthy,health)
		if _study_requested:
			material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA if health<0.2 else BaseMaterial3D.TRANSPARENCY_DISABLED
			material.albedo_color.a=0.18+health if health<0.2 else 1.0
		else:
			material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA if health<0.1 else BaseMaterial3D.TRANSPARENCY_DISABLED
			if health<0.1:material.albedo_color.a=health*10.0
		colliders[coord].set_deferred("disabled",health<0.2)

func apply_grid_config(config:Dictionary) -> void:
	if str(config.get("study",""))=="proximity" and not _study_requested:
		_study_requested=true
		if _built:
			_study_dimensions();_initialize_bridge();_mount_study()
