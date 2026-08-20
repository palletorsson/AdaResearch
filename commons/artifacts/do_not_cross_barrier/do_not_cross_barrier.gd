extends Node3D
class_name DoNotCrossBarrier

## A line you must not cross — REBUILT PROCEDURALLY. No glb, no asset dependency:
## every mesh here is built in _ready(), like the rest of the corpus.
##
## Two FORMS, because the same prohibition has two street bodies:
##
##   tape       two steel posts and a ribbon hung between them. The ribbon is a
##              TRUE CATENARY — a·cosh(x/a), the constant solved by Newton from
##              the span and the sag — because this project's wave 17 published
##              "the catenary that is a parabola" as a defect, and a barrier
##              shipped after that finding does not get to repeat it.
##   sawhorse   the New York police barricade: a straight wooden plank painted
##              NYPD blue on two A-frame legs, the legend stencilled white on
##              both faces. A plank does not sag, so no curve is owed.
##
## The LEGEND IS A PARAMETER now, not baked geometry — the glb version's words
## were frozen in the mesh; here `legend_text` is stencilled at build time, so
## "DO NOT CROSS", "POLICE LINE DO NOT CROSS" or anything else a map wants is a
## config away.
##
## The companion is `walk_this_line_marking` — the same line as INSTRUCTION
## painted on the floor, standing at right angles to this prohibition:
##
##   "Measure is also violence. What doesn't fit the grid is remainder, error,
##    erased. The line inherits this: efficient, relentless, forgetting
##    everything but endpoints."   — Point_Lines/blurb.md

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Which body the prohibition wears.
@export_enum("tape", "sawhorse") var form: String = "sawhorse"
## Metres between the posts (tape) or the plank's length (sawhorse).
@export var span_m: float = 3.2
## The words. Stencilled at build time — an empty string means a bare barrier.
@export var legend_text: String = "DO NOT CROSS"
## Tape only: how far the ribbon's midpoint hangs below its ends, metres.
@export var sag_m: float = 0.18
## Lean the whole barrier off vertical, degrees, as though it has been shoved.
@export var shove_deg: float = 0.0

const POST_H := 0.95           # tape posts: attachment height
const TAPE_W := 0.15           # ribbon height (vertical extent)
const PLANK_H := 0.71          # sawhorse: plank centre height (NYPD barricades run ~28 in)
const PLANK_D := 0.045
const PLANK_FACE := 0.15       # plank board width (vertical) — a board, not a billboard
const NYPD_BLUE := Color(0.13, 0.29, 0.55)
const WOOD_LEG := Color(0.38, 0.30, 0.22)
const STEEL := Color(0.62, 0.64, 0.67)
const TAPE_YELLOW := Color(0.89, 0.65, 0.08)
const INK := Color(0.09, 0.08, 0.07)

var _built: bool = false


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("form"):
		var f: String = str(config_data["form"]).strip_edges().to_lower()
		if f in ["tape", "sawhorse"]:
			form = f
	if config_data.has("span_m"):
		span_m = clampf(float(config_data["span_m"]), 0.8, 8.0)
	if config_data.has("legend_text"):
		legend_text = str(config_data["legend_text"])
	if config_data.has("sag_m"):
		sag_m = clampf(float(config_data["sag_m"]), 0.01, 1.0)
	if config_data.has("shove_deg"):
		shove_deg = float(config_data["shove_deg"])
	if _built:
		_built = false
		_build()


func _build() -> void:
	if _built:
		return
	_built = true
	for child in get_children():
		child.queue_free()
	var mount := Node3D.new()
	mount.name = "Barrier"
	add_child(mount)
	if form == "tape":
		_build_tape(mount)
	else:
		_build_sawhorse(mount)
	mount.rotation_degrees.z = shove_deg


# ── the New York form: straight wood, painted blue ───────────────────────────

func _build_sawhorse(mount: Node3D) -> void:
	var half: float = span_m * 0.5
	var plank_mat := HangarKit.finish_body("terminal", NYPD_BLUE, 0.25)
	var leg_mat := HangarKit.finish_body("terminal", WOOD_LEG, 0.4)

	# The plank: one straight board, its top edge at PLANK_H + half the face.
	mount.add_child(HangarKit.box(Vector3(0, PLANK_H, 0),
		Vector3(span_m, PLANK_FACE, PLANK_D), plank_mat))

	# A-frame legs at each end: two boards meeting at the TOP, feet spread on the
	# floor. The rotation is about each leg's own centre, so the SIGN decides the
	# orientation: with +lean the top swings outward (tops at z ±0.19, feet at
	# ±0.03 — a V, an upside-down trestle, and it shipped that way until Palle
	# met it in the museum). With −lean the top swings inward: tops at z ±0.03
	# under the plank, feet at z ±0.19. An A.
	for side in [-1.0, 1.0]:
		var lx: float = side * (half - 0.12)
		for lean in [-1.0, 1.0]:
			var leg := HangarKit.box(Vector3(0, (PLANK_H - 0.02) * 0.5, 0),
				Vector3(0.07, PLANK_H - 0.02, 0.035), leg_mat)
			leg.position.x = lx
			leg.position.z = lean * 0.11
			leg.rotation_degrees.x = -lean * 14.0
			mount.add_child(leg)
		mount.add_child(HangarKit.box(Vector3(lx, 0.24, 0),
			Vector3(0.07, 0.035, 0.34), leg_mat))

	# The legend, white stencil on BOTH faces — it is a prohibition, not a poster,
	# and a barrier read from behind still has to say so.
	if legend_text.strip_edges() != "":
		for facing in [-1.0, 1.0]:
			var label: MeshInstance3D = HangarKit.stencil(legend_text,
				Vector2(minf(span_m * 0.86, 3.2), PLANK_FACE * 0.62), Color(0.94, 0.95, 0.96))
			if label:
				label.position = Vector3(0, PLANK_H, facing * (PLANK_D * 0.5 + 0.004))
				if facing < 0.0:
					label.rotation_degrees.y = 180.0
				mount.add_child(label)


