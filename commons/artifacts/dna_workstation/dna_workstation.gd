# dna_workstation.gd — VR browser for all DNA substrate variants.
#
# Same pattern as ArtifactWorkstationVR: kiosk with 2D UI + presentation area.
# UI emits dna_changed(substrate, config_id); workstation clears the area and
# builds the selected DNA variant live.
#
# Live-renderable substrates (build 3D geometry in the presentation area):
#   L-system        — turtle walk → tube MultiMesh
#   Trajectory      — integrate force → tube MultiMesh
#   Pattern         — render wallpaper group → textured plane
#   RD              — simulate Gray-Scott → heightmap mesh
#   Primitive stack — primitive_stack.build() → Node3D
#   Soft-body glass — run sim → ArrayMesh
#
# Config-only substrates (show JSON text, pointer to /dna):
#   Graph grammar, mesh grammar — too heavy to live-render here.

class_name DNAWorkstation
extends Node3D

const VIEWPORT_2D_3D = preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const UI_SCENE = preload("res://commons/artifacts/dna_workstation/dna_workstation_ui.tscn")

const LSystemSim     = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtle  = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")
const TrajSim        = preload("res://commons/trajectory_grammar/trajectory_sim.gd")
const PatternSim     = preload("res://commons/pattern_grammar/pattern_sim.gd")
const RDSim          = preload("res://commons/rd_grammar/rd_sim.gd")
const PrimStack      = preload("res://commons/primitive_grammar/primitive_stack.gd")
const SoftBodySim    = preload("res://commons/soft_body/soft_body_sim.gd")

var _presentation_area: Node3D
var _current_artifact: Node = null
var _ui_instance: Control = null
var _info_label: Label3D


func _ready() -> void:
	_build_kiosk()
	_build_presentation_area()


func _build_kiosk() -> void:
	var kiosk_z := 2.2
	var panel_y := 1.2

	# Screen backing
	var screen := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.85, 0.48, 0.015)
	screen.mesh = box
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.05, 0.08)
	screen.material_override = screen_mat
	screen.transform = Transform3D(
		Basis(Vector3.RIGHT, deg_to_rad(-25)),
		Vector3(0, panel_y, kiosk_z))
	add_child(screen)

	# Viewport2Din3D → renders the 2D UI onto the screen
	var viewport := VIEWPORT_2D_3D.instantiate()
	viewport.transform = Transform3D(
		Basis(Vector3.RIGHT, deg_to_rad(-25)),
		Vector3(0, panel_y, kiosk_z + 0.01))
	viewport.screen_size = Vector2(0.8, 0.44)
	viewport.scene = UI_SCENE
	viewport.viewport_size = Vector2(800, 420)
	add_child(viewport)

	call_deferred("_connect_ui", viewport)


func _connect_ui(viewport: Node) -> void:
	for _i in range(15):
		await get_tree().process_frame
		_ui_instance = viewport.get_scene_instance() if viewport.has_method("get_scene_instance") else null
		if _ui_instance:
			break
	if _ui_instance and _ui_instance.has_signal("dna_changed"):
		_ui_instance.dna_changed.connect(_on_dna_changed)
		print("DNAWorkstation: UI connected")


func _build_presentation_area() -> void:
	_presentation_area = Node3D.new()
	_presentation_area.name = "PresentationArea"
	_presentation_area.position = Vector3(0, 0.8, -1.0)
	add_child(_presentation_area)

	var title := Label3D.new()
	title.text = "DNA Workstation"
	title.font_size = 32
	title.modulate = Color(1, 1, 1, 0.55)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0, 3.2, -1.0)
	add_child(title)

	_info_label = Label3D.new()
	_info_label.text = "Select a substrate + config from the kiosk panel"
	_info_label.font_size = 18
	_info_label.modulate = Color(0.78, 0.82, 0.9, 0.75)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, 2.7, -1.0)
	add_child(_info_label)


func _on_dna_changed(substrate: String, config_id: String) -> void:
	_info_label.text = "%s · %s" % [substrate, config_id]
	_load_variant(substrate, config_id)


