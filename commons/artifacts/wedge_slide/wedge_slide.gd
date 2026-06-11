extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name WedgeSlide

## @identity
## lineage: the inclined-plane free-body problem made playable — a block on a wedge, the
##   weight split into mg sin θ (down the slope) and mg cos θ (into it), friction opposing —
##   the force-decomposition toy for the embodied vectors-forces arc.
## essence: dial the incline; a primitive sits on the slope while its forces draw themselves
##   in 3D, and the monitor renders the flat free-body section — the textbook triangle with
##   gravity, normal, friction and the two components, live. Tilt past tan θ = μ and it slides.
## truth: a slope doesn't change gravity — it changes how much of gravity points along your
##   path; the whole inclined-plane problem is one vector, resolved into the two that matter.
##
## A ToyConsole: the INCLINE slider sets θ; the demo is the wedge + block + 3D force vectors;
## the monitor is a 2D free-body section sketch. μ is the (fixed) friction coefficient.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var incline: float = 0.5
@export var mu: float = 0.28
@export var wedge_color: Color = Color(0.52, 0.55, 0.60)   # the ramp
@export var block_color: Color = Color(0.45, 0.80, 0.98)   # the primitive
@export var grav_color: Color = Color(0.95, 0.40, 0.38)    # mg (weight)
@export var norm_color: Color = Color(0.45, 0.66, 0.98)    # N (normal)
@export var fric_color: Color = Color(0.98, 0.72, 0.32)    # friction f
@export var net_color: Color = Color(0.55, 0.95, 0.55)     # net down-slope
@export var guide_color: Color = Color(0.58, 0.62, 0.70)   # decomposition / lines

const MIN_DEG := 12.0
const MAX_DEG := 55.0

var _sketch: Node3D


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("incline"): incline = clampf(float(config_data["incline"]), 0.0, 1.0)
	if config_data.has("mu"): mu = clampf(float(config_data["mu"]), 0.0, 1.0)
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	wedge_color = _parse_color(config_data.get("wedge_color", wedge_color), wedge_color)
	block_color = _parse_color(config_data.get("block_color", block_color), block_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "WEDGE SLIDE", "slider": "INCLINE"}

func _param_get() -> float:
	return incline

func _param_set(v: float) -> void:
	incline = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("WedgeSlideRig")
	var theta: float = deg_to_rad(lerpf(MIN_DEG, MAX_DEG, incline))
	var mgs: float = sin(theta)                 # mg sin θ  (mg = 1)
	var mgc: float = cos(theta)                 # mg cos θ
	var n_force: float = mgc                     # normal balances the into-slope part
	var f_max: float = mu * n_force
	var sliding: bool = mgs > f_max + 0.001
	var f_force: float = f_max if sliding else mgs
	var net: float = maxf(mgs - f_force, 0.0)

	_build_3d(rig, theta, n_force, f_force, net, sliding)
	_build_sketch(theta, mgs, mgc, n_force, f_force, net, sliding)

	# compact readout under the section sketch
	set_readout("θ=%d°   μ=%.2f\nmg sinθ=%.2f  mg cosθ=%.2f\nf=%.2f   a=%.2f\n%s"
		% [int(roundf(rad_to_deg(theta))), mu, mgs, mgc, f_force, net, ("▶ SLIDING" if sliding else "· STATIC")],
		net_color.lerp(Color.WHITE, 0.3) if sliding else Color(0.7, 0.78, 0.86))
	_settle(rig)


