extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheTreeYouAreIn

## @identity
## lineage: the graph taxonomy's rung 13, the mirror — a pedestal projecting a live
##   miniature of its OWN runtime subtree. Once a second it walks get_children()
##   recursively and rebuilds the projection: every plinth, placard and lamp of this
##   very artifact as a small glowing node in a radial tree. The projection's own
##   container appears in it as one honest ellipsis node, so the mirror admits it
##   contains itself without chasing the regress.
## essence: get_children() is the cheat-code under the whole sequence — the scene tree
##   IS a graph, and everything in this world lives on it: this map, this artifact,
##   the player. The projection is not a diagram OF the structure; it is read from the
##   structure, live, and changes when the structure does.
## truth: you have been standing in a graph all along.
##
## The 2026-08-27 graph taxonomy (doc/GRAPHTHEORY_TAXONOMY.md), rung 13 of 13 — the
## loop closes: rung 1's "a node and an edge" was never an abstraction here.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const MAX_DEPTH := 4
const MAX_NODES := 48

@export var seed: int = 48
@export var rebuild_every: float = 1.0

var _projection: Node3D                 # excluded from its own walk, shown as ellipsis
var _clock := 0.0
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_pedestal()
	_projection = Node3D.new()
	_projection.position = Vector3(0.0, 1.5, 0.0)
	add_child(_projection)
	_build_plaque()
	_rebuild()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "rebuild_every"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_clock += delta
	_projection.rotation.y += delta * 0.15
	if _clock >= rebuild_every:
		_clock = 0.0
		_rebuild()

# --- the pedestal -------------------------------------------------------------------

func _build_pedestal() -> void:
	var column := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 0.38
	cm.height = 1.0
	column.mesh = cm
	column.position = Vector3(0.0, 0.5, 0.0)
	column.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(column)
	var lens := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.26
	lm.bottom_radius = 0.26
	lm.height = 0.02
	lens.mesh = lm
	lens.position = Vector3(0.0, 1.02, 0.0)
	var mat := _glow_mat(Color(0.5, 0.8, 0.9), 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.4
	lens.material_override = mat
	add_child(lens)

# --- the walk, and the projection it becomes ----------------------------------------

func _rebuild() -> void:
	for c in _projection.get_children():
		_projection.remove_child(c)
		c.queue_free()
	# WALK MYSELF: this is the honest read — the projection draws whatever the
	# artifact's subtree actually is right now, projection container excluded
	var counted := {"n": 0}
	_draw_node(self, Vector3.ZERO, 0, TAU, 0, counted)
	if _readout and _readout.has_method("set_text"):
		_readout.set_text("get_children(): %d nodes" % counted["n"],
			"rebuilt %.0fx per second from the live subtree" % (1.0 / rebuild_every))

func _draw_node(node: Node, at: Vector3, ang0: float, span: float, depth: int, counted: Dictionary) -> void:
	if counted["n"] >= MAX_NODES:
		return
	counted["n"] += 1
	var is_self := node == self
	var is_mirror := node == _projection
	var tint := Color(0.95, 0.85, 0.4) if is_self else (Color(0.9, 0.3, 0.5) if is_mirror else Color.from_hsv(0.5 + 0.09 * float(depth), 0.55, 0.95))
	var dot := MeshInstance3D.new()
	var dm := SphereMesh.new()
	var r := 0.05 if is_self else 0.03
	dm.radius = r
	dm.height = r * 2.0
	dot.mesh = dm
	dot.position = at
	dot.material_override = _glow_mat(tint, 1.8)
	_projection.add_child(dot)
	if is_mirror:
		# the honest ellipsis: the mirror contains the mirror, declared once and
		# not descended into — the regress named instead of chased
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.1
		tag.position = at + Vector3(0.0, -0.08, 0.0)
		_projection.add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text("...", "this projection")
		return
	if depth >= MAX_DEPTH:
		return
	var kids := node.get_children()
	if kids.is_empty():
		return
	var n := kids.size()
	for i in range(n):
		if counted["n"] >= MAX_NODES:
			return
		var a := ang0 + span * (float(i) + 0.5) / float(n) - span * 0.5
		var drop := 0.22 + 0.02 * float(n)
		var child_at := at + Vector3(cos(a) * (0.3 + 0.05 * float(n)) * 0.9, -drop, sin(a) * (0.3 + 0.05 * float(n)) * 0.9) * (1.0 / (1.0 + 0.25 * float(depth)))
		var e := MeshInstance3D.new()
		var em := CylinderMesh.new()
		em.top_radius = 0.006
		em.bottom_radius = 0.006
		em.height = at.distance_to(child_at)
		e.mesh = em
		e.position = (at + child_at) * 0.5
		var dir := (child_at - at).normalized()
		var axis := Vector3.UP.cross(dir)
		if axis.length() > 0.001:
			e.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
		e.material_override = _glow_mat(Color(0.8, 0.78, 0.65), 0.4)
		_projection.add_child(e)
		_draw_node(kids[i], child_at, a, span * 0.6, depth + 1, counted)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "MirrorTreePlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-0.85, 0.24, 0.85)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE TREE YOU ARE IN",
			"Once a second this pedestal walks its own get_children() and redraws\nitself as the graph it is - plinth, placards, lamps, and one honest '...'\nwhere the projection contains the projection. You have been standing\nin a graph all along.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.32
	_readout.position = Vector3(0.85, 0.24, 0.85)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
