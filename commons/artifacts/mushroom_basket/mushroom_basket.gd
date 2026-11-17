extends Node3D
## A basket of mushrooms on a pillar, to be eaten. Each kind carries one of the camera study's pixel operations
## (commons/artifacts/camera_glitch_study): eaten, the operation is in the visitor's own eyes for ten seconds and
## fades over five more (mushroom_trip.gd) - the errors the camera's record was read with, now in the reading of the room itself.
## Six kinds, two of each. An eaten mushroom grows back in its place after REGROW seconds.

const Mushroom := preload("res://commons/artifacts/mushroom_basket/mushroom.gd")
const Trip := preload("res://commons/artifacts/mushroom_basket/mushroom_trip.gd")
const PILLAR_HEIGHT := 1.05
const REGROW := 20.0
const KINDS := 6

var spots: Array[Vector3] = []
var grown: Dictionary = {}


func _ready() -> void:
	name = "MushroomBasket"
	# the pillar
	var pillar := _box(Vector3(0, PILLAR_HEIGHT * 0.5, 0), Vector3(0.36, PILLAR_HEIGHT, 0.36), Color("d8d2c6"))
	_solid(pillar.position, Vector3(0.36, PILLAR_HEIGHT, 0.36))
	_box(Vector3(0, PILLAR_HEIGHT + 0.015, 0), Vector3(0.46, 0.03, 0.46), Color("bdb5a8"))
	_solid(Vector3(0, PILLAR_HEIGHT + 0.015, 0), Vector3(0.46, 0.03, 0.46))
	# the basket: a woven ring of slats round a floor
	var top := PILLAR_HEIGHT + 0.03
	var floor := CylinderMesh.new()
	floor.top_radius = 0.19
	floor.bottom_radius = 0.17
	floor.height = 0.02
	_mesh(floor, Vector3(0, top + 0.01, 0), Color("a0743f"))
	for i in 20:
		var a := TAU * float(i) / 20.0
		var slat := BoxMesh.new()
		slat.size = Vector3(0.05, 0.1, 0.012)
		var m := _mesh(slat, Vector3(cos(a) * 0.19, top + 0.055, sin(a) * 0.19), Color("b98a4e") if i % 2 == 0 else Color("8f6533"))
		m.rotation.y = -a + PI * 0.5
		m.rotation.x = 0.12
	for ring in 2:
		var band := TorusMesh.new()
		band.inner_radius = 0.185
		band.outer_radius = 0.205
		_mesh(band, Vector3(0, top + 0.035 + 0.05 * float(ring), 0), Color("7a5429"))
	var handle := TorusMesh.new()
	handle.inner_radius = 0.17
	handle.outer_radius = 0.19
	var h := _mesh(handle, Vector3(0, top + 0.1, 0), Color("8f6533"))
	h.rotation.x = PI * 0.5
	# the sign, on the pillar's face
	var sign := Label3D.new()
	sign.text = "EAT ONE\nthe camera's errors, in your own eyes\nhold it to your mouth (trigger / left click while held)"
	sign.font_size = 40
	sign.pixel_size = 0.0011
	sign.outline_size = 0
	sign.modulate = Color("3b3540")
	sign.position = Vector3(0, PILLAR_HEIGHT * 0.62, 0.182)
	add_child(sign)
	# twelve places in the basket, two rings
	for i in 12:
		var r := 0.07 if i < 4 else 0.135
		var count := 4 if i < 4 else 8
		var k := i if i < 4 else i - 4
		var a := TAU * float(k) / float(count) + (0.4 if i < 4 else 0.0)
		spots.append(Vector3(cos(a) * r, top + 0.02, sin(a) * r))
	for i in spots.size(): _grow(i, i % KINDS)


func _grow(spot: int, kind: int) -> void:
	var m := Mushroom.new()
	m.kind = kind
	m.basket = self
	m.spot = spot
	m.position = spots[spot]
	m.rotation.y = float(spot) * 1.7
	add_child(m)
	grown[spot] = m


## A mushroom from this place was eaten: another of the same kind grows there.
func regrow(spot: int, kind: int) -> void:
	grown.erase(spot)
	await get_tree().create_timer(REGROW).timeout
	if is_inside_tree() and not grown.has(spot): _grow(spot, kind)


func _process(_delta: float) -> void:
	# one taken and set down somewhere else stays where it was put; its place in the basket grows another
	for spot in grown.keys():
		var m: Variant = grown[spot]
		if not is_instance_valid(m):
			grown.erase(spot)
			continue
		if (m as Node3D).position.distance_to(spots[spot]) > 0.5 and not (m as XRToolsPickable).is_picked_up():
			grown.erase(spot)
			regrow(spot, (m as Node).get("kind"))


func _box(at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, at, colour)


func _mesh(mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	var surface := StandardMaterial3D.new()
	surface.albedo_color = colour
	surface.roughness = 0.75
	part.material_override = surface
	add_child(part)
	return part


func _solid(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func apply_grid_config(_config: Dictionary) -> void:
	pass
