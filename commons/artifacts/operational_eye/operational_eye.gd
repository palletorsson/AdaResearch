extends Node3D

## Operational Eye — the images this world runs on, none of which were made for you.
##
## @identity
## essence: a rack of machine views — cost field, frustum, collision hull, AABB, LOD ramp, and the player as the system holds them
## desire: to stand in front of the pictures the engine actually uses and recognise that none of them were composed
## critical_parameter: channel — which operational view is foregrounded; the others stay on, because a rack with one screen is a diagram and a rack with six is a control room
## triggers: nothing to press. The rack is already running and was running before you arrived
## emerges: the screen second from the left is you — a capsule, a velocity vector, a grounded flag — and it is the least flattering portrait in the building
## needs: nothing external; each view is drawn in the flat false-colour register the engine would use, not illustrated
## relationships: kin to stock_stratum and sturtevant_bench — artifacts whose subject is this project's own machinery. Reads the same ideas the pathfinder and capture rig use daily.
## truth: most images in this world were never made to be looked at. They are how it runs, and you were never the audience.
##
## Farocki's operational images: pictures that are not representations of an object but
## parts of an operation. A cost field is not a picture of a room, it is how a path
## gets chosen. Seeing one framed is trespass, and the flatness is not a style — it is
## what an image looks like when nobody expected a viewer.
##
## So nothing here is prettied. False colour, no perspective, no composition, and the
## labels are the engine's own vocabulary rather than an explanation.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

const VIEWS := ["COST FIELD", "SUBJECT", "FRUSTUM", "COLLISION", "AABB", "LOD"]

## Which view is foregrounded — brought forward on its bracket and lit. The rest keep
## running, because that is what they do.
@export_range(0, 5, 1) var channel: int = 1
@export var cols: int = 3
@export var screen_w: float = 0.42
@export var screen_h: float = 0.30
@export var rack_height: float = 0.92
@export var finish: String = "terminal"
@export var unit_code: String = "OE-01"


func _ready() -> void:
	_build_rack()
	for i in range(VIEWS.size()):
		_build_screen(i)


func _build_rack() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)

	var rows: int = int(ceil(float(VIEWS.size()) / float(maxi(cols, 1))))
	var w: float = float(cols) * (screen_w + 0.06) + 0.10
	var h: float = float(rows) * (screen_h + 0.09) + 0.16

	var shell: StandardMaterial3D = HangarKit.finish_body(finish, pal["body"], 0.12)
	var steel: StandardMaterial3D = HangarKit.worn_metal(pal["body"].lightened(0.10))
	cab.add_child(HangarKit.box(Vector3(0, rack_height + h * 0.5, -0.06),
		Vector3(w, h, 0.09), shell))
	# service posts — the rack is equipment, bolted, not a display case
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(Vector3(sx * (w * 0.5 - 0.03), rack_height * 0.5, -0.06),
			Vector3(0.045, rack_height, 0.06), steel))
	cab.add_child(HangarKit.box(Vector3(0, rack_height + h - 0.02, -0.012),
		Vector3(w * 0.96, 0.006, 0.006), HangarKit.emissive(pal["accent"], 2.0)))
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.09, 0.020),
		pal["accent"].lightened(0.25))
	if code:
		code.position = Vector3(-w * 0.5 + 0.08, rack_height + 0.06, -0.012)
		cab.add_child(code)


func _slot(i: int) -> Vector3:
	var rows: int = int(ceil(float(VIEWS.size()) / float(maxi(cols, 1))))
	var c: int = i % maxi(cols, 1)
	var r: int = i / maxi(cols, 1)
	var w: float = float(cols) * (screen_w + 0.06)
	var x: float = -w * 0.5 + screen_w * 0.5 + 0.03 + float(c) * (screen_w + 0.06)
	var y: float = rack_height + float(rows - 1 - r) * (screen_h + 0.09) + screen_h * 0.5 + 0.10
	return Vector3(x, y, 0.0)


func _build_screen(i: int) -> void:
	var fore: bool = (i == channel)
	var p: Vector3 = _slot(i) + Vector3(0, 0, 0.035 if fore else 0.0)
	var holder := Node3D.new()
	holder.name = "View_" + VIEWS[i].replace(" ", "_")
	holder.position = p
	add_child(holder)

	# the panel: black, non-reflective, no bezel styling. A monitor in a plant room.
	var back := StandardMaterial3D.new()
	back.albedo_color = Color(0.035, 0.038, 0.042)
	back.roughness = 0.95
	holder.add_child(HangarKit.box(Vector3.ZERO, Vector3(screen_w, screen_h, 0.014), back))

	match i:
		0: _draw_cost_field(holder)
		1: _draw_subject(holder)
		2: _draw_frustum(holder)
		3: _draw_collision(holder)
		4: _draw_aabb(holder)
		5: _draw_lod(holder)

	var lbl: MeshInstance3D = HangarKit.stencil(VIEWS[i], Vector2(screen_w * 0.52, 0.017),
		Color(0.55, 0.60, 0.58) if not fore else Color(0.30, 0.95, 0.55))
	if lbl:
		lbl.position = Vector3(-screen_w * 0.22, -screen_h * 0.5 - 0.020, 0.008)
		holder.add_child(lbl)


