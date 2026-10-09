extends Node3D
## The existing pickup-cube lattice, made navigable using the Menger enclosure.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
var grid: Node3D
var enclosure: Node3D
var selected := Vector3i.ZERO
var values: Array = []
var marker: MeshInstance3D
var readout: Label

func _ready() -> void:
	enclosure = load("res://commons/movement/museum_flight_box.gd").new()
	enclosure.name = "ArrayFlightBox"
	enclosure.monochrome = true
	enclosure.instruction_title = "FLY INTO THE THIRD INDEX"
	add_child(enclosure)
	grid = load("res://algorithms/arrays/grid_3d_4x4x4.gd").new()
	grid.name = "AddressedVolume"
	grid.position = Vector3(-3.6,0.7,-3.6)
	grid.call("apply_grid_config", {"spacing":2.4,"label_size":30})
	add_child(grid)
	for y in 4:
		var layer: Array = []
		for z in 4: layer.append([1,1,1,1])
		values.append(layer)
	var p := Kit.panel(self,"THREE INDICES",Vector3(3.5,1.2,-6.9))
	p.add_button("X +").pressed.connect(func(): select_axis(0))
	p.add_button("Y +").pressed.connect(func(): select_axis(1))
	p.add_button("Z +").pressed.connect(func(): select_axis(2))
	readout = p.add_readout("")
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.95,0.95,0.95)
	marker = MeshInstance3D.new()
	marker.name = "SelectedAddress"
	marker.mesh = mesh
	var mat := Kit.material(Color(1,1,1,0.16))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = mat
	add_child(marker)
	_connect_cells.call_deferred()
	refresh()

func _connect_cells() -> void:
	# Let the original grid apply its deferred configuration before connecting.
	await get_tree().process_frame
	await get_tree().process_frame
	for cell in grid.get_children():
		if not str(cell.name).begins_with("Cube_"): continue
		var parts := str(cell.name).split("_")
		cell.tree_exiting.connect(_removed.bind(int(parts[1]),int(parts[2]),int(parts[3])))

func _removed(x: int, y: int, z: int) -> void:
	if not is_inside_tree(): return
	values[y][z][x] = 0
	refresh()

func select_axis(axis: int) -> void:
	selected[axis] = (selected[axis] + 1) % 4
	refresh()

func refresh() -> void:
	if readout == null: return
	readout.text = "[x,y,z] = [%d,%d,%d] | value %d" % [selected.x,selected.y,selected.z,values[selected.y][selected.z][selected.x]]
	marker.position = grid.position + Vector3(selected) * 2.4 + Vector3(0,0.35,0)
