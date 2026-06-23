extends Node3D
class_name RackTemplates

const BakedTextAlbedo := preload("res://commons/utils/baked_text_albedo.gd")

## Composable rack panel builder — Dieter Rams aesthetic.
##
## Universal API:
##   var panel = RackTemplates.create_panel("TITLE", [
##       [{"type": "slider_h", "label": "FREQ", "default": 0.5}],
##       [{"type": "button", "label": "RESET"}],
##   ])
##
## Element types: slider_h, slider_v, knob, button, monitor, code, gauge, label, spacer
## Sugar functions (create_parameter_panel, create_fader_bank, etc.) wrap create_panel.

# ── Dieter Rams palette ──────────────────────────────────────────────
const CREAM := Color(0.90, 0.87, 0.80)
const CREAM_LIGHT := Color(0.93, 0.91, 0.85)
const DARK := Color(0.12, 0.12, 0.12)
const COPPER := Color(0.75, 0.38, 0.13)
const WARM_DARK := Color(0.25, 0.23, 0.20)
const RECESS := Color(0.82, 0.79, 0.72)   # slightly darker cream for element wells
const HP := 0.018

# ── Element dimensions (width, height) in meters ────────────────────
# These are the SLOT sizes — the actual scene may be smaller
const ELEM_SIZE := {
	"slider_h":  Vector2(0.14, 0.045),
	"slider_v":  Vector2(0.05, 0.13),
	"knob":      Vector2(0.065, 0.065),
	"button":    Vector2(0.06, 0.05),
	"monitor":   Vector2(0.16, 0.10),
	"code":      Vector2(0.22, 0.035),
	"gauge":     Vector2(0.10, 0.08),
	"label":     Vector2(0.08, 0.02),
	"spacer":    Vector2(0.04, 0.01),
	# ── Visualization elements ──
	"histogram": Vector2(0.14, 0.08),
	"matrix":    Vector2(0.10, 0.08),
	"graph":     Vector2(0.12, 0.08),
	"spectrum":  Vector2(0.14, 0.06),
	"phase":     Vector2(0.08, 0.08),
}

const ELEM_GAP := 0.012       # horizontal gap between elements in a row
const ROW_GAP := 0.012        # vertical gap between rows
const LABEL_H := 0.016        # height reserved for label below element
const TITLE_H := 0.024        # height reserved for title
const PAD := 0.016            # panel edge padding


# ══════════════════════════════════════════════════════════════════════
# UNIVERSAL BUILDER
# ══════════════════════════════════════════════════════════════════════

## frameless: if true, skip all panel geometry (cream box, frame, accent, recesses).
## Used by create_csg_case() where the CSG boolean IS the frame.
## Controls are placed at the same positions but with no backing mesh.
static func create_panel(title: String, rows: Array, frameless: bool = false) -> Node3D:
	var module := Node3D.new()
	module.name = title.replace(" ", "_")

	# ── 1. Measure ────────────────────────────────────────────────
	var row_widths: Array[float] = []
	var row_heights: Array[float] = []

	for row in rows:
		var rw := 0.0
		var rh := 0.0
		for i in row.size():
			var elem: Dictionary = row[i]
			var t: String = elem.get("type", "spacer")
			var sz: Vector2 = ELEM_SIZE.get(t, Vector2(0.04, 0.04))
			rw += sz.x
			if i > 0:
				rw += ELEM_GAP
			rh = maxf(rh, sz.y + LABEL_H)
		row_widths.append(rw)
		row_heights.append(rh)

	var panel_w := 0.0
	for rw in row_widths:
		panel_w = maxf(panel_w, rw)
	panel_w += PAD * 2

	var panel_h := TITLE_H + PAD
	for rh in row_heights:
		panel_h += rh + ROW_GAP
	panel_h += PAD - ROW_GAP

	# Store dimensions for CSG case to read
	module.set_meta("panel_w", panel_w)
	module.set_meta("panel_h", panel_h)

	# ── 2. Build panel + frame (skip if frameless) ────────────────
	if not frameless:
		_add_panel(module, panel_w, panel_h)
	_add_title(module, title, panel_w, panel_h)

	# ── 3. Place elements ─────────────────────────────────────────
	var counters := {"slider_h": 0, "slider_v": 0, "knob": 0, "button": 0, "monitor": 0, "code": 0, "gauge": 0, "label": 0, "histogram": 0, "matrix": 0, "graph": 0, "spectrum": 0, "phase": 0}
	var cursor_y := panel_h / 2.0 - TITLE_H - PAD

	for ri in rows.size():
		var row: Array = rows[ri]
		var rw: float = row_widths[ri]
		var rh: float = row_heights[ri]
		var cursor_x := -rw / 2.0

		for elem in row:
			var t: String = elem.get("type", "spacer")
			var sz: Vector2 = ELEM_SIZE.get(t, Vector2(0.04, 0.04))
			var cx := cursor_x + sz.x / 2.0
			var cy := cursor_y - sz.y / 2.0

			if t != "spacer":
				# Element recess/well behind the control (skip in frameless mode)
				if not frameless and t in ["slider_h", "slider_v", "knob", "button", "monitor", "gauge"]:
					_add_element_recess(module, cx, cy, sz.x, sz.y)

				var node: Node = _instantiate_element(t, elem, counters)
				if node:
					node.transform.origin = Vector3(cx, cy, 0.012)
					module.add_child(node)

				# Label below element — capped to this control's column width so labels never collide.
				var lbl_text: String = elem.get("label", "")
				if lbl_text != "":
					_add_label(module, lbl_text, Vector3(cx, cy - sz.y / 2.0 - 0.012, 0.012), 11, HORIZONTAL_ALIGNMENT_CENTER, sz.x + ELEM_GAP)

			cursor_x += sz.x + ELEM_GAP

		cursor_y -= rh + ROW_GAP

	return module


# ── Element recess (recessed well behind each control) ───────────────

static func _add_element_recess(parent: Node3D, cx: float, cy: float, w: float, h: float) -> void:
	var recess := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(w + 0.004, h + 0.004, 0.003)
	recess.mesh = rbox
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = RECESS
	rmat.roughness = 0.9
	recess.material_override = rmat
	recess.transform.origin = Vector3(cx, cy, 0.003)
	parent.add_child(recess)

	# Thin dark border around recess
	var border := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(w + 0.006, h + 0.006, 0.001)
	border.mesh = bbox
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.65, 0.62, 0.56)
	bmat.roughness = 0.8
	border.material_override = bmat
	border.transform.origin = Vector3(cx, cy, 0.002)
	parent.add_child(border)


# ── Element factory ──────────────────────────────────────────────────

