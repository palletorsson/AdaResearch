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
const HAND_POSE_AREA = preload("res://addons/godot-xr-tools/objects/hand_pose_area.tscn")

## VR-preview caps: applied to configs before live-rendering in the workstation.
## Same DNA, reduced fidelity, faster build. Gallery-side renders use full
## resolution by running tools/<sub>_research.py instead.
@export var vr_preview: bool = true

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
	# Kiosk offset to the side (+x) so it doesn't block the view of the
	# generated artifact at origin. Player stands at -Z looking toward +Z;
	# artifact is center-front, kiosk is right-front at waist height.
	var kiosk_x := 1.5
	var kiosk_z := -1.0      # slightly toward the player, easy to reach
	var panel_y := 1.05
	# Rotate kiosk to face the player at origin (kiosk is right of origin,
	# so it needs to turn toward -X as well as tilt back)
	var kiosk_yaw: float = deg_to_rad(-40)
	var kiosk_pitch: float = deg_to_rad(-25)
	var kiosk_basis := Basis.from_euler(Vector3(kiosk_pitch, kiosk_yaw, 0))

	# Screen backing
	var screen := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.85, 0.48, 0.015)
	screen.mesh = box
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.05, 0.08)
	screen.material_override = screen_mat
	screen.transform = Transform3D(kiosk_basis, Vector3(kiosk_x, panel_y, kiosk_z))
	add_child(screen)

	# Viewport2Din3D → renders the 2D UI onto the screen
	var viewport := VIEWPORT_2D_3D.instantiate()
	# Tiny forward offset along the panel's surface normal so the UI
	# sits just in front of the backing (not fighting z-buffer)
	var fwd_offset: Vector3 = kiosk_basis * Vector3(0, 0, 0.01)
	viewport.transform = Transform3D(kiosk_basis,
		Vector3(kiosk_x, panel_y, kiosk_z) + fwd_offset)
	viewport.screen_size = Vector2(0.8, 0.44)
	viewport.scene = UI_SCENE
	viewport.viewport_size = Vector2(800, 420)
	add_child(viewport)

	# VR hand-pose area — so XR controllers can point at the 2D panel
	if ResourceLoader.exists("res://addons/godot-xr-tools/objects/hand_pose_area.tscn"):
		var hand_area := HAND_POSE_AREA.instantiate()
		hand_area.transform = Transform3D(kiosk_basis,
			Vector3(kiosk_x, panel_y, kiosk_z))
		if ResourceLoader.exists("res://addons/godot-xr-tools/hands/poses/pose_point_left.tres"):
			hand_area.left_pose = load("res://addons/godot-xr-tools/hands/poses/pose_point_left.tres")
		if ResourceLoader.exists("res://addons/godot-xr-tools/hands/poses/pose_point_right.tres"):
			hand_area.right_pose = load("res://addons/godot-xr-tools/hands/poses/pose_point_right.tres")
		add_child(hand_area)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.9, 0.25, 0.6)
		collision.shape = shape
		hand_area.add_child(collision)

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
		# Load whatever's currently selected — the UI auto-selected the first
		# substrate + first config in its _ready(), but that signal fired before
		# we connected. Pull the current selection now.
		if _ui_instance.has_method("get_current_selection"):
			var sel: Dictionary = _ui_instance.get_current_selection()
			if not sel.is_empty():
				_on_dna_changed(str(sel.get("substrate", "")), str(sel.get("config_id", "")))
	else:
		print("DNAWorkstation: UI not found or missing dna_changed signal")


func _build_presentation_area() -> void:
	# Presentation at artifact origin (0,0,0). Player stands to the -Z side,
	# faces +Z — sees the generated geometry first, with the kiosk visible
	# further beyond it. Matches ArtifactWorkstationVR's layout.
	_presentation_area = Node3D.new()
	_presentation_area.name = "PresentationArea"
	_presentation_area.position = Vector3(0, 0, 0)
	add_child(_presentation_area)

	var title := Label3D.new()
	title.text = "DNA Workstation"
	title.font_size = 32
	title.modulate = Color(1, 1, 1, 0.55)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0, 3.5, 0)
	add_child(title)

	_info_label = Label3D.new()
	_info_label.text = "Select a substrate + config from the kiosk panel"
	_info_label.font_size = 18
	_info_label.modulate = Color(0.78, 0.82, 0.9, 0.75)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, 3.0, 0)
	add_child(_info_label)


func _on_dna_changed(substrate: String, config_id: String) -> void:
	_info_label.text = "%s · %s" % [substrate, config_id]
	_load_variant(substrate, config_id)
	# After a brief deferral (so the artifact has entered the tree), count
	# draw calls and append to the label. Visible pedagogical feedback.
	call_deferred("_update_draw_call_label")


func _update_draw_call_label() -> void:
	if _info_label == null: return
	if _current_artifact == null: return
	var dc: int = _count_draw_calls(_current_artifact)
	_info_label.text = "%s   ·   %d draw call%s" % [
		_info_label.text, dc, "" if dc == 1 else "s"
	]


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
	if vr_preview:
		cfg = _apply_vr_caps(substrate, cfg)

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
		_show_placeholder("build failed: %s/%s" % [substrate, config_id])
		print("DNAWorkstation: %s/%s returned null" % [substrate, config_id])
		return
	_current_artifact = node
	# Always wrap the artifact in a container Node3D so _fit_artifact can
	# translate without fighting per-builder transforms, and so _get_aabb
	# can walk INTO the container to find VisualInstance3D children.
	var container := Node3D.new()
	container.name = "ArtifactContainer"
	container.add_child(node)
	_presentation_area.add_child(container)
	_current_artifact = container
	call_deferred("_fit_artifact")
	print("DNAWorkstation: loaded %s/%s" % [substrate, config_id])


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
	var segments: Array = walk.get("segments", [])
	print("DNAWorkstation: L-system %s → %d segments" % [cfg.get("id", "?"), segments.size()])
	var ct := _c(cfg.get("color_trunk", [0.45, 0.28, 0.12]))
	var cp := _c(cfg.get("color_tip",   [0.2, 0.65, 0.15]))
	return LSystemTurtle.to_tubes(walk, ct, cp, int(cfg.get("tube_sides", 6)))


