extends Node3D
class_name WeaponCabinet

## THE WALL BOX (2026-08-29, Palle: "make very very nice wall box for it and
## another one for the pink gun", with two photographs: a red IN CASE OF
## EMERGENCY axe cabinet, glass door over black-and-yellow hazard stripes; and a
## black pistol case lined in red velvet, glass door, chrome lock with its key).
##
## A cabinet is a shallow steel box on a wall with a glass door that swings open
## when a hand or the visitor comes close, and one weapon inside, hung the way
## the photographs hang theirs: the sledgehammer diagonally like the axe, the
## gun level like the pistol. The weapon is the registry's own scene, frozen and
## grabbable; taking it leaves the box open and empty, which is the right thing
## for a box to be afterwards.
##
## DNA. `style` is what the box ARGUES — the civic red steel that says break
## the glass, or the black velvet that says this is precious and locked —
## and `weapon` is what it holds. Both photograph: a style is a whole different
## object, a weapon is a whole different silhouette behind the glass.
##
## Local frame: the back panel lies against the wall at z = 0; the door hangs at
## z = -depth; the visitor stands at negative z looking +z into the box.

signal weapon_taken(cabinet: Node3D)

@export_enum("emergency", "velvet") var style: String = "emergency"
@export_enum("none", "pink_gun", "line_sledgehammer") var weapon: String = "none"
@export var label: String = ""             # "" = the style's own line
@export var open_reach_m: float = 0.9      # a hand this close opens the door
@export var door_open_deg: float = 108.0
@export var seed: int = 0                  # the grain on the stripes and the velvet

const WEAPON_SCENES := {
	"pink_gun": "res://commons/artifacts/pink_gun/pink_gun.tscn",
	"line_sledgehammer": "res://commons/artifacts/line_sledgehammer/line_sledgehammer.tscn",
}

var _door: Node3D = null
var _weapon_node: Node3D = null
var _open: bool = false
var _taken: bool = false
var _tween: Tween = null
var _openers: Array = []
var _rescan_t: float = 0.0
var _w: float = 0.5
var _h: float = 1.16
var _d: float = 0.16
var _bar: float = 0.04
var _hinge: float = 1.0        # +1 hinge on the right (the axe cabinet), -1 on the left (the pistol case)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("style"):
		var s := String(config.get("style", "")).to_lower()
		if s in ["emergency", "velvet"]:
			style = s
	if config.has("weapon"):
		var wv := String(config.get("weapon", "")).to_lower()
		if wv in ["none", "pink_gun", "line_sledgehammer"]:
			weapon = wv
	if config.has("label"):
		label = String(config.get("label", ""))
	if config.has("open_reach_m"):
		open_reach_m = maxf(0.2, float(config.get("open_reach_m", 0.9)))
	if config.has("door_open_deg"):
		door_open_deg = clampf(float(config.get("door_open_deg", 108.0)), 20.0, 170.0)
	if config.has("seed"):
		seed = int(config.get("seed", 0))
	if is_inside_tree():
		_build()


func _ready() -> void:
	_build()


func get_weapon_node() -> Node3D:
	return _weapon_node if _weapon_node != null and is_instance_valid(_weapon_node) else null


func is_open() -> bool:
	return _open


# ── the box ──────────────────────────────────────────────────────────────

