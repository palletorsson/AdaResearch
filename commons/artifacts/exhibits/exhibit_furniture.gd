extends Node3D
class_name ExhibitFurniture

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the display-furniture FAMILY as one parametric artifact — kind decides the body: floating_wall (MoMA: a hanging wall hovering above the floor, a soft shadow in the gap — the cheap accent that makes a room expensive), plinth (s/m/l), hollow_plinth, platform, table_2m, vitrine_tall, cabinet, infoboard, sign_exit, sign_fire. All empty; all waiting.
# desire: to give the gallery-DNA a full vocabulary of hosting — every footprint size, every display posture, plus the wayfinding that says someone cares for this building.
# critical_parameter: kind — selects the body; w/h/size scale it.
# triggers: _ready builds by kind; apply_grid_config({kind, w, h, size}).
# emerges: a room furnished from one family reads coherent; the floating wall's shadow line is the museum's signature written in light.
# needs: BakedText for signage and infoboard.
# relationships: grows [[exhibit_podium]] and [[exhibit_vitrine]] into a family; planted by tools/gallery_evolve.py; filled later by the Curator.
# truth: display furniture is the grammar of attention — the same object reads different on a plinth, a table, or behind glass.

@export var kind: String = "plinth"
@export var size_class: String = "m"      # s | m | l
@export var panel_w: float = 4.0          # floating_wall width
@export var panel_h: float = 2.6

@export var mount: String = ""            # a lookup_name to seat on the bed's surface

func _ready() -> void:
	_read_meta_overrides()
	_build()
	if mount != "":
		_mount_artifact(mount)

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_kind"):
		kind = str(get_meta("config_kind"))
	if has_meta("config_size"):
		size_class = str(get_meta("config_size"))
	if has_meta("config_w"):
		panel_w = float(str(get_meta("config_w")))
	if has_meta("config_h"):
		panel_h = float(str(get_meta("config_h")))
	if has_meta("config_mount"):
		mount = str(get_meta("config_mount"))

# The bed's surface height — where a mounted artifact sits.
func _surface_y() -> float:
	match kind:
		"plinth":
			return {"s": 1.19, "m": 0.99, "l": 0.64}.get(size_class, 0.99)
		"hollow_plinth": return 0.95
		"table_2m": return 0.8
		"platform": return 0.31
		"pit": return -0.28          # the object sits DOWN in the well
		"floor_work": return 0.05
		"vitrine_tall": return 0.3
		"panel": return 1.4 + ({"s": 1.2, "m": 2.0, "l": 3.2}.get(size_class, 2.0) * 0.66) * 0.5
		_: return 0.9

