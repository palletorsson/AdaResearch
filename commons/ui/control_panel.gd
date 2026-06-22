@tool
extends Node3D
class_name ControlPanel
## The canonical home for interactive controls — ONE way to seat sliders,
## buttons, and screens across every artifact.
##
## You don't position controls by hand any more. Make a ControlPanel, add the
## canonical controls to it, and it gives them a backed panel, consistent
## spacing, a reading-angle tilt toward the player, and a baked label under
## each one. Standardised orientation + spacing, for free, everywhere.
##
##   var p := ControlPanel.new()
##   add_child(p)
##   var k := p.add_slider("k")        # canonical slider_smooth, labelled
##   var snap := p.add_button("SNAP")  # canonical push_button, labelled
##   p.add_screen("STRETCH BENCH", "k*v = scale v by k")
##   k.slider_moved.connect(_on_k)
##
## Controls come from commons/interactables (one canonical set). Text uses
## BakedText / TextScreen (baked, never floating). Palette matches text_screen.gd.

# Control scenes are loaded LAZILY (in add_slider/add_button) — their scripts
# depend on the XR autoloads, which aren't present in headless tooling. Text
# helpers have no such dependency, so they preload normally.
# slider_smooth, NOT slider_horizontal: the smooth variant has constraint
# enforcement + snap-back, fixing the jumpy/discontinuous VR drag of the old
# physics slider. Same API (slider_moved / set_range / set_normalized_value).
const SLIDER_PATH := "res://commons/interactables/slider_smooth.tscn"
const BUTTON_PATH := "res://commons/interactables/push_button.tscn"
const DIAL_PATH := "res://commons/interactables/dial_smooth.tscn"
const JOYSTICK_PATH := "res://commons/interactables/joystick_smooth.tscn"
const TextScreenScript = preload("res://commons/ui/text_screen.gd")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

@export var title: String = "": set = _set_title
@export var spacing: float = 0.30: set = _set_spacing       # metres between slots
@export var tilt_degrees: float = -20.0: set = _set_tilt     # recline toward the player
@export var panel_height: float = 0.42

# Dieter Rams / Braun palette — a warm light-grey matte plate, charcoal text, one
# restrained orange accent. Calm, honest, minimal: less but better.
@export var panel_color: Color = Color(0.81, 0.80, 0.76)   # warm light grey (Braun SK4)
@export var frame_color: Color = Color(0.62, 0.61, 0.57)   # subtle hairline edge
@export var title_color: Color = Color(0.17, 0.17, 0.18)   # near-black charcoal
@export var label_color: Color = Color(0.26, 0.26, 0.27)   # dark grey
@export var accent_color: Color = Color(0.88, 0.42, 0.12)  # Braun orange — the one accent
## Render the static labels + title as real black TextMesh geometry (engraved
## look, exports to glTF as geometry) instead of baked-texture quads. Cheap —
## a few short labels tessellated once. The live readout stays 2D-in-3D.
@export var label_mesh: bool = false
@export var label_mesh_color: Color = Color(0.07, 0.07, 0.08)   # near-black
@export var label_mesh_depth: float = 0.004                     # slight relief

const CONTROL_Z := 0.02       # forward from the back panel
const PLATE_Z := -0.001       # the plate's front face (BackPanel at -0.007, 0.012 thick)
# THE canonical text display (the one interactable_demo uses, lines 1257-1268).
const RackPassive = preload("res://commons/interactables/RackPassiveElements.gd")
const READOUT_GREEN := Color(0.22, 0.92, 0.33)   # scroll-display LED green
const READOUT_NATIVE_W := 0.54   # build_text_display_static 2 slots = 2*0.28-0.02
const READOUT_NATIVE_H := 0.06

# ── Box model (metres) — the plate is sized to its content, stacked compactly:
#    [readout] · [accent + title] · [controls row] · [labels],  PAD around all.
const PAD := 0.028        # plate padding around content
const GAP := 0.020        # gap between stacked zones
const CTRL_H := 0.135     # control footprint height (slider / dial / button)
const LBL_H := 0.036      # baked label band height
const TITLE_H := 0.044    # title wordmark height
const ACCENT_T := 0.005   # accent hairline thickness
const READOUT_H := 0.105  # readout display zone height when present

