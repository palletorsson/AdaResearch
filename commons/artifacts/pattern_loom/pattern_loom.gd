extends Node3D
class_name PatternLoom

# @identity
# essence: a sci-fi loom that manufactures wallpaper. The 17 wallpaper groups
#          stop being a flat sample on a plate and become OUTPUT — a carpet woven
#          on glowing warp threads and fed continuously out of the machine, the
#          symmetry group scrolling past like fabric off a mill.
# desire: to show that a pattern is produced, not given. A plate says "here is
#         p6m"; a loom says "watch p6m being made, metre after metre, by a rule."
# critical_parameter: loom_style — roller | warp | mirror. Same wallpaper engine,
#         three machines: a press that rolls carpet onto the floor, an upright
#         tapestry loom that drops a banner, a mirror-loom that weaves the pattern
#         against its own reflection.
# triggers: _ready renders the wallpaper image via PatternSim, dresses the chosen
#           machine, hangs the textured cloth; _process scrolls the weave + pulses
#           the warp glow so the thing is always producing.
# emerges: the same federated move as the assembler — reuse the grammar's
#          render_to_image, wrap it in an apparatus. The loom is a body for a rule.
# needs: a dark machine frame with emissive accents [present]; glowing warp
#        threads + a weave bar [present]; a wallpaper-textured cloth that scrolls
#        out of the weave line [present]; DNA for group/palette/seed/style [present]
# relationships: sibling to primitive_assembler & conveyor_belt (machines that
#        output the algorithm); re-bodies pattern_maker_station / pattern_tile_plate
#        (those edit the carpet; this manufactures it); draws machine vocabulary
#        from props-dna-gallery (autoclave, cable tray, electrical panel)
# truth: every textile in history was a loom's output before it was a floor. The
#        wallpaper group is the program; the loom is the press that runs it.

const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")

# ── DNA ────────────────────────────────────────────────────────────────
## Wallpaper symmetry group (p1..p6m).
@export var group: String = "p4m"
## Palette name (bauhaus, escher, alhambra, tatami, pastel, memphis, persian, monochrome).
@export var palette: String = "alhambra"
## Motif seed — two digits of DNA decide the whole tiling.
@export var motif_seed: int = 7
## Machine form: roller | warp | mirror.
@export var loom_style: String = "roller"
## Fill density of the source motif.
@export var density: float = 0.55

@export_group("Machine")
@export var frame_color: Color = Color(0.12, 0.12, 0.15)
@export var accent_color: Color = Color(0.30, 0.85, 0.95)   # cyan sci-fi accent
@export var warp_color: Color = Color(0.45, 0.95, 1.0)
@export var carpet_width: float = 1.2
@export var carpet_length: float = 2.6
@export var scroll_speed: float = 0.16

# ── Runtime ────────────────────────────────────────────────────────────
var _carpet_tex: ImageTexture
var _carpet_mat: StandardMaterial3D
var _scroll_axis: int = 1          # which uv axis the cloth feeds along (0=x,1=y)
var _weave_mats: Array[StandardMaterial3D] = []
var _warp_mats: Array[StandardMaterial3D] = []
var _spinners: Array = []          # [{node, axis, speed}] — drum/roller/disc rotation
var _elapsed: float = 0.0


func _ready() -> void:
	_read_overrides()
	_gen_texture()
	match loom_style:
		"warp":     _build_warp()
		"mirror":   _build_mirror()
		"drum":     _build_drum()
		"bolt":     _build_bolt()
		"fountain": _build_fountain()
		_:          _build_roller()


func apply_grid_config(cfg: Dictionary) -> void:
	if cfg.has("group"): group = str(cfg["group"])
	if cfg.has("palette"): palette = str(cfg["palette"])
	if cfg.has("motif_seed"): motif_seed = int(cfg["motif_seed"])
	if cfg.has("loom_style"): loom_style = str(cfg["loom_style"])
	if cfg.has("density"): density = float(cfg["density"])
	for c in get_children(): c.queue_free()
	_weave_mats.clear(); _warp_mats.clear(); _spinners.clear()
	call_deferred("_ready")


func _read_overrides() -> void:
	for k in ["group", "palette", "loom_style"]:
		if has_meta("config_%s" % k): set(k, str(get_meta("config_%s" % k)))
	if has_meta("config_motif_seed"): motif_seed = int(str(get_meta("config_motif_seed")))


# ── Wallpaper texture ──────────────────────────────────────────────────

func _gen_texture() -> void:
	var cfg := {
		"group": group, "palette": palette, "motif_seed": motif_seed,
		"tile_size": 16, "canvas_size": 256, "density": density,
	}
	var img: Image = PatternSim.render_to_image(cfg)
	_carpet_tex = ImageTexture.create_from_image(img)


