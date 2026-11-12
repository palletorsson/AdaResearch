# noise_ground_pair.gd
# Two grounds from one seed: heights drawn alone beside heights that agree with their neighbours.
#
# @identity
# essence: one seed gives every point of two equal plots a height in the same range. LEFT, alone: h = u(x, z), each
#   drawn by itself. RIGHT, related: h = field(x, z), read off a Perlin field in which near points have near values.
#   Both rise from the floor at their rim.
# desire: to find out with the feet what "related" means. The ground where each height was drawn alone cannot be
#   crossed - every step is a wall or a pit. The ground where neighbours agree can be walked from end to end.
# critical_parameter: agreement - how far a height's agreement with its neighbours reaches on the right plot
#   (none | near | far). `none` draws the right plot alone as well: two grounds nobody crosses. `near` agrees over a
#   pace; `far` over a few metres - rolling ground.
# triggers: stepping on the DRAW AGAIN plate draws both grounds from the next seed.
# emerges: draw again and the left plot is as impassable as before, somewhere else; the right one is a new set of
#   hills and still a walk. What changes is the draws; what holds is the relation.
# needs: 12 x 5 m of floor [has when placed]; a body that walks [the tower's walker climbs slopes, not steps].
# relationships: the body-scale sibling of [[perlin_noise_bridge]] (two 24 cm grids at chest height: "independent
#   draws versus spatial correlation") and of the INDEPENDENT / PERLIN buttons of [[seeded_room]]. It is the door to
#   the noise floors: what they call noise is the right-hand ground. Kin to [[bounded_plank_causeway]] (the ends
#   agree) and [[sorted_draw_stairs]] (the draws are put in order): three ways chance becomes ground.
# truth: Noise is randomness you can walk on. (After perlin_noise_bridge: "Nearby samples can be related by a
#   spatial construction without recording a history of visits.")
# lineage: MATH - white noise against gradient noise (Ken Perlin, "An Image Synthesizer", 1985): the second was
#   invented because the first makes no surface. ART - Isamu Noguchi's play landscapes: ground modelled so that a
#   body reads it. DESIGN - the skatepark bowl: a surface is a promise about its own slope. ARCHITECTURE - landform
#   building, where the floor is the form.
# history: 2026-11-12. Floor Random_Space_Geometry greets with seeded_room, already a room a body walks. Its bridge
#   to noise was a 60 cm model behind that room. Read as code, the comparison has a meaning for legs that nothing on
#   the floor let them try. Built from what the tower has earned: array, sample, and the surface a body stands on.

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

## How far a height's agreement with its neighbours reaches on the right plot.
@export_enum("none", "near", "far") var agreement := "far"
@export var seed_value := 20261121      ## a draw whose related ground has hills (0.6 m of relief) a body can still take
@export_range(6, 24) var cells := 12
@export var cell := 0.4                 ## metres: the plot is cells x cell on a side
@export var gap := 2.1                  ## clear floor between the two plots
@export var height := 0.8               ## the range both plots share
@export var field_scale := 0.38         ## cycles per metre of the related field at `far`

var _built: Array[Node] = []
var _last_draw := -10.0
var _seed_label: Label3D
var _aged: Material
var _red: Material


func _ready() -> void:
	_read_config()
	_aged = Stock.finish("76695a", .95)
	_red = Stock.finish("c8452f", .6)
	_fixed()
	_draw()