var _items: Array = []        # [{node, label}]
var _tilt: Node3D
var _row: Node3D
var _chrome: Node3D           # backing + frame + title (rebuilt on relayout)
var _readout_disp: Node3D     # persistent dark display at the top (if add_readout)
var _readout_label: Label     # the live number — a 2D Label inside a SubViewport
var _relayout_pending: bool = false   # set when _relayout is skipped pre-tree; flushed by _ready on tree entry


func _ready() -> void:
	_ensure_roots()
	_relayout()


func _ensure_roots() -> void:
	if _tilt and is_instance_valid(_tilt):
		return
	_tilt = Node3D.new()
	_tilt.name = "Tilt"
	_tilt.rotation_degrees = Vector3(tilt_degrees, 0, 0)
	add_child(_tilt)
	_row = Node3D.new()
	_row.name = "Row"
	_tilt.add_child(_row)


# ── Public: add canonical controls ────────────────────────────────────────

## Add a canonical slider. Returns it — connect `slider_moved`, read
## `get_normalized_value()`. The label is baked under the slot.
func add_slider(label: String, param_name: String = "") -> Node3D:
	_ensure_roots()
	var s: Node3D = load(SLIDER_PATH).instantiate()
	# slider_smooth is a vertical fader — lay it HORIZONTAL on the board (the
	# XRT slider's grab math is local-space, so root rotation is safe), and
	# counter-rotate the value label so the number stays upright. +90 (not -90)
	# so the fader's slide axis maps to +X: dragging RIGHT increases.
	s.rotation_degrees.z = 90.0
	var vl := s.get_node_or_null("Frame/Label3DValue") as Label3D
	if vl:
		vl.rotation_degrees.z = -90.0
	if s.has_method("set_param_name"):
		s.set_param_name(param_name if param_name != "" else label)
	_row.add_child(s)
	# wide: the unscaled fader needs ~1.4 slots (physics controls are never
	# shrunk to fit — see _fit_items_to_cells).
	_items.append({"node": s, "label": label, "wide": true})
	call_deferred("_strip_internal_label", s)
	_relayout()
	return s


## Add a canonical joystick (2D). Returns it. The label is baked under the slot.
func add_joystick(label: String, param_name: String = "") -> Node3D:
	_ensure_roots()
	var j: Node3D = load(JOYSTICK_PATH).instantiate()
	if j.has_method("set_param_name"):
		j.set_param_name(param_name if param_name != "" else label)
	_row.add_child(j)
	_items.append({"node": j, "label": label})
	call_deferred("_strip_internal_label", j)
	_relayout()
	return j


## Add a canonical dial. Returns it — connect `hinge_moved`, read
## `get_normalized_value()`. The label is baked under the slot.
func add_dial(label: String, param_name: String = "") -> Node3D:
	_ensure_roots()
	var d: Node3D = load(DIAL_PATH).instantiate()
	if d.has_method("set_param_name"):
		d.set_param_name(param_name if param_name != "" else label)
	_row.add_child(d)
	_items.append({"node": d, "label": label})
	call_deferred("_strip_internal_label", d)
	_relayout()
	return d


## Add a canonical push button. Returns it — connect its
## InteractableAreaButton.button_pressed.
func add_button(label: String) -> Node3D:
	_ensure_roots()
	var b: Node3D = load(BUTTON_PATH).instantiate()
	_row.add_child(b)
	_items.append({"node": b, "label": label})
	_relayout()
	return b


## Add a numeric readout DISPLAY at the TOP of the plate (Braun calculator
## layout: dark screen on top, controls below). Returns the Label3D — update its
## text per frame. The display persists across relayouts (built once here).
func add_readout(text: String = "") -> Label:
	_ensure_roots()
	if _readout_disp == null:
		_readout_disp = Node3D.new()
		_readout_disp.name = "ReadoutDisplay"
		_tilt.add_child(_readout_disp)
		# Build the canonical STATIC 2D-in-3D display (RackPassiveElements) — a real
		# 2D Label in a SubViewport on the screen quad, LED green. Full text control.
		# _build_chrome scales the holder (native 0.54 x 0.06) to the plate.
		_readout_label = RackPassive.build_text_display_2d(_readout_disp, 2, " ", READOUT_GREEN)
	if _readout_label:
		_readout_label.text = text
	_relayout()
	return _readout_label