# ─── 3D demo: the wedge + block + force vectors ──────────────────────────────
func _build_3d(rig: Node3D, theta: float, n_force: float, f_force: float, net: float, sliding: bool) -> void:
	var L := 1.4
	var H: float = L * tan(theta)
	var D := 0.7
	# wedge (right-triangle prism), base on y=0
	var pm := PrismMesh.new()
	pm.size = Vector3(L, H, D)
	pm.left_to_right = 0.0
	var wedge := MeshInstance3D.new()
	wedge.mesh = pm
	wedge.material_override = _solid(wedge_color, 0.7)
	wedge.position = Vector3(0.0, H * 0.5, 0.0)
	rig.add_child(wedge)
	rig.add_child(_box(Vector3(0.0, -0.02, 0.0), Vector3(L + 0.2, 0.04, D + 0.2), _solid(Color(0.18, 0.19, 0.22), 1.0)))  # ground

	# incline frame: TL (top-back) -> BR (bottom-front)
	var tl := Vector3(-L * 0.5, H, 0.0)
	var br := Vector3(L * 0.5, 0.0, 0.0)
	var down: Vector3 = (br - tl).normalized()
	var norm: Vector3 = Vector3(down.y, -down.x, 0.0).normalized() * sign(down.cross(Vector3.FORWARD).y if false else 1.0)
	norm = Vector3(-down.y, down.x, 0.0).normalized()   # out of the slope (up-right)
	if norm.y < 0: norm = -norm

	# the block on the slope
	var p: Vector3 = tl.lerp(br, 0.34)
	var c: Vector3 = p + norm * 0.14
	var block := _box(c, Vector3(0.24, 0.18, 0.34), _glow_mat(block_color, 0.6))
	block.rotation.z = -theta
	rig.add_child(block)

	# force vectors from the block centre
	var s := 0.62
	rig.add_child(_arrow(c, c + Vector3(0, -1.0, 0) * s, 0.026, _glow_mat(grav_color, 1.5)))        # mg (weight)
	rig.add_child(_arrow(c, c + norm * n_force * s, 0.026, _glow_mat(norm_color, 1.5)))             # N
	if f_force > 0.03:
		rig.add_child(_arrow(c, c + (-down) * f_force * s, 0.024, _glow_mat(fric_color, 1.5)))      # friction (up-slope)
	if net > 0.03:
		rig.add_child(_arrow(c, c + down * net * s, 0.03, _glow_mat(net_color, 1.9)))               # net (down-slope)

	# θ arc at the bottom-front corner
	_arc3(rig, br, Vector3.LEFT, (tl - br).normalized(), 0.3, _glow_mat(guide_color, 1.2))


# ─── 2D free-body section sketch on the monitor ──────────────────────────────
func _build_sketch(theta: float, mgs: float, mgc: float, n_force: float, f_force: float, net: float, sliding: bool) -> void:
	if _sketch == null:
		_sketch = Node3D.new()
		_sketch.name = "Section"
		add_child(_sketch)
		# nudge the monitor readout below the screen so it doesn't fight the sketch
		if monitor_label:
			monitor_label.position = Vector3(-0.48, 0.965, 0.115)
			monitor_label.font_size = 22
			monitor_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	for c in _sketch.get_children():
		_sketch.remove_child(c); c.queue_free()

	# wedge triangle: right angle bottom-left, incline TL->BR
	var L := 1.0
	var H: float = L * tan(theta)
	var BL := Vector2.ZERO
	var BR := Vector2(L, 0.0)
	var TL := Vector2(0.0, H)
	var down: Vector2 = (BR - TL).normalized()
	var norm := Vector2(-down.y, down.x); if norm.y < 0: norm = -norm
	var b: Vector2 = TL.lerp(BR, 0.40) + norm * 0.07       # block centre on the slope
	var sg := 0.5

	# auto-fit: scale + centre the whole diagram to the monitor screen each rebuild
	var pts: Array[Vector2] = [BL, BR, TL,
		b + Vector2(0, -1) * sg, b + norm * n_force * sg, b - down * f_force * sg,
		b + down * net * sg, b - norm * mgc * sg]
	var mn: Vector2 = pts[0]; var mx: Vector2 = pts[0]
	for p in pts: mn = mn.min(p); mx = mx.max(p)
	var ctr: Vector2 = (mn + mx) * 0.5
	var sc: float = 0.34 / maxf(maxf(mx.x - mn.x, mx.y - mn.y), 0.01)
	_sketch.transform = Transform3D(Basis().scaled(Vector3.ONE * sc), Vector3(-0.48, 1.17, 0.12) - Vector3(ctr.x, ctr.y, 0.0) * sc)

	var line := _glow_mat(Color(0.90, 0.92, 1.0), 1.0)
	_seg2(BL, BR, 0.016, line)          # base
	_seg2(BL, TL, 0.016, line)          # vertical back
	_seg2(TL, BR, 0.020, _glow_mat(wedge_color.lerp(Color.WHITE, 0.5), 1.2))   # incline
	_quad(b, down * 0.115, norm * 0.10, _glow_mat(block_color, 0.95))

	# the resolved components of the weight (subtle dashed) — mg sinθ along, mg cosθ into
	_seg2_dashed(b, b + down * mgs * sg, 0.007, _glow_mat(guide_color, 0.8))
	_seg2_dashed(b, b - norm * mgc * sg, 0.007, _glow_mat(guide_color, 0.8))
	# the force arrows
	_arr2(b, b + Vector2(0, -1) * sg, 0.011, _glow_mat(grav_color, 1.5))                # mg (weight)
	_arr2(b, b + norm * n_force * sg, 0.011, _glow_mat(norm_color, 1.5))                # N
	if f_force > 0.03:
		_arr2(b, b - down * f_force * sg, 0.010, _glow_mat(fric_color, 1.5))            # friction
	if net > 0.03:
		_arr2(b, b + down * net * sg, 0.013, _glow_mat(net_color, 1.8))                 # net
	# θ arc + the little labels
	_arc2(BR, Vector2.LEFT, (TL - BR).normalized(), 0.11, _glow_mat(Color(0.7, 0.95, 0.7), 1.0))
	_tag("θ", BR + Vector2(-0.16, 0.05), 0.6, Color(0.8, 1.0, 0.8))
	_tag("mg", b + Vector2(0.03, -sg - 0.03), 0.6, grav_color)
	_tag("N", b + norm * n_force * sg + Vector2(0.02, 0.03), 0.6, norm_color)
	if net > 0.03:
		_tag("net", b + down * net * sg + Vector2(0.02, -0.04), 0.55, net_color)