func _read_config() -> void:
	if has_meta("config_agreement") and str(get_meta("config_agreement")) in ["none", "near", "far"]:
		agreement = str(get_meta("config_agreement"))
	for key in ["seed_value", "cells"]:
		for meta in ["config_" + key, "config_seed" if key == "seed_value" else ""]:
			if meta != "" and has_meta(meta): set(key, int(str(get_meta(meta)).to_float()))
	for key in ["cell", "gap", "height", "field_scale"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()
	if is_inside_tree() and _aged != null:
		_draw()


func _side() -> float:
	return cells * cell


func _plot_x(which: int) -> float:
	return which * (gap + _side()) / 2.0


## The heights of one plot at its (cells + 1) squared corners. `relation`: alone | near | far.
func heights(relation: String) -> Array:
	var n := cells + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.frequency = field_scale if relation == "far" else field_scale * 2.4
	var out := []
	for k in n:
		var row := []
		for i in n:
			var u := rng.randf()      # drawn for every corner at every setting: one stream, whatever is shown
			var rim := mini(mini(i, k), mini(n - 1 - i, n - 1 - k))
			var h := u * height
			if relation != "alone":
				# the field, eased down to the floor over four cells so that the way on is a slope too
				h = clampf(.5 + noise.get_noise_2d(i * cell, k * cell) * .9, 0, 1) * height * smoothstep(0.0, 1.0, rim / 4.0)
			if rim == 0:
				h = 0.0      # both plots meet the floor: a body can step on anywhere
			row.append(snappedf(h, .001))
		out.append(row)
	return out


func _plot(which: int, relation: String) -> void:
	var host := StaticBody3D.new()
	host.name = "Ground_" + relation
	host.position = Vector3(_plot_x(which) - _side() / 2.0, 0, -_side() / 2.0)
	add_child(host)
	_built.append(host)
	var h: Array = heights(relation)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var low := Color("d88a59")
	var high := Color("5a4582")
	for k in cells:
		for i in cells:
			var corners := [Vector3(i * cell, h[k][i], k * cell), Vector3((i + 1) * cell, h[k][i + 1], k * cell),
				Vector3((i + 1) * cell, h[k + 1][i + 1], (k + 1) * cell), Vector3(i * cell, h[k + 1][i], (k + 1) * cell)]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				for c in tri:
					var p: Vector3 = corners[c]
					tool.set_color(low.lerp(high, clampf(p.y / maxf(.01, height), 0, 1)))
					tool.add_vertex(p + Vector3(0, .012, 0))
	tool.generate_normals()
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = .9
	var instance := MeshInstance3D.new()
	instance.name = "Surface"
	instance.mesh = mesh
	instance.material_override = material
	host.add_child(instance)
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	host.add_child(collider)


func _sign(text: String, at: Vector3) -> void:
	for dz in [-.72, .72]:
		Stock.box(self, "SignPost", Vector3(at.x, at.y / 2.0, at.z + dz), Vector3(.05, at.y, .05), _aged, false)
	var board := Stock.box(self, "SignBoard", at, Vector3(.03, .42, 1.6), Stock.finish("d9cfbd", .9), false)
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = .0011
	label.outline_size = 0
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.modulate = Color("202329")
	label.rotation.y = PI / 2.0      # the words face east, toward a body coming from the spawn point
	label.position = Vector3(.02, 0, 0)
	board.add_child(label)


func _fixed() -> void:
	var right := "DRAWN ALONE AS WELL\nno height agrees with the next" if agreement == "none" else \
		("NEIGHBOURS AGREE, A PACE AT A TIME\nthe same seed, read off a field" if agreement == "near" else "NEIGHBOURS AGREE\nthe same seed, read off a field: noise")
	_sign("EACH HEIGHT DRAWN ALONE\nit knows nothing of the next", Vector3(_plot_x(-1) + _side() / 2.0 + .25, 1.9, 0))
	_sign(right, Vector3(_plot_x(1) + _side() / 2.0 + .25, 1.9, 0))
	var plate := Stock.box(self, "DrawAgain", Vector3(.5, .02, -1.2), Vector3(.8, .04, .8), _red, false)
	var words := Label3D.new()
	words.text = "DRAW AGAIN"
	words.font_size = 48
	words.pixel_size = .0017
	words.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	words.modulate = Color("f3ece2")
	words.rotation.x = -PI / 2
	words.position = Vector3(0, .025, 0)
	plate.add_child(words)
	_seed_label = Label3D.new()
	_seed_label.font_size = 40
	_seed_label.pixel_size = .0017
	_seed_label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_seed_label.modulate = Color("202329")
	_seed_label.rotation.x = -PI / 2
	_seed_label.position = Vector3(.5, .01, -.55)
	add_child(_seed_label)
	var area := Area3D.new()
	area.name = "DrawAgainArea"
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	area.position = Vector3(.5, .5, -1.2)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.8, 1.0, .8)
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_stepped)


func _stepped(body: Node) -> void:
	if not body is CharacterBody3D:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_draw < 1.5:
		return
	_last_draw = now
	seed_value += 1
	_draw()


func _draw() -> void:
	for node in _built:
		if is_instance_valid(node):
			node.queue_free()
	_built.clear()
	_plot(-1, "alone")
	_plot(1, "alone" if agreement == "none" else agreement)
	if _seed_label != null:
		_seed_label.text = "seed %d" % seed_value


## For probes: the steepest rise between two neighbouring corners of a plot, in metres.
func steepest(relation: String) -> float:
	var h: Array = heights(relation)
	var worst := 0.0
	for k in h.size():
		for i in h.size():
			if i + 1 < h.size(): worst = maxf(worst, absf(float(h[k][i + 1]) - float(h[k][i])))
			if k + 1 < h.size(): worst = maxf(worst, absf(float(h[k + 1][i]) - float(h[k][i])))
	return worst