static func _instantiate_element(type: String, elem: Dictionary, counters: Dictionary) -> Node:
	var idx: int = counters.get(type, 0)
	counters[type] = idx + 1

	match type:
		"slider_h":
			var slider: Node = load("res://commons/interactables/slider_horizontal.tscn").instantiate()
			slider.name = "Param_%d" % idx
			slider.scale = Vector3.ONE * 0.7
			if slider.has_method("set_param_name"):
				slider.set_param_name(elem.get("label", "P%d" % idx))
			var nm_lbl = slider.find_child("LabelName", true, false)
			if nm_lbl:
				nm_lbl.visible = false
			var def: float = elem.get("default", -1.0)
			if def >= 0.0 and slider.has_method("set_normalized_value"):
				slider.set_normalized_value(def)
			return slider

		"slider_v":
			var slider: Node = load("res://commons/interactables/slider_smooth.tscn").instantiate()
			slider.name = "Fader_%d" % idx
			slider.scale = Vector3.ONE * 0.8
			if slider.has_method("set_param_name"):
				slider.set_param_name(elem.get("label", "F%d" % idx))
			var def: float = elem.get("default", -1.0)
			if def >= 0.0 and slider.has_method("set_normalized_value"):
				slider.set_normalized_value(def)
			return slider

		"knob":
			var knob: Node = load("res://commons/interactables/dial_smooth.tscn").instantiate()
			knob.name = "Knob_%d" % idx
			knob.scale = Vector3.ONE * 0.85
			if knob.has_method("set_param_name"):
				knob.set_param_name(elem.get("label", "K%d" % idx))
			return knob

		"button":
			# Round button (already rotated to face +Z in the .tscn root transform)
			var btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")
			if not btn_scene:
				return null
			var btn: Node = btn_scene.instantiate()
			btn.name = "Btn_%d" % idx
			btn.scale = Vector3.ONE * 0.55
			# Hide the flat base plate (it sticks out as a shelf when panel-mounted)
			var base_mesh: Node = btn.find_child("BaseMesh", true, false)
			if base_mesh:
				base_mesh.visible = false
			return btn

		"monitor":
			var container := Node3D.new()
			container.name = "Monitor_%d" % idx
			var sz: Vector2 = ELEM_SIZE["monitor"]
			# Build monitor inline instead of RackPassiveElements (better size control)
			# Dark screen background
			var screen_bg := MeshInstance3D.new()
			screen_bg.name = "ScreenBg"
			var sbox := BoxMesh.new()
			sbox.size = Vector3(sz.x - 0.01, sz.y - 0.01, 0.004)
			screen_bg.mesh = sbox
			var smat := StandardMaterial3D.new()
			smat.albedo_color = Color(0.04, 0.04, 0.04)
			smat.metallic = 0.1
			smat.roughness = 0.85
			screen_bg.material_override = smat
			container.add_child(screen_bg)
			# Scanline overlay hint (thin horizontal lines via emission)
			var glow := MeshInstance3D.new()
			glow.name = "Glow"
			var gbox := BoxMesh.new()
			gbox.size = Vector3(sz.x - 0.015, 0.001, 0.001)
			glow.mesh = gbox
			var gmat := StandardMaterial3D.new()
			gmat.albedo_color = Color(0.1, 0.9, 0.2)
			gmat.emission = Color(0.1, 0.9, 0.2)
			gmat.emission_energy_multiplier = 0.5
			glow.material_override = gmat
			glow.transform.origin = Vector3(0, 0, 0.003)
			container.add_child(glow)
			# SubViewport waveform (if RackPassiveElements available)
			var RackPassive: GDScript = load("res://commons/interactables/RackPassiveElements.gd")
			if RackPassive and RackPassive.has_method("build_monitor_grid"):
				var sub_container := Node3D.new()
				sub_container.name = "WaveformContainer"
				sub_container.scale = Vector3(sz.x / 0.26, sz.y / 0.18, 1.0)
				sub_container.transform.origin.z = 0.001
				container.add_child(sub_container)
				var mode: String = elem.get("mode", "scope")
				RackPassive.build_monitor_grid(sub_container, 1, mode)
			return container

		"code":
			var container := Node3D.new()
			container.name = "Code_%d" % idx
			var text: String = elem.get("text", elem.get("label", ""))
			var sz: Vector2 = ELEM_SIZE["code"]
			# Dark background with subtle border
			var bg := MeshInstance3D.new()
			var bgbox := BoxMesh.new()
			bgbox.size = Vector3(sz.x - 0.01, sz.y, 0.004)
			bg.mesh = bgbox
			var bgmat := StandardMaterial3D.new()
			bgmat.albedo_color = Color(0.04, 0.04, 0.06)
			bgmat.metallic = 0.05
			bgmat.roughness = 0.9
			bg.material_override = bgmat
			container.add_child(bg)
			# Code text
			var lbl := Label3D.new()
			lbl.name = "Text"
			lbl.text = text
			lbl.font_size = 11
			lbl.pixel_size = 0.0004
			lbl.modulate = Color(0.3, 0.7, 0.95)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.transform.origin.z = 0.004
			container.add_child(lbl)
			return container

		"gauge":
			var container := Node3D.new()
			container.name = "Gauge_%d" % idx
			# Meter face (light cream with metallic sheen)
			var face := MeshInstance3D.new()
			var fmesh := BoxMesh.new()
			fmesh.size = Vector3(0.08, 0.05, 0.004)
			face.mesh = fmesh
			var fmat := StandardMaterial3D.new()
			fmat.albedo_color = Color(0.95, 0.92, 0.85)
			fmat.metallic = 0.1
			fmat.roughness = 0.6
			face.material_override = fmat
			container.add_child(face)
			# Arc ticks
			for i in 9:
				var pct := float(i) / 8.0
				var a := PI + pct * PI
				var tick := MeshInstance3D.new()
				var tbox := BoxMesh.new()
				tbox.size = Vector3(0.001, 0.006, 0.001)
				tick.mesh = tbox
				var tmat := StandardMaterial3D.new()
				tmat.albedo_color = Color(0.8, 0.2, 0.2) if i >= 7 else Color(0.2, 0.2, 0.2)
				tick.material_override = tmat
				tick.transform.origin = Vector3(cos(a) * 0.028, sin(a) * 0.016, 0.004)
				tick.rotation.z = a - PI / 2.0
				container.add_child(tick)
			# Needle
			var needle := MeshInstance3D.new()
			needle.name = "Needle"
			var nbox := BoxMesh.new()
			nbox.size = Vector3(0.0015, 0.025, 0.001)
			needle.mesh = nbox
			var nmat := StandardMaterial3D.new()
			nmat.albedo_color = COPPER
			nmat.emission = COPPER
			nmat.emission_energy_multiplier = 0.3
			needle.material_override = nmat
			needle.transform.origin = Vector3(0.008, 0, 0.006)
			needle.rotation.z = -0.4
			container.add_child(needle)
			return container

		# ── Visualization elements (SubViewport with live 2D drawing) ──

		"histogram":
			return _build_viz_element("Histogram_%d" % idx, ELEM_SIZE["histogram"], "histogram")

		"matrix":
			var cols: int = elem.get("cols", 8)
			var rows_count: int = elem.get("rows_count", 8)
			return _build_viz_element("Matrix_%d" % idx, ELEM_SIZE["matrix"], "matrix_%d_%d" % [cols, rows_count])

		"graph":
			return _build_viz_element("Graph_%d" % idx, ELEM_SIZE["graph"], "graph")

		"spectrum":
			return _build_viz_element("Spectrum_%d" % idx, ELEM_SIZE["spectrum"], "spectrum")

		"phase":
			return _build_viz_element("Phase_%d" % idx, ELEM_SIZE["phase"], "phase")

		"label":
			var container := Node3D.new()
			container.name = "Label_%d" % idx
			var text: String = elem.get("text", elem.get("label", ""))
			var lbl := Label3D.new()
			lbl.name = "Text"
			lbl.text = text
			lbl.font_size = 14
			lbl.pixel_size = 0.0004
			lbl.modulate = Color(0.15, 0.15, 0.15)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			container.add_child(lbl)
			return container

	return null


# ── Visualization element builder (SubViewport + live 2D draw) ───────

static func _build_viz_element(node_name: String, sz: Vector2, mode: String) -> Node3D:
	var container := Node3D.new()
	container.name = node_name

	# Dark screen background
	var bg := MeshInstance3D.new()
	bg.name = "ScreenBg"
	var bgbox := BoxMesh.new()
	bgbox.size = Vector3(sz.x - 0.006, sz.y - 0.006, 0.004)
	bg.mesh = bgbox
	var bgmat := StandardMaterial3D.new()
	bgmat.albedo_color = Color(0.04, 0.04, 0.04)
	bgmat.metallic = 0.1
	bgmat.roughness = 0.85
	bg.material_override = bgmat
	container.add_child(bg)

	# SubViewport for live drawing
	var viewport := SubViewport.new()
	viewport.name = "VizViewport"
	viewport.disable_3d = true
	viewport.size = Vector2i(int(sz.x * 1600), int(sz.y * 1600))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	container.add_child(viewport)

	# 2D drawing control
	var draw_ctrl := Control.new()
	draw_ctrl.name = "VizDraw"
	draw_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_ctrl.set_script(_create_viz_script(mode))
	viewport.add_child(draw_ctrl)

	# Textured quad
	var quad := MeshInstance3D.new()
	quad.name = "ScreenQuad"
	var qmesh := QuadMesh.new()
	qmesh.size = Vector2(sz.x - 0.008, sz.y - 0.008)
	quad.mesh = qmesh
	var qmat := StandardMaterial3D.new()
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.albedo_texture = viewport.get_texture()
	quad.material_override = qmat
	quad.transform.origin.z = 0.004
	container.add_child(quad)

	# Mode label (small copper text, top-left)
	var mode_short: String = mode.split("_")[0].to_upper()
	var mlbl := Label3D.new()
	mlbl.text = mode_short
	mlbl.font_size = 10
	mlbl.pixel_size = 0.0003
	mlbl.modulate = COPPER
	mlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mlbl.transform.origin = Vector3(-sz.x / 2.0 + 0.008, sz.y / 2.0 - 0.008, 0.006)
	container.add_child(mlbl)

	return container


