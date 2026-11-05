class_name FormTable
extends Node3D
## THE FORM TABLE (Palle, 2026-11-05: "in the primitive profile add a table with cone and column parts that we can
## stack on to each other and that snaps so we can make form"). A table set with white parts turned from the profiles
## of this floor - drums and tall drums (a column's shaft, a straight profile), cones and a spire (a profile leaning
## in), funnels (leaning out), capitals (a short flare) and square bases. Each is held as a hand holds anything (XR
## Tools pickable; a desktop grab too). Released with its foot near the top of another part, it SNAPS: stood upright,
## centred on that top, and it stays. Released over the table it stands where it is let go. Released anywhere else it
## falls. Lifting a part lifts everything stacked on it - a column comes away whole - and setting it down snaps the
## bottom of it, the rest riding along. One example column stands at the table's end.
##   config: length, width (m, the table top), top (m, its height), snap (m, how far a foot may be from a top centre)
## The origin is the table's middle on the floor; its length along x.

const PICKABLE := "res://addons/godot-xr-tools/objects/pickable.tscn"
## r0 the foot's radius, r1 the top's, h the height (m); square: a block, not a turned part
const KINDS := {
	"base": {"r0": .13, "r1": .13, "h": .05, "square": true},
	"drum": {"r0": .09, "r1": .09, "h": .14},
	"tall": {"r0": .09, "r1": .09, "h": .28},
	"cone": {"r0": .09, "r1": .025, "h": .16},
	"spire": {"r0": .06, "r1": .008, "h": .26},
	"funnel": {"r0": .03, "r1": .09, "h": .14},
	"capital": {"r0": .085, "r1": .13, "h": .07},
}
const LOOSE := ["base", "drum", "drum", "drum", "tall", "cone", "cone", "spire", "funnel", "funnel", "capital", "drum", "tall", "base", "cone", "capital"]
const EXAMPLE := ["base", "drum", "tall", "drum", "capital"]

@export var length := 2.2
@export var width := 1.0
@export var top := 0.85
@export var snap := 0.08

var parts: Array = []        ## [{body: RigidBody3D, kind, h}]
var support := {}            ## body -> the body it stands on (absent: the table, or loose)
var holding: RigidBody3D = null
var carried: Array = []      ## [{body, rel: Transform3D}] - the stack riding on the held part
var _plaster: StandardMaterial3D

func apply_grid_config(config: Dictionary) -> void:
	for key in ["length", "width", "top", "snap"]:
		if config.has(key) and str(config[key]).is_valid_float():set(key, float(str(config[key])))

func _ready() -> void:
	var cfg := {}
	for key in ["length", "width", "top", "snap"]:
		if has_meta("config_" + key):cfg[key] = get_meta("config_" + key)
	apply_grid_config(cfg)
	_build_table()
	_plaster = StandardMaterial3D.new();_plaster.albedo_color = Color("eeebe4");_plaster.roughness = .85
	if not ResourceLoader.exists(PICKABLE):
		push_warning("FORM_TABLE: no XR Tools pickable");return
	# the loose parts in two rows, then the example column at the table's +x end
	var row := 8
	for i in LOOSE.size():
		var x := -length * .5 + .18 + (i % row) * (length - .6) / float(row - 1)
		var z := -.2 if i < row else .2
		_make(LOOSE[i], Vector3(x, top, z))
	var at := Vector3(length * .5 - .16, top, 0)
	var below: RigidBody3D = null
	for kind in EXAMPLE:
		var b := _make(kind, at)
		if below != null:support[b] = below
		at.y += float(KINDS[kind].h);below = b
	var l := Label3D.new();l.name = "Words";l.text = "STACK THEM: A PART SNAPS ONTO ANOTHER'S TOP\nLIFT ONE AND WHAT STANDS ON IT COMES ALONG"
	l.font_size = 32;l.pixel_size = .0013;l.modulate = Color("2b2d30");l.outline_size = 0
	l.position = Vector3(0, top - .07, width * .5 + .006);add_child(l)

func _build_table() -> void:
	var wood := StandardMaterial3D.new();wood.albedo_color = Color("d9cfbf");wood.roughness = .7
	var body := StaticBody3D.new();body.name = "Table";add_child(body)
	_block(body, "Top", Vector3(length, .05, width), Vector3(0, top - .025, 0), wood)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_block(body, "Leg", Vector3(.06, top - .05, .06), Vector3(sx * (length * .5 - .08), (top - .05) * .5, sz * (width * .5 - .08)), wood)