func _build() -> void:
	for c in get_children():
		c.queue_free()
	_door = null
	_weapon_node = null
	_open = false
	_taken = false
	var velvet: bool = style == "velvet"
	if velvet:
		_w = 0.64; _h = 0.50; _d = 0.14; _bar = 0.045; _hinge = -1.0
	else:
		_w = 0.50; _h = 1.16; _d = 0.16; _bar = 0.04; _hinge = 1.0

	# materials
	var paint := StandardMaterial3D.new()
	if velvet:
		paint.albedo_color = Color(0.05, 0.05, 0.055)
		paint.roughness = 0.5
		paint.metallic = 0.35
	else:
		paint.albedo_color = Color(0.80, 0.05, 0.04)
		paint.roughness = 0.32
		paint.metallic = 0.15
		paint.clearcoat_enabled = true
		paint.clearcoat = 0.6
	var inner := StandardMaterial3D.new()
	inner.albedo_color = Color(0.04, 0.04, 0.045) if velvet else Color(0.55, 0.04, 0.03)
	inner.roughness = 0.7
	var back := StandardMaterial3D.new()
	back.albedo_texture = _velvet_texture(seed) if velvet else _stripes_texture(seed)
	back.roughness = 1.0 if velvet else 0.85
	back.metallic = 0.0
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.85, 0.92, 1.0, 0.16)
	glass.roughness = 0.04
	glass.metallic = 0.05
	glass.specular = 0.8
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var chrome := StandardMaterial3D.new()
	chrome.albedo_color = Color(0.85, 0.85, 0.88)
	chrome.metallic = 1.0
	chrome.roughness = 0.18

	# the body: back panel, four walls, and the lining you see through the glass
	_box(Vector3(_w, _h, 0.012), Vector3(0, 0, 0.006), paint)
	_box(Vector3(_bar, _h, _d), Vector3(-(_w - _bar) * 0.5, 0, -_d * 0.5), paint)
	_box(Vector3(_bar, _h, _d), Vector3((_w - _bar) * 0.5, 0, -_d * 0.5), paint)
	_box(Vector3(_w, _bar, _d), Vector3(0, (_h - _bar) * 0.5, -_d * 0.5), paint)
	_box(Vector3(_w, _bar, _d), Vector3(0, -(_h - _bar) * 0.5, -_d * 0.5), paint)
	var iw: float = _w - 2.0 * _bar
	var ih: float = _h - 2.0 * _bar
	_box(Vector3(0.006, ih, _d - 0.02), Vector3(-(iw * 0.5 - 0.003), 0, -_d * 0.5 + 0.01), inner)
	_box(Vector3(0.006, ih, _d - 0.02), Vector3((iw * 0.5 - 0.003), 0, -_d * 0.5 + 0.01), inner)
	_box(Vector3(iw, 0.006, _d - 0.02), Vector3(0, (ih * 0.5 - 0.003), -_d * 0.5 + 0.01), inner)
	_box(Vector3(iw, 0.006, _d - 0.02), Vector3(0, -(ih * 0.5 - 0.003), -_d * 0.5 + 0.01), inner)
	# the back you look at: a quad with the whole texture, facing the visitor
	var q := QuadMesh.new()
	q.size = Vector2(iw, ih)
	var qm := MeshInstance3D.new()
	qm.mesh = q
	qm.material_override = back
	qm.position = Vector3(0, 0, -0.002)
	qm.rotation_degrees = Vector3(0, 180, 0)
	add_child(qm)
	if velvet:
		# the cushion: a second, slightly smaller field standing proud of the back
		var cq := QuadMesh.new()
		cq.size = Vector2(iw - 0.05, ih - 0.05)
		var cm := MeshInstance3D.new()
		cm.mesh = cq
		cm.material_override = back
		cm.position = Vector3(0, 0, -0.018)
		cm.rotation_degrees = Vector3(0, 180, 0)
		add_child(cm)
		_box(Vector3(iw - 0.05, ih - 0.05, 0.016), Vector3(0, 0, -0.01), back)

	# hinges on the hinge side
	for hy in [-_h / 3.0, _h / 3.0]:
		var hinge := CylinderMesh.new()
		hinge.top_radius = 0.008
		hinge.bottom_radius = 0.008
		hinge.height = 0.04
		var hm := MeshInstance3D.new()
		hm.mesh = hinge
		hm.material_override = chrome
		hm.position = Vector3(_hinge * (_w * 0.5 + 0.007), hy, -_d + 0.02)
		add_child(hm)

	# the door: a frame with a glass pane, hung at the hinge edge
	_door = Node3D.new()
	_door.name = "Door"
	_door.position = Vector3(_hinge * (_w * 0.5 - 0.004), 0, -_d + 0.02)
	add_child(_door)
	var dx: float = -_hinge * _w * 0.5          # the door's centre, from the hinge
	_box(Vector3(_w, _bar, 0.02), Vector3(dx, (_h - _bar) * 0.5, 0), paint, _door)
	_box(Vector3(_w, _bar, 0.02), Vector3(dx, -(_h - _bar) * 0.5, 0), paint, _door)
	_box(Vector3(_bar, _h, 0.02), Vector3(dx - (_w - _bar) * 0.5, 0, 0), paint, _door)
	_box(Vector3(_bar, _h, 0.02), Vector3(dx + (_w - _bar) * 0.5, 0, 0), paint, _door)
	var pane := BoxMesh.new()
	pane.size = Vector3(iw + 0.01, ih + 0.01, 0.006)
	var pm := MeshInstance3D.new()
	pm.mesh = pane
	pm.material_override = glass
	pm.position = Vector3(dx, 0, 0)
	pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_door.add_child(pm)
	# the lock, on the free edge
	var free_x: float = dx - _hinge * (_w * 0.5 - _bar * 0.5)
	if velvet:
		var lock := CylinderMesh.new()
		lock.top_radius = 0.012
		lock.bottom_radius = 0.012
		lock.height = 0.022
		var lm := MeshInstance3D.new()
		lm.mesh = lock
		lm.material_override = chrome
		lm.position = Vector3(free_x, 0, -0.012)
		lm.rotation_degrees = Vector3(90, 0, 0)
		_door.add_child(lm)
		# the key, left in it, hanging from a ring
		var ring := TorusMesh.new()
		ring.inner_radius = 0.009
		ring.outer_radius = 0.013
		var rm := MeshInstance3D.new()
		rm.mesh = ring
		rm.material_override = chrome
		rm.position = Vector3(free_x, -0.022, -0.03)
		_door.add_child(rm)
		_box(Vector3(0.007, 0.034, 0.003), Vector3(free_x, -0.05, -0.03), chrome, _door)
		_box(Vector3(0.012, 0.008, 0.003), Vector3(free_x + 0.004, -0.062, -0.03), chrome, _door)
	else:
		var keyhole := CylinderMesh.new()
		keyhole.top_radius = 0.009
		keyhole.bottom_radius = 0.009
		keyhole.height = 0.006
		var km := MeshInstance3D.new()
		km.mesh = keyhole
		km.material_override = chrome
		km.position = Vector3(free_x, 0, -0.011)
		km.rotation_degrees = Vector3(90, 0, 0)
		_door.add_child(km)
		# the line on the top rail
		var l := Label3D.new()
		l.text = label if label != "" else "IN CASE OF EMERGENCY"
		l.font_size = 64
		l.pixel_size = 0.00042
		l.modulate = Color(0.97, 0.97, 0.97)
		l.outline_size = 0
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector3(dx, (_h - _bar) * 0.5, -0.012)
		l.rotation_degrees = Vector3(0, 180, 0)
		_door.add_child(l)

	# the collider: the box is on a wall at chest height; a visitor meets it
	var body := StaticBody3D.new()
	body.name = "Body"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(_w, _h, _d)
	cs.shape = bs
	cs.position = Vector3(0, 0, -_d * 0.5)
	body.add_child(cs)
	add_child(body)

	_hang_weapon(chrome)