func _load_variant(substrate: String, config_id: String) -> void:
	# Clear previous
	if _current_artifact:
		_current_artifact.queue_free()
		_current_artifact = null
	for child in _presentation_area.get_children():
		child.queue_free()

	var cfg: Dictionary = _find_config(substrate, config_id)
	if cfg.is_empty():
		_show_placeholder("config not found: %s/%s" % [substrate, config_id])
		return

	var node: Node3D = null
	match substrate:
		"lsystem":        node = _build_lsystem(cfg)
		"trajectory":     node = _build_trajectory(cfg)
		"pattern":        node = _build_pattern(cfg)
		"rd":             node = _build_rd(cfg)
		"primitive_stack":node = _build_primitive_stack(cfg)
		"soft_body":      node = _build_soft_body(cfg)
		_:                _show_placeholder("%s · config only — see /dna" % substrate); return
	if node == null:
		_show_placeholder("build failed")
		return
	_current_artifact = node
	_presentation_area.add_child(node)
	call_deferred("_fit_artifact")


func _find_config(substrate: String, config_id: String) -> Dictionary:
	var path_map := {
		"lsystem":        "res://commons/lsystem_grammar/research_configs.json",
		"trajectory":     "res://commons/trajectory_grammar/research_configs.json",
		"pattern":        "res://commons/pattern_grammar/research_configs.json",
		"rd":             "res://commons/rd_grammar/research_configs.json",
		"primitive_stack":"res://commons/primitive_grammar/research_configs.json",
		"soft_body":      "res://commons/soft_body/research_configs.json",
		"graph_grammar":  "res://commons/graph_grammar/research_configs.json",
		"mesh_grammar":   "res://commons/mesh_grammar/research_configs.json",
	}
	var path: String = path_map.get(substrate, "")
	if path.is_empty(): return {}
	var txt: String = FileAccess.get_file_as_string(path)
	if txt.is_empty(): return {}
	var j := JSON.new()
	if j.parse(txt) != OK: return {}
	var lib = j.data
	if not (lib is Dictionary): return {}
	for c in lib.get("configs", []):
		if str(c.get("id", "")) == config_id:
			return c
	return {}


# ─── Per-substrate builders ───────────────────────────────────

func _build_lsystem(cfg: Dictionary) -> Node3D:
	var axiom: String = String(cfg.get("axiom", "F"))
	var rules: Dictionary = cfg.get("rules", {})
	var iters: int = int(cfg.get("iterations", 4))
	var seed_val: int = int(cfg.get("seed", 0))
	var has_stoch := false
	for k in rules.keys():
		if rules[k] is Array: has_stoch = true; break
	var s: String
	if has_stoch:
		s = LSystemSim.rewrite_stochastic(axiom, rules, iters, seed_val)
	else:
		s = LSystemSim.rewrite(axiom, rules, iters)
	var walk: Dictionary = LSystemTurtle.walk(s, {
		"angle_deg":    float(cfg.get("angle_deg", 25.7)),
		"step_len":     float(cfg.get("step_len", 0.1)),
		"step_shrink":  float(cfg.get("step_shrink", 0.72)),
		"base_width":   float(cfg.get("base_width", 0.02)),
		"width_shrink": float(cfg.get("width_shrink", 0.75)),
	})
	var ct := _c(cfg.get("color_trunk", [0.45, 0.28, 0.12]))
	var cp := _c(cfg.get("color_tip",   [0.2, 0.65, 0.15]))
	return LSystemTurtle.to_tubes(walk, ct, cp, int(cfg.get("tube_sides", 6)))


func _build_trajectory(cfg: Dictionary) -> Node3D:
	var result: Dictionary = TrajSim.simulate(cfg)
	var trails: Array = result["trajectories"]
	var root := Node3D.new()
	var cs := _c(cfg.get("color_start", [0.2, 0.3, 0.5]))
	var ce := _c(cfg.get("color_end",   [0.9, 0.55, 0.2]))
	var radius: float = float(cfg.get("tube_radius", 0.025))
	# Build a single MultiMesh of cylinders for all trail segments
	var total_seg := 0
	for t in trails:
		var pts: PackedVector3Array = t
		if pts.size() >= 2: total_seg += pts.size() - 1
	if total_seg == 0: return root
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new(); cyl.top_radius = 1.0; cyl.bottom_radius = 1.0; cyl.height = 1.0
	cyl.radial_segments = 6; cyl.rings = 1
	mm.mesh = cyl
	mm.instance_count = total_seg
	var idx := 0
	for t in trails:
		var pts: PackedVector3Array = t
		if pts.size() < 2: continue
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]; var b: Vector3 = pts[i + 1]
			var v: Vector3 = b - a; var h: float = v.length()
			if h < 1e-6: idx += 1; continue
			var axis := v / h
			var basis := Basis()
			var dot := Vector3.UP.dot(axis)
			if dot > 0.9999: basis = Basis.IDENTITY
			elif dot < -0.9999: basis = Basis(Vector3.RIGHT, PI)
			else: basis = Basis(Vector3.UP.cross(axis).normalized(), acos(clampf(dot, -1.0, 1.0)))
			basis = basis.scaled(Vector3(radius, h, radius))
			mm.set_instance_transform(idx, Transform3D(basis, (a + b) * 0.5))
			mm.set_instance_color(idx, cs.lerp(ce, float(i) / float(pts.size() - 1)))
			idx += 1
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true; mat.roughness = 0.55
	mmi.material_override = mat
	root.add_child(mmi)
	return root