static func _create_viz_script(mode: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = _get_viz_source(mode)
	script.reload()
	return script


static func _get_viz_source(mode: String) -> String:
	# Common header for all viz scripts
	var header := """extends Control

var _time: float = 0.0
var _mode: String = "%s"

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.04, 0.04))
""" % mode

	if mode == "histogram":
		return header + """
	# Animated bar chart — distribution visualization
	var bars: int = 16
	var bar_w: float = w / float(bars) - 2.0
	for i in bars:
		var t: float = float(i) / float(bars)
		# Bell curve shape with noise
		var center: float = 0.5 + sin(_time * 0.3) * 0.15
		var dist: float = abs(t - center)
		var val: float = exp(-dist * dist * 12.0) + sin(_time * 2.0 + float(i) * 0.7) * 0.08
		val = clampf(val, 0.05, 1.0)
		var bar_h: float = val * h * 0.85
		var x: float = float(i) * (bar_w + 2.0) + 1.0
		# Color gradient: green center, copper edges
		var green_mix: float = 1.0 - dist * 2.0
		var col: Color = Color(0.75 - green_mix * 0.55, 0.38 + green_mix * 0.52, 0.13, 0.8)
		draw_rect(Rect2(Vector2(x, h - bar_h), Vector2(bar_w, bar_h)), col)
	# Axis line
	draw_line(Vector2(0, h - 2), Vector2(w, h - 2), Color(0.3, 0.3, 0.3), 1.0)
"""

	if mode == "spectrum":
		return header + """
	# Frequency spectrum bars — audio visualization
	var bars: int = 24
	var bar_w: float = w / float(bars) - 1.0
	for i in bars:
		var t: float = float(i) / float(bars)
		var val: float = abs(sin(t * 8.0 + _time * 2.0) * 0.5 + sin(t * 13.0 - _time * 1.7) * 0.3)
		val *= (1.0 - t * 0.6)  # roll off high frequencies
		val = clampf(val, 0.02, 1.0)
		var bar_h: float = val * h * 0.9
		var x: float = float(i) * (bar_w + 1.0)
		# Green to copper gradient based on level
		var col: Color
		if val > 0.7:
			col = Color(0.85, 0.3, 0.1, 0.9)
		elif val > 0.4:
			col = Color(0.75, 0.65, 0.1, 0.85)
		else:
			col = Color(0.2, 0.85, 0.3, 0.75)
		draw_rect(Rect2(Vector2(x, h - bar_h), Vector2(bar_w, bar_h)), col)
"""

	if mode == "phase":
		return header + """
	# Lissajous / phase plot — oscillation visualization
	var cx: float = w / 2.0
	var cy: float = h / 2.0
	var r: float = min(w, h) * 0.4
	# Dim grid crosshair
	draw_line(Vector2(cx, 0), Vector2(cx, h), Color(0.15, 0.15, 0.15), 0.5)
	draw_line(Vector2(0, cy), Vector2(w, cy), Color(0.15, 0.15, 0.15), 0.5)
	# Lissajous curve
	var prev: Vector2 = Vector2.ZERO
	var points: int = 300
	for i in points:
		var t: float = float(i) / float(points)
		var px: float = cx + sin(_time * 1.3 + t * PI * 4.0) * r
		var py: float = cy + sin(_time * 2.1 + t * PI * 6.0) * r
		var pt: Vector2 = Vector2(px, py)
		if i > 0:
			var alpha: float = 0.3 + t * 0.7
			draw_line(prev, pt, Color(0.2, 0.9, 0.3, alpha), 2.0)
		prev = pt
	# Center dot
	draw_circle(Vector2(cx, cy), 3.0, Color(0.75, 0.38, 0.13))
"""

	if mode == "graph":
		return header + """
	# Node-link graph — network visualization
	var nodes: Array = []
	var node_count: int = 8
	# Deterministic positions with gentle drift
	for i in node_count:
		var angle: float = float(i) / float(node_count) * TAU + _time * 0.15
		var radius: float = min(w, h) * (0.25 + sin(float(i) * 1.7 + _time * 0.5) * 0.08)
		var nx: float = w / 2.0 + cos(angle) * radius
		var ny: float = h / 2.0 + sin(angle) * radius
		nodes.append(Vector2(nx, ny))
	# Draw edges
	for i in node_count:
		for j in range(i + 1, node_count):
			var dist: float = nodes[i].distance_to(nodes[j])
			if dist < min(w, h) * 0.55:
				var alpha: float = 1.0 - dist / (min(w, h) * 0.55)
				draw_line(nodes[i], nodes[j], Color(0.3, 0.6, 0.3, alpha * 0.5), 1.0)
	# Draw nodes
	for i in node_count:
		var pulse: float = 0.8 + sin(_time * 2.0 + float(i) * 0.9) * 0.2
		var r: float = 4.0 + pulse * 3.0
		draw_circle(nodes[i], r + 1.0, Color(0.1, 0.1, 0.1))
		var col: Color = Color(0.2, 0.85, 0.3) if i % 3 != 2 else Color(0.75, 0.38, 0.13)
		draw_circle(nodes[i], r, col * pulse)
"""

	# Matrix mode: parse cols and rows from mode string "matrix_8_8"
	if mode.begins_with("matrix"):
		var parts: PackedStringArray = mode.split("_")
		var cols_str: String = parts[1] if parts.size() > 1 else "8"
		var rows_str: String = parts[2] if parts.size() > 2 else "8"
		return header + """
	# Cell matrix — cellular automata / patch bay visualization
	var cols: int = %s
	var rows: int = %s
	var cell_w: float = w / float(cols)
	var cell_h: float = h / float(rows)
	var gap: float = 1.0
	for row in rows:
		for col in cols:
			var val: float = sin(float(col) * 1.3 + float(row) * 2.1 + _time * 1.5)
			var alive: bool = val > 0.0
			var brightness: float = abs(val)
			var cx: float = float(col) * cell_w + gap
			var cy: float = float(row) * cell_h + gap
			var cw: float = cell_w - gap * 2.0
			var ch: float = cell_h - gap * 2.0
			if alive:
				var col_mix: float = sin(float(col + row) * 0.5 + _time) * 0.5 + 0.5
				var color: Color
				if col_mix > 0.6:
					color = Color(0.75, 0.38, 0.13, brightness * 0.8 + 0.2)
				elif col_mix > 0.3:
					color = Color(0.2, 0.85, 0.3, brightness * 0.7 + 0.3)
				else:
					color = Color(0.6, 0.2, 0.8, brightness * 0.6 + 0.2)
				draw_rect(Rect2(Vector2(cx, cy), Vector2(cw, ch)), color)
			else:
				draw_rect(Rect2(Vector2(cx, cy), Vector2(cw, ch)), Color(0.08, 0.08, 0.08))
""" % [cols_str, rows_str]

	# Fallback: simple sine wave
	return header + """
	var prev: Vector2 = Vector2.ZERO
	for i in int(w):
		var t: float = float(i) / w
		var yy: float = h / 2.0 + sin(t * PI * 6.0 + _time * 3.0) * h * 0.35
		var pt: Vector2 = Vector2(i, yy)
		if i > 0:
			draw_line(prev, pt, Color(0.2, 0.9, 0.3), 2.0)
		prev = pt
"""


# ══════════════════════════════════════════════════════════════════════
# SUGAR FUNCTIONS — backward-compatible wrappers
# ══════════════════════════════════════════════════════════════════════

## N vertical sliders side by side
static func create_fader_bank(count: int, labels: Array = [], _params: Array = []) -> Node3D:
	var row := []
	for i in count:
		var lbl: String = labels[i] if i < labels.size() else "CH%d" % (i + 1)
		row.append({"type": "slider_v", "label": lbl})
	return create_panel("FADER BANK", [row])


## N rotary knobs in a row
static func create_knob_panel(count: int, labels: Array = []) -> Node3D:
	var row := []
	for i in count:
		var lbl: String = labels[i] if i < labels.size() else "K%d" % (i + 1)
		row.append({"type": "knob", "label": lbl})
	return create_panel("KNOBS", [row])


## N horizontal sliders stacked + reset button
static func create_parameter_panel(count: int, labels: Array = [], defaults: Array = []) -> Node3D:
	var slider_row := []
	for i in count:
		var lbl: String = labels[i] if i < labels.size() else "P%d" % (i + 1)
		var def: float = defaults[i] if i < defaults.size() else 0.5
		slider_row.append({"type": "slider_h", "label": lbl, "default": def})
	return create_panel("PARAMETERS", [slider_row, [{"type": "button", "label": "RESET"}]])


## Array of buttons (cols x rows)
static func create_button_grid(cols: int, rows: int, labels: Array = [], _colors: Array = []) -> Node3D:
	var grid_rows := []
	var idx := 0
	for _r in rows:
		var row := []
		for _c in cols:
			var lbl: String = labels[idx] if idx < labels.size() else "%d" % (idx + 1)
			row.append({"type": "button", "label": lbl})
			idx += 1
		grid_rows.append(row)
	return create_panel("CONTROLS", grid_rows)


## Fader + pan knob + mute button (vertical strip)
static func create_mixer_strip(strip_label: String = "CH") -> Node3D:
	return create_panel(strip_label, [
		[{"type": "slider_v", "label": "VOL"}],
		[{"type": "knob", "label": "PAN"}],
		[{"type": "button", "label": "MUTE"}],
	])


## Monitor display on top, faders below
static func create_monitor_faders(fader_count: int, labels: Array = [], mode: String = "scope") -> Node3D:
	var fader_row := []
	for i in fader_count:
		var lbl: String = labels[i] if i < labels.size() else "F%d" % (i + 1)
		fader_row.append({"type": "slider_v", "label": lbl})
	return create_panel("MONITOR", [
		[{"type": "monitor", "label": "", "mode": mode}],
		fader_row,
	])


## Horizontal sliders + code snippet display
static func create_shader_panel(count: int, labels: Array = [], defaults: Array = [], code_snippet: String = "") -> Node3D:
	var slider_row := []
	for i in count:
		var lbl: String = labels[i] if i < labels.size() else "U%d" % i
		var def: float = defaults[i] if i < defaults.size() else 0.5
		slider_row.append({"type": "slider_h", "label": lbl, "default": def})
	var all_rows := [slider_row]
	if code_snippet != "":
		all_rows.append([{"type": "code", "text": code_snippet, "label": ""}])
	return create_panel("SHADER", all_rows)


## VU-style needle meter + trim knob
static func create_gauge_meter(meter_label: String = "LEVEL", knob_label: String = "TRIM") -> Node3D:
	return create_panel(meter_label, [
		[{"type": "gauge", "label": ""}],
		[{"type": "knob", "label": knob_label}],
	])


## Row of preset buttons + optional slider
static func create_preset_bar(preset_labels: Array, _preset_colors: Array = [], slider_label: String = "", slider_default: float = 0.5) -> Node3D:
	var row := []
	for lbl in preset_labels:
		row.append({"type": "button", "label": lbl})
	if slider_label != "":
		row.append({"type": "slider_h", "label": slider_label, "default": slider_default})
	return create_panel("PRESETS", [row])


## Multi-section experiment layout
static func create_experiment_panel(sections: Array) -> Node3D:
	var all_rows := []
	var title_row := []
	for sec in sections:
		title_row.append({"type": "label", "text": sec.get("title", ""), "label": ""})
	all_rows.append(title_row)

	var max_sliders := 0
	for sec in sections:
		var sl: Array = sec.get("sliders", [])
		max_sliders = maxi(max_sliders, sl.size())

	for si in max_sliders:
		var row := []
		for sec in sections:
			var sl: Array = sec.get("sliders", [])
			if si < sl.size():
				var sd: Dictionary = sl[si]
				row.append({"type": "slider_h", "label": sd.get("label", ""), "default": sd.get("default", 0.5)})
			else:
				row.append({"type": "spacer", "label": ""})
		all_rows.append(row)

	var max_buttons := 0
	for sec in sections:
		var bl: Array = sec.get("buttons", [])
		max_buttons = maxi(max_buttons, bl.size())

	for bi in max_buttons:
		var row := []
		for sec in sections:
			var bl: Array = sec.get("buttons", [])
			if bi < bl.size():
				row.append({"type": "button", "label": bl[bi]})
			else:
				row.append({"type": "spacer", "label": ""})
		all_rows.append(row)

	return create_panel("EXPERIMENT", all_rows)


# ══════════════════════════════════════════════════════════════════════
# CASE HOUSINGS — physical furniture that holds panels
# ══════════════════════════════════════════════════════════════════════

## Wrap a panel in a physical case/housing.
## Types:
##   "wall"    — flat wall mount, simple bracket frame
##   "desktop" — tilted 35° toward player, with base foot
##   "studio"  — wooden angled case with side cheeks (producer desk style)
##   "rack"    — vertical 19"-style frame with rails
##
## Usage:
##   var panel = RackTemplates.create_panel("SYNTH", [...])
##   var cased = RackTemplates.create_case("desktop", panel)
##   add_child(cased)

static func create_case(case_type: String, panel: Node3D) -> Node3D:
	var housing := Node3D.new()
	housing.name = "Case_%s" % case_type

	# Measure panel from its Panel mesh child
	var panel_mesh: MeshInstance3D = panel.get_node_or_null("Panel")
	var pw := 0.28
	var ph := 0.20
	if panel_mesh and panel_mesh.mesh is BoxMesh:
		var box: BoxMesh = panel_mesh.mesh
		pw = box.size.x
		ph = box.size.y

	match case_type:
		"wall":
			_build_wall_case(housing, panel, pw, ph)
		"desktop":
			_build_desktop_case(housing, panel, pw, ph)
		"studio":
			_build_studio_case(housing, panel, pw, ph)
		"rack":
			_build_rack_case(housing, panel, pw, ph)
		_:
			# No case — just parent the panel directly
			housing.add_child(panel)

	return housing


# ══════════════════════════════════════════════════════════════════════
# CSG BOOLEAN CASE — 3 nodes: box + wedge cut + panel inset
# ══════════════════════════════════════════════════════════════════════

## Build a case using 3 CSG boolean operations.
## Pattern from res://commons/lab/booleancase/exempelbool.tscn:
##   CSGBox3D (solid) → CSGBox3D (subtract wedge) → CSGBox3D (subtract inset)
##
## Parameters:
##   w, h, d       — outer case dimensions (meters)
##   tilt_deg      — angle of the panel face (0 = wall, 35 = desk, 45 = steep)
##   panel         — the interface panel (from create_panel()), or null for empty case
##   case_color    — main case material color
##   inset_color   — recess interior color (darker)
##   inset_margin  — gap between panel edge and inset edge (padding)
##   inset_depth   — how deep the panel sits into the case

static func create_csg_case(
	w: float, h: float, d: float, tilt_deg: float,
	panel: Node3D = null,
	case_color: Color = Color(0.12, 0.12, 0.12),
	inset_margin: float = 0.008,
	inset_depth: float = 0.012
) -> Node3D:

	var container := Node3D.new()
	container.name = "CSGCase_%d" % int(tilt_deg)

	var tilt := deg_to_rad(tilt_deg)

	# ── Measure panel (from meta if frameless, else from Panel mesh) ──
	var pw := 0.20
	var ph := 0.14
	if panel:
		if panel.has_meta("panel_w"):
			pw = panel.get_meta("panel_w")
			ph = panel.get_meta("panel_h")
		else:
			var pmesh: MeshInstance3D = panel.get_node_or_null("Panel")
			if pmesh and pmesh.mesh is BoxMesh:
				var pbox: BoxMesh = pmesh.mesh
				pw = pbox.size.x
				ph = pbox.size.y

	var inset_w := pw + inset_margin * 2.0
	var inset_h := ph + inset_margin * 2.0

	# ── Materials ─────────────────────────────────────────────────
	# Default: use the Grid wireframe shader (same as lab cubes)
	var case_mat: Material = _create_grid_shader_material(case_color)

	# Inset material is CREAM — the CSG recess IS the panel face
	var recess_mat := StandardMaterial3D.new()
	recess_mat.albedo_color = CREAM
	recess_mat.metallic = 0.05
	recess_mat.roughness = 0.75

	# ── NODE 1: Solid box ─────────────────────────────────────────
	var solid := CSGBox3D.new()
	solid.name = "SolidBox"
	solid.size = Vector3(w, h, d)
	solid.transform.origin = Vector3(0, h / 2.0, -d / 2.0)
	solid.operation = CSGShape3D.OPERATION_UNION
	solid.material = case_mat

	# ── NODE 2: Wedge cut (subtract) ──────────────────────────────
	# Large box rotated at tilt angle, positioned to slice the top-front.
	# Pivot point is the front edge where the angle starts.
	if tilt_deg > 1.0:
		var front_h := h * 0.4  # solid front portion height
		var cut_len := maxf(w, maxf(h, d)) * 2.5  # oversized to ensure clean cut

		var wedge := CSGBox3D.new()
		wedge.name = "WedgeCut"
		wedge.operation = CSGShape3D.OPERATION_SUBTRACTION
		wedge.size = Vector3(w + 0.002, cut_len, cut_len)
		# Place above pivot so the bottom face of this box IS the cut plane
		wedge.transform.origin = Vector3(0, cut_len / 2.0, 0)

		# Pivot at the front edge at front_h height
		var wedge_pivot := Node3D.new()
		wedge_pivot.name = "WedgePivot"
		wedge_pivot.transform.origin = Vector3(0, front_h, 0)
		wedge_pivot.rotation.x = -tilt

		wedge_pivot.add_child(wedge)
		solid.add_child(wedge_pivot)

		# ── NODE 3: Panel inset (subtract from wedge child) ───────
		# Counter-rotate so the inset is aligned flat on the angled face.
		var inset := CSGBox3D.new()
		inset.name = "PanelInset"
		inset.operation = CSGShape3D.OPERATION_SUBTRACTION
		inset.size = Vector3(inset_w, inset_h, inset_depth + 0.02)
		inset.material = recess_mat
		# Position: centered on the angled face, pushed in by inset_depth
		inset.transform.origin = Vector3(0, 0, inset_depth / 2.0 + 0.005)

		# Counter-rotate to align with angled face
		var inset_pivot := Node3D.new()
		inset_pivot.name = "InsetPivot"
		# Same pivot point as wedge, but rotate back to face normal of cut
		var angle_center_y := (front_h + h) / 2.0 - front_h
		var angle_center_z := 0.0
		# The cut face center in wedge-pivot-local space:
		# after wedge pivot rotates by -tilt, the cut face is horizontal locally
		# The center of the visible face is at mid-height of the remaining angle
		var face_h := (h - front_h) / sin(tilt) if sin(tilt) > 0.01 else h
		var face_center_local_y := face_h / 2.0
		inset.transform.origin = Vector3(0, -face_center_local_y, inset_depth / 2.0 + 0.003)

		wedge_pivot.add_child(inset)

	else:
		# Wall case (0° tilt): inset directly on front face
		var inset := CSGBox3D.new()
		inset.name = "PanelInset"
		inset.operation = CSGShape3D.OPERATION_SUBTRACTION
		inset.size = Vector3(inset_w, inset_h, inset_depth + 0.02)
		inset.material = recess_mat
		inset.transform.origin = Vector3(0, 0, inset_depth / 2.0 + 0.005)
		solid.add_child(inset)

	container.add_child(solid)

	# ── Place panel in the inset ──────────────────────────────────
	if panel:
		if tilt_deg > 1.0:
			var front_h := h * 0.4
			var panel_pivot := Node3D.new()
			panel_pivot.name = "PanelMount"
			panel_pivot.transform.origin = Vector3(0, front_h, 0)
			panel_pivot.rotation.x = -tilt

			var face_h := (h - front_h) / sin(tilt) if sin(tilt) > 0.01 else h
			panel.transform.origin = Vector3(0, -face_h / 2.0, inset_depth + 0.005)
			panel_pivot.add_child(panel)
			container.add_child(panel_pivot)
		else:
			panel.transform.origin = Vector3(0, h / 2.0, inset_depth + 0.005)
			container.add_child(panel)

	return container


# ══════════════════════════════════════════════════════════════════════
# GRID-FITTED CASES — panels sized to fit 1m cube subdivisions
# ══════════════════════════════════════════════════════════════════════

## Preset: shelf-level slot (case sits on table at y=1.0, tilted 35°)
static func shelf_slot(cube_size: float = 1.0) -> Dictionary:
	return {
		"mount": "shelf",
		"cube_fraction": Vector3(0.5, 0.5, 0.6),
		"offset": Vector3(-0.25, 0.0, 0.15),
		"tilt": 35.0,
		"case_style": "dark",
		"cube_size": cube_size,
	}

## Preset: wall-level slot (hanging frame in cube above table)
static func wall_slot(cube_size: float = 1.0) -> Dictionary:
	return {
		"mount": "wall",
		"cube_fraction": Vector3(0.6, 0.8, 0.12),
		"offset": Vector3(0.0, 0.35, 0.25),
		"tilt": 0.0,
		"case_style": "dark",
		"cube_size": cube_size,
	}

## Preset: floor pedestal (standing case at ground level)
static func floor_pedestal_slot(cube_size: float = 1.0) -> Dictionary:
	return {
		"mount": "floor",
		"cube_fraction": Vector3(0.4, 0.8, 0.4),
		"offset": Vector3(0.0, 0.0, 0.0),
		"tilt": 25.0,
		"case_style": "wood",
		"cube_size": cube_size,
	}


## Build a case fitted to a grid cube subdivision.
## The slot dictionary defines available space, offset, tilt, and style.
## The panel is auto-scaled to fit inside the computed case interior.
##
## slot keys:
##   "mount": "shelf" | "wall" | "floor"
##   "cube_fraction": Vector3 — fraction of 1m cube (width, height, depth)
##   "offset": Vector3 — local offset within grid cell
##   "tilt": float — panel angle in degrees
##   "case_style": "dark" | "wood" | "rack"
##   "cube_size": float — grid cell size (default 1.0)

static func create_fitted_case(slot: Dictionary, panel: Node3D) -> Node3D:
	var housing := Node3D.new()
	var mount: String = slot.get("mount", "shelf")
	housing.name = "FittedCase_%s" % mount

	var cs: float = slot.get("cube_size", 1.0)
	var frac: Vector3 = slot.get("cube_fraction", Vector3(0.5, 0.5, 0.6))
	var offset: Vector3 = slot.get("offset", Vector3.ZERO)
	var tilt_deg: float = slot.get("tilt", 35.0)
	var style: String = slot.get("case_style", "dark")

	# ── 1. Available space from cube subdivision ──────────────────
	var avail := frac * cs  # e.g. Vector3(0.5, 0.5, 0.6) meters

	# ── 2. Case outer dimensions (available minus margin) ─────────
	var margin := 0.01
	var case_w := avail.x - margin * 2.0
	var case_h := avail.y - margin * 2.0
	var case_d := avail.z - margin * 2.0

	# ── 3. Wall thickness depends on style ────────────────────────
	var wall_t := 0.012
	match style:
		"wood": wall_t = 0.022
		"rack": wall_t = 0.014

	# ── 4. Panel interior space ───────────────────────────────────
	var tilt := deg_to_rad(tilt_deg)
	var interior_w := case_w - wall_t * 2.0
	var interior_h: float
	if tilt_deg > 5.0:
		# Tilted: panel height limited by case depth projected onto tilt
		interior_h = minf(case_d / cos(tilt) - wall_t, case_h / sin(tilt) - wall_t)
		interior_h = maxf(interior_h, 0.05)
	else:
		# Flat: panel fills case face
		interior_h = case_h - wall_t * 2.0

	# ── 5. Measure existing panel and compute scale ───────────────
	var panel_mesh: MeshInstance3D = panel.get_node_or_null("Panel")
	var pw := 0.28
	var ph := 0.20
	if panel_mesh and panel_mesh.mesh is BoxMesh:
		var box: BoxMesh = panel_mesh.mesh
		pw = box.size.x
		ph = box.size.y

	var scale_factor := minf(interior_w / maxf(pw, 0.01), interior_h / maxf(ph, 0.01))
	scale_factor = minf(scale_factor, 1.0)  # don't upscale

	# ── 6. Pick case material ─────────────────────────────────────
	var case_mat: StandardMaterial3D
	match style:
		"wood":
			case_mat = StandardMaterial3D.new()
			case_mat.albedo_color = Color(0.55, 0.38, 0.22)
			case_mat.metallic = 0.05
			case_mat.roughness = 0.6
		"rack":
			case_mat = StandardMaterial3D.new()
			case_mat.albedo_color = Color(0.20, 0.20, 0.22)
			case_mat.metallic = 0.5
			case_mat.roughness = 0.35
		_:
			case_mat = StandardMaterial3D.new()
			case_mat.albedo_color = Color(0.12, 0.12, 0.12)
			case_mat.metallic = 0.35
			case_mat.roughness = 0.55

	# ── 7. Build case geometry based on mount type ────────────────
	match mount:
		"wall":
			_build_fitted_wall(housing, panel, case_w, case_h, case_d, scale_factor, case_mat)
		"floor":
			_build_fitted_tilted(housing, panel, case_w, case_h, case_d, tilt, scale_factor, case_mat, wall_t)
		_: # "shelf" and default
			_build_fitted_tilted(housing, panel, case_w, case_h, case_d, tilt, scale_factor, case_mat, wall_t)

	# ── 8. Apply grid offset ─────────────────────────────────────
	housing.transform.origin = offset

	# ── 9. Debug wireframe cube (shows the slot boundary) ─────────
	var wire := _make_wireframe_box(avail.x, avail.y, avail.z)
	wire.transform.origin = Vector3(0, avail.y / 2.0, -avail.z / 2.0) - offset
	housing.add_child(wire)

	return housing


## Fitted wall case — panel flat, back plate sized to slot
static func _build_fitted_wall(housing: Node3D, panel: Node3D, cw: float, ch: float, cd: float, scale_f: float, case_mat: StandardMaterial3D) -> void:
	# Back plate
	var back := MeshInstance3D.new()
	back.name = "BackPlate"
	var bbox := BoxMesh.new()
	bbox.size = Vector3(cw, ch, maxf(cd, 0.008))
	back.mesh = bbox
	back.material_override = case_mat
	back.transform.origin = Vector3(0, ch / 2.0, -cd / 2.0)
	housing.add_child(back)

	# Mounting brackets
	var bracket_mat := StandardMaterial3D.new()
	bracket_mat.albedo_color = Color(0.35, 0.35, 0.38)
	bracket_mat.metallic = 0.6
	bracket_mat.roughness = 0.3
	for side in [-1.0, 1.0]:
		var bracket := MeshInstance3D.new()
		var brbox := BoxMesh.new()
		brbox.size = Vector3(0.012, 0.03, 0.01)
		bracket.mesh = brbox
		bracket.material_override = bracket_mat
		bracket.transform.origin = Vector3(side * (cw / 2.0 + 0.004), ch - 0.015, -0.003)
		housing.add_child(bracket)

	# Panel centered on face, scaled to fit
	panel.scale = Vector3.ONE * scale_f
	panel.transform.origin = Vector3(0, ch / 2.0, 0.004)
	housing.add_child(panel)


## Fitted tilted case — wedge cheeks, panel angled (used for shelf + floor)
static func _build_fitted_tilted(housing: Node3D, panel: Node3D, cw: float, ch: float, cd: float, tilt: float, scale_f: float, case_mat: StandardMaterial3D, wall_t: float) -> void:
	var base_depth := cd
	var case_height := ch

	# Wedge side cheeks
	for side in [-1.0, 1.0]:
		var cx: float = side * (cw / 2.0 + wall_t / 2.0)
		var cheek_mesh := MeshInstance3D.new()
		cheek_mesh.name = "Cheek_%s" % ("L" if side < 0 else "R")
		cheek_mesh.mesh = _build_wedge_mesh(base_depth, case_height, wall_t)
		cheek_mesh.material_override = case_mat
		cheek_mesh.transform.origin = Vector3(cx, 0, 0)
		housing.add_child(cheek_mesh)

	# Base plate
	var base := MeshInstance3D.new()
	base.name = "Base"
	var basebox := BoxMesh.new()
	basebox.size = Vector3(cw, 0.005, base_depth)
	base.mesh = basebox
	base.material_override = case_mat
	base.transform.origin = Vector3(0, -0.0025, -base_depth / 2.0)
	housing.add_child(base)

	# Back wall
	var back := MeshInstance3D.new()
	back.name = "Back"
	var bkbox := BoxMesh.new()
	bkbox.size = Vector3(cw, case_height, 0.005)
	back.mesh = bkbox
	back.material_override = case_mat
	back.transform.origin = Vector3(0, case_height / 2.0, -base_depth)
	housing.add_child(back)

	# Front face — solid block closing the gap below the tilted panel
	var front_h := case_height * 0.45
	var front_depth := base_depth * 0.3
	var front := MeshInstance3D.new()
	front.name = "Front"
	var frbox := BoxMesh.new()
	frbox.size = Vector3(cw, front_h, front_depth)
	front.mesh = frbox
	front.material_override = case_mat
	front.transform.origin = Vector3(0, front_h / 2.0, -front_depth / 2.0 + 0.003)
	housing.add_child(front)

	# Front lip on top of front face (metal accent edge)
	var lip_mat := StandardMaterial3D.new()
	lip_mat.albedo_color = Color(0.30, 0.30, 0.33)
	lip_mat.metallic = 0.5
	lip_mat.roughness = 0.4
	var lip := MeshInstance3D.new()
	lip.name = "FrontLip"
	var lbox := BoxMesh.new()
	lbox.size = Vector3(cw + 0.008, 0.006, front_depth + 0.004)
	lip.mesh = lbox
	lip.material_override = lip_mat
	lip.transform.origin = Vector3(0, front_h + 0.002, -front_depth / 2.0 + 0.003)
	housing.add_child(lip)

	# Panel tilted inside case — sits above the front face
	var pivot := Node3D.new()
	pivot.name = "PanelPivot"
	pivot.transform.origin = Vector3(0, front_h + 0.004, 0)
	pivot.rotation.x = -tilt
	panel.scale = Vector3.ONE * scale_f
	panel.transform.origin = Vector3(0, (ch * 0.3) * scale_f, 0)
	pivot.add_child(panel)
	housing.add_child(pivot)


## Debug wireframe box for visualizing the grid slot boundary
static func _make_wireframe_box(w: float, h: float, d: float) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var hw := w / 2.0
	var hd := d / 2.0
	# 12 edges of a box
	var corners := [
		Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd),
		Vector3(hw, 0, -hd), Vector3(hw, 0, hd),
		Vector3(hw, 0, hd), Vector3(-hw, 0, hd),
		Vector3(-hw, 0, hd), Vector3(-hw, 0, -hd),
		Vector3(-hw, h, -hd), Vector3(hw, h, -hd),
		Vector3(hw, h, -hd), Vector3(hw, h, hd),
		Vector3(hw, h, hd), Vector3(-hw, h, hd),
		Vector3(-hw, h, hd), Vector3(-hw, h, -hd),
		Vector3(-hw, 0, -hd), Vector3(-hw, h, -hd),
		Vector3(hw, 0, -hd), Vector3(hw, h, -hd),
		Vector3(hw, 0, hd), Vector3(hw, h, hd),
		Vector3(-hw, 0, hd), Vector3(-hw, h, hd),
	]
	for v in corners:
		im.surface_add_vertex(v)
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.name = "SlotWireframe"
	mi.mesh = im
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.4, 0.7, 0.4, 0.3)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = wmat
	return mi


