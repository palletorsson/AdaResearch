extends MeshInstance3D

const Look := preload("res://supplied/look.gd")
const PAINT := {"stay": Look.BODY, "pass": Look.SECOND}
const CELL := 0.25                 # metres: the side of one cell of the field
const CELLS := Vector2i(32, 20)    # 32 by 20 cells cover the floor, 8 m by 5 m

@export var file := "res://samples.json"
@export_enum("one person", "the class", "a default dataset", "random labels", "you") var labelled_by := 0
@export_range(1, 9, 2) var k := 3  # how many neighbours vote
@export_enum("neighbours", "a line", "the error") var rule := 0

var consent := {}                  # labeller -> whether the file records their consent
var samples: Array = []            # every sample of the file
var who := ["the builder", "classmate", "nobody", "a coin", "you"]   # whose samples each value of labelled_by trains on
var chosen: Array = []             # the samples we train on
var balls: Array = []              # one ball for each of them
var image: Image
var texture: ImageTexture
var readout: Label3D
var weights := Vector2.ZERO        # the line: weights.x * x + weights.y * z + bias = 0
var bias := 0.0
var line: MeshInstance3D           # the line of the weights, laid on the floor
var save_file := "res://my_samples.json"

func _ready() -> void:
	assert(xor_wrong() > 0, "a line split XOR: no line can, so the test is broken")
	if FileAccess.file_exists(save_file):
		file = save_file
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
	consent = data.consent
	samples = data.samples
	choose()
	make_floor()
	if rule == 1:
		train()
	paint_field()
	readout = Look.label("")
	readout.position = Vector3(0, 1.3, -2.6)
	add_child(readout)
	line = preload("res://supplied/segment.gd").new()
	add_child(line)
	var walker := get_node_or_null("../Walker")
	if rule == 2 and walker != null:
		walker.walk_to(walk_down(walker.position))
	if rule != 2:
		print("wrong about its own samples: ", wrong(), " of ", chosen.size())

## Picks the samples to train on by who labelled them, and stands a ball on each.
func choose() -> void:
	for ball: Node in balls:
		ball.free()
	balls = []
	chosen = []
	var labellers := {}
	for sample: Dictionary in samples:
		if not sample.labelled_by.begins_with(who[labelled_by]):
			continue
		chosen.append(sample)
		labellers[sample.labelled_by] = consent.get(sample.labelled_by, "not recorded")
		var ball := MeshInstance3D.new()
		ball.mesh = SphereMesh.new()
		ball.scale = Vector3.ONE * 0.14
		ball.position = Vector3(sample.x, 0.07, sample.z)
		ball.material_override = Look.paint(PAINT[sample.label])
		add_child(ball)
		balls.append(ball)
	print(chosen.size(), " of ", samples.size(), " samples; labelled by, and their consent: ", labellers)

## The k nearest samples vote. Returns the winning label and its share of the votes.
func neighbours_say(x: float, z: float) -> Array:
	var near: Array = []
	for sample: Dictionary in chosen:
		near.append([Vector2(sample.x - x, sample.z - z).length(), sample.label])
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

## What the rule in use says of a place: a label, and how sure it is, from 0 to 1.
func says(x: float, z: float) -> Array:
	if rule == 0:
		return neighbours_say(x, z)
	return line_says(x, z)

## The floor's own mesh and material: one pixel of the image for each cell.
func make_floor() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(CELLS) * CELL
	mesh = plane
	image = Image.create(CELLS.x, CELLS.y, false, Image.FORMAT_RGB8)
	texture = ImageTexture.create_from_image(image)
	var material := Look.paint(Color.WHITE)
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material_override = material

## The colour of a place: the ground, turned toward the label's colour as far as the answer is sure.
func colour_at(x: float, z: float) -> Color:
	if rule == 2:
		return Look.GROUND.lerp(Look.THIRD, minf(1.0, error_at(x, z) / 8.0))
	var said := says(x, z)
	if said[0] == "":
		return Look.GROUND
	return Look.GROUND.lerp(PAINT[said[0]], said[1] * 0.75)