# ── the tape form: two posts and a TRUE catenary ─────────────────────────────

## Solve the catenary constant `a` for a hang of horizontal half-span h and sag d:
## d = a·(cosh(h/a) − 1). Newton on f(a) = a·cosh(h/a) − a − d, whose derivative
## is f'(a) = cosh(h/a) − (h/a)·sinh(h/a) − 1. Converges in a handful of steps
## from a = h²/(2d) (the parabola's constant — used ONLY as the seed, wave 17).
func _solve_catenary_a(h: float, d: float) -> float:
	var a: float = maxf(h * h / (2.0 * d), 0.05)
	for _i in range(40):
		var u: float = h / a
		var f: float = a * cosh(u) - a - d
		var fp: float = cosh(u) - u * sinh(u) - 1.0
		if absf(fp) < 1e-9:
			break
		var step: float = f / fp
		a -= step
		a = maxf(a, 0.02)
		if absf(step) < 1e-7:
			break
	return a


func _build_tape(mount: Node3D) -> void:
	var half: float = span_m * 0.5
	var post_mat := HangarKit.finish_body("terminal", STEEL, 0.2)
	var base_mat := HangarKit.finish_body("terminal", Color(0.14, 0.145, 0.16), 0.3)

	for side in [-1.0, 1.0]:
		var x: float = side * half
		var base := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.14
		cyl.bottom_radius = 0.19
		cyl.height = 0.05
		base.mesh = cyl
		base.material_override = base_mat
		base.position = Vector3(x, 0.025, 0)
		mount.add_child(base)
		var post := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.021
		pc.bottom_radius = 0.021
		pc.height = POST_H
		post.mesh = pc
		post.material_override = post_mat
		post.position = Vector3(x, 0.05 + POST_H * 0.5, 0)
		mount.add_child(post)

	# The ribbon: a vertical strip extruded along y = a·cosh(x/a) − a·cosh(h/a),
	# so y = 0 at the posts and −sag at the centre. Both faces are built, because
	# a tape is read from both sides and a single-sided strip vanishes from behind.
	var a: float = _solve_catenary_a(half, sag_m)
	var y_end: float = a * cosh(half / a)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = 48
	var top_y: float = 0.05 + POST_H
	var pts: PackedVector2Array = []
	for i in range(steps + 1):
		var x: float = -half + span_m * float(i) / float(steps)
		pts.append(Vector2(x, top_y + a * cosh(x / a) - y_end))
	for i in range(steps):
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var v00 := Vector3(p0.x, p0.y, 0)
		var v01 := Vector3(p0.x, p0.y - TAPE_W, 0)
		var v10 := Vector3(p1.x, p1.y, 0)
		var v11 := Vector3(p1.x, p1.y - TAPE_W, 0)
		for tri in [[v00, v10, v01], [v10, v11, v01]]:
			for v in tri:
				st.set_uv(Vector2((v.x + half) / span_m, (top_y - v.y) / TAPE_W))
				st.add_vertex(v)
		for tri in [[v00, v01, v10], [v10, v01, v11]]:
			for v in tri:
				st.set_uv(Vector2((v.x + half) / span_m, (top_y - v.y) / TAPE_W))
				st.add_vertex(v)
	st.generate_normals()
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = st.commit()
	var tape_mat := StandardMaterial3D.new()
	tape_mat.albedo_color = TAPE_YELLOW
	tape_mat.roughness = 0.55
	ribbon.material_override = tape_mat
	mount.add_child(ribbon)

	# The legend rides the curve: stencil panels placed at quarter points, each
	# rotated to the catenary's local slope (dy/dx = sinh(x/a)) so the words lie
	# ON the tape rather than floating level across it.
	if legend_text.strip_edges() != "":
		for fx in [-0.5, 0.0, 0.5]:
			var x: float = fx * half
			var y: float = top_y + a * cosh(x / a) - y_end
			var slope: float = sinh(x / a)
			for facing in [-1.0, 1.0]:
				var label: MeshInstance3D = HangarKit.stencil(legend_text,
					Vector2(minf(span_m * 0.26, 1.0), TAPE_W * 0.6), INK)
				if label:
					label.position = Vector3(x, y - TAPE_W * 0.5, facing * 0.004)
					label.rotation_degrees.z = -rad_to_deg(atan(slope)) * facing
					if facing < 0.0:
						label.rotation_degrees.y = 180.0
					mount.add_child(label)