# ── Wall mount: flat on wall, mounting brackets ──────────────────────

static func _build_wall_case(housing: Node3D, panel: Node3D, pw: float, ph: float) -> void:
	var CASE_DARK := Color(0.15, 0.15, 0.15)
	var CASE_METAL := Color(0.35, 0.35, 0.38)

	# Back plate (slightly larger than panel)
	var back := MeshInstance3D.new()
	back.name = "BackPlate"
	var bbox := BoxMesh.new()
	bbox.size = Vector3(pw + 0.02, ph + 0.02, 0.006)
	back.mesh = bbox
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = CASE_DARK
	bmat.metallic = 0.4
	bmat.roughness = 0.5
	back.material_override = bmat
	back.transform.origin.z = -0.008
	housing.add_child(back)

	# Mounting brackets (2 small L-shapes at top)
	for side in [-1.0, 1.0]:
		var bracket := MeshInstance3D.new()
		var brbox := BoxMesh.new()
		brbox.size = Vector3(0.015, 0.03, 0.012)
		bracket.mesh = brbox
		var brmat := StandardMaterial3D.new()
		brmat.albedo_color = CASE_METAL
		brmat.metallic = 0.6
		brmat.roughness = 0.3
		bracket.material_override = brmat
		bracket.transform.origin = Vector3(side * (pw / 2.0 + 0.005), ph / 2.0 - 0.015, -0.003)
		housing.add_child(bracket)

	# Panel sits flat
	housing.add_child(panel)