func _box(size: Vector3, at: Vector3, m: Material, parent: Node3D = null) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = m
	mi.position = at
	(parent if parent != null else self).add_child(mi)
	return mi


## The weapon, hung. The registry's own scene, frozen where it hangs, grabbable;
## the inventory adopts it the moment a hand takes it.
func _hang_weapon(chrome: Material) -> void:
	if weapon == "none" or not WEAPON_SCENES.has(weapon):
		return
	var path: String = WEAPON_SCENES[weapon]
	if not ResourceLoader.exists(path):
		push_warning("[cabinet] no scene for %s" % weapon)
		return
	var n: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	if n == null:
		return
	n.name = "Weapon"
	n.set_meta("artifact_lookup_name", weapon)
	n.set_meta("em_cabinet_weapon", true)
	n.set("freeze", true)
	if "snap_to_shelf" in n:
		n.set("snap_to_shelf", false)
	match weapon:
		"pink_gun":
			# level, barrel to the visitor's left, on two chrome pegs
			n.position = Vector3(0.0, -0.01, -_d * 0.5)
			n.rotation_degrees = Vector3(0, 90, 0)
			for px in [-0.07, 0.07]:
				var peg := CylinderMesh.new()
				peg.top_radius = 0.005
				peg.bottom_radius = 0.005
				peg.height = _d * 0.5
				var pm := MeshInstance3D.new()
				pm.mesh = peg
				pm.material_override = chrome
				pm.position = Vector3(px, -0.06, -_d * 0.25)
				pm.rotation_degrees = Vector3(90, 0, 0)
				add_child(pm)
		"line_sledgehammer":
			# diagonal, like the axe: the head up and to the right
			n.position = Vector3(-0.15, -_h * 0.5 + 0.09, -_d * 0.5)
			n.rotation_degrees = Vector3(0, 0, -24)
	add_child(n)
	_weapon_node = n


