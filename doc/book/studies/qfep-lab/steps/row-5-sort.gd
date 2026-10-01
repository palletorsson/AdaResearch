extends Node3D

const Look := preload("res://supplied/look.gd")

const ALPHABET := 10   # the symbols are the whole numbers 0 to 9
const PITCH := 0.02    # metres from one bar's middle to the next

@export var seed_value := 40   # the row's name: the same number returns the same draws
@export var count := 200       # how many symbols are drawn

var values := PackedInt32Array()      # the symbols, in the order they were drawn
var bars := MultiMesh.new()
var readout: Label3D

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		values.append(rng.randi_range(0, ALPHABET - 1))
	build()
	for i in count:
		stand(i, i)
	readout.text = "H = %.3f bits" % entropy(values)
	var sorted := values.duplicate()
	sorted.sort()
	print("sorted: ", sorted.slice(0, 12), " ... ", sorted.slice(194), "; H = %.3f bits" % entropy(sorted))

## How many times each symbol occurs.
func tally(symbols: PackedInt32Array) -> Dictionary:
	var counts := {}
	for s in symbols:
		counts[s] = counts.get(s, 0) + 1
	return counts

## The Shannon entropy of the symbols' shares, in bits for each symbol.
func entropy(symbols: PackedInt32Array) -> float:
	var counts := tally(symbols)
	var h := 0.0
	for s in ALPHABET:
		var c: int = counts.get(s, 0)
		var p := float(c) / symbols.size()
		h -= p * log(p) / log(2.0)
	return h

## Stands bar i at a place of the row; a place may lie between two whole numbers.
func stand(i: int, place: float) -> void:
	var height := 0.1 * (values[i] + 1)
	var x := (place - (count - 1) / 2.0) * PITCH
	bars.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1.0, height, 1.0)), Vector3(x, height / 2.0, 0.0)))

func build() -> void:
	var bar := BoxMesh.new()
	bar.size = Vector3(PITCH, 1.0, 0.3)
	var paint := Look.paint(Color.WHITE)
	paint.vertex_color_use_as_albedo = true   # each bar takes the colour of its instance
	paint.vertex_color_is_srgb = true
	bar.material = paint
	bars.transform_format = MultiMesh.TRANSFORM_3D
	bars.use_colors = true
	bars.mesh = bar
	bars.instance_count = count
	for i in count:
		bars.set_instance_color(i, Look.BODIES[values[i] % 4])
	var holder := MultiMeshInstance3D.new()
	holder.multimesh = bars
	add_child(holder)
	var wall := CollisionShape3D.new()   # for a body the row is one box, as long, high and deep as the row can be
	wall.shape = BoxShape3D.new()
	wall.shape.size = Vector3(count * PITCH, 1.0, 0.3)
	wall.position.y = 0.5
	var body := StaticBody3D.new()
	body.add_child(wall)
	add_child(body)
	readout = Look.label("")
	readout.position.y = 1.3
	add_child(readout)
