extends Node3D
## The guest of Bodies that learn: the kit's floor at about a fifth of its size,
## as a slab a body can stand on. It reads the samples in its own folder, lets
## the k nearest vote for every cell, and says what it was trained on and how
## often it is wrong. A walker who stands on it is told which label it stands on.
## A guest names nothing outside its folder, so the kit's colours are written out.

const FILE := "res://guests/learning-body/samples.json"
const GROUND := Color("32188a")
const BODY := Color("c6ff3d")
const SECOND := Color("22d9ff")
const INK := Color("ffffff")
const SHADE := Color("0d0620")
const PAINT := {"stay": BODY, "pass": SECOND}
const CELL := 0.25                 # metres: one cell of the kit's floor
const CELLS := Vector2i(32, 20)    # the kit's floor: 8 m by 5 m
const SHRINK := 0.19               # 8 m by 5 m become 1.52 m by 0.95 m
const HEIGHT := 0.1                # metres: the slab is low enough to step onto

@export var trained_on := "the builder"   # whose labels of the file it learns from
@export_range(1, 9, 2) var k := 3         # how many neighbours vote

var consent := {}        # labeller -> whether the file records their consent
var chosen: Array = []   # the samples it is trained on
var about := ""          # what it says of itself
var readout: Label3D
var area: Area3D

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	consent = data.consent
	var labellers := {}
	for sample: Dictionary in data.samples:
		if sample.labelled_by.begins_with(trained_on):
			chosen.append(sample)
			labellers[sample.labelled_by] = consent.get(sample.labelled_by, false)
	var size := Vector2(CELLS) * CELL * SHRINK
	_slab(size)
	_field(size)
	for sample: Dictionary in chosen:
		var ball := MeshInstance3D.new()
		ball.mesh = SphereMesh.new()
		ball.scale = Vector3.ONE * 0.035
		ball.position = Vector3(sample.x * SHRINK, HEIGHT + 0.0175, sample.z * SHRINK)
		ball.material_override = _paint(PAINT[sample.label])
		add_child(ball)
	var recorded := labellers.size() > 0 and not labellers.values().has(false)
	about = "%d labels by %s\nconsent %s\nwrong about %d of its own\nand %d when each is left out" % [chosen.size(), trained_on, "recorded" if recorded else "not recorded", wrong(), left_out_wrong()]
	readout = Label3D.new()
	readout.text = about
	readout.pixel_size = 0.004
	readout.font_size = 24
	readout.modulate = INK
	readout.outline_modulate = SHADE
	readout.outline_size = 8
	readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	readout.position = Vector3(0, 2.3, 0)
	add_child(readout)
	print(about.replace("\n", "; "))

## The k nearest samples vote. Returns the winning label and its share of the votes.
func says(x: float, z: float, without := -1) -> Array:
	var near: Array = []
	for i in chosen.size():
		if i != without:
			near.append([Vector2(chosen[i].x - x, chosen[i].z - z).length(), chosen[i].label])
	near.sort()
	var voters := mini(k, near.size())
	var votes := {}
	for i in voters:
		votes[near[i][1]] = votes.get(near[i][1], 0) + 1
	var winner := ""
	for label: String in votes:
		if winner == "" or votes[label] > votes[winner]:
			winner = label
	return [winner, votes.get(winner, 0) / float(maxi(1, voters))]

## The first test: how many of its own samples does it answer against their label?
func wrong() -> int:
	var count := 0
	for sample: Dictionary in chosen:
		if says(sample.x, sample.z)[0] != sample.label:
			count += 1
	return count

## The second test: each sample asked of a field that never saw it.
func left_out_wrong() -> int:
	var count := 0
	for i in chosen.size():
		if says(chosen[i].x, chosen[i].z, i)[0] != chosen[i].label:
			count += 1
	return count

func _process(_delta: float) -> void:
	var text := about
	for body: Node3D in area.get_overlapping_bodies():
		if body is CharacterBody3D:
			var at := to_local(body.global_position) / SHRINK
			var said := says(at.x, at.z)
			text = "you stand on %s, sure to %d%%\n%s" % [said[0], roundi(said[1] * 100), about]
	readout.text = text

## What a body meets: a slab with a collider, and a region above it that knows who stands there.
func _slab(size: Vector2) -> void:
	var slab := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, HEIGHT, size.y)
	slab.mesh = box
	slab.position.y = HEIGHT / 2.0
	slab.material_override = _paint(GROUND)
	add_child(slab)
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collider.shape = shape
	body.add_child(collider)
	slab.add_child(body)
	area = Area3D.new()
	var region := CollisionShape3D.new()
	var above := BoxShape3D.new()
	above.size = Vector3(size.x, 2.0, size.y)
	region.shape = above
	region.position.y = HEIGHT + 1.0
	area.add_child(region)
	add_child(area)

## What the eye gets: one pixel of an image for each cell, laid on top of the slab.
func _field(size: Vector2) -> void:
	var image := Image.create(CELLS.x, CELLS.y, false, Image.FORMAT_RGB8)
	for cz in CELLS.y:
		for cx in CELLS.x:
			var said := says((cx + 0.5) * CELL - 4.0, (cz + 0.5) * CELL - 2.5)
			image.set_pixel(cx, cz, GROUND if said[0] == "" else GROUND.lerp(PAINT[said[0]], said[1] * 0.75))
	var top := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	top.mesh = plane
	top.position.y = HEIGHT + 0.002
	var material := _paint(Color.WHITE)
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	top.material_override = material
	add_child(top)

func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
