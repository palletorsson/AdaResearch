@tool
extends Node3D
class_name DragPointTarget

# @identity
# essence: a place the room asks you to put something — a red arrow over a marked spot, and a consequence when you obey
# desire: the learner stops reading the coordinate frame and USES it; the point becomes a thing you move to a place, not a number you look at
# critical_parameter: catch_radius — how exact the room insists you are. Wide is an invitation, tight is a test
# triggers: any node in group "ada_coordinate_point" entering the catch sphere fires once; leaving and re-entering re-arms only if rearm is true
# emerges: the moment the balls fall, the coordinate stops being a label and becomes a cause
# needs: a point in group ada_coordinate_point somewhere in the map [checked at runtime, reported if absent]
# relationships: built for CoordinateSystem3M's floating point in Point_One; works with any ada_coordinate_point
# truth: a coordinate you can reach is a different object from a coordinate you can read
#
## Palle, 2026-09-04: "a big red arrow in the map with the text 'drag point here'
## ... and we then drag the point to that position the balls fall out of the sky."
##
## This replaces an `if_not_exist_create` wish that stood at (10,6) in Point_One.
##
## WHY IT WATCHES A GROUP AND NOT A NODE PATH. The thing being dragged is
## interactive_point_origin, an XRToolsPickable — a RigidBody3D whose transform
## belongs to the physics server, and which may be a child of a CoordinateSystem3M
## frame or free in the map. A path would break the moment either changed. It
## joins `ada_coordinate_point` in its own _ready (interactive_point_origin.gd:154),
## so that is the contract this reads.

const PBR := preload("res://commons/render/pbr_kit.gd")

## What the sign says. Kept as text rather than a texture so a map can change the
## instruction without a re-bake.
@export var text: String = "DRAG POINT HERE"
## How close counts, in metres, measured in 3D from the catch centre.
@export var catch_radius: float = 0.45
## The catch sphere's height above this artifact's origin. The arrow points AT it.
## A point held in the hand rides near chest height, so the target is not the floor.
@export var catch_height: float = 1.20
@export var arrow_color: Color = Color(0.90, 0.13, 0.13)

@export_group("The fall")
## 2026-09-08, Palle: "can we do so that there are not so many balls but they all
## show their vector coordinate as a label sitting on top of them". It was 24. A
## ball that carries a number is something to READ, and two dozen of them is
## confetti — the count is now small enough that every label can be read before
## the next one lands.
@export var ball_count: int = 7
## Where they come from. High enough to read as sky, low enough to land this decade.
@export var drop_height: float = 9.0
## The circle they are scattered across before they let go.
@export var drop_spread: float = 1.8
@export var ball_radius: float = 0.09
## 2026-09-08, Palle: "they should also be just white". They used to be
## Color.from_hsv(rng.randf(), 0.42, 0.92) — a different hue per ball, which
## read as a party. White lets the coordinate above each one be the only thing
## on it that carries information.
@export var ball_color: Color = Color(1, 1, 1)
## Seconds before a ball is removed. 0 keeps them forever, which on a Quest is a
## promise the frame budget cannot keep.
@export var ball_life: float = 26.0
## Fire again on a later arrival, or once only.
@export var rearm: bool = true

@export_group("The coordinate on each ball")
## Every ball says where it is, above itself, upright, all the way down and after
## it settles. The fall stops being confetti and becomes the coordinate frame
## demonstrating itself: three numbers you watch change and then stop.
@export var ball_labels: bool = true
## THE NUMBERS ARE THE WORLD'S, NOT THE FRAME'S — the same ruling
## CoordinateSystem3M's readout_space carries (2026-08-31, Palle: "do not think
## about CoordinateSystem3M as local but the global values from vector.zero").
## A ball reads its real position in the map, so it agrees with the wall readout
## and with the point the learner just dragged. `local` measures from THIS
## artifact instead, for a self-contained demonstration.
@export_enum("world", "local") var label_space: String = "world"
@export_range(0, 3) var label_decimals: int = 1
@export var label_font_size: int = 26
## How far above the ball's centre the text floats, on top of its radius.
@export var label_gap: float = 0.10