# ── Desktop stand: tilted 35° toward player, wedge side cheeks ──────

static func _build_desktop_case(housing: Node3D, panel: Node3D, pw: float, ph: float) -> void:
	var CASE_DARK := Color(0.12, 0.12, 0.12)
	var CASE_METAL := Color(0.25, 0.25, 0.28)
	var tilt := deg_to_rad(35.0)
	var base_depth := ph * cos(tilt) + 0.03
	var case_height := ph * sin(tilt) + 0.01
	var cheek_t := 0.012

	# Wedge side cheeks (triangular prism: base→back→slant)
	# Profile: front-bottom(0,0) → back-bottom(-depth,0) → back-top(-depth,height) → front(0,0)
	for side in [-1.0, 1.0]:
		var cx: float = side * (pw / 2.0 + cheek_t / 2.0 + 0.005)
		var cheek_mesh := MeshInstance3D.new()
		cheek_mesh.name = "Cheek_%s" % ("L" if side < 0 else "R")
		cheek_mesh.mesh = _build_wedge_mesh(base_depth, case_height, cheek_t)
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = CASE_DARK
		cmat.metallic = 0.35
		cmat.roughness = 0.55
		cheek_mesh.material_override = cmat
		cheek_mesh.transform.origin = Vector3(cx, 0, 0)
		housing.add_child(cheek_mesh)

	# Base plate between cheeks
	var base := MeshInstance3D.new()
	base.name = "Base"
	var basebox := BoxMesh.new()
	basebox.size = Vector3(pw + 0.01, 0.005, base_depth)
	base.mesh = basebox
	var basemat := StandardMaterial3D.new()
	basemat.albedo_color = CASE_DARK
	basemat.metallic = 0.3
	basemat.roughness = 0.6
	base.material_override = basemat
	base.transform.origin = Vector3(0, -0.0025, -base_depth / 2.0)
	housing.add_child(base)

	# Back wall
	var back := MeshInstance3D.new()
	back.name = "Back"
	var bkbox := BoxMesh.new()
	bkbox.size = Vector3(pw + 0.01, case_height, 0.005)
	back.mesh = bkbox
	var bkmat := StandardMaterial3D.new()
	bkmat.albedo_color = CASE_DARK
	bkmat.metallic = 0.3
	bkmat.roughness = 0.6
	back.material_override = bkmat
	back.transform.origin = Vector3(0, case_height / 2.0, -base_depth)
	housing.add_child(back)

	# Front face — solid panel closing the gap below the tilted interface
	var front_h := case_height * 0.45
	# Depth: from z=0 back to meet the base plate
	var front_depth := base_depth * 0.3
	var front := MeshInstance3D.new()
	front.name = "Front"
	var frbox := BoxMesh.new()
	frbox.size = Vector3(pw + 0.01, front_h, front_depth)
	front.mesh = frbox
	var frmat := StandardMaterial3D.new()
	frmat.albedo_color = CASE_DARK
	frmat.metallic = 0.3
	frmat.roughness = 0.6
	front.material_override = frmat
	front.transform.origin = Vector3(0, front_h / 2.0, -front_depth / 2.0 + 0.003)
	housing.add_child(front)

	# Front lip (metal accent on top of front face)
	var lip := MeshInstance3D.new()
	lip.name = "FrontLip"
	var lbox := BoxMesh.new()
	lbox.size = Vector3(pw + 0.018, 0.006, front_depth + 0.004)
	lip.mesh = lbox
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = CASE_METAL
	lmat.metallic = 0.5
	lmat.roughness = 0.4
	lip.material_override = lmat
	lip.transform.origin = Vector3(0, front_h + 0.002, -front_depth / 2.0 + 0.003)
	housing.add_child(lip)

	# Rubber feet
	for fx in [-1.0, 1.0]:
		for fz_off in [0.015, base_depth - 0.015]:
			var foot := MeshInstance3D.new()
			var fcyl := CylinderMesh.new()
			fcyl.top_radius = 0.005
			fcyl.bottom_radius = 0.007
			fcyl.height = 0.004
			foot.mesh = fcyl
			var fmat := StandardMaterial3D.new()
			fmat.albedo_color = Color(0.08, 0.08, 0.08)
			fmat.roughness = 0.95
			foot.material_override = fmat
			foot.transform.origin = Vector3(fx * (pw / 2.0 + 0.008), -0.005, -fz_off)
			housing.add_child(foot)

	# Panel: sits above front face, tilts back at 35°
	var panel_pivot := Node3D.new()
	panel_pivot.name = "PanelPivot"
	panel_pivot.transform.origin = Vector3(0, front_h + 0.004, 0)
	panel_pivot.rotation.x = -tilt
	panel.transform.origin = Vector3(0, ph / 2.0, 0)
	panel_pivot.add_child(panel)
	housing.add_child(panel_pivot)