# ── the door ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _door == null:
		return
	# the weapon was taken: the box stays open, and empty
	if _weapon_node != null and (not is_instance_valid(_weapon_node) or _weapon_node.get_parent() != self):
		_weapon_node = null
		_taken = true
		weapon_taken.emit(self)
		_set_open(true)
	if _taken:
		return
	_rescan_t -= delta
	if _rescan_t <= 0.0:
		_rescan_t = 1.0
		_rescan_openers()
	var front: Vector3 = to_global(Vector3(0, 0, -_d))
	var nearest: float = 1.0e9
	for o_v in _openers:
		if not is_instance_valid(o_v):
			continue
		var o: Node3D = o_v
		var reach: float = open_reach_m
		if o is XRController3D:
			reach = open_reach_m
		else:
			reach = open_reach_m + 0.6            # a body or an eye, not a hand
		var dd: float = o.global_position.distance_to(front) - (reach - open_reach_m)
		nearest = minf(nearest, dd)
	if not _open and nearest <= open_reach_m:
		_set_open(true)
	elif _open and nearest > open_reach_m * 1.9:
		_set_open(false)


func _rescan_openers() -> void:
	_openers.clear()
	if not is_inside_tree():
		return
	var root: Node = get_tree().get_root()
	for c in root.find_children("*", "XRController3D", true, false):
		_openers.append(c)
	for wlk in get_tree().get_nodes_in_group("em_walker"):
		if wlk is Node3D:
			_openers.append(wlk)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam != null:
		_openers.append(cam)


func _set_open(open: bool) -> void:
	if _open == open or _door == null:
		return
	_open = open
	var target: float = -_hinge * deg_to_rad(door_open_deg) if open else 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_door, "rotation:y", target, 0.55 if open else 0.8) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ── the two linings ──────────────────────────────────────────────────────

## Black and yellow at 45 degrees, with grain and a worn edge.
static func _stripes_texture(sd: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd + 7
	var wpx := 128
	var hpx := 256
	var img := Image.create(wpx, hpx, false, Image.FORMAT_RGB8)
	for y in range(hpx):
		for x in range(wpx):
			var band: int = int(floor(float(x + y) / 24.0)) % 2
			var c: Color = Color(0.86, 0.66, 0.12) if band == 0 else Color(0.08, 0.08, 0.085)
			var g: float = (rng.randf() - 0.5) * 0.08
			var ex: float = minf(minf(x, wpx - 1 - x), minf(y, hpx - 1 - y)) / 18.0
			var wear: float = 0.72 + 0.28 * clampf(ex, 0.0, 1.0)
			img.set_pixel(x, y, Color(clampf((c.r + g) * wear, 0, 1), clampf((c.g + g) * wear, 0, 1), clampf((c.b + g * 0.5) * wear, 0, 1)))
	return ImageTexture.create_from_image(img)


## Deep red, lighter where the light would pool at the centre, with a nap.
static func _velvet_texture(sd: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd + 11
	var wpx := 128
	var hpx := 128
	var img := Image.create(wpx, hpx, false, Image.FORMAT_RGB8)
	for y in range(hpx):
		for x in range(wpx):
			var u: float = (float(x) / float(wpx - 1)) * 2.0 - 1.0
			var v: float = (float(y) / float(hpx - 1)) * 2.0 - 1.0
			var r2: float = u * u + v * v
			var lift: float = 0.14 * (1.0 - clampf(r2, 0.0, 1.0))
			var nap: float = (rng.randf() - 0.5) * 0.035
			img.set_pixel(x, y, Color(clampf(0.52 + lift + nap, 0, 1), clampf(0.03 + lift * 0.15 + nap * 0.3, 0, 1), clampf(0.06 + lift * 0.2 + nap * 0.3, 0, 1)))
	return ImageTexture.create_from_image(img)