signal point_arrived(where: Vector3)
signal balls_dropped(count: int)

var _fired: bool = false
var _inside: bool = false
var _t: float = 0.0
var _arrow: Node3D = null
var _ring: MeshInstance3D = null
var _stem: MeshInstance3D = null
var _label: Label3D = null
var _balls: Node3D = null
## {body, label} per dropped ball. The label is a SIBLING of the body, never a
## child: a RigidBody3D tumbles as it lands, and a child label would roll with it
## — orbiting the ball and reading upside down. Kept level and above by _process.
var _tags: Array = []
var _warned: bool = false


func _ready() -> void:
	_build()
	set_process(true)


func apply_grid_config(config_data: Dictionary) -> void:
	# Every key optional; a map that sets none still gets a working target.
	if config_data.has("text"):
		text = str(config_data["text"])
	if config_data.has("catch_radius"):
		catch_radius = float(config_data["catch_radius"])
	if config_data.has("catch_height"):
		catch_height = float(config_data["catch_height"])
	if config_data.has("balls"):
		ball_count = int(config_data["balls"])
	if config_data.has("drop_height"):
		drop_height = float(config_data["drop_height"])
	if config_data.has("spread"):
		drop_spread = float(config_data["spread"])
	if config_data.has("ball_radius"):
		ball_radius = float(config_data["ball_radius"])
	if config_data.has("ball_life"):
		ball_life = float(config_data["ball_life"])
	if config_data.has("rearm"):
		rearm = _as_bool(config_data["rearm"])
	if config_data.has("color"):
		arrow_color = _as_color(config_data["color"], arrow_color)
	if config_data.has("ball_color"):
		ball_color = _as_color(config_data["ball_color"], ball_color)
	if config_data.has("labels"):
		ball_labels = _as_bool(config_data["labels"])
	# WORD-VALUED, so it is safe in both engines: the grid reads #key:<float> as
	# the tutorial shorthand unless the key is in CONFIG_PARAM_NAMES, and
	# `#label_space:world` can never be mistaken for a rotation.
	if config_data.has("label_space"):
		var ls := str(config_data["label_space"]).strip_edges().to_lower()
		if ls == "world" or ls == "local":
			label_space = ls
	if config_data.has("label_decimals"):
		label_decimals = clampi(int(config_data["label_decimals"]), 0, 3)
	if config_data.has("label_size"):
		label_font_size = maxi(6, int(config_data["label_size"]))
	if is_inside_tree():
		_rebuild()


func _as_bool(v: Variant) -> bool:
	if v is bool:
		return v
	var s := str(v).strip_edges().to_lower()
	return s in ["1", "true", "yes", "on"]


func _as_color(v: Variant, fallback: Color) -> Color:
	if v is Color:
		return v
	var s := str(v).strip_edges()
	if s.begins_with("#") or s.length() in [6, 8]:
		return Color.html(s.lstrip("#")) if Color.html_is_valid(s.lstrip("#")) else fallback
	return fallback


func _rebuild() -> void:
	for c in [_arrow, _ring, _label, _stem]:
		if is_instance_valid(c):
			c.queue_free()
	_arrow = null
	_ring = null
	_label = null
	_stem = null
	_build()