# ── Studio case: wooden wedge cheeks, Moog style ────────────────────

static func _build_studio_case(housing: Node3D, panel: Node3D, pw: float, ph: float) -> void:
	var WOOD := Color(0.55, 0.38, 0.22)
	var WOOD_DARK := Color(0.35, 0.22, 0.12)
	var tilt := deg_to_rad(30.0)
	var case_depth := ph * cos(tilt) + 0.05
	var case_height := ph * sin(tilt) + 0.03
	var cheek_w := 0.022

	# Wedge wooden side cheeks
	for side in [-1.0, 1.0]:
		var cx: float = side * (pw / 2.0 + cheek_w / 2.0 + 0.006)
		var cheek_mesh := MeshInstance3D.new()
		cheek_mesh.name = "Cheek_%s" % ("L" if side < 0 else "R")
		cheek_mesh.mesh = _build_wedge_mesh(case_depth, case_height, cheek_w)
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = WOOD
		cmat.metallic = 0.05
		cmat.roughness = 0.6
		cheek_mesh.material_override = cmat
		cheek_mesh.transform.origin = Vector3(cx, 0, 0)
		housing.add_child(cheek_mesh)

		# Dark wood front edge accent
		var edge := MeshInstance3D.new()
		var ebox := BoxMesh.new()
		ebox.size = Vector3(cheek_w + 0.004, case_height * 0.15, 0.003)
		edge.mesh = ebox
		var emat := StandardMaterial3D.new()
		emat.albedo_color = WOOD_DARK
		emat.metallic = 0.05
		emat.roughness = 0.7
		edge.material_override = emat
		edge.transform.origin = Vector3(cx, 0.005, 0.003)
		housing.add_child(edge)

	# Bottom plate
	var bottom := MeshInstance3D.new()
	bottom.name = "Bottom"
	var btbox := BoxMesh.new()
	btbox.size = Vector3(pw + 0.012, 0.006, case_depth)
	bottom.mesh = btbox
	var btmat := StandardMaterial3D.new()
	btmat.albedo_color = WOOD_DARK
	btmat.metallic = 0.05
	btmat.roughness = 0.7
	bottom.material_override = btmat
	bottom.transform.origin = Vector3(0, -0.003, -case_depth / 2.0)
	housing.add_child(bottom)

	# Back panel
	var back := MeshInstance3D.new()
	back.name = "Back"
	var bkbox := BoxMesh.new()
	bkbox.size = Vector3(pw + 0.012, case_height, 0.005)
	back.mesh = bkbox
	var bkmat := StandardMaterial3D.new()
	bkmat.albedo_color = Color(0.12, 0.12, 0.12)
	bkmat.metallic = 0.2
	bkmat.roughness = 0.7
	back.material_override = bkmat
	back.transform.origin = Vector3(0, case_height / 2.0, -case_depth)
	housing.add_child(back)

	# Front face (wood, solid block closing below tilted panel)
	var front_h := case_height * 0.45
	var front_depth := case_depth * 0.3
	var front := MeshInstance3D.new()
	front.name = "Front"
	var frbox := BoxMesh.new()
	frbox.size = Vector3(pw + 0.012, front_h, front_depth)
	front.mesh = frbox
	var frmat := StandardMaterial3D.new()
	frmat.albedo_color = WOOD_DARK
	frmat.metallic = 0.05
	frmat.roughness = 0.7
	front.material_override = frmat
	front.transform.origin = Vector3(0, front_h / 2.0, -front_depth / 2.0 + 0.003)
	housing.add_child(front)

	# Front lip (wood accent on top of front face)
	var lip := MeshInstance3D.new()
	lip.name = "FrontLip"
	var lipbox := BoxMesh.new()
	lipbox.size = Vector3(pw + 0.016, 0.005, front_depth + 0.004)
	lip.mesh = lipbox
	var lipmat := StandardMaterial3D.new()
	lipmat.albedo_color = WOOD
	lipmat.metallic = 0.08
	lipmat.roughness = 0.55
	lip.material_override = lipmat
	lip.transform.origin = Vector3(0, front_h + 0.002, -front_depth / 2.0 + 0.003)
	housing.add_child(lip)

	# Rubber feet
	for fx in [-1.0, 1.0]:
		for fz_off in [0.02, case_depth - 0.02]:
			var foot := MeshInstance3D.new()
			var fcyl := CylinderMesh.new()
			fcyl.top_radius = 0.005
			fcyl.bottom_radius = 0.007
			fcyl.height = 0.004
			foot.mesh = fcyl
			var fmat := StandardMaterial3D.new()
			fmat.albedo_color = Color(0.08, 0.08, 0.08)
			fmat.roughness = 0.95
			foot.material_override = fmat
			foot.transform.origin = Vector3(fx * (pw / 2.0 + 0.01), -0.008, -fz_off)
			housing.add_child(foot)

	# Panel tilted inside case — sits above front face
	var panel_pivot := Node3D.new()
	panel_pivot.name = "PanelPivot"
	panel_pivot.transform.origin = Vector3(0, front_h + 0.004, 0)
	panel_pivot.rotation.x = -tilt
	panel.transform.origin = Vector3(0, ph / 2.0, 0)
	panel_pivot.add_child(panel)
	housing.add_child(panel_pivot)


