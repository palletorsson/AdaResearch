extends "res://commons/artifacts/array_floor_writer/array_floor_writer.gd"
## The museum writer keeps its operations, pause and occupied-cell restoration.
## This adapter supplies a bounded construction grid, above the fixed Void slab.
const Construction = preload("res://commons/void/construction_grid.gd")
var controls: Node3D
var pause_button: Node3D
var copy_button: Node3D
var consume_button: Node3D
var restore_button: Node3D

class CellGrid extends Node:
	var parent_node: Node3D
	var host: Node3D
	var cube_positions: Dictionary = {}
	var batch: Node3D
	var pending := false

	func get_grid_dimensions() -> Vector3i:
		return Vector3i(8, 3, 10)

	func has_cube_at(x: int, y: int, z: int) -> bool:
		return cube_positions.has(Vector3i(x,y,z))

	func add_cube_at(x: int, y: int, z: int) -> bool:
		var cell := Vector3i(x,y,z)
		if not host.editable(cell) or cube_positions.has(cell): return false
		cube_positions[cell] = true
		queue_rebuild()
		return true

	func remove_cube_at(x: int, y: int, z: int) -> bool:
		var cell := Vector3i(x,y,z)
		if not host.editable(cell) or not cube_positions.has(cell): return false
		cube_positions.erase(cell)
		queue_rebuild()
		return true

	func queue_rebuild() -> void:
		if pending: return
		pending = true
		rebuild.call_deferred()

	func rebuild() -> void:
		pending = false
		if is_instance_valid(batch):
			parent_node.remove_child(batch)
			batch.queue_free()
		batch = Construction.new()
		batch.name = "AddressedCubes"
		for cell: Vector3i in cube_positions:
			# Construction cells name the foot; this grid names the cube centre.
			batch.items.append({"id":"cell_%d_%d_%d" % [cell.x,cell.y,cell.z],
				"kind":"cube","position":[cell.x,cell.y-0.5,cell.z],"facing":0})
		parent_node.add_child(batch)

func bind_grid() -> void:
	var frame := Node3D.new()
	frame.name = "GridFrame"
	frame.position = Vector3(-3.5,0.5,-4.5)
	add_child(frame)
	var cells := CellGrid.new()
	cells.name = "GridStructureComponent"
	cells.parent_node = frame
	cells.host = self
	add_child(cells)
	grid = cells
	dimensions = grid.get_grid_dimensions()
	for x in dimensions.x:
		for z in dimensions.z:
			var cell := Vector3i(x,0,z)
			cells.cube_positions[cell] = true
			if editable(cell): original[cell] = true
	cells.rebuild()
	agent = FloorAgent.new()
	agent.host = self
	agent.position = frame.position + Vector3(3,1.15,4)
	add_child(agent)
	agent.grid_cell_position = Vector3i(3,1,4)
	running = false
	agent.set_physics_process(false)
	controls = Kit.panel(self,"AN ADDRESS BECOMES SUPPORT",Vector3(0,1.2,7.3),0)
	controls.name = "Controls"
	pause_button = controls.add_button("PAUSE / RESUME")
	copy_button = controls.add_button("COPY ONE")
	consume_button = controls.add_button("CONSUME ONE")
	restore_button = controls.add_button("RESTORE")
	pause_button.pressed.connect(toggle_running)
	copy_button.pressed.connect(step.bind(true))
	consume_button.pressed.connect(step.bind(false))
	restore_button.pressed.connect(restore_floor)
	readout = controls.add_readout("")
	last_change = "ONE METRE CUBES / ADDRESSED SUPPORT"
	Kit.label(self,"80 CUBES / ONE METRE EACH\nTHE MIDDLE CAN CHANGE. THE EDGE STAYS.",Vector3(0,2.5,-4.8))
	for x in range(2,6):
		for z in range(3,7):
			var label := Kit.label(self,"[%d, %d]" % [x,z],frame.position+Vector3(x,0.54,z))
			label.rotation_degrees.x = -90
			label.font_size = 24
			label.pixel_size = 0.003
	refresh()

func editable(cell: Vector3i) -> bool:
	return cell.x>=2 and cell.x<=5 and cell.z>=3 and cell.z<=6 and cell.y>=0 and cell.y<=2

func step(copy: bool) -> void:
	if restoring: return
	running = false
	agent.set_physics_process(false)
	write_cell(copy)
	refresh()

func prepare_editor_preview() -> void:
	if is_instance_valid(agent): agent.set_physics_process(false)