# Load an artifact by lookup_name from the registries and seat it on the bed.
func _mount_artifact(lookup: String) -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir == null:
		return
	var scene_path := ""
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json"):
			var file := FileAccess.open("res://commons/artifacts/registry/" + f, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary and parsed.get("artifacts", {}).has(lookup):
					scene_path = str(parsed["artifacts"][lookup].get("scene", ""))
					break
		f = dir.get_next()
	if scene_path == "":
		return
	var scene = load(scene_path)
	if scene == null:
		return
	var inst = scene.instantiate()
	if inst is Node3D:
		var on_panel := kind == "panel"
		inst.position = Vector3(0, _surface_y(), 0.15 if on_panel else 0.0)
		add_child(inst)

func _mat(c: Color, rough := 0.6, emit := 0.0, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi

func _build() -> void:
	var stone := _mat(Color(0.85, 0.83, 0.78))
	var dark := _mat(Color(0.22, 0.22, 0.24))
	var glass := _mat(Color(0.8, 0.9, 0.95, 0.16), 0.05)
	match kind:
		"floating_wall":
			_floating_wall(stone)
		"plinth":
			var dims: Vector3 = {"s": Vector3(0.4, 1.15, 0.4), "m": Vector3(0.55, 0.95, 0.55),
					"l": Vector3(0.85, 0.6, 0.85)}.get(size_class, Vector3(0.55, 0.95, 0.55))
			_box(dims, Vector3(0, dims.y * 0.5, 0), stone)
			_box(Vector3(dims.x + 0.05, 0.04, dims.z + 0.05),
					Vector3(0, dims.y + 0.02, 0), _mat(Color(0.92, 0.9, 0.86), 0.4))
		"hollow_plinth":
			var s := 0.6
			var h := 0.9
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_box(Vector3(0.06, h, 0.06),
							Vector3(sx * (s * 0.5 - 0.03), h * 0.5, sz * (s * 0.5 - 0.03)), dark)
			_box(Vector3(s + 0.06, 0.05, s + 0.06), Vector3(0, h + 0.025, 0), stone)
		"platform":
			var side: float = {"s": 1.2, "m": 1.6, "l": 2.4, "xl": 3.4}.get(size_class, 1.6)
			_box(Vector3(side, 0.28, side), Vector3(0, 0.14, 0), stone)
			_box(Vector3(side + 0.08, 0.03, side + 0.08), Vector3(0, 0.295, 0), _mat(Color(0.9, 0.88, 0.84), 0.4))
		"pit":
			# a sunken well — the inverse of a plinth; a raised lip, a dark recess,
			# a soft up-light. The object sits DOWN in it (the well posture).
			var pw: float = {"s": 1.0, "m": 1.6, "l": 2.4}.get(size_class, 1.6)
			var lip := _mat(Color(0.7, 0.68, 0.63))
			for a in [Vector3(pw * 0.5, 0, 0), Vector3(-pw * 0.5, 0, 0), Vector3(0, 0, pw * 0.5), Vector3(0, 0, -pw * 0.5)]:
				var horiz: bool = abs(a.x) > 0.01
				_box(Vector3(0.14 if horiz else pw + 0.28, 0.18, pw + 0.28 if horiz else 0.14),
						a + Vector3(0, 0.09, 0), lip)
			_box(Vector3(pw, 0.04, pw), Vector3(0, -0.4, 0), _mat(Color(0.06, 0.06, 0.08), 0.5))   # recessed floor
			var up := OmniLight3D.new()
			up.position = Vector3(0, -0.2, 0)
			up.omni_range = pw * 1.4
			up.light_energy = 1.2
			up.light_color = Color(0.9, 0.95, 1.0)
			add_child(up)
		"panel":
			# a wall-mounted flat display — for flat/graphic works. A framed plane
			# on a thin standoff (reads as hung), MoMA shadow-gap under the frame.
			var pwid: float = {"s": 1.2, "m": 2.0, "l": 3.2}.get(size_class, 2.0)
			var phgt: float = pwid * 0.66
			_box(Vector3(pwid + 0.08, phgt + 0.08, 0.05), Vector3(0, 1.4 + phgt * 0.5, -0.06), dark)   # frame
			_box(Vector3(pwid, phgt, 0.02), Vector3(0, 1.4 + phgt * 0.5, -0.03), _mat(Color(0.93, 0.92, 0.89), 0.75))
			var sh := MeshInstance3D.new()
			var q := QuadMesh.new(); q.size = Vector2(pwid + 0.2, 0.4); sh.mesh = q
			sh.material_override = _mat(Color(0.02, 0.02, 0.03, 0.45), 1.0, 0.0, true)
			sh.rotation_degrees = Vector3(-90, 0, 0); sh.position = Vector3(0, 0.012, 0.1)
			sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(sh)
		"floor_work":
			# terrain posture: the work sits DIRECTLY on the floor, marked only by a
			# flush pad + corner studs (don't-step-here), no plinth.
			var fw: float = {"s": 1.4, "m": 2.2, "l": 3.2}.get(size_class, 2.2)
			_box(Vector3(fw, 0.03, fw), Vector3(0, 0.015, 0), _mat(Color(0.3, 0.3, 0.33), 0.7))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_box(Vector3(0.1, 0.14, 0.1), Vector3(sx * fw * 0.48, 0.07, sz * fw * 0.48), _mat(Color(0.7, 0.6, 0.3), 0.4, 1.0))
		"table_2m":
			_box(Vector3(2.0, 0.05, 0.9), Vector3(0, 0.75, 0), _mat(Color(0.5, 0.42, 0.34), 0.5))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_box(Vector3(0.06, 0.73, 0.06),
							Vector3(sx * 0.92, 0.365, sz * 0.38), dark)
		"vitrine_tall":
			_box(Vector3(0.7, 0.25, 0.7), Vector3(0, 0.125, 0), dark)
			var gl := _box(Vector3(0.62, 1.7, 0.62), Vector3(0, 1.12, 0), glass)
			gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_box(Vector3(0.7, 0.06, 0.7), Vector3(0, 2.0, 0), dark)
		"cabinet":
			var w := 1.6
			_box(Vector3(w, 2.0, 0.12), Vector3(0, 1.0, -0.22), stone)      # back
			_box(Vector3(0.08, 2.0, 0.5), Vector3(-w * 0.5, 1.0, 0), stone)
			_box(Vector3(0.08, 2.0, 0.5), Vector3(w * 0.5, 1.0, 0), stone)
			_box(Vector3(w, 0.08, 0.5), Vector3(0, 2.0, 0), stone)
			for i in 3:
				_box(Vector3(w - 0.1, 0.04, 0.42), Vector3(0, 0.5 + 0.55 * float(i), 0), _mat(Color(0.6, 0.56, 0.5)))
		"infoboard":
			_box(Vector3(0.1, 0.95, 0.1), Vector3(0, 0.475, 0), dark)
			var board := _box(Vector3(0.85, 0.55, 0.05), Vector3(0, 1.1, 0.12), dark)
			board.rotation_degrees = Vector3(-30, 0, 0)
			var label: MeshInstance3D = BakedText.make_label_mesh(
					"INFO", Color(0.92, 0.9, 0.85), Vector2(0.6, 0.28), 1400, true)
			if label:
				label.position = Vector3(0, 1.13, 0.16)
				label.rotation_degrees = Vector3(-30, 0, 0)
				add_child(label)
		"sign_exit":
			_sign("EXIT", Color(0.12, 0.55, 0.25), Color(0.95, 1.0, 0.95))
		"sign_fire":
			_sign("FIRE", Color(0.72, 0.12, 0.1), Color(1.0, 0.96, 0.94))
			# the little red cylinder itself, hanging under the sign
			var ext := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.09
			cm.bottom_radius = 0.09
			cm.height = 0.5
			ext.mesh = cm
			ext.material_override = _mat(Color(0.78, 0.1, 0.08), 0.35)
			ext.position = Vector3(0, 1.1, 0)
			add_child(ext)
		_:
			_box(Vector3(0.5, 0.9, 0.5), Vector3(0, 0.45, 0), stone)

func _floating_wall(stone: StandardMaterial3D) -> void:
	# MoMA: the wall hovers; the shadow in the gap is the accent
	var gap := 0.14
	var wall := _box(Vector3(panel_w, panel_h, 0.18), Vector3(0, gap + panel_h * 0.5, 0),
			_mat(Color(0.93, 0.92, 0.89), 0.75))
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# contact shadow: an unshaded dark quad lying in the gap's floor
	var sh := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(panel_w + 0.25, 0.55)
	sh.mesh = qm
	sh.material_override = _mat(Color(0.02, 0.02, 0.03, 0.5), 1.0, 0.0, true)
	sh.rotation_degrees = Vector3(-90, 0, 0)
	sh.position = Vector3(0, 0.012, 0)
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sh)
	# slim steel hangers from above (reads as suspended)
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.03, 0.6, 0.03),
				Vector3(sx * panel_w * 0.35, gap + panel_h + 0.3, 0), _mat(Color(0.4, 0.42, 0.45), 0.4))

func _sign(text: String, bg: Color, fg: Color) -> void:
	var pole := _box(Vector3(0.05, 2.3, 0.05), Vector3(0, 1.15, 0), _mat(Color(0.35, 0.36, 0.4), 0.5))
	var panel: MeshInstance3D = BakedText.make_panel_mesh(
			text, bg, fg, Vector2(0.55, 0.22), 1400, true)
	if panel:
		panel.position = Vector3(0, 2.15, 0.04)
		add_child(panel)
	var panel2: MeshInstance3D = BakedText.make_panel_mesh(
			text, bg, fg, Vector2(0.55, 0.22), 1400, true)
	if panel2:
		panel2.position = Vector3(0, 2.15, -0.04)
		panel2.rotation_degrees = Vector3(0, 180, 0)
		add_child(panel2)