# ── the sign ──────────────────────────────────────────────────────────────────
func _build() -> void:
	var mat := PBR.hard_plastic(arrow_color, 0.66, 0.04)
	mat.emission_enabled = true
	mat.emission = arrow_color
	# Low energy on purpose: this has to read across a hall without becoming a
	# lamp that washes out the coordinate frame it is pointing into.
	mat.emission_energy_multiplier = 0.55

	_arrow = Node3D.new()
	_arrow.name = "Arrow"
	add_child(_arrow)

	# The head. A cone with top_radius 0, turned to point DOWN at the catch centre.
	var head := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.20
	cone.height = 0.40
	cone.radial_segments = 20
	head.mesh = cone
	head.material_override = mat
	head.rotation_degrees = Vector3(180.0, 0.0, 0.0)   # apex down
	# The apex lands EXACTLY on the catch centre. The first capture had it 22 cm
	# high — a cone's origin is its middle, not its tip — and an arrow pointing at
	# a spot 22 cm off the thing it means is an arrow pointing at nothing.
	head.position = Vector3(0.0, catch_height + cone.height * 0.5, 0.0)
	_arrow.add_child(head)

	# The shaft.
	var shaft := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.055
	rod.bottom_radius = 0.055
	rod.height = 0.72
	rod.radial_segments = 12
	shaft.mesh = rod
	shaft.material_override = mat
	shaft.position = Vector3(0.0, catch_height + cone.height + rod.height * 0.5, 0.0)
	_arrow.add_child(shaft)

	# THE TETHER. The arrow points into the air at catch height; the ring is on the
	# floor. Without something joining them the two read as unrelated objects and
	# the target has no location. A thin translucent stem does it, and it does NOT
	# bob with the arrow — it belongs to the place, not to the sign.
	var stem := MeshInstance3D.new()
	var srod := CylinderMesh.new()
	srod.top_radius = 0.012
	srod.bottom_radius = 0.012
	srod.height = maxf(0.05, catch_height)
	srod.radial_segments = 8
	stem.mesh = srod
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(arrow_color.r, arrow_color.g, arrow_color.b, 0.38)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.emission_enabled = true
	smat.emission = arrow_color
	smat.emission_energy_multiplier = 0.30
	stem.material_override = smat
	stem.position = Vector3(0.0, catch_height * 0.5, 0.0)
	_stem = stem
	add_child(stem)

	# The spot on the floor. A ring, not a disc: a disc reads as a hole in the
	# floor from a distance, and this room already has a void layer.
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.05, catch_radius - 0.04)
	torus.outer_radius = maxf(0.09, catch_radius)
	torus.rings = 24
	_ring.mesh = torus
	_ring.material_override = mat
	_ring.position = Vector3(0.0, 0.015, 0.0)
	add_child(_ring)

	_label = Label3D.new()
	_label.text = text.to_upper()
	_label.font_size = 44
	_label.pixel_size = 0.0032
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1)
	_label.outline_size = 10
	_label.outline_modulate = Color(0.05, 0.03, 0.03, 0.85)
	_label.no_depth_test = false
	_label.position = Vector3(0.0, catch_height + 1.62, 0.0)
	add_child(_label)

	_balls = get_node_or_null("Balls")
	if _balls == null:
		_balls = Node3D.new()
		_balls.name = "Balls"
		add_child(_balls)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if is_instance_valid(_arrow):
		# a slow bob, so the arrow reads as an instruction rather than scenery
		_arrow.position.y = sin(_t * 1.7) * 0.075
	_follow_tags()
	_check()


## Keep every ball's coordinate above it, level, and true while it falls.
##
## The label is a SIBLING of its body, so this is a per-frame copy rather than a
## parenting trick: a child label would inherit the RigidBody3D's tumble and end
## up orbiting the ball and reading upside down. A ball whose body has been freed
## by the ball_life timer takes its label with it here — nothing else is watching.
func _follow_tags() -> void:
	if _tags.is_empty():
		return
	var lift: float = ball_radius + maxf(0.0, label_gap)
	var d: int = clampi(label_decimals, 0, 3)
	var f: String = "%." + str(d) + "f"
	var fmt: String = f + ", " + f + ", " + f
	var live: Array = []
	for e_v in _tags:
		var e: Dictionary = e_v
		# is_instance_valid FIRST, cast second. ball_life frees these bodies out
		# from under us, and casting a freed reference is not a safe way to find
		# out that it is gone — the project's own idiom, from endless_museum's
		# _edit_records loop.
		var bv: Variant = e.get("body")
		var tv: Variant = e.get("tag")
		var tag: Label3D = (tv as Label3D) if (tv != null and is_instance_valid(tv)) else null
		if bv == null or not is_instance_valid(bv):
			if tag != null:
				tag.queue_free()
			continue
		if tag == null:
			continue
		var body: Node3D = bv as Node3D
		if body == null:
			continue
		var w: Vector3 = body.global_position
		tag.global_position = w + Vector3(0.0, lift, 0.0)
		# THE NUMBERS ARE THE WORLD'S unless the map says otherwise — the ruling
		# CoordinateSystem3M carries on readout_space, so a ball agrees with the
		# wall readout instead of quietly measuring from this artifact.
		var shown: Vector3 = w if label_space == "world" else to_local(w)
		tag.text = fmt % [shown.x, shown.y, shown.z]
		live.append(e)
	_tags = live