# ─── small 2D sketch helpers (flat geometry on the screen) ───────────────────
func _seg2(a: Vector2, b: Vector2, w: float, mat: Material) -> void:
	var d: Vector2 = b - a
	var box := _box(Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0), Vector3(maxf(d.length(), 0.001), w, 0.003), mat)
	box.rotation.z = atan2(d.y, d.x)
	_sketch.add_child(box)

func _seg2_dashed(a: Vector2, b: Vector2, w: float, mat: Material) -> void:
	var n := 7
	for i in range(n):
		if i % 2 == 1: continue
		_seg2(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), w, mat)

func _arr2(a: Vector2, b: Vector2, w: float, mat: Material) -> void:
	_seg2(a, b, w, mat)
	var d: Vector2 = (b - a).normalized()
	var perp := Vector2(-d.y, d.x)
	var back: Vector2 = b - d * 0.045
	_seg2(b, back + perp * 0.03, w, mat)
	_seg2(b, back - perp * 0.03, w, mat)

func _quad(center: Vector2, ax: Vector2, ay: Vector2, mat: Material) -> void:
	var box := _box(Vector3(center.x, center.y, 0.0), Vector3(ax.length() * 2.0, ay.length() * 2.0, 0.006), mat)
	box.rotation.z = atan2(ax.y, ax.x)
	_sketch.add_child(box)

func _arc2(center: Vector2, va: Vector2, vb: Vector2, radius: float, mat: Material) -> void:
	var a0: float = atan2(va.y, va.x)
	var a1: float = atan2(vb.y, vb.x)
	var steps := 8
	for i in range(steps + 1):
		var a: float = lerpf(a0, a1, float(i) / steps)
		_sketch.add_child(_sphere2(center + Vector2(cos(a), sin(a)) * radius, 0.008, mat))

func _sphere2(p: Vector2, r: float, mat: Material) -> MeshInstance3D:
	return _box(Vector3(p.x, p.y, 0.0), Vector3(r, r, 0.003), mat)

func _tag(text: String, pos: Vector2, scale: float, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 40
	l.pixel_size = 0.0016 * scale
	l.modulate = color
	l.outline_size = 4
	l.position = Vector3(pos.x, pos.y, 0.01)
	_sketch.add_child(l)


# ─── shared bits ─────────────────────────────────────────────────────────────
func _solid(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

func _arc3(parent: Node3D, center: Vector3, va: Vector3, vb: Vector3, radius: float, mat: Material) -> void:
	var axis: Vector3 = va.cross(vb)
	if axis.length() < 0.0001: return
	axis = axis.normalized()
	var total: float = va.angle_to(vb)
	for i in range(9):
		var dir: Vector3 = va.rotated(axis, total * float(i) / 8.0).normalized()
		parent.add_child(_sphere(center + dir * radius, 0.013, mat))