## Add a TextScreen (SCREEN mode) as a slot — a baked readout in the row,
## sized to the panel so it never overflows.
func add_screen(scr_title: String, body: String = "") -> Node3D:
	_ensure_roots()
	var ts = TextScreenScript.new()
	ts.mode = ts.Mode.SCREEN
	ts.width_m = panel_height * 0.62      # fit inside the panel height (ASPECT)
	ts.set_text(scr_title, body)
	_row.add_child(ts)
	_items.append({"node": ts, "label": "", "wide": true})
	_relayout()
	return ts


## Drop in an already-built control node (e.g. a bespoke widget). Gets the same
## slot spacing + baked label as the canonical controls.
func add_node(node: Node3D, label: String = "") -> Node3D:
	_ensure_roots()
	_row.add_child(node)
	_items.append({"node": node, "label": label})
	_relayout()
	return node


# ── Layout ────────────────────────────────────────────────────────────────

func _relayout() -> void:
	# Internal layout reads child global_transforms (see _min_z_in_tilt), which error
	# if the panel isn't in the tree yet — e.g. sliders added during an artifact's
	# _ready, before the panel is mounted. Defer; _ready re-runs us on tree entry.
	if not is_inside_tree():
		_relayout_pending = true
		return
	_relayout_pending = false
	if _row == null:
		return
	var n := _items.size()
	var has_controls := n > 0
	var has_readout := _readout_disp != null
	# Bail only when there is genuinely nothing — a readout-only or title-only
	# board (no controls) still gets a full plate (was: early-return on n==0,
	# which left readout-only boards plateless).
	if not has_controls and not has_readout and title == "":
		return
	# Each item occupies `slots` of horizontal width — wide items (screens) get more.
	var slot_w: Array = []
	var total_slots := 0.0
	var has_labels := false
	for item in _items:
		var s: float = 1.4 if item.get("wide", false) else 1.0
		slot_w.append(s)
		total_slots += s
		if String(item.get("label", "")) != "":
			has_labels = true
	var total_w := total_slots * spacing
	# No controls → size the plate to the readout instead of collapsing to nothing.
	if not has_controls:
		total_w = maxf(total_w, spacing * 2.0)
	# Clear old baked labels NOW (queue_free defers a frame; relayout runs
	# synchronously on every add, so deferred frees would pile up duplicates).
	var stale: Array = []
	for c in _row.get_children():
		if String(c.name).begins_with("Label_"):
			stale.append(c)
	for c in stale:
		_row.remove_child(c)
		c.free()
	var box := _compute_box(total_w, has_labels, has_controls)
	# Walk left→right, centring each item in its own slot span (controls at y=0).
	var cursor := -total_w * 0.5
	for i in n:
		var item: Dictionary = _items[i]
		var node: Node3D = item["node"]
		var span: float = slot_w[i] * spacing
		var cx := cursor + span * 0.5
		if is_instance_valid(node):
			node.position = Vector3(cx, 0.0, CONTROL_Z)
		var lbl: String = item.get("label", "")
		if lbl != "":
			var lm := _label_node(lbl, label_color, Vector2(spacing * 0.74, LBL_H))
			if lm:
				lm.name = "Label_%d" % i
				var lz: float = (PLATE_Z + 0.001) if label_mesh else (CONTROL_Z + 0.002)
				lm.position = Vector3(cx, box["label_y"], lz)
				_row.add_child(lm)
		cursor += span
	_build_chrome(box)
	# Force every item to fit its grid cell so tall controls (joystick, screens)
	# never overflow into the accent/label zones. Run now AND deferred (some
	# controls build their geometry in a deferred _ready).
	_fit_items_to_cells()
	call_deferred("_fit_items_to_cells")