## One colour for each cell of the floor, written into the image.
func paint_field() -> void:
	for cz in CELLS.y:
		for cx in CELLS.x:
			image.set_pixel(cx, cz, colour_at((cx + 0.5) * CELL - 4.0, (cz + 0.5) * CELL - 2.5))
	texture.update(image)
	print("painted ", CELLS.x * CELLS.y, " cells")

func _process(_delta: float) -> void:
	var walker := get_node_or_null("../Walker")
	if walker == null or readout == null:
		return
	var at: Vector3 = walker.position
	if Input.is_action_just_pressed("pause"):
		add_sample(at, "stay")
	if Input.is_action_just_pressed("drop"):
		add_sample(at, "pass")
	if rule == 2:
		weights = Vector2(at.x, at.z) * 0.25
		bias = 0.0
		var along := Vector3(-at.z, 0.0, at.x).normalized() * 2.4
		line.show_between(Vector3(0, 0.03, 0) - along, Vector3(0, 0.03, 0) + along)
		readout.text = "error %.2f here; the line of these weights gets %d of %d wrong" % [error_at(at.x, at.z), wrong(), chosen.size()]
		return
	var said := says(at.x, at.z)
	readout.text = "you stand on %s, sure to %d%%" % [said[0], roundi(said[1] * 100)]
	if said[0] == "":
		readout.text = "no label yet: Space says stay here, M says pass"

## The test that catches the field lying about its own data: how many of the
## samples it was trained on does it answer against their own label?
func wrong() -> int:
	var count := 0
	for sample: Dictionary in chosen:
		if says(sample.x, sample.z)[0] != sample.label:
			count += 1
	return count

## The line answers by the side a place is on. It is always sure.
func line_says(x: float, z: float) -> Array:
	return ["stay" if weights.x * x + weights.y * z + bias > 0.0 else "pass", 1.0]

## The perceptron: go through the samples, and each time the line is wrong about one, turn it a little toward that sample.
func train(rounds := 100) -> void:
	weights = Vector2.ZERO
	bias = 0.0
	for count in rounds:
		for sample: Dictionary in chosen:
			if line_says(sample.x, sample.z)[0] != sample.label:
				var target := 1.0 if sample.label == "stay" else -1.0
				weights += 0.1 * target * Vector2(sample.x, sample.z)
				bias += 0.1 * target

## Four samples that no line can split: how many does the trained line get wrong?
func xor_wrong() -> int:
	var before := [rule, chosen]
	rule = 1
	chosen = [
		{"x": -1.0, "z": -1.0, "label": "stay"}, {"x": 1.0, "z": 1.0, "label": "stay"},
		{"x": -1.0, "z": 1.0, "label": "pass"}, {"x": 1.0, "z": -1.0, "label": "pass"},
	]
	train(1000)
	var count := wrong()
	rule = before[0]
	chosen = before[1]
	return count

## The squared error of the line through the middle of the floor whose two
## weights are this place: a quarter of a weight for every metre.
func error_at(x: float, z: float) -> float:
	var sum := 0.0
	for sample: Dictionary in chosen:
		var target := 1.0 if sample.label == "stay" else -1.0
		sum += pow(0.25 * x * sample.x + 0.25 * z * sample.z - target, 2)
	return sum / maxi(1, chosen.size())

## Downhill from a place: step to the lowest of the four cells around, until none is lower.
func walk_down(from: Vector3) -> Array:
	var points: Array = []
	var here := from
	while points.size() < 100:
		var best := here
		for step: Vector3 in [Vector3(CELL, 0, 0), Vector3(-CELL, 0, 0), Vector3(0, 0, CELL), Vector3(0, 0, -CELL)]:
			if error_at(here.x + step.x, here.z + step.z) < error_at(best.x, best.z):
				best = here + step
		if best == here:
			break
		here = best
		points.append(here)
	return points

## A new sample where the walker stands, labelled by you, and saved at once.
func add_sample(at: Vector3, label: String) -> void:
	samples.append({"x": snappedf(at.x, 0.01), "z": snappedf(at.z, 0.01), "label": label, "labelled_by": "you"})
	consent["you"] = true
	var saved := FileAccess.open(save_file, FileAccess.WRITE)
	saved.store_string(JSON.stringify({"consent": consent, "samples": samples}, "\t"))
	saved.close()
	choose()
	paint_field()
