class_name PointLineRoom
extends Node3D
## THE POINT ROOM (Palle, 2026-11-05: "move the point line example to a large box around the shaft with a floor, fully
## black inside, the measure text on the wall large ... it should be like the point room in the museum but larger";
## then "we should just do the add point together as a making the line" and "like the room pairing_point_field"; and,
## asked where: "turn that box black" - the scaffold workstation's glass bay over shaft A on floor 3).
## A black lining inside the workstation's glass bay - floor, back, sides, ceiling, and a front with a doorway - and in
## it the pairing field at room size: large points hanging in the dark, each lettered. Bring two close and release:
## they join in a line (the snap-point system of pairing_point_field, the same manager and the same points). Move them
## apart and the line follows. The back wall says how long each line is, the newest one large.
## The lining is only SEEN: it adds no body inside the bay but the front wall beside the doorway, so the workstation's
## own BUILD, drop test and quarter-size visit find the bay as they did; the points stay off the bay's middle and off
## the visitor's start. The workstation's glass gate (closed by default: chamber_gate.gd) is opened, so a visitor walks
## in at full size.
##   config: size (m, the bay), height (m), door (m, the doorway's width), points (how many), open_gate
## The origin is the bay's middle on its floor (the workstation's Output); the doorway faces +z, as the gate does.

const Point := preload("res://commons/primitives/snappoint/snap_point.tscn")
const Driver := preload("res://commons/artifacts/primitive_encounters/corridor_point.gd")
const Manager := preload("res://commons/primitives/snappoint/snap_connection_manager.gd")
const LETTERS := "ABCDEFGHJK"
## Where the points hang: round the walls at reach, clear of the bay's middle and of the visitor's start (0, z 2.5).
const SPOTS := [Vector3(-2.3, 1.25, -2.2), Vector3(-1.1, 1.5, -2.55), Vector3(0.1, 1.25, -2.6), Vector3(1.3, 1.5, -2.5),
	Vector3(2.4, 1.3, -2.1), Vector3(-2.65, 1.4, -0.9), Vector3(2.6, 1.35, -0.7), Vector3(2.55, 1.55, 0.6)]

@export var size := 6.6
@export var height := 5.4
@export var door := 1.6
@export var points := 8
@export var open_gate := true

var manager: Node
var balls: Array[Node3D] = []
var measure: Label3D
var gate_opened := false
var _black: StandardMaterial3D

func apply_grid_config(config: Dictionary) -> void:
	for key in ["size", "height", "door"]:
		if config.has(key) and str(config[key]).is_valid_float():set(key, float(str(config[key])))
	if config.has("points") and str(config.points).is_valid_int():points = clampi(int(str(config.points)), 2, SPOTS.size())
	if config.has("open_gate"):open_gate = str(config.open_gate).to_lower() not in ["false", "0", "no"]

func _ready() -> void:
	var cfg := {}
	for key in ["size", "height", "door", "points", "open_gate"]:
		if has_meta("config_" + key):cfg[key] = get_meta("config_" + key)
	apply_grid_config(cfg)
	_build()
	if open_gate:_open_gate.call_deferred()

func _build() -> void:
	_black = StandardMaterial3D.new();_black.albedo_color = Color.BLACK;_black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var h := size * .5 - .03
	var lining := Node3D.new();lining.name = "Lining";add_child(lining)
	_panel(lining, "Floor", Vector3(size - .06, .01, size - .06), Vector3(0, .012, 0))
	_floor_if_absent.call_deferred()
	_panel(lining, "Ceiling", Vector3(size - .06, .01, size - .06), Vector3(0, height - .04, 0))
	_panel(lining, "Back", Vector3(size - .06, height - .05, .01), Vector3(0, (height - .05) * .5, -h))
	for s in [-1.0, 1.0]:
		_panel(lining, "Side", Vector3(.01, height - .05, size - .06), Vector3(s * h, (height - .05) * .5, 0))
	# the front: two leaves beside the doorway and a lintel over it, solid (at the bay's edge, outside its clear 6.4 m)
	var front := StaticBody3D.new();front.name = "Front";add_child(front)
	var leaf := (size - .06 - door) * .5
	var door_h := 2.6
	for s in [-1.0, 1.0]:
		_solid(front, "Leaf", Vector3(leaf, height - .05, .04), Vector3(s * (door + leaf) * .5, (height - .05) * .5, h))
	_solid(front, "Lintel", Vector3(door, height - .05 - door_h, .04), Vector3(0, door_h + (height - .05 - door_h) * .5, h))
	# the points: the pairing field's, larger, light against the black, each with its letter
	manager = Manager.new();manager.name = "SnapConnectionManager";add_child(manager)
	for i in points:
		var p := Point.instantiate() as Node3D;p.set_script(Driver)
		p.name = "Point%s" % LETTERS[i];p.position = SPOTS[i]
		p.snap_distance = .4;p.release_mode = XRToolsPickable.ReleaseMode.FROZEN
		var sphere := SphereShape3D.new();sphere.radius = .1
		p.get_node("CollisionShape3D").shape = sphere
		p.get_node("MeshInstance3D/Sphere").set("radius", .085)
		p.get_node("MeshInstance3D/Sphere").set("color", Color("f1ede4"))
		add_child(p);balls.append(p)
		var tag := Label3D.new();tag.name = "Letter";tag.text = LETTERS[i];tag.font_size = 64;tag.pixel_size = .0024;tag.modulate = Color("f1ede4")
		tag.outline_size = 0;tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED;tag.position = Vector3(0, .2, 0);p.add_child(tag)
	measure = Label3D.new();measure.name = "Measure";measure.font_size = 120;measure.pixel_size = .006;measure.modulate = Color("f1ede4")
	measure.outline_size = 0;measure.width = 900;measure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	measure.position = Vector3(0, 3.1, -h + .03);add_child(measure)
	var hint := Label3D.new();hint.name = "Hint";hint.text = "BRING TWO POINTS CLOSE. RELEASE.\nMOVE THEM APART: THE LINE FOLLOWS."
	hint.font_size = 44;hint.pixel_size = .0022;hint.modulate = Color("b9b4aa");hint.outline_size = 0;hint.rotation_degrees.x = -90
	hint.position = Vector3(0, .03, 1.5);add_child(hint)
	measure.text = _measure_text()