## Scale each item uniformly so it fits within one grid cell — cell width
## (spacing) and the control-zone height (CTRL_H). Contain, never stretch.
func _fit_items_to_cells() -> void:
	if _row == null:
		return
	var cell_w := spacing * 0.92
	for i in _items.size():
		var item: Dictionary = _items[i]
		var node = item["node"]
		if not is_instance_valid(node):
			continue
		node.scale = Vector3.ONE
		var ab := _local_aabb(node)
		if ab.size.x <= 0.0001 or ab.size.y <= 0.0001:
			continue
		# NEVER scale physics controls (slider/button handles are RigidBody3D —
		# Godot physics does not support scaled bodies; a scaled grab eats part
		# of every hand movement → the jumpy/sticky VR drag). They keep scale 1
		# and get room via their item's slot span instead.
		if not _has_rigid_body(node):
			# Contain only — shrink items that overflow the cell, never enlarge a
			# small control (keep natural size, don't balloon to fill the cell).
			var s: float = minf(cell_w / ab.size.x, CTRL_H / ab.size.y)
			s = minf(s, 1.0)
			node.scale = Vector3(s, s, s)
		# Seat the control's BACK face on the plate (smack on the board) — its
		# handle/cap still stands proud forward. Measure min-z in the PLATE's frame
		# (_tilt) so it's correct even if the control's own root is rotated.
		var mz := _min_z_in_tilt(node)
		if mz < INF:
			node.position.z += (PLATE_Z + 0.001) - mz


## True if the node contains a RigidBody3D (a physics-grabbed control part).
func _has_rigid_body(node: Node) -> bool:
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is RigidBody3D:
			return true
		for c in n.get_children():
			stack.append(c)
	return false


