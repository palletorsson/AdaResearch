extends Node3D
class_name StationWallModule

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: a COMBINABLE wall SEGMENT — one member of a butt-jointed run, 1 m per cell, same
# slab family as [[station_wall]] but each segment carries ONE kind of wall work: a whiteboard,
# a small display, a glass bay, vertical pipe drops, a cable tray with its conduit drop, a
# louvred vent, a hazard chevron band, or the ENDCAP — the special short ending that closes a
# run on purpose. Origin at the floor centre; plane XY facing +Z.
# desire: to give walls a working vocabulary — the Black-Mesa lab read where services run DOWN
# the wall toward the benches and every run ends with a decision, not a cut.
# critical_parameter: kind × length_cells — what work this metre of wall does, and how many
# cells it claims before the next segment takes over.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: whiteboard scribbles read "someone thought here"; a conduit drop reads "power goes
# to that bench"; glass reads "observed, not sealed"; the endcap reads "the wall ends before it
# stops existing" (R-018/R-019 — the ending made visible).
# needs: a slab backplate matching station_wall's depth [present]; per-kind face work [present];
# seeded variation for scribbles/cables [present]; finish + colour DNA [present].
# relationships: the working sibling of [[station_wall]] (that one backs, this one WORKS);
# drops services toward [[station_bench]]/[[station_plinth]]; closed by its own endcap kind;
# ceiling services continue in [[station_ceiling]], floor services in [[station_floor_module]].
# truth: a wall is not a boundary but a chassis — the lab hangs its thinking, its services and
# its endings on it, and each metre admits what it is for.

@export_group("Kind")
## "whiteboard" | "display" | "glass" | "pipes" | "cabletray" | "vent" | "chevron" | "endcap"
@export var kind: String = "whiteboard"

@export_group("Grid")
## Segment width in 1 m cells (endcap ignores this — it is always a short 0.4 m return).
@export var length_cells: int = 1
## Wall height (matches station_wall's default).
@export var height: float = 2.5

@export_group("Surface")
## "rams" (light Braun) | "terminal" (dark charcoal).
@export var finish: String = "rams"
@export var wear: float = 0.08
## Deterministic variation seed (scribbles, cable sag, magnet spots).
@export var seed: int = 1
## Mirror the segment in X (endcap: close the run toward -X instead of +X).
@export var flip: bool = false
@export var stencil_text: String = ""

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const SLAB_DEPTH := 0.15
const FRONT_Z := SLAB_DEPTH * 0.5