# ── Rack frame: vertical 19" style with rails ───────────────────────

static func _build_rack_case(housing: Node3D, panel: Node3D, pw: float, ph: float) -> void:
	var RAIL := Color(0.20, 0.20, 0.22)
	var rail_w := 0.012
	var rail_depth := 0.04

	# Two vertical rails
	for side in [-1.0, 1.0]:
		var rx: float = side * (pw / 2.0 + rail_w / 2.0 + 0.004)

		var rail := MeshInstance3D.new()
		rail.name = "Rail_%s" % ("L" if side < 0 else "R")
		var rbox := BoxMesh.new()
		rbox.size = Vector3(rail_w, ph + 0.04, rail_depth)
		rail.mesh = rbox
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = RAIL
		rmat.metallic = 0.5
		rmat.roughness = 0.35
		rail.material_override = rmat
		rail.transform.origin = Vector3(rx, 0, -rail_depth / 2.0)
		housing.add_child(rail)

		# Rack holes (small recessed dots along rail)
		for i in range(0, int(ph / 0.015) + 1):
			var hy := -ph / 2.0 + float(i) * 0.015
			var hole := MeshInstance3D.new()
			var hcyl := CylinderMesh.new()
			hcyl.top_radius = 0.002
			hcyl.bottom_radius = 0.002
			hcyl.height = 0.002
			hole.mesh = hcyl
			var hmat := StandardMaterial3D.new()
			hmat.albedo_color = Color(0.08, 0.08, 0.08)
			hole.material_override = hmat
			hole.rotation.x = PI / 2.0
			hole.transform.origin = Vector3(rx, hy, -rail_depth - 0.001)
			housing.add_child(hole)

	# Top crossbar
	var top_bar := MeshInstance3D.new()
	top_bar.name = "TopBar"
	var tbox := BoxMesh.new()
	tbox.size = Vector3(pw + rail_w * 2 + 0.008, rail_w, rail_depth)
	top_bar.mesh = tbox
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = RAIL
	tmat.metallic = 0.5
	tmat.roughness = 0.35
	top_bar.material_override = tmat
	top_bar.transform.origin = Vector3(0, ph / 2.0 + 0.02, -rail_depth / 2.0)
	housing.add_child(top_bar)

	# Bottom crossbar
	var bot_bar := MeshInstance3D.new()
	bot_bar.name = "BottomBar"
	bot_bar.mesh = tbox
	bot_bar.material_override = tmat
	bot_bar.transform.origin = Vector3(0, -ph / 2.0 - 0.02, -rail_depth / 2.0)
	housing.add_child(bot_bar)

	# Panel mounted flat inside
	panel.transform.origin.z = 0.002
	housing.add_child(panel)