func _build_pattern(cfg: Dictionary) -> Node3D:
	var img: Image = PatternSim.render_to_image(cfg)
	if img == null: return null
	var tex := ImageTexture.create_from_image(img)
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.2, 2.2)
	mi.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.rotation_degrees = Vector3(-90, 0, 0)   # face upward, read as top-down tile
	mi.position = Vector3(0, 1.2, 0)
	root.add_child(mi)
	return root


func _build_rd(cfg: Dictionary) -> Node3D:
	var N: int = int(cfg.get("grid_size", 96))
	var field: PackedFloat32Array = RDSim.simulate(cfg)
	var color_lo := _c(cfg.get("color_lo", [0.15, 0.2, 0.3]))
	var color_hi := _c(cfg.get("color_hi", [0.9, 0.8, 0.5]))
	var world_size: float = 1.5
	var height_amp: float = float(cfg.get("height_amp", 0.5))
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var cell: float = world_size * 2.0 / float(N - 1)
	for iy in N:
		for ix in N:
			var x: float = -world_size + float(ix) * cell
			var z: float = -world_size + float(iy) * cell
			var h: float = field[iy * N + ix] * height_amp
			verts.append(Vector3(x, h, z))
			var t: float = clampf(field[iy * N + ix] * 2.0, 0.0, 1.0)
			colors.append(color_lo.lerp(color_hi, t))
	for iy in N - 1:
		for ix in N - 1:
			var i0: int = iy * N + ix
			var i1: int = iy * N + ix + 1
			var i2: int = (iy + 1) * N + ix + 1
			var i3: int = (iy + 1) * N + ix
			indices.append_array([i0, i1, i2, i0, i2, i3])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true; mat.roughness = 0.55
	mi.material_override = mat
	var root := Node3D.new()
	mi.position = Vector3(0, 0.5, 0)
	root.add_child(mi)
	return root


func _build_primitive_stack(cfg: Dictionary) -> Node3D:
	return PrimStack.build(cfg)


func _build_soft_body(cfg: Dictionary) -> Node3D:
	# Best-effort — soft-body sims can be slow. For the workstation we
	# skip simulation and just show a placeholder noting the compute cost.
	_show_placeholder("Soft-body live-sim is slow — run via tools/soft_body_research.py and view PNG in gallery")
	return null


# ─── Helpers ──────────────────────────────────────────────────

func _c(a) -> Color:
	if a is Array and a.size() >= 3:
		return Color(float(a[0]), float(a[1]), float(a[2]))
	return Color.WHITE


func _show_placeholder(msg: String) -> void:
	var lbl := Label3D.new()
	lbl.text = msg
	lbl.font_size = 22
	lbl.modulate = Color(0.9, 0.6, 0.5, 0.95)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 1.4, 0)
	_presentation_area.add_child(lbl)


func _fit_artifact() -> void:
	if not _current_artifact or not _current_artifact is Node3D:
		return
	var n3d := _current_artifact as Node3D
	var aabb := _get_aabb(n3d)
	if aabb.size.length() < 0.01: return
	n3d.position -= aabb.get_center()
	n3d.position.y += aabb.size.y * 0.5 + 0.3
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	if max_dim > 2.5:
		n3d.scale = Vector3.ONE * (2.5 / max_dim)


func _get_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var a: AABB = vi.global_transform * vi.get_aabb()
			if first: result = a; first = false
			else: result = result.merge(a)
		for c in n.get_children():
			if c is Node3D: stack.append(c)
	return result


# Desktop keyboard fallback
func _unhandled_input(event: InputEvent) -> void:
	if not _ui_instance: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT: if _ui_instance.has_method("_on_next"): _ui_instance._on_next()
			KEY_LEFT:  if _ui_instance.has_method("_on_prev"): _ui_instance._on_prev()
			KEY_TAB:   if _ui_instance.has_method("_on_mode"): _ui_instance._on_mode()


func apply_grid_config(config: Dictionary) -> void:
	pass