var _built := false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_kind"): kind = str(get_meta("config_kind")).to_lower()
	if has_meta("config_length_cells"): length_cells = int(str(get_meta("config_length_cells")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_seed"): seed = int(str(get_meta("config_seed")))
	if has_meta("config_flip"): flip = str(get_meta("config_flip")).to_lower() in ["true", "1", "yes"]
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_term: bool = finish == "terminal"
	var bcol: Color = pal["body"] if is_term else body_color
	var pcol: Color = pal["panel"] if is_term else panel_color
	var acol: Color = pal["accent"] if is_term else accent_color
	var w: float = maxf(float(length_cells), 1.0)
	var h: float = maxf(height, 1.2)
	var body := HangarKit.finish_body(finish, bcol, wear)
	var trim := HangarKit.worn_metal(pcol)

	match kind:
		"endcap":
			_build_endcap(h, body, trim, acol, pcol)
		"glass":
			_build_glass(w, h, trim, pcol, acol)
		_:
			# Slab backplate shared by the face-work kinds — butt-joins station_wall runs.
			add_child(HangarKit.box(Vector3(0, h * 0.5, 0), Vector3(w, h, SLAB_DEPTH), body))
			# R-019 wall_on_floor: base reveal — the slab is SET ONTO the floor, not cut off.
			add_child(HangarKit.box(Vector3(0, 0.035, FRONT_Z - 0.01), Vector3(w - 0.04, 0.07, 0.03), trim))
			match kind:
				"whiteboard": _build_whiteboard(w, h, trim, pcol, acol)
				"display": _build_display(w, h, trim, pcol, acol)
				"pipes": _build_pipes(w, h, trim, pcol, acol)
				"cabletray": _build_cabletray(w, h, trim, pcol, acol)
				"vent": _build_vent(w, h, trim, pcol, acol)
				"chevron": _build_chevron(w, h)
	if stencil_text.strip_edges() != "":
		var q := HangarKit.stencil(stencil_text, Vector2(minf(w * 0.5, 0.6), 0.08))
		if q:
			q.position = Vector3(0, 0.32, FRONT_Z + 0.012)
			add_child(q)
	if kind != "glass" and kind != "endcap":
		add_child(HangarKit.grime_band(w * 0.9, 0.05, FRONT_Z + 0.004, bcol))


# ── whiteboard: the thinking surface — gloss board, tray, seeded scribbles ──
func _build_whiteboard(w: float, h: float, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var bw: float = w - 0.3
	var bh: float = minf(h * 0.52, 1.3)
	var cy: float = h * 0.58
	var gloss := StandardMaterial3D.new()
	gloss.albedo_color = Color(0.96, 0.96, 0.94)
	gloss.roughness = 0.12
	gloss.metallic = 0.05
	# frame + board
	add_child(HangarKit.box(Vector3(0, cy, FRONT_Z + 0.015), Vector3(bw + 0.06, bh + 0.06, 0.03), trim))
	add_child(HangarKit.box(Vector3(0, cy, FRONT_Z + 0.032), Vector3(bw, bh, 0.012), gloss))
	# marker tray + eraser + one marker
	add_child(HangarKit.box(Vector3(0, cy - bh * 0.5 - 0.05, FRONT_Z + 0.05), Vector3(bw * 0.7, 0.03, 0.09), trim))
	add_child(HangarKit.box(Vector3(bw * 0.18, cy - bh * 0.5 - 0.02, FRONT_Z + 0.06), Vector3(0.12, 0.035, 0.05), HangarKit.worn_metal(Color(0.25, 0.26, 0.3))))
	add_child(HangarKit.box(Vector3(-bw * 0.2, cy - bh * 0.5 - 0.025, FRONT_Z + 0.06), Vector3(0.11, 0.022, 0.022), HangarKit.worn_metal(acol)))
	# seeded scribbles — short strokes at slight angles, a few accent ones
	var ink := HangarKit.worn_metal(Color(0.18, 0.2, 0.26))
	for i in range(9 + rng.randi_range(0, 5)):
		var sx: float = rng.randf_range(-bw * 0.42, bw * 0.42)
		var sy: float = cy + rng.randf_range(-bh * 0.4, bh * 0.4)
		var sl: float = rng.randf_range(0.08, 0.34)
		var stroke := HangarKit.box(Vector3(sx, sy, FRONT_Z + 0.042),
			Vector3(sl, 0.012, 0.004), ink if rng.randf() > 0.25 else HangarKit.worn_metal(acol))
		stroke.rotation_degrees.z = rng.randf_range(-18.0, 18.0)
		add_child(stroke)
	# magnets
	for i in range(rng.randi_range(2, 4)):
		var m := _disc(Vector3(rng.randf_range(-bw * 0.4, bw * 0.4), cy + rng.randf_range(-bh * 0.38, bh * 0.42), FRONT_Z + 0.042),
			0.02, 0.008, HangarKit.worn_metal([acol, pcol.darkened(0.3), Color(0.2, 0.45, 0.7)][rng.randi_range(0, 2)]))
		add_child(m)


# ── display: the SMALL screen — bezel, readout, status LEDs ─────────────────
func _build_display(w: float, h: float, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var cy: float = h * 0.6
	add_child(HangarKit.box(Vector3(0, cy, FRONT_Z + 0.02), Vector3(minf(w - 0.35, 0.72), 0.52, 0.04), HangarKit.worn_metal(pcol.darkened(0.35))))
	var r := HangarKit.readout("STATION", ["FEED  LIVE", "LINK  OK"], Vector2(minf(w - 0.45, 0.62), 0.42))
	r.position = Vector3(0, cy, FRONT_Z + 0.045)
	add_child(r)
	for i in range(3):
		add_child(HangarKit.box(Vector3(-0.1 + i * 0.1, cy - 0.33, FRONT_Z + 0.03),
			Vector3(0.03, 0.012, 0.012),
			HangarKit.emissive([Color(0.3, 0.9, 0.4), acol, Color(0.9, 0.8, 0.3)][i], 1.4)))


# ── glass: the observed bay — frame, pane, frosted band, mullions ──────────
func _build_glass(w: float, h: float, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.72, 0.84, 0.9, 0.16)
	glass.roughness = 0.06
	glass.metallic = 0.1
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var frost := StandardMaterial3D.new()
	frost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frost.albedo_color = Color(0.9, 0.93, 0.95, 0.5)
	frost.roughness = 0.6
	# top/bottom rails + end posts
	add_child(HangarKit.box(Vector3(0, 0.06, 0), Vector3(w, 0.12, SLAB_DEPTH), trim))
	add_child(HangarKit.box(Vector3(0, h - 0.05, 0), Vector3(w, 0.1, SLAB_DEPTH), trim))
	add_child(HangarKit.box(Vector3(-w * 0.5 + 0.03, h * 0.5, 0), Vector3(0.06, h, SLAB_DEPTH * 0.8), trim))
	add_child(HangarKit.box(Vector3(w * 0.5 - 0.03, h * 0.5, 0), Vector3(0.06, h, SLAB_DEPTH * 0.8), trim))
	# pane + frosted privacy band + per-cell mullions
	add_child(HangarKit.box(Vector3(0, h * 0.5, 0), Vector3(w - 0.1, h - 0.22, 0.02), glass))
	add_child(HangarKit.box(Vector3(0, h * 0.42, 0.012), Vector3(w - 0.14, 0.35, 0.006), frost))
	for i in range(1, length_cells):
		add_child(HangarKit.box(Vector3(-w * 0.5 + float(i), h * 0.5, 0), Vector3(0.03, h - 0.2, SLAB_DEPTH * 0.6), trim))
	# a thin accent line at the top rail — the lit seam continues across glass
	add_child(HangarKit.box(Vector3(0, h - 0.11, FRONT_Z), Vector3(w - 0.1, 0.02, 0.01), HangarKit.emissive(acol, 1.2)))


# ── pipes: services running DOWN the wall — drops, brackets, a valve ────────
func _build_pipes(w: float, h: float, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var metal := HangarKit.worn_metal(pcol.darkened(0.15))
	var painted := HangarKit.painted_metal(acol, 0.2)
	var xs: Array = [-w * 0.24, 0.0, w * 0.24]
	for i in range(3):
		var px: float = xs[i]
		var r: float = 0.045 if i == 1 else 0.032
		var mat: StandardMaterial3D = painted if i == 1 else metal
		# vertical drop: from the top edge DOWN to the floor
		add_child(_vpipe(Vector3(px, h - 0.08, FRONT_Z + 0.06), Vector3(px, 0.02, FRONT_Z + 0.06), r, mat))
		# elbow back into the wall at the top
		add_child(HangarKit.box(Vector3(px, h - 0.06, FRONT_Z * 0.5 + 0.03), Vector3(r * 2.2, r * 2.2, 0.14), mat))
		# brackets
		for by in [h * 0.3, h * 0.7]:
			add_child(HangarKit.box(Vector3(px, by + rng.randf_range(-0.08, 0.08), FRONT_Z + 0.035), Vector3(r * 2.8, 0.04, 0.07), trim))
	# valve wheel on the accent pipe
	var wheel := _disc(Vector3(0.0, h * 0.48, FRONT_Z + 0.145), 0.09, 0.025, HangarKit.worn_metal(acol.darkened(0.1)))
	wheel.rotation_degrees.x = 90
	add_child(wheel)
	add_child(HangarKit.box(Vector3(0.0, h * 0.48, FRONT_Z + 0.1), Vector3(0.03, 0.03, 0.09), trim))


# ── cabletray: the high run + the conduit drop to a junction box ───────────
func _build_cabletray(w: float, h: float, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var ty: float = h - 0.35
	var tz: float = FRONT_Z + 0.09
	# C-channel tray
	add_child(HangarKit.box(Vector3(0, ty, tz), Vector3(w - 0.08, 0.025, 0.2), trim))
	add_child(HangarKit.box(Vector3(0, ty + 0.05, tz - 0.09), Vector3(w - 0.08, 0.1, 0.02), trim))
	add_child(HangarKit.box(Vector3(0, ty + 0.05, tz + 0.09), Vector3(w - 0.08, 0.1, 0.02), trim))
	# cables lying in the tray
	for i in range(4):
		var cc: Color = [Color(0.16, 0.17, 0.2), acol, Color(0.2, 0.4, 0.65), Color(0.16, 0.17, 0.2)][i]
		add_child(_vpipe(Vector3(-w * 0.5 + 0.06, ty + 0.045 + (i % 2) * 0.03, tz - 0.05 + i * 0.033),
			Vector3(w * 0.5 - 0.06, ty + 0.045 + (i % 2) * 0.03, tz - 0.05 + i * 0.033), 0.014, HangarKit.worn_metal(cc)))
	# conduit drop at a seeded cell — DOWN toward the bench line
	var dx: float = (rng.randf_range(-0.35, 0.35)) * w
	add_child(_vpipe(Vector3(dx, ty, FRONT_Z + 0.045), Vector3(dx, 0.9, FRONT_Z + 0.045), 0.022, trim))
	add_child(HangarKit.box(Vector3(dx, 0.82, FRONT_Z + 0.05), Vector3(0.16, 0.2, 0.09), HangarKit.worn_metal(pcol.darkened(0.25))))
	add_child(HangarKit.box(Vector3(dx - 0.04, 0.86, FRONT_Z + 0.098), Vector3(0.02, 0.02, 0.01), HangarKit.emissive(Color(0.3, 0.9, 0.4), 1.5)))
	add_child(_vpipe(Vector3(dx, 0.72, FRONT_Z + 0.045), Vector3(dx, 0.04, FRONT_Z + 0.045), 0.022, trim))


# ── vent: the louvred grille — breathing wall ───────────────────────────────
func _build_vent(w: float, h: float, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var vw: float = minf(w - 0.35, 0.8)
	var vh: float = 0.55
	var cy: float = h * 0.62
	add_child(HangarKit.box(Vector3(0, cy, FRONT_Z + 0.008), Vector3(vw + 0.08, vh + 0.08, 0.016), trim))
	add_child(HangarKit.box(Vector3(0, cy, FRONT_Z - 0.01), Vector3(vw, vh, 0.01), HangarKit.worn_metal(Color(0.09, 0.1, 0.12))))
	var slats: int = 7
	for i in range(slats):
		var sy: float = cy - vh * 0.5 + vh * (float(i) + 0.5) / float(slats)
		var slat := HangarKit.box(Vector3(0, sy, FRONT_Z + 0.012), Vector3(vw, 0.055, 0.012), HangarKit.worn_metal(pcol))
		slat.rotation_degrees.x = -38
		add_child(slat)
	add_child(HangarKit.dust_streaks(vw * 0.8, 0.3, FRONT_Z + 0.005, 3))


# ── chevron: the hazard band segment ────────────────────────────────────────
func _build_chevron(w: float, h: float) -> void:
	var band := HangarKit.box(Vector3(0, 0.42, FRONT_Z + 0.006), Vector3(w - 0.06, 0.34, 0.012), HangarKit.striped_mat())
	add_child(band)


# ── endcap: the special SHORT ENDING — the run closes on purpose (R-018/19) ─
func _build_endcap(h: float, body: StandardMaterial3D, trim: StandardMaterial3D, acol: Color, pcol: Color) -> void:
	var s: float = -1.0 if flip else 1.0
	# Stepped return: three plates stepping back — the wall ends in three breaths.
	add_child(HangarKit.box(Vector3(0.0, h * 0.5, 0), Vector3(0.26, h, SLAB_DEPTH), body))
	add_child(HangarKit.box(Vector3(s * 0.20, (h - 0.25) * 0.5, 0), Vector3(0.14, h - 0.25, SLAB_DEPTH * 0.8), HangarKit.finish_body(finish, pcol, wear)))
	add_child(HangarKit.box(Vector3(s * 0.30, (h - 0.6) * 0.5, 0), Vector3(0.08, h - 0.6, SLAB_DEPTH * 0.6), trim))
	# the lit vertical groove on the outermost face — the ending made visible
	add_child(HangarKit.box(Vector3(s * 0.345, (h - 0.7) * 0.5, 0), Vector3(0.012, h - 0.75, 0.03), HangarKit.emissive(acol, 1.6)))
	# cap plate + bolts + foot
	add_child(HangarKit.box(Vector3(s * 0.12, h + 0.03, 0), Vector3(0.55, 0.06, SLAB_DEPTH + 0.06), trim))
	add_child(HangarKit.box(Vector3(s * 0.1, 0.045, 0), Vector3(0.5, 0.09, SLAB_DEPTH + 0.04), trim))
	add_child(HangarKit.bolts(Vector3(0.0, h - 0.15, FRONT_Z + 0.01), Vector3(0.0, 0.3, FRONT_Z + 0.01), 4, 0.012, HangarKit.worn_metal(pcol.darkened(0.2))))


# ── primitives ───────────────────────────────────────────────────────────────
func _disc(at: Vector3, radius: float, thick: float, mat: Material) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = thick
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.rotation_degrees.x = 90
	mi.position = at
	return mi


func _vpipe(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var yv: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
