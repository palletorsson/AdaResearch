extends Node3D

## Default Body Bay — a figure in the engine's own default state, and the cost of
## leaving it there.
##
## @identity
## essence: defaults_applied(0..5) -> each click adds one unmarked convention to a body, and retires an equal amount of the blue that admitted nothing had been decided
## desire: to watch neutrality get used up, and to see that what replaces it was chosen by someone who is not in the room
## critical_parameter: defaults_applied — how many conventions have been accepted. At 0 the figure is grey, capsule-collidered and honest; at 5 it looks finished and nothing about it was decided here.
## triggers: the dial; each step stencils the arriving default with its provenance on the bay wall
## emerges: the blue is the only surface that was ever telling the truth, and it is the one that disappears
## needs: nothing external — the figure is procedural, because a figure loaded from an asset library would already be the argument's conclusion
## relationships: the bias thesis of the grant made standable; kin to bias_visualizer (that one shows bias in a model, this one shows it in a body)
## truth: there is no default body. There is a body someone chose, and then stopped labelling.
##
## Chroma-key blue is the colour of the not-yet-decided: it exists to be replaced and
## it announces that it exists to be replaced. Every other surface in a 3D pipeline
## lies about this — a grey "neutral" material, a "default" skin tone, a "standard"
## rig — each of them a decision wearing the costume of an absence.
##
## So the bay is honest at 0 and dishonest at 5, and it looks BETTER at 5. That is the
## uncomfortable part and it must not be softened: the finished-looking body is the one
## whose choices have all gone unlabelled.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# Chroma BLUE, not the green. Both are "replace me" surfaces, but the blue is the one
# this argument descends from, and the identity block above says blue — a colour
# constant quietly disagreeing with its own documentation is the exact defect the
# bench next door exists to catch.
const CHROMA := Color(0.02, 0.29, 0.78)
const DEFAULTS := [
	{"name": "SKIN TONE", "from": "engine default albedo 0.8,0.8,0.8",
		"color": Color(0.78, 0.62, 0.50)},
	{"name": "PROPORTION", "from": "8-head canon, asset-store humanoid",
		"color": Color(0.74, 0.60, 0.49)},
	{"name": "RIG", "from": "Mixamo bone names, T-pose bind",
		"color": Color(0.70, 0.58, 0.48)},
	{"name": "IDLE", "from": "breathing loop, 24fps, uncredited",
		"color": Color(0.68, 0.56, 0.47)},
	{"name": "FINISH", "from": "subsurface preset 'Human Skin'",
		"color": Color(0.80, 0.66, 0.56)},
]

## How many conventions have been accepted, 0..5.
@export_range(0, 5, 1) var defaults_applied: int = 0
@export var bay_width: float = 1.5
@export var bay_height: float = 1.9
@export var finish: String = "terminal"
@export var unit_code: String = "DB-01"

var _n: int = 0


func _ready() -> void:
	_n = clampi(defaults_applied, 0, DEFAULTS.size())
	_build_bay()
	_build_figure()
	_build_dial()


# ── the bay ──────────────────────────────────────────────────────────────────

func _build_bay() -> void:
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)

	# THE BLUE RECEDES. At 0 defaults the bay is fully chroma; each accepted convention
	# retires a fifth of it to plain studio grey. The room fills in as the honesty runs
	# out, and the two are the same motion.
	var t: float = float(_n) / float(DEFAULTS.size())
	var wall_col: Color = CHROMA.lerp(Color(0.62, 0.61, 0.58), t)
	var wall := StandardMaterial3D.new()
	wall.albedo_color = wall_col
	wall.roughness = 0.98
	wall.metallic = 0.0

	var w: float = bay_width
	var h: float = bay_height
	var d: float = bay_width * 0.8
	cab.add_child(HangarKit.box(Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, 0.05), wall))
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(Vector3(sx * w * 0.5, h * 0.5, 0),
			Vector3(0.05, h, d), wall))
	cab.add_child(HangarKit.box(Vector3(0, 0.02, 0), Vector3(w, 0.04, d), wall))

	# The provenance of every accepted default, stencilled on the back wall. A default
	# with its source written on it has stopped being a default.
	for i in range(_n):
		var e: Dictionary = DEFAULTS[i]
		var line: MeshInstance3D = HangarKit.stencil(
			"%s  <- %s" % [str(e["name"]), str(e["from"])],
			Vector2(w * 0.86, 0.026), Color(0.94, 0.94, 0.92))
		if line:
			line.position = Vector3(0, h - 0.22 - float(i) * 0.115, -d * 0.5 + 0.03)
			cab.add_child(line)

	var sign: MeshInstance3D = HangarKit.stencil(
		"BAY · NOTHING HAS BEEN DECIDED HERE YET" if _n == 0
			else "BAY · %d OF %d DECIDED ELSEWHERE" % [_n, DEFAULTS.size()],
		Vector2(w * 0.80, 0.028), Color(0.96, 0.96, 0.94))
	if sign:
		sign.position = Vector3(0, h - 0.09, -d * 0.5 + 0.03)
		cab.add_child(sign)


