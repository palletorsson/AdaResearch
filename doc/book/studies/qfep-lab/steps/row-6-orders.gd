extends Node3D

const Look := preload("res://supplied/look.gd")

const NAMES := ["as drawn", "sorted by value", "sorted by colour", "sorted in reverse"]
const ALPHABET := 10   # the symbols are the whole numbers 0 to 9
const PITCH := 0.02    # metres from one bar's middle to the next

@export_enum("as drawn", "sorted by value", "sorted by colour", "sorted in reverse") var arrangement := 0
@export var seed_value := 40   # the row's name: the same number returns the same draws
@export var count := 200       # how many symbols are drawn
@export var glide := 1.5       # seconds a new arrangement takes

var values := PackedInt32Array()      # the symbols, in the order they were drawn
var order: Array = []                 # order[k] is the draw that stands at place k
var came_from := PackedInt32Array()   # for each draw, the place it leaves
var goes_to := PackedInt32Array()     # and the place it glides to
var bars := MultiMesh.new()
var readout: Label3D
var gliding: Tween

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		values.append(rng.randi_range(0, ALPHABET - 1))
	build()
	goes_to.resize(count)
	arrange(arrangement, 0.0)

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

## The row as it stands now, read from left to right.
func row() -> PackedInt32Array:
	var out := PackedInt32Array()
	for k in order:
		out.append(values[k])
	return out

## Does draw a stand before draw b? The answer depends on `arrangement`.
func before(a: int, b: int) -> bool:
	var va := values[a]
	var vb := values[b]
	if arrangement == 2 and va % 4 != vb % 4:
		return va % 4 < vb % 4
	if va != vb:
		return va > vb if arrangement == 3 else va < vb
	return a < b   # two equal symbols keep the order they were drawn in

func arrange(how: int, seconds: float) -> void:
	arrangement = how
	came_from = goes_to.duplicate()
	order = range(count)
	if how > 0:
		order.sort_custom(before)
	for place in count:
		goes_to[order[place]] = place
	if gliding:
		gliding.kill()   # a glide still under way stops where it is
	if seconds <= 0.0:
		slide(1.0)
	else:
		gliding = create_tween()
		gliding.tween_method(slide, 0.0, 1.0, seconds)
	readout.text = "%s: H = %.3f bits" % [NAMES[how], entropy(row())]
	print(readout.text, "; the row begins ", row().slice(0, 12))

## Every bar at `t` of its way from the place it leaves to the place it goes to.
func slide(t: float) -> void:
	for i in count:
		stand(i, lerpf(came_from[i], goes_to[i], t))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		arrange((arrangement + 1) % NAMES.size(), glide)
