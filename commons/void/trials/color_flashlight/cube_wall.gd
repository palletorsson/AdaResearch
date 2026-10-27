extends Node3D
## Sixteen identical open-front cells compare the museum's five-light score.
const StudyControl = preload("res://commons/artifacts/spine_studies/station.gd").StudyButton
const Cell = preload("sphere_cell.gd")
# Single sources first, then pairs, then the complete five-source setup.
const PRESETS := [1,2,4,8,16,3,5,9,17,6,10,18,12,20,24,31]
const LIGHT_NAMES := ["TOP","LEFT","RIGHT","FRONT","BACK"]
const CELL_LAYERS := 0x1fffe
var cells: Array[Node3D] = []
var buttons: Array[StaticBody3D] = []
var captions: Array[Label3D] = []
var reset_button: StaticBody3D

func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = .26
	sphere.height = .52
	sphere.radial_segments = 32
	sphere.rings = 16
	for i in 16:
		var button := StudyControl.new()
		button.name = "Cell%02d" % i
		button.position = Vector3((i%4-1.5)*1.06, (3-i/4)*1.06+.55, 0)
		button.collision_layer = 1 | (1<<20) | (1<<22)
		button.action = cycle.bind(i)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.02,1.02,1.02)
		collision.shape = shape
		collision.position.y = .5
		button.add_child(collision)
		add_child(button)
		buttons.append(button)
		var cell := Cell.new()
		cell.name = "Study"
		cell.sphere_mesh = sphere
		cell.study_layer = 1 << (i+1)
		button.add_child(cell)
		cells.append(cell)
		var caption := label("",Vector3(0,.07,.53),.00125,22)
		button.add_child(caption)
		captions.append(caption)
	reset_button = StudyControl.new()
	reset_button.name = "Reset"
	reset_button.position = Vector3(0,.28,.59)
	reset_button.collision_layer = (1<<20) | (1<<22)
	reset_button.action = reset
	var reset_shape := BoxShape3D.new()
	reset_shape.size = Vector3(1.1,.23,.1)
	var reset_collision := CollisionShape3D.new()
	reset_collision.shape = reset_shape
	reset_button.add_child(reset_collision)
	var reset_mesh := MeshInstance3D.new()
	var reset_box := BoxMesh.new()
	reset_box.size = reset_shape.size
	reset_mesh.mesh = reset_box
	var reset_material := StandardMaterial3D.new()
	reset_material.albedo_color = Color(.12,.12,.14)
	reset_mesh.material_override = reset_material
	reset_button.add_child(reset_mesh)
	reset_button.add_child(label("RESET COMPARISON",Vector3(0,0,.06),.0014,26))
	add_child(reset_button)
	add_child(label("ONE SPHERE / FIVE LIGHT POSITIONS / SIXTEEN COMBINATIONS",
		Vector3(0,4.95,.15),.0018,28))
	add_child(label("Red light. Pale spheres. Point and click a cell to change its lights.",
		Vector3(0,4.75,.15),.0016,25))
	set_meta("em_visibility_bounds",AABB(Vector3(-2.15,0,-.55),Vector3(4.3,5.1,1.25)))
	reset()

func label(text: String, at: Vector3, pixel: float, font: int) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.position = at
	node.pixel_size = pixel
	node.font_size = font
	node.outline_size = 2
	return node

func cycle(index: int) -> void:
	# The same 5-bit mask as the full-size museum specimen: all 32 states.
	cells[index].set_lights((cells[index].mask+1)%32)
	update_caption(index)

func reset() -> void:
	for i in cells.size():
		cells[i].set_lights(PRESETS[i])
		update_caption(i)

func update_caption(index: int) -> void:
	var active := PackedStringArray()
	for bit in 5:
		if cells[index].mask & (1<<bit): active.append(LIGHT_NAMES[bit])
	captions[index].text = "%02d / %s" % [index+1,
		" + ".join(active) if not active.is_empty() else "NO LIGHT"]