func _block(body: StaticBody3D, n: String, s: Vector3, at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new();mi.name = n;var bm := BoxMesh.new();bm.size = s;mi.mesh = bm;mi.material_override = mat;mi.position = at;add_child(mi)
	var cs := CollisionShape3D.new();cs.name = n + "Shape";var bs := BoxShape3D.new();bs.size = s;cs.shape = bs;cs.position = at;body.add_child(cs)

## One part: a pickable whose origin is its foot's centre, standing frozen where it is put.
func _make(kind: String, at: Vector3) -> RigidBody3D:
	var k: Dictionary = KINDS[kind]
	var h: float = k.h
	var pk: RigidBody3D = (load(PICKABLE) as PackedScene).instantiate()
	for c in pk.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape == null:c.free()
	pk.name = "%s%02d" % [kind.capitalize(), parts.size()]
	pk.mass = .4
	var mi := MeshInstance3D.new();mi.name = "Form";mi.position.y = h * .5;mi.material_override = _plaster
	var cs := CollisionShape3D.new();cs.name = "Shape";cs.position.y = h * .5
	if bool(k.get("square", false)):
		var bm := BoxMesh.new();bm.size = Vector3(k.r0 * 2.0, h, k.r0 * 2.0);mi.mesh = bm
		var bs := BoxShape3D.new();bs.size = bm.size;cs.shape = bs
	else:
		var cm := CylinderMesh.new();cm.bottom_radius = k.r0;cm.top_radius = maxf(float(k.r1), .002);cm.height = h;cm.radial_segments = 28;mi.mesh = cm
		if is_equal_approx(float(k.r0), float(k.r1)):
			var cy := CylinderShape3D.new();cy.radius = k.r0;cy.height = h;cs.shape = cy
		else:
			var pts := PackedVector3Array()
			for i in 12:
				var a := TAU * i / 12.0
				pts.append(Vector3(cos(a) * float(k.r0), -h * .5, sin(a) * float(k.r0)));pts.append(Vector3(cos(a) * maxf(float(k.r1), .004), h * .5, sin(a) * maxf(float(k.r1), .004)))
			var cv := ConvexPolygonShape3D.new();cv.points = pts;cs.shape = cv
	pk.add_child(mi);pk.add_child(cs)
	pk.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;pk.freeze = true
	add_child(pk);pk.position = at
	pk.set_meta("form_kind", kind);pk.set_meta("form_h", h)
	pk.picked_up.connect(func(_p): _on_picked(pk))
	pk.dropped.connect(func(_p): _settle.call_deferred(pk))   # after XR Tools' own let_go has set the body free
	parts.append({"body": pk, "kind": kind, "h": h})
	return pk

func part_h(b: RigidBody3D) -> float:
	return float(b.get_meta("form_h", 0.0))

## A part's top centre in the world, if it stands upright (a fallen part is no support).
func top_of(b: RigidBody3D) -> Variant:
	if b.global_basis.y.normalized().dot(Vector3.UP) < .98:return null
	return b.global_transform * Vector3(0, part_h(b), 0)

## Everything standing on b, and on those, and so on.
func stack_above(b: RigidBody3D) -> Array:
	var out: Array = []
	var frontier: Array = [b]
	while not frontier.is_empty():
		var under: RigidBody3D = frontier.pop_back()
		for p in parts:
			var body: RigidBody3D = p.body
			if support.get(body) == under and not body in out:out.append(body);frontier.append(body)
	return out

func _on_picked(pk: RigidBody3D) -> void:
	support.erase(pk)
	holding = pk
	carried.clear()
	for b in stack_above(pk):
		(b as RigidBody3D).freeze = true
		carried.append({"body": b, "rel": pk.global_transform.affine_inverse() * (b as Node3D).global_transform})

func _physics_process(_delta: float) -> void:
	if holding == null or not is_instance_valid(holding):return
	for c in carried:(c.body as Node3D).global_transform = holding.global_transform * (c.rel as Transform3D)

## Let go: onto the nearest top within `snap` (foot to top centre, across) and a hand's height (up and down), upright,
## centred; else standing on the table where it is over it; else free to fall. The stack it carried rides along.
func _settle(pk: RigidBody3D) -> void:
	if not is_instance_valid(pk):return
	var foot := pk.global_position
	var riders: Array = carried.map(func(c): return c.body)
	var best: RigidBody3D = null
	var best_d := INF
	for p in parts:
		var b: RigidBody3D = p.body
		if b == pk or b in riders:continue
		var t = top_of(b)
		if t == null:continue
		var across := Vector2(foot.x - (t as Vector3).x, foot.z - (t as Vector3).z).length()
		var rise := absf(foot.y - (t as Vector3).y)
		if across < snap and rise < .14 and across + rise < best_d:best = b;best_d = across + rise
	var x := pk.global_basis.x
	var upright := Basis(Vector3.UP, atan2(-x.z, x.x))
	var lp := to_local(foot)
	var over_table := absf(lp.x) < length * .5 - .02 and absf(lp.z) < width * .5 - .02 and lp.y > top - .25 and lp.y < top + .35
	if best != null:
		pk.global_transform = Transform3D(upright, top_of(best));support[pk] = best
		_hold_still(pk)
	elif over_table:
		pk.global_transform = Transform3D(upright, to_global(Vector3(lp.x, top, lp.z)));support.erase(pk)
		_hold_still(pk)
	else:
		support.erase(pk);pk.freeze = false   # it falls, and the stack it carried falls with it
		for c in carried:support.erase(c.body);(c.body as RigidBody3D).freeze = false
	if best != null or over_table:
		for c in carried:(c.body as Node3D).global_transform = pk.global_transform * (c.rel as Transform3D)
	holding = null;carried.clear()

func _hold_still(pk: RigidBody3D) -> void:
	pk.linear_velocity = Vector3.ZERO;pk.angular_velocity = Vector3.ZERO
	pk.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;pk.freeze = true
	PhysicsServer3D.body_set_state(pk.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, pk.global_transform)