## Palle asked for a box WITH a floor. In the workstation's bay the glass base is that floor (and the workstation's
## drop test and BUILD read it, so no body of ours may lie inside the bay); but the workstation stands only in the
## working tree (Codex's, 2026-11-05), so on a floor without it the room is over the open shaft. Up to 60 frames are
## given for a floor to appear under the room's middle; if none does, the lining's floor becomes solid.
var own_floor := false
func _floor_if_absent() -> void:
	for i in 60:
		if not is_inside_tree():return
		var from := global_transform * Vector3(0, .5, 0)
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * .9, 1))
		if not hit.is_empty():return
		await get_tree().process_frame
	var body := StaticBody3D.new();body.name = "OwnFloor";body.collision_layer = 1;add_child(body)
	var cs := CollisionShape3D.new();var bs := BoxShape3D.new();bs.size = Vector3(size - .06, .03, size - .06);cs.shape = bs;cs.position = Vector3(0, .002, 0);body.add_child(cs)
	own_floor = true

## The workstation's glass gate on the bay's front, opened once it exists (the workstation builds its bay in its own
## _ready, which may come after this one).
func _open_gate() -> void:
	# the floor's own nodes (the Void mounts a work at <floor>/<id>/Artifact), searched every tenth frame for 6 s
	var floor_root: Node = get_parent().get_parent() if get_parent() != null and get_parent().get_parent() != null else get_tree().root
	for i in 36:
		if not is_inside_tree():return
		var front := global_transform * Vector3(0, 0, size * .5)
		for g in floor_root.find_children("EntryGate", "", true, false):
			if (g as Node3D).global_position.distance_to(front) < .6 and g.has_method("open"):
				g.open();gate_opened = true
				return
		for f in 10:await get_tree().process_frame

## Every line between two of the points, its length, the newest first - read from the manager's own graph.
func lines() -> Array:
	var out: Array = []
	if manager == null:return out
	# pair by pair through are_points_connected: the manager's get_connections_for_point returns an untyped Array
	# where it declares Array[Node3D], which Godot refuses at runtime (a SCRIPT ERROR, measured in the tower probe)
	for i in balls.size():
		for j in range(i + 1, balls.size()):
			if manager.are_points_connected(balls[i], balls[j]):
				out.append({"a": LETTERS[i], "b": LETTERS[j], "length": balls[i].global_position.distance_to(balls[j].global_position)})
	return out

var _last := []
func _process(_delta: float) -> void:
	if measure == null:return
	var now := lines()
	var keys := now.map(func(l): return l.a + l.b)
	for k in keys:
		if not k in _last:_last.append(k)   # the newest line goes last
	_last = _last.filter(func(k): return k in keys)
	measure.text = _measure_text(now)

func _measure_text(now: Array = []) -> String:
	if now.is_empty():return "A LINE IS TWO POINTS\nBROUGHT TOGETHER"
	var by := {}
	for l in now:by[l.a + l.b] = l
	var newest: Dictionary = by.get(_last[-1], now[0]) if not _last.is_empty() else now[0]
	var rest := []
	for k in _last:
		if k != newest.a + newest.b and by.has(k):rest.append("%s-%s  %.2f m" % [by[k].a, by[k].b, float(by[k].length)])
	return "%s - %s\n%.2f m" % [newest.a, newest.b, float(newest.length)] + ("\n\n" + "    ".join(PackedStringArray(rest)) if not rest.is_empty() else "")

func _panel(parent: Node3D, n: String, s: Vector3, at: Vector3) -> void:
	var mi := MeshInstance3D.new();mi.name = n;var bm := BoxMesh.new();bm.size = s;mi.mesh = bm;mi.material_override = _black;mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(mi)

func _solid(body: StaticBody3D, n: String, s: Vector3, at: Vector3) -> void:
	_panel(self, n, s, at)
	var cs := CollisionShape3D.new();cs.name = n + "Shape";var bs := BoxShape3D.new();bs.size = s;cs.shape = bs;cs.position = at;body.add_child(cs)