# ── the figure ───────────────────────────────────────────────────────────────

func _build_figure() -> void:
	var fig := Node3D.new()
	fig.name = "Figure"
	fig.position = Vector3(0, 0.04, 0)
	add_child(fig)

	# At zero, the engine default: flat grey, and the collider showing. A capsule with
	# its collision visible is the most honest a body gets in this medium.
	var skin := StandardMaterial3D.new()
	if _n == 0:
		skin.albedo_color = Color(0.80, 0.80, 0.80)
		skin.roughness = 0.85
	else:
		var e: Dictionary = DEFAULTS[mini(_n - 1, DEFAULTS.size() - 1)]
		skin.albedo_color = e["color"]
		skin.roughness = lerpf(0.85, 0.42, float(_n) / float(DEFAULTS.size()))

	# PROPORTION is default #2: before it lands the figure is a blunt capsule; after,
	# it takes the eight-head canon nobody in this room chose.
	var proportioned: bool = _n >= 2
	var head_r: float = 0.10 if proportioned else 0.13
	var torso_h: float = 0.62 if proportioned else 0.54
	var leg_h: float = 0.72 if proportioned else 0.56

	fig.add_child(_cap(Vector3(0, leg_h * 0.5, 0), 0.115, leg_h, skin))
	fig.add_child(_cap(Vector3(0, leg_h + torso_h * 0.5, 0), 0.155, torso_h, skin))
	fig.add_child(_ball(Vector3(0, leg_h + torso_h + head_r, 0), head_r, skin))

	# RIG is default #3 — arms only appear in the T-pose the bind demanded.
	if _n >= 3:
		for sx in [-1.0, 1.0]:
			var arm := _cap(Vector3(sx * 0.30, leg_h + torso_h * 0.80, 0), 0.055, 0.46, skin)
			arm.rotation_degrees.z = 90.0 * sx
			fig.add_child(arm)

	if _n == 0:
		# the collider, drawn. It is normally invisible, which is the point.
		var wire := StandardMaterial3D.new()
		wire.albedo_color = Color(0.20, 0.95, 0.55, 0.20)
		wire.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wire.cull_mode = BaseMaterial3D.CULL_DISABLED
		fig.add_child(_cap(Vector3(0, (leg_h + torso_h) * 0.62, 0), 0.30,
			leg_h + torso_h + head_r * 2.0, wire))


func _cap(p: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = maxf(h, r * 2.0 + 0.01)
	mi.mesh = cm
	mi.material_override = m
	mi.position = p
	return mi


func _ball(p: Vector3, r: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.material_override = m
	mi.position = p
	return mi


func _build_dial() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var rail := HangarKit.box(Vector3(0, 0.92, bay_width * 0.40),
		Vector3(0.34, 0.05, 0.10), HangarKit.worn_metal(pal["body"].lightened(0.10)))
	add_child(rail)
	# one detent per default, the accepted ones lit
	for i in range(DEFAULTS.size()):
		var lit: bool = i < _n
		var mat: StandardMaterial3D = HangarKit.emissive(pal["accent"], 2.0) if lit \
			else HangarKit.painted_metal(Color(0.10, 0.10, 0.11), 0.1, 0.4, 0.5)
		add_child(HangarKit.box(
			Vector3(-0.13 + float(i) * 0.065, 0.951, bay_width * 0.40 + 0.03),
			Vector3(0.030, 0.010, 0.030), mat))
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.09, 0.020),
		pal["accent"].lightened(0.25))
	if code:
		code.position = Vector3(0.20, 0.92, bay_width * 0.40 + 0.055)
		add_child(code)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("defaults_applied"):
		defaults_applied = int(config_data["defaults_applied"])
