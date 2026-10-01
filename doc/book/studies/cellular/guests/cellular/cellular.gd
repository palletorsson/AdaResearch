extends Node3D

const BODY := Color("c6ff3d")   # the kit's BODY colour, written out: a guest names nothing outside its folder

@export_range(0, 255) var rule := 90   # the eight answers, written as one number
@export var ring := true               # the two ends of a row are neighbours; unticked, beyond an end is dead
@export var pace := 0.25               # seconds from one row to the next; 0 lays every row at once
@export var n := 17                    # cells in a row
@export var rows := 11                 # rows we keep
@export var cell := 0.4                # metres: a cell's width and depth
@export var rise := 0.15               # metres: a tile's thickness, and how much higher the next row stands

var now := PackedByteArray()    # the row we read: one byte for each cell, 0 or 1
var next := PackedByteArray()   # the row we write
var made := 0                   # rows laid so far
var clock := 0.0                # seconds since the last row
var tile := BoxMesh.new()       # one mesh for every cell

func _ready() -> void:
	tile.size = Vector3(cell * 0.9, rise, cell * 0.9)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	tile.material = paint
	now.resize(n)
	next.resize(n)
	@warning_ignore("integer_division")
	now[n / 2] = 1
	lay_row()
	while pace <= 0.0 and made < rows:
		step()
		lay_row()

func _process(delta: float) -> void:
	if pace <= 0.0 or made >= rows:
		return
	clock += delta
	if clock >= pace:
		clock -= pace
		step()
		lay_row()

func cell_at(i: int) -> int:
	if ring:
		return now[(i + n) % n]
	if i < 0 or i >= n:
		return 0
	return now[i]

func step() -> void:
	for i in n:
		var index := cell_at(i - 1) * 4 + now[i] * 2 + cell_at(i + 1)
		next[i] = (rule >> index) & 1
	var spare := now
	now = next
	next = spare

func lay_row() -> void:
	var row := StaticBody3D.new()
	row.position = Vector3(0.0, made * rise, -made * cell)
	add_child(row)
	var tiles := MultiMesh.new()
	tiles.transform_format = MultiMesh.TRANSFORM_3D
	tiles.mesh = tile
	tiles.instance_count = now.count(1)
	var drawn := MultiMeshInstance3D.new()
	drawn.multimesh = tiles
	row.add_child(drawn)
	var k := 0          # which tile comes next
	var start := -1     # where the run of live cells we are in began; -1: we are in none
	for i in n + 1:
		if i < n and now[i] == 1:
			tiles.set_instance_transform(k, Transform3D(Basis(), Vector3(x_of(i), rise / 2.0, 0.0)))
			k += 1
			if start < 0:
				start = i
		elif start >= 0:
			var box := BoxShape3D.new()
			box.size = Vector3((i - start) * cell, rise, cell)
			var collider := CollisionShape3D.new()
			collider.shape = box
			collider.position = Vector3((x_of(start) + x_of(i - 1)) / 2.0, rise / 2.0, 0.0)
			row.add_child(collider)
			start = -1
	print(made, " ", now)
	made += 1

func x_of(i: int) -> float:
	return (i - (n - 1) / 2.0) * cell