## THE CATCH. Distance in 3D from the catch centre, against every registered
## point. There are one or two of these in a map, so a per-frame scan is cheaper
## than an Area3D plus the signal plumbing to survive a re-parent.
func _check() -> void:
	var pts := get_tree().get_nodes_in_group("ada_coordinate_point")
	if pts.is_empty():
		if not _warned:
			_warned = true
			push_warning("drag_point_target: nothing in group 'ada_coordinate_point' — "
				+ "place an interactive_point_origin, or set floating_point:1 on a CoordinateSystem3M")
		return
	var centre := global_position + Vector3(0.0, catch_height, 0.0)
	var near := false
	var where := Vector3.ZERO
	for p in pts:
		var n := p as Node3D
		if n == null or not n.is_inside_tree():
			continue
		if n.global_position.distance_to(centre) <= catch_radius:
			near = true
			where = n.global_position
			break

	if near and not _inside:
		_inside = true
		if not _fired or rearm:
			_fired = true
			point_arrived.emit(where)
			_drop()
	elif not near and _inside:
		_inside = false


# ── the consequence ───────────────────────────────────────────────────────────
## Plain RigidBody3D spheres. No pooling, no MultiMesh: two dozen bodies for
## twenty seconds is well inside budget, and a MultiMesh cannot fall.
func _drop() -> void:
	if not is_instance_valid(_balls):
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var mesh := SphereMesh.new()
	mesh.radius = ball_radius
	mesh.height = ball_radius * 2.0
	mesh.radial_segments = 14
	mesh.rings = 8
	var shape := SphereShape3D.new()
	shape.radius = ball_radius
	# ONE material for all of them, like the mesh and the shape above. It was per
	# ball only because each ball had its own hue; now that they are one colour,
	# a material each would be N StandardMaterial3Ds and N pipeline states for a
	# single appearance — and this runs on a Quest.
	var ball_mat := PBR.hard_plastic(ball_color, 0.60, 0.05)

	for i in range(maxi(0, ball_count)):
		var body := RigidBody3D.new()
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * drop_spread     # sqrt keeps them evenly spread, not clumped at the middle
		body.position = Vector3(cos(a) * r, drop_height + rng.randf() * 1.4, sin(a) * r)

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = ball_mat
		body.add_child(mi)

		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)

		_balls.add_child(body)

		if ball_labels:
			var tag := Label3D.new()
			tag.font_size = label_font_size
			tag.pixel_size = 0.0026
			# upright and facing the reader wherever they stand — the ball rolls,
			# the number must not
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			tag.modulate = Color(1, 1, 1)
			tag.outline_size = 8
			tag.outline_modulate = Color(0.05, 0.03, 0.03, 0.85)
			tag.text = ""
			_balls.add_child(tag)
			_tags.append({"body": body, "tag": tag})

		if ball_life > 0.0:
			var t := get_tree().create_timer(ball_life + rng.randf() * 2.0)
			t.timeout.connect(func() -> void:
				if is_instance_valid(body):
					body.queue_free())

	balls_dropped.emit(ball_count)