# ══════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════

## Build a wedge/prism mesh (right triangle profile extruded along X).
## Side view: front-bottom(0,0) → back-bottom(0,0,-depth) → back-top(0,height,-depth) → front(0,0,0)
## Extruded along X by 'thickness'. Panel sits on the hypotenuse.
static func _build_wedge_mesh(depth: float, height: float, thickness: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_t := thickness / 2.0
	# 6 vertices of the prism (2 triangular faces × 3 vertices)
	# Front-bottom, back-bottom, back-top — on both left and right X faces
	var fb_l := Vector3(-half_t, 0, 0)
	var bb_l := Vector3(-half_t, 0, -depth)
	var bt_l := Vector3(-half_t, height, -depth)
	var fb_r := Vector3(half_t, 0, 0)
	var bb_r := Vector3(half_t, 0, -depth)
	var bt_r := Vector3(half_t, height, -depth)

	# Left face (triangle)
	st.set_normal(Vector3(-1, 0, 0))
	st.add_vertex(fb_l)
	st.add_vertex(bt_l)
	st.add_vertex(bb_l)

	# Right face (triangle)
	st.set_normal(Vector3(1, 0, 0))
	st.add_vertex(fb_r)
	st.add_vertex(bb_r)
	st.add_vertex(bt_r)

	# Bottom face (quad as 2 tris)
	st.set_normal(Vector3(0, -1, 0))
	st.add_vertex(fb_l)
	st.add_vertex(bb_l)
	st.add_vertex(bb_r)
	st.add_vertex(fb_l)
	st.add_vertex(bb_r)
	st.add_vertex(fb_r)

	# Back face (quad as 2 tris)
	st.set_normal(Vector3(0, 0, -1))
	st.add_vertex(bb_l)
	st.add_vertex(bt_l)
	st.add_vertex(bt_r)
	st.add_vertex(bb_l)
	st.add_vertex(bt_r)
	st.add_vertex(bb_r)

	# Hypotenuse face (the slanted front — where panel sits)
	var hyp_normal := Vector3(0, depth, height).normalized()
	st.set_normal(hyp_normal)
	st.add_vertex(fb_l)
	st.add_vertex(fb_r)
	st.add_vertex(bt_r)
	st.add_vertex(fb_l)
	st.add_vertex(bt_r)
	st.add_vertex(bt_l)

	return st.commit()


## Create a ShaderMaterial matching the Grid wireframe shader used by lab cubes.
## Falls back to StandardMaterial3D if shader not found.
static func _create_grid_shader_material(base_color: Color = Color(0.069, 0.069, 0.069)) -> Material:
	var shader: Shader = load("res://commons/resourses/shaders/Grid.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("modelColor", base_color)
		mat.set_shader_parameter("wireframeColor", Color(1, 0, 1, 1))
		mat.set_shader_parameter("emissionColor", Color(0.98, 0.76, 0.91, 1))
		mat.set_shader_parameter("width", 3.7)
		mat.set_shader_parameter("blur", 0.58)
		mat.set_shader_parameter("emission_strength", 0.46)
		mat.set_shader_parameter("show_interior", true)
		return mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = base_color
		mat.metallic = 0.3
		mat.roughness = 0.6
		return mat


static func _add_panel(parent: Node3D, w: float, h: float) -> void:
	# Outer frame (dark surround)
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var fbox := BoxMesh.new()
	fbox.size = Vector3(w + 0.006, h + 0.006, 0.006)
	frame.mesh = fbox
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = WARM_DARK
	fmat.metallic = 0.2
	fmat.roughness = 0.6
	frame.material_override = fmat
	frame.transform.origin.z = -0.002
	parent.add_child(frame)

	# Main cream panel
	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var box := BoxMesh.new()
	box.size = Vector3(w, h, 0.008)
	panel.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = CREAM
	mat.metallic = 0.05
	mat.roughness = 0.75
	panel.material_override = mat
	parent.add_child(panel)

	# Subtle inner highlight (top edge catch light)
	var highlight := MeshInstance3D.new()
	highlight.name = "Highlight"
	var hbox := BoxMesh.new()
	hbox.size = Vector3(w - 0.004, 0.001, 0.001)
	highlight.mesh = hbox
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = CREAM_LIGHT
	hmat.emission = CREAM_LIGHT
	hmat.emission_energy_multiplier = 0.15
	highlight.material_override = hmat
	highlight.transform.origin = Vector3(0, h / 2.0 - 0.003, 0.005)
	parent.add_child(highlight)

	# Copper accent strip at top
	var accent := MeshInstance3D.new()
	accent.name = "AccentStrip"
	var abox := BoxMesh.new()
	abox.size = Vector3(w * 0.6, 0.002, 0.002)
	accent.mesh = abox
	var amat := StandardMaterial3D.new()
	amat.albedo_color = COPPER
	amat.metallic = 0.6
	amat.roughness = 0.35
	amat.emission = COPPER
	amat.emission_energy_multiplier = 0.15
	accent.material_override = amat
	accent.transform.origin = Vector3(0, h / 2.0 + 0.0005, 0.002)
	parent.add_child(accent)


static func _add_title(parent: Node3D, text: String, _panel_w: float, panel_h: float) -> void:
	var lbl := Label3D.new()
	lbl.name = "Title"
	lbl.text = text
	lbl.font_size = 16
	lbl.pixel_size = 0.0004
	lbl.modulate = Color(0.12, 0.12, 0.12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(0, panel_h / 2.0 - 0.013, 0.006)
	parent.add_child(lbl)


static func _add_label(parent: Node3D, text: String, pos: Vector3, size: int = 14, align: int = HORIZONTAL_ALIGNMENT_CENTER, max_w: float = 0.18) -> void:
	if text.strip_edges() == "":
		return
	# Crisp 2D-in-3D label tag: a small dark plate + light text, surface-pinned (not a billboard).
	# This both LABELS the control and gives it a readable plate under it. Width is capped to the
	# control's own column (max_w) so adjacent labels never collide — the text auto-shrinks to fit.
	var w: float = clampf(float(text.length()) * 0.016 + 0.024, 0.045, max_w)
	var tag: MeshInstance3D = BakedTextAlbedo.make_panel_mesh(text, Color(0.11, 0.12, 0.14), Color(0.94, 0.92, 0.88), Vector2(w, 0.024), 1400, true)
	if tag:
		tag.transform.origin = pos + Vector3(0, 0, 0.004)
		parent.add_child(tag)
		return
	# Fallback if text-baking is unavailable (keeps panels working): plain dark Label3D.
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = size
	lbl.pixel_size = 0.0005
	lbl.modulate = Color(0.15, 0.15, 0.15)
	lbl.horizontal_alignment = align
	lbl.transform.origin = pos
	parent.add_child(lbl)
