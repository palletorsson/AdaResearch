extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FoldingMenagerieRoom

## @identity
## name: "Folding creatures"
## tier: large
## lineage: A room of folding creatures — origami-like critters that unfold and re-fold, each
##   moving by changing its own shape rather than swinging a limb against a bone. Locomotion as
##   crease, not as lever.
## truth: "STRUCTURE THAT WALKS BY FOLDING, NOT BY PUSHING AGAINST BONE"
## applications: folding robots, self-deploying structures, inchworm and origami locomotion —
##   bodies that travel by reconfiguring, not by levering joints.

@export var room: float = 7.0
@export var creature_count: int = 5
@export var fold_rate: float = 0.4
@export var floor_col: Color = Color(0.11, 0.12, 0.14)
@export var creature_a: Color = Color(0.90, 0.45, 0.40)
@export var creature_b: Color = Color(0.40, 0.70, 0.90)
@export var creature_c: Color = Color(0.55, 0.85, 0.50)
@export var label_col: Color = Color(0.95, 0.96, 0.99)

var _t: float = 0.0
var _creatures: Array = []   # each: { node:Node3D, panels:Array, phase, gait_dir:Vector3, home:Vector3 }


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("creature_count"):
		creature_count = int(clampf(float(config["creature_count"]), 3, 8))
	if config.has("fold_rate"):
		fold_rate = clampf(float(config["fold_rate"]), 0.2, 0.7)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_creatures.clear()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room, 0.1, room), _matte_mat(floor_col, 0.9)))

	var pal := [creature_a, creature_b, creature_c]
	for i in range(creature_count):
		var ang: float = TAU * float(i) / float(creature_count)
		var rad: float = room * 0.26
		var home := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		var col: Color = pal[i % pal.size()]
		_add_creature(home, col, float(i) * 1.1)

	add_child(_billboard_label("STRUCTURE THAT WALKS BY FOLDING, NOT BY BONE", Vector3(0.0, 3.6, 0.0), 25, label_col))


func _add_creature(home: Vector3, col: Color, phase: float) -> void:
	var node := Node3D.new()
	node.position = home
	add_child(node)
	var mat := _glow_mat(col, 0.4)

	# A creature = a chain of hinged flat panels, like a fold-out concertina with legs.
	var panels: Array = []
	var seg: int = 5
	var panel_len: float = 0.32
	var prev_pivot := Vector3(0.0, 0.35, 0.0)
	for s in range(seg):
		# Each panel is a hinge node holding a thin plate; folding rotates the hinge.
		var hinge := Node3D.new()
		hinge.position = prev_pivot
		node.add_child(hinge)
		var plate := _box(Vector3(0.0, 0.0, panel_len * 0.5), Vector3(0.30, 0.04, panel_len), mat)
		hinge.add_child(plate)
		panels.append(hinge)
		prev_pivot = Vector3(0.0, 0.0, panel_len)   # next hinge sits at end of this panel, in hinge-local space

	# A little head sphere on the front.
	var head := _sphere(Vector3(0.0, 0.0, panel_len), 0.09, _glow_mat(col.lerp(Color.WHITE, 0.3), 0.7))
	(panels[seg - 1] as Node3D).add_child(head)

	var gait_dir := Vector3(cos(phase), 0.0, sin(phase)).normalized()
	_creatures.append({ "node": node, "panels": panels, "phase": phase, "gait_dir": gait_dir, "home": home })


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for ci in range(_creatures.size()):
		var cr: Dictionary = _creatures[ci]
		var node: Node3D = cr["node"]
		var panels: Array = cr["panels"]
		var ph: float = cr["phase"]
		var home: Vector3 = cr["home"]
		# Fold wave travels down the chain — each hinge folds out of phase.
		for pi in range(panels.size()):
			var hinge: Node3D = panels[pi]
			var wave: float = sin(_t * TAU * fold_rate + ph + float(pi) * 0.8)
			# Concertina fold: alternate panels bend opposite ways.
			var fold_sign: float = 1.0 if pi % 2 == 0 else -1.0
			hinge.rotation.x = wave * 0.6 * fold_sign
		# Locomotion by folding: a gentle bob + drift back toward home so it reads as crawling.
		var crawl: float = sin(_t * TAU * fold_rate * 0.5 + ph) * 0.4
		var pos: Vector3 = home + (cr["gait_dir"] as Vector3) * crawl
		pos.y = absf(sin(_t * TAU * fold_rate + ph)) * 0.06
		node.position = pos
		node.rotation.y = ph + sin(_t * 0.3 + ph) * 0.2