func _make_carpet_material(rep_x: float, rep_y: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _carpet_tex
	m.uv1_scale = Vector3(rep_x, rep_y, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST   # crisp tiles
	m.cull_mode = BaseMaterial3D.CULL_DISABLED                 # cloth visible from both sides
	m.roughness = 0.85
	m.metallic = 0.0
	return m


# ── Style: roller (carpet rolls onto the floor) ────────────────────────

func _build_roller() -> void:
	_scroll_axis = 1
	# Back frame: two posts + top crossbar holding the feed roller.
	var w := carpet_width * 0.5 + 0.18
	_box(Vector3(0.08, 1.2, 0.08), Vector3(-w, 0.6, 0), frame_color)
	_box(Vector3(0.08, 1.2, 0.08), Vector3(w, 0.6, 0), frame_color)
	_box(Vector3(w * 2.0 + 0.08, 0.09, 0.12), Vector3(0, 1.18, 0), frame_color)
	_emissive_box(Vector3(w * 2.0, 0.02, 0.02), Vector3(0, 1.0, 0.07), accent_color, 1.6)

	# Feed roller — the carpet emerges over it.
	var roller := _cyl(carpet_width + 0.16, 0.09, Vector3(0, 1.0, 0.12), frame_color.lightened(0.1))
	roller.rotation_degrees = Vector3(0, 0, 90)

	# Warp threads (vertical, behind the roller) — the loom reading.
	_warp_threads(Vector3(0, 0.18, -0.02), 1.0, carpet_width, 13)
	# Glowing weave bar at the feed line.
	_weave_bar(Vector3(0, 1.0, 0.12), carpet_width + 0.1, 0)

	# Carpet: drops from the roller and runs forward across the floor.
	var carpet := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width, carpet_length)
	pm.subdivide_depth = 1
	carpet.mesh = pm
	carpet.position = Vector3(0, 0.01, 0.12 + carpet_length * 0.5)
	_carpet_mat = _make_carpet_material(2.0, carpet_length / carpet_width * 2.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


# ── Style: warp (upright tapestry loom, banner drops) ──────────────────

func _build_warp() -> void:
	_scroll_axis = 1
	var w := carpet_width * 0.5 + 0.16
	var top := carpet_length + 0.4
	_box(Vector3(0.09, top, 0.09), Vector3(-w, top * 0.5, 0), frame_color)
	_box(Vector3(0.09, top, 0.09), Vector3(w, top * 0.5, 0), frame_color)
	_box(Vector3(w * 2.0 + 0.09, 0.1, 0.13), Vector3(0, top, 0), frame_color)
	_emissive_box(Vector3(w * 2.0, 0.02, 0.02), Vector3(0, top - 0.05, 0.07), accent_color, 1.6)

	# Top beam roller.
	var roller := _cyl(carpet_width + 0.14, 0.08, Vector3(0, top - 0.12, 0.0), frame_color.lightened(0.1))
	roller.rotation_degrees = Vector3(0, 0, 90)

	# Vertical warp threads down the full frame.
	_warp_threads(Vector3(0, 0.1, -0.04), top - 0.2, carpet_width, 15)
	# Weave bar partway down (the active shed).
	_weave_bar(Vector3(0, top - 0.12, 0.04), carpet_width + 0.08, 0)

	# The banner: hangs vertically from the top roller.
	var carpet := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width, carpet_length)
	carpet.mesh = pm
	carpet.rotation_degrees = Vector3(-90, 0, 0)             # stand it up facing +Z
	carpet.position = Vector3(0, top - 0.12 - carpet_length * 0.5, 0.04)
	_carpet_mat = _make_carpet_material(2.0, carpet_length / carpet_width * 2.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


# ── Style: mirror (twin panels woven against a reflection) ─────────────

func _build_mirror() -> void:
	_scroll_axis = 0
	var h := carpet_length * 0.6
	var pw := carpet_width
	# Frame.
	_box(Vector3(0.08, h + 0.2, 0.08), Vector3(-pw - 0.05, (h + 0.2) * 0.5, 0), frame_color)
	_box(Vector3(0.08, h + 0.2, 0.08), Vector3(pw + 0.05, (h + 0.2) * 0.5, 0), frame_color)
	_box(Vector3((pw + 0.05) * 2.0, 0.09, 0.1), Vector3(0, h + 0.2, 0), frame_color)
	# Central glowing seam — the mirror axis.
	_emissive_box(Vector3(0.03, h + 0.1, 0.06), Vector3(0, (h + 0.2) * 0.5, 0.03), accent_color, 2.2)
	_weave_bar(Vector3(0, h + 0.16, 0.04), (pw + 0.05) * 2.0, 0)

	# Two panels, the right one mirrored on X.
	for side in [-1.0, 1.0]:
		var panel := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(pw, h)
		panel.mesh = pm
		panel.rotation_degrees = Vector3(-90, 0, 0)
		panel.position = Vector3(side * (pw * 0.5 + 0.02), (h + 0.2) * 0.5, 0.02)
		var mat := _make_carpet_material(1.0, h / pw * 1.0)
		if side > 0.0:
			mat.uv1_scale = Vector3(-1.0, mat.uv1_scale.y, 1.0)   # reflect
		panel.material_override = mat
		if side < 0.0:
			_carpet_mat = mat       # scroll the left one (right tracks via shared feel)
		add_child(panel)


# ── Shared machine parts ───────────────────────────────────────────────

func _warp_threads(base: Vector3, height: float, span: float, count: int) -> void:
	for i in range(count):
		var t := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.004; cm.bottom_radius = 0.004; cm.height = height
		cm.radial_segments = 6
		t.mesh = cm
		var x := lerpf(-span * 0.5, span * 0.5, float(i) / float(maxi(1, count - 1)))
		t.position = base + Vector3(x, height * 0.5, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = warp_color
		m.emission_enabled = true; m.emission = warp_color
		m.emission_energy_multiplier = 0.9
		t.material_override = m
		_warp_mats.append(m)
		add_child(t)


func _weave_bar(pos: Vector3, length: float, axis: int) -> void:
	var bar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.025; cm.bottom_radius = 0.025; cm.height = length
	cm.radial_segments = 12
	bar.mesh = cm
	bar.rotation_degrees = Vector3(0, 0, 90)
	bar.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = accent_color
	m.emission_enabled = true; m.emission = accent_color
	m.emission_energy_multiplier = 2.0
	bar.material_override = m
	_weave_mats.append(m)
	add_child(bar)


func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.roughness = 0.5; m.metallic = 0.35
	mi.material_override = m
	add_child(mi)
	return mi


func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mi := _box(size, pos, color)
	var m: StandardMaterial3D = mi.material_override
	m.emission_enabled = true; m.emission = color
	m.emission_energy_multiplier = energy
	return mi


func _cyl(height: float, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius; cm.bottom_radius = radius; cm.height = height
	cm.radial_segments = 20
	mi.mesh = cm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.metallic = 0.6; m.roughness = 0.35
	mi.material_override = m
	add_child(mi)
	return mi


# ── Style: drum (rotary press — carpet feeds off a spinning print drum) ─

func _build_drum() -> void:
	_scroll_axis = 1
	var w := carpet_width * 0.5 + 0.22
	_box(Vector3(0.12, 1.15, 0.12), Vector3(-w, 0.575, 0), frame_color)
	_box(Vector3(0.12, 1.15, 0.12), Vector3(w, 0.575, 0), frame_color)
	_box(Vector3(w * 2.0 + 0.12, 0.09, 0.55), Vector3(0, 1.1, 0), frame_color)
	_emissive_box(Vector3(w * 2.0, 0.02, 0.02), Vector3(0, 1.02, 0.28), accent_color, 1.6)
	# Big print drum — the wallpaper wraps it; it spins on its X axle.
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.78, 0)
	add_child(pivot)
	var drum := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.42; dm.bottom_radius = 0.42; dm.height = carpet_width
	dm.radial_segments = 44
	drum.mesh = dm
	drum.rotation_degrees = Vector3(0, 0, 90)
	var drum_mat := _make_carpet_material(1.0, 3.0)
	drum.material_override = drum_mat
	pivot.add_child(drum)
	_spinners.append({"node": pivot, "axis": Vector3.RIGHT, "speed": 0.8})
	# End caps.
	for sx in [-1.0, 1.0]:
		_cyl(0.04, 0.44, Vector3(sx * carpet_width * 0.5, 0.78, 0), frame_color.lightened(0.15)).rotation_degrees = Vector3(0, 0, 90)
	_warp_threads(Vector3(0, 1.0, -0.2), 0.42, carpet_width, 11)
	_weave_bar(Vector3(0, 0.78, 0.42), carpet_width + 0.1, 0)
	# Carpet feeds off the drum front onto the floor.
	var carpet := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(carpet_width, carpet_length)
	carpet.mesh = pm
	carpet.position = Vector3(0, 0.01, 0.42 + carpet_length * 0.5)
	_carpet_mat = _make_carpet_material(2.0, carpet_length / carpet_width * 2.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


# ── Style: bolt (wall dispenser — a bolt of wallpaper unrolls down) ─────

func _build_bolt() -> void:
	_scroll_axis = 1
	var w := carpet_width * 0.5 + 0.16
	var top := carpet_length + 0.55
	# Header mounting plate (behind the roller only) + brackets + top supply roller.
	_box(Vector3(carpet_width + 0.5, 0.42, 0.08), Vector3(0, top - 0.12, -0.16), frame_color.darkened(0.2))
	_box(Vector3(0.1, 0.34, 0.34), Vector3(-w, top - 0.12, 0.02), frame_color)
	_box(Vector3(0.1, 0.34, 0.34), Vector3(w, top - 0.12, 0.02), frame_color)
	var roller := _cyl(carpet_width + 0.22, 0.11, Vector3(0, top - 0.12, 0.08), frame_color.lightened(0.1))
	roller.rotation_degrees = Vector3(0, 0, 90)
	_emissive_box(Vector3(carpet_width + 0.22, 0.02, 0.02), Vector3(0, top - 0.26, 0.12), accent_color, 1.6)
	_warp_threads(Vector3(0, top - 0.55, -0.08), 0.32, carpet_width, 9)
	# The bolt: wallpaper hangs down the wall, unrolling (uv scrolls down).
	var sheet := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(carpet_width, carpet_length)
	sheet.mesh = pm
	sheet.rotation_degrees = Vector3(-90, 0, 0)
	sheet.position = Vector3(0, top - 0.12 - carpet_length * 0.5, 0.1)
	_carpet_mat = _make_carpet_material(2.0, carpet_length / carpet_width * 2.0)
	sheet.material_override = _carpet_mat
	add_child(sheet)
	# Weighted cutter bar at the hem.
	_emissive_box(Vector3(carpet_width + 0.12, 0.05, 0.07), Vector3(0, top - 0.12 - carpet_length, 0.12), accent_color, 1.3)


# ── Style: fountain (radial — a round rug spins out of a central spout) ─

func _build_fountain() -> void:
	# Central spout column + glowing head.
	_cyl(1.0, 0.13, Vector3(0, 0.5, 0), frame_color)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.19; sm.height = 0.38
	head.mesh = sm; head.position = Vector3(0, 1.08, 0)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = accent_color
	hmat.emission_enabled = true; hmat.emission = accent_color
	hmat.emission_energy_multiplier = 2.0
	head.material_override = hmat
	add_child(head)
	_weave_mats.append(hmat)
	_warp_threads(Vector3(0, 0.12, 0), 0.92, carpet_width * 0.5, 8)
	# Round carpet on the floor, radiating from centre, slowly turning.
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = carpet_length * 0.6; dm.bottom_radius = carpet_length * 0.6
	dm.height = 0.02; dm.radial_segments = 56
	disc.mesh = dm; disc.position = Vector3(0, 0.01, 0)
	var disc_mat := _make_carpet_material(3.0, 3.0)
	disc.material_override = disc_mat
	add_child(disc)
	_spinners.append({"node": disc, "axis": Vector3.UP, "speed": 0.18})
	# Glowing rim ring.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = carpet_length * 0.58; tm.outer_radius = carpet_length * 0.63
	ring.mesh = tm; ring.position = Vector3(0, 0.02, 0)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = accent_color
	rmat.emission_enabled = true; rmat.emission = accent_color
	rmat.emission_energy_multiplier = 1.4
	ring.material_override = rmat
	add_child(ring)


# ── Animate: the machine is always producing ───────────────────────────

func _process(delta: float) -> void:
	_elapsed += delta
	for s in _spinners:
		(s["node"] as Node3D).rotate(s["axis"], s["speed"] * delta)
	if _carpet_mat:
		var o := _carpet_mat.uv1_offset
		if _scroll_axis == 0:
			o.x = fposmod(o.x + scroll_speed * delta, 1.0)
		else:
			o.y = fposmod(o.y + scroll_speed * delta, 1.0)
		_carpet_mat.uv1_offset = o
	var weave_pulse := 1.6 + 1.2 * (0.5 + 0.5 * sin(_elapsed * 5.0))
	for m in _weave_mats:
		m.emission_energy_multiplier = weave_pulse
	# Warp threads shimmer in a travelling wave.
	for i in range(_warp_mats.size()):
		_warp_mats[i].emission_energy_multiplier = 0.6 + 0.6 * (0.5 + 0.5 * sin(_elapsed * 4.0 - i * 0.5))