## Clear a control's OWN name label so the ControlPanel's baked label is the
## single source of truth (controls like the slider carry an internal "LabelName"
## that otherwise duplicates the baked one). The value readout label is kept.
func _strip_internal_label(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label3D and String(n.name).to_lower().contains("labelname"):
			(n as Label3D).text = ""
		for c in n.get_children():
			stack.append(c)


## Smallest Z of a node's visual descendants, expressed in the PLATE frame
## (_tilt) — the back-most face, used to seat controls flush on the plate.
func _min_z_in_tilt(node: Node3D) -> float:
	if _tilt == null or not is_instance_valid(_tilt):
		return INF
	var inv := _tilt.global_transform.affine_inverse()
	var mz := INF
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		# Skip shadow/decal meshes — they lie flat ON the surface and would be
		# mistaken for the control's back face (the slider's ShadowMesh did this).
		if n is VisualInstance3D and not String(n.name).to_lower().contains("shadow"):
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			var xf: Transform3D = inv * (n as Node3D).global_transform
			for j in 8:
				var p: Vector3 = xf * ab.get_endpoint(j)
				mz = minf(mz, p.z)
		for c in n.get_children():
			stack.append(c)
	return mz


## AABB of a node's visual descendants expressed in the NODE's own local frame.
func _local_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var inv := node.global_transform.affine_inverse()
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			var xf: Transform3D = inv * (n as Node3D).global_transform
			for j in 8:
				var p: Vector3 = xf * ab.get_endpoint(j)
				if first:
					box = AABB(p, Vector3.ZERO); first = false
				else:
					box = box.expand(p)
		for c in n.get_children():
			stack.append(c)
	return box


## The box model: stack zones around the controls (at y=0) and return every
## zone's y plus the content-sized plate dimensions. Compact — no fixed height.
func _compute_box(total_w: float, has_labels: bool, has_controls: bool = true) -> Dictionary:
	var has_title := title != ""
	var has_readout := _readout_disp != null
	var has_header := has_title or has_readout
	# No controls (readout/title-only board) → collapse the empty control band so
	# the plate is compact around the header instead of leaving a hollow middle.
	var ctrl_top := (CTRL_H * 0.5) if has_controls else 0.0
	var ctrl_bot := (-CTRL_H * 0.5) if has_controls else 0.0
	# Below the controls: the baked labels, then padding.
	var label_y := ctrl_bot - 0.010 - LBL_H * 0.5
	var bottom := (label_y - LBL_H * 0.5 if has_labels else ctrl_bot) - PAD
	# Above the controls: accent, title, then the readout display, then padding.
	var y := ctrl_top + GAP
	var accent_y := 0.0
	if has_header:
		accent_y = y
		y += ACCENT_T + 0.010
	var title_y := 0.0
	if has_title:
		title_y = y + TITLE_H * 0.5
		y += TITLE_H + 0.006
	var readout_y := 0.0
	if has_readout:
		y += GAP
		readout_y = y + READOUT_H * 0.5
		y += READOUT_H
	var top := y + PAD
	return {
		"w": total_w + PAD * 2.0,
		"h": top - bottom,
		"cy": (top + bottom) * 0.5,
		"label_y": label_y,
		"accent_y": accent_y,
		"title_y": title_y,
		"readout_y": readout_y,
		"has_header": has_header,
	}


func _build_chrome(box: Dictionary) -> void:
	if _chrome and is_instance_valid(_chrome):
		_tilt.remove_child(_chrome)
		_chrome.free()
	_chrome = Node3D.new()
	_chrome.name = "Chrome"
	_tilt.add_child(_chrome)

	var w: float = box["w"]
	var bh: float = box["h"]
	var bcy: float = box["cy"]
	# Backing — matte light-grey plate, sized to the content box.
	var back := MeshInstance3D.new()
	back.name = "BackPanel"
	var bbox := BoxMesh.new()
	bbox.size = Vector3(w, bh, 0.012)
	back.mesh = bbox
	back.material_override = _mat(panel_color, 0.9, 0.0)
	back.position = Vector3(0, bcy, -0.007)
	_chrome.add_child(back)
	# Frame — a thin recessed hairline edge.
	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(w + 0.012, bh + 0.012, 0.006)
	frame.mesh = fbox
	frame.material_override = _mat(frame_color, 0.85, 0.0)
	frame.position = Vector3(0, bcy, -0.013)
	_chrome.add_child(frame)
	# Readout display — the canonical text display, scaled to the readout zone.
	if _readout_disp != null:
		var target_w: float = minf(w * 0.84, w - PAD * 2.0)
		var s: float = minf(target_w / READOUT_NATIVE_W, READOUT_H / READOUT_NATIVE_H)
		_readout_disp.scale = Vector3(s, s, s)
		_readout_disp.position = Vector3(0, box["readout_y"], 0.004)
	# Title — a small charcoal wordmark, top-left.
	if title != "":
		var tb := _label_node(title.to_upper(), title_color, Vector2(minf(w * 0.5, 0.5), TITLE_H))
		if tb:
			var tz: float = (PLATE_Z + 0.001) if label_mesh else 0.004
			tb.position = Vector3(-w * 0.5 + minf(w * 0.25, 0.25) + 0.025, box["title_y"], tz)
			_chrome.add_child(tb)
	# One accent: a thin orange hairline — the single Braun cue (only with a header).
	if box["has_header"]:
		var accent := MeshInstance3D.new()
		var abox := BoxMesh.new()
		abox.size = Vector3(w * 0.94, ACCENT_T, 0.004)
		accent.mesh = abox
		accent.material_override = _mat(accent_color, 0.5, 0.0)
		accent.position = Vector3(0, box["accent_y"], 0.004)
		_chrome.add_child(accent)


func _mat(c: Color, rough: float, emission: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.1
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


## A label node — either a baked-texture quad (default) or real black TextMesh
## geometry (label_mesh). Both are centred and fit-to-box; caller sets position.
func _label_node(text: String, baked_color: Color, box_size: Vector2) -> Node3D:
	if not label_mesh:
		return BakedText.make_label_mesh(text, baked_color, box_size, 1400, false)
	var tm := TextMesh.new()
	tm.text = text
	tm.font_size = 64
	tm.pixel_size = 0.001
	tm.depth = label_mesh_depth
	tm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = label_mesh_color
	m.roughness = 0.6
	mi.material_override = m
	# Contain within box_size and centre on the holder origin.
	var holder := Node3D.new()
	holder.add_child(mi)
	var ab: AABB = tm.get_aabb()
	if ab.size.x > 0.0 and ab.size.y > 0.0:
		var sc: float = minf(box_size.x / ab.size.x, box_size.y / ab.size.y)
		mi.scale = Vector3(sc, sc, sc)
		var c: Vector3 = ab.get_center()
		# Centre in x/y; back-flush in z so the letters REST on the plate (holder
		# origin = back face) and the relief extrudes forward.
		mi.position = Vector3(-c.x * sc, -c.y * sc, -ab.position.z * sc)
	return holder


func _set_title(v: String) -> void:
	title = v
	if is_inside_tree(): _relayout()

func _set_spacing(v: float) -> void:
	spacing = maxf(0.12, v)
	if is_inside_tree(): _relayout()

func _set_tilt(v: float) -> void:
	tilt_degrees = v
	if _tilt and is_instance_valid(_tilt):
		_tilt.rotation_degrees = Vector3(tilt_degrees, 0, 0)
