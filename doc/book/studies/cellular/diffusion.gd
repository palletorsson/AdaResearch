extends Node3D

const Look := preload("res://supplied/look.gd")

@export var feed := 0.055   # how fast A is fed in, everywhere
@export var kill := 0.062   # how fast B is taken out
@export var pace := 4       # steps in one frame; 0 and nothing moves until step() is called

var g := 24             # cells along one side
var cell := 0.125       # metres: a cell's width and depth
var high := 0.6         # metres: how high a cell full of B would stand
var a := PackedFloat32Array()        # substance A, the buffer we read
var b := PackedFloat32Array()        # substance B, the buffer we read
var a_next := PackedFloat32Array()   # the two we write
var b_next := PackedFloat32Array()
var steps := 0
var tiles := MultiMesh.new()
var ground := HeightMapShape3D.new()

func _ready() -> void:
	for buffer: PackedFloat32Array in [a, b, a_next, b_next]:
		buffer.resize(g * g)
	a.fill(1.0)
	for z in range(10, 14):
		for x in range(10, 14):
			b[z * g + x] = 1.0
	var box := BoxMesh.new()
	box.size = Vector3(cell, 1.0, cell)
	box.material = Look.paint(Look.THIRD)
	tiles.transform_format = MultiMesh.TRANSFORM_3D
	tiles.mesh = box
	tiles.instance_count = g * g
	var drawn := MultiMeshInstance3D.new()
	drawn.multimesh = tiles
	add_child(drawn)
	ground.map_width = g
	ground.map_depth = g
	var collider := CollisionShape3D.new()
	collider.shape = ground
	collider.scale = Vector3(cell, cell, cell)
	var body := StaticBody3D.new()
	body.add_child(collider)
	add_child(body)
	show_b()

func _process(_delta: float) -> void:
	for i in pace:
		step()
	if pace > 0:
		show_b()

func around(buffer: PackedFloat32Array, x: int, z: int) -> float:
	var left := buffer[z * g + (x - 1 + g) % g]
	var right := buffer[z * g + (x + 1) % g]
	var back := buffer[(z - 1 + g) % g * g + x]
	var front := buffer[(z + 1) % g * g + x]
	return (left + right + back + front) / 4.0

func step() -> void:
	for z in g:
		for x in g:
			var i := z * g + x
			var eaten := a[i] * b[i] * b[i]
			a_next[i] = a[i] + 0.32 * (around(a, x, z) - a[i]) - eaten + feed * (1.0 - a[i])
			b_next[i] = b[i] + 0.16 * (around(b, x, z) - b[i]) + eaten - (feed + kill) * b[i]
	var spare := a
	a = a_next
	a_next = spare
	spare = b
	b = b_next
	b_next = spare
	steps += 1

func show_b() -> void:
	var heights := PackedFloat32Array()
	heights.resize(g * g)
	for z in g:
		for x in g:
			var i := z * g + x
			var h := b[i] * high
			var wide := 1.0
			if b[i] < 0.1:      # too little B to count: nothing stands here
				h = 0.0
				wide = 0.0
			heights[i] = h / cell
			var at := Vector3((x - (g - 1) / 2.0) * cell, h / 2.0, (z - (g - 1) / 2.0) * cell)
			tiles.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(wide, h, wide)), at))
	ground.map_data = heights