func _px(host: Node3D, x: float, y: float, w: float, h: float, c: Color, glow: float = 1.0) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = glow
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	host.add_child(HangarKit.box(Vector3(x, y, 0.009), Vector3(w, h, 0.002), m))


## A* cost, false-coloured. Not a picture of the room: the room's walkability, which is
## the only thing the pathfinder has ever seen of it.
func _draw_cost_field(h: Node3D) -> void:
	var nx: int = 11
	var ny: int = 8
	var cw: float = screen_w * 0.86 / float(nx)
	var ch: float = screen_h * 0.78 / float(ny)
	for gx in range(nx):
		for gy in range(ny):
			var d: float = sqrt(pow(float(gx) - 2.0, 2.0) + pow(float(gy) - 5.0, 2.0)) / 9.0
			var blocked: bool = (gx > 4 and gx < 7 and gy > 1 and gy < 6)
			var c: Color = Color(0.10, 0.10, 0.12) if blocked \
				else Color(0.10, 0.35, 0.75).lerp(Color(0.95, 0.85, 0.20), clampf(d, 0.0, 1.0))
			_px(h, -screen_w * 0.43 + cw * (float(gx) + 0.5),
				-screen_h * 0.39 + ch * (float(gy) + 0.5), cw * 0.92, ch * 0.92, c, 0.9)


## YOU. A capsule, a velocity vector, a grounded flag. The least flattering portrait in
## the building and the only one the engine keeps.
func _draw_subject(h: Node3D) -> void:
	_px(h, -0.02, 0.0, 0.055, 0.15, Color(0.25, 0.90, 0.50), 1.3)
	_px(h, -0.02, 0.085, 0.055, 0.055, Color(0.25, 0.90, 0.50), 1.3)
	for i in range(6):
		_px(h, 0.03 + float(i) * 0.017, 0.012, 0.012, 0.006, Color(0.95, 0.55, 0.15), 1.5)
	_px(h, -0.02, -0.085, 0.10, 0.004, Color(0.30, 0.95, 0.55), 1.6)
	_px(h, 0.115, -0.104, 0.020, 0.020, Color(0.30, 0.95, 0.55), 1.8)


func _draw_frustum(h: Node3D) -> void:
	for i in range(9):
		var t: float = float(i) / 8.0
		var half: float = 0.012 + t * 0.115
		_px(h, -0.13 + t * 0.26, 0.0, 0.004, half * 2.0, Color(0.35, 0.70, 0.95), 1.0)
	_px(h, -0.13, 0.0, 0.010, 0.030, Color(0.95, 0.85, 0.20), 1.4)


func _draw_collision(h: Node3D) -> void:
	for pair in [[-0.10, 0.03, 0.085, 0.075], [0.06, -0.04, 0.10, 0.055],
			[0.10, 0.07, 0.055, 0.055]]:
		var x: float = pair[0]
		var y: float = pair[1]
		var w: float = pair[2]
		var hh: float = pair[3]
		var c := Color(0.30, 0.95, 0.55)
		_px(h, x, y + hh * 0.5, w, 0.003, c, 1.2)
		_px(h, x, y - hh * 0.5, w, 0.003, c, 1.2)
		_px(h, x - w * 0.5, y, 0.003, hh, c, 1.2)
		_px(h, x + w * 0.5, y, 0.003, hh, c, 1.2)


## The box the capture rig frames by — the reason a 4 m artifact photographs as a speck.
func _draw_aabb(h: Node3D) -> void:
	var c := Color(0.95, 0.55, 0.15)
	_px(h, 0.0, 0.075, 0.19, 0.003, c, 1.2)
	_px(h, 0.0, -0.075, 0.19, 0.003, c, 1.2)
	_px(h, -0.095, 0.0, 0.003, 0.15, c, 1.2)
	_px(h, 0.095, 0.0, 0.003, 0.15, c, 1.2)
	_px(h, 0.0, 0.0, 0.045, 0.055, Color(0.55, 0.58, 0.62), 0.5)
	for d in [-1.0, 1.0]:
		_px(h, d * 0.095, 0.075, 0.014, 0.014, c, 1.6)


func _draw_lod(h: Node3D) -> void:
	for i in range(5):
		var t: float = float(i) / 4.0
		var s: float = 0.075 - t * 0.052
		_px(h, -0.14 + float(i) * 0.070, 0.0, s, s,
			Color(0.75, 0.35, 0.85).lerp(Color(0.25, 0.25, 0.30), t), 1.0 - t * 0.6)
	_px(h, 0.0, -0.10, 0.28, 0.003, Color(0.55, 0.30, 0.65), 0.8)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("channel"):
		channel = int(config_data["channel"])
	if config_data.has("cols"):
		cols = int(config_data["cols"])
