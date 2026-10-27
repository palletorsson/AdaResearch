extends "res://algorithms/arrays/grid_model/grid_model.gd"
## Original miniature and grab/stack UI, bound only to this Void floor.
## The fixed slab, pillars and shafts cannot be edited. Added metre cubes can.
const Construction = preload("res://commons/void/construction_grid.gd")
var receiver: Node3D

class FloorGrid extends Node:
	signal cube_changed(pos: Vector3i, added: bool)
	var owner_model: Node3D
	var spec: Dictionary
	var base: Array = []
	var heights: Array = []
	var batch: Node3D
	var pending := false
	var data_component: Node:
		get: return self
	var structure_component: Node:
		get: return self
	func initialize(model: Node3D, floor_spec: Dictionary) -> void:
		owner_model=model;spec=floor_spec
		for z in int(spec.depth):
			var row: Array=[]
			for x in int(spec.width):
				var at:=Vector2(x-spec.width/2+.5,z-spec.depth/2+.5)
				var h:=1
				for shaft in spec.shafts:
					if absf(at.x-float(shaft.x))<spec.shaft_width/2+.5 and absf(at.y)<spec.shaft_depth/2: h=0
				for px in spec.column_x:
					for pz in spec.column_z:
						if absf(at.x-px)<spec.column_width/2+.5 and absf(at.y-pz)<spec.column_width/2+.5:h=6
				row.append(h)
			base.append(row)
		heights=base.duplicate(true)
	func is_data_loaded() -> bool: return true
	func get_structure_data() -> Array: return heights
	func enable_editing(_data: Array) -> void: pass
	func get_grid_dimensions() -> Vector3i: return Vector3i(spec.width,6,spec.depth)
	func get_height_at(x: int,z: int) -> int: return heights[z][x]
	func stack_add(x: int,z: int) -> bool:
		if base[z][x]!=1 or heights[z][x]>=5:return false
		heights[z][x]+=1
		cube_changed.emit(Vector3i(x,heights[z][x]-1,z),true);queue_rebuild();return true
	func stack_remove(x: int,z: int) -> bool:
		if heights[z][x]<=base[z][x]:return false
		heights[z][x]-=1
		cube_changed.emit(Vector3i(x,heights[z][x],z),false);queue_rebuild();return true
	func queue_rebuild() -> void:
		if pending:return
		pending=true;rebuild.call_deferred()
	func rebuild() -> void:
		pending=false
		if is_instance_valid(batch):batch.get_parent().remove_child(batch);batch.queue_free()
		batch=Construction.new();batch.name="MiniatureEdits"
		for z in heights.size():
			for x in heights[z].size():
				for y in range(base[z][x],heights[z][x]):
					batch.items.append({"id":"model_%d_%d_%d"%[x,y,z],"kind":"cube","position":[x-spec.width/2+.5,y-1,z-spec.depth/2+.5],"facing":0})
		owner_model.receiver.add_child(batch)

func _find_grid_system() -> void:
	var room: Node=preload("res://commons/artifacts/regularity/room_tools.gd").room_root(self)
	var building: Node3D=room.get_parent().building
	var index:=int(room.get_meta("void_content_floor"))
	receiver=Node3D.new();receiver.name="GridModelConstruction"
	room.add_child(receiver)
	var grid:=FloorGrid.new();grid.name="FloorLocalGrid";add_child(grid)
	grid.initialize(self,building.spec)
	_grid_system=grid;_data_component=grid;_structure_component=grid
	_initialize_model()

func freeze_held(cube: Node) -> void: cube.freeze=true

func _spawn_pickable_cube(x: int,z: int,y: int) -> GridModelCube:
	var cube:=super(x,z,y)
	cube.picked_up.connect(freeze_held)
	return cube

func _build_spawners() -> void:
	super()
	for cube in _spawner_cubes:cube.picked_up.connect(freeze_held)

func _spawn_replacement_spawner(x: int,z: int) -> void:
	super(x,z)
	_spawner_cubes.back().picked_up.connect(freeze_held)

func _on_mini_cube_dropped(fx: int,fz: int,tx: int,tz: int) -> void:
	# XRTools releases hand collision exceptions after 0.5 s. The original
	# model replaces the released rigid body; keep its RID alive until then.
	await get_tree().create_timer(.6).timeout
	if is_inside_tree():super(fx,fz,tx,tz)

func _on_spawner_dropped(fx: int,fz: int,tx: int,tz: int) -> void:
	await get_tree().create_timer(.6).timeout
	if is_inside_tree():super(fx,fz,tx,tz)

func _exit_tree() -> void:
	if is_instance_valid(receiver):receiver.queue_free()