func _build_trajectory(cfg: Dictionary) -> Node3D:
	var result: Dictionary = TrajSim.simulate(cfg)
	var trails: Array = result["trajectories"]
	var sample_total: int = 0
	for t in trails: sample_total += (t as PackedVector3Array).size()
	print("DNAWorkstation: Trajectory %s → %d trail(s), %d samples" % [
		cfg.get("id", "?"), trails.size(), sample_total])
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
	print("DNAWorkstation: Pattern %s → image %s" % [
		cfg.get("id", "?"),
		"null" if img == null else str(img.get_size())])
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
	print("DNAWorkstation: RD %s → simulating %d×%d, %d iterations…" % [
		cfg.get("id", "?"), N, N, int(cfg.get("iterations", 3000))])
	var field: PackedFloat32Array = RDSim.simulate(cfg)
	print("DNAWorkstation: RD %s → field length %d" % [cfg.get("id", "?"), field.size()])
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
	var n := PrimStack.build(cfg)
	print("DNAWorkstation: PrimStack %s → %d children" % [
		cfg.get("id", "?"), n.get_child_count() if n else -1])
	return n


func _build_soft_body(cfg: Dictionary) -> Node3D:
	# Best-effort — soft-body sims can be slow. For the workstation we
	# skip simulation and just show a placeholder noting the compute cost.
	_show_placeholder("Soft-body live-sim is slow — run via tools/soft_body_research.py and view PNG in gallery")
	return null


# ─── VR-preview caps + draw-call counter ─────────────────────
#
# Applied to the cfg dict before the builder runs. Caps iterations,
# grid sizes, sample counts to values that build in <500ms so the
# workstation feels responsive in VR. Same DNA; lower fidelity.

func _apply_vr_caps(substrate: String, cfg_in: Dictionary) -> Dictionary:
	var cfg: Dictionary = cfg_in.duplicate(true)
	match substrate:
		"rd":
			# 3000 iterations × 96×96 grid ≈ 3-5s. Cap to 32×32 × 800 ≈ 200ms.
			cfg["grid_size"] = mini(int(cfg.get("grid_size", 96)), 32)
			cfg["iterations"] = mini(int(cfg.get("iterations", 3000)), 800)
		"trajectory":
			# Trajectories at dt=0.005 with 40s duration produce 8000 samples —
			# 8000 cylinder instances is fine (MultiMesh), but RD/Lorenz sim
			# iterates 8000×. Cap by halving sample density.
			cfg["dt"] = maxf(float(cfg.get("dt", 0.02)) * 2.0, 0.01)
		"pattern":
			# Canvas 512×512 × 17 wallpaper-group lookups per pixel is borderline.
			# Drop to 256×256 for preview — still reads as the pattern.
			cfg["canvas_size"] = mini(int(cfg.get("canvas_size", 512)), 256)
		"lsystem":
			# Iterations above 4 produce huge strings. Cap at 4 for preview.
			cfg["iterations"] = mini(int(cfg.get("iterations", 4)), 4)
	return cfg


# Counts draw calls for a built artifact: each MeshInstance3D = 1 call;
# each MultiMeshInstance3D = 1 call regardless of how many instances.
func _count_draw_calls(node: Node3D) -> int:
	var count := 0
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D or n is MultiMeshInstance3D:
			count += 1
		for c in n.get_children():
			if c is Node3D: stack.append(c)
	return count


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
	# Center artifact on origin, lift so base sits at y=0.2 (just above floor),
	# and scale to fit roughly 2m cube so it reads well for a standing player.
	if not _current_artifact or not _current_artifact is Node3D:
		return
	var n3d := _current_artifact as Node3D
	var aabb := _get_aabb(n3d)
	if aabb.size.length() < 0.01: return
	# Reset any transform the builder applied
	n3d.position = Vector3.ZERO
	n3d.scale = Vector3.ONE
	# Scale to fit a 2m box
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	if max_dim > 2.0:
		var s: float = 2.0 / max_dim
		n3d.scale = Vector3(s, s, s)
		aabb = AABB(aabb.position * s, aabb.size * s)
	# Re-center horizontally, shift so base sits at y=0.2
	n3d.position = Vector3(-aabb.get_center().x, 0.2 - aabb.position.y, -aabb.get_center().z)


func _get_aabb(node: Node3D) -> AABB:
	# Recursive walk: any VisualInstance3D (MeshInstance3D, MultiMeshInstance3D)
	# contributes its world-space AABB. Called after the node enters the tree
	# so global_transform is valid.
	var result := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var a_local: AABB = vi.get_aabb()
			if a_local.size.length() > 1e-6:
				var a: AABB = vi.global_transform * a_local
				if first: result = a; first = false
				else: result = result.merge(a)
		for c in n.get_children():
			if c is Node3D: stack.append(c)
	if first:
		# Fallback — no renderable children found. Return a 1m cube at origin
		# so _fit_artifact has SOMETHING to work with rather than bailing out.
		return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
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
