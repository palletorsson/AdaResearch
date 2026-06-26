extends RefCounted
class_name WHStyle

## Shared THEME + visual-polish library for the WALL HANGAR editor.
##
## One cohesive Dieter-Rams / Braun look — dark anthracite panels, calm light type, a single
## warm orange accent — factored out of WallHangarEditor.gd's inline `_box`/`_heading`/`_row`
## helpers so the host editor and every sibling palette/inspector/hud component share one style.
##
## Pure utility: every method is `static`, there is no `_ready`, and nothing assumes a scene tree.
## Hosts call it as `WHStyle.panel_box()`, `WHStyle.style_button(b)`, `WHStyle.dim_for_ghost(node)`.
##
## The palette is tuned to sit with the painted-metal props (commons/artifacts/_hangar/hangar_kit.gd):
## the same warm orange accent (≈ BRAUN_ACCENT) and warm-neutral light text read as one set with the
## station kit, while the UI chrome stays a darker anthracite so it recedes behind the 3D scene.

# ── Dieter-Rams / Braun palette ───────────────────────────────────────
# Inherited from WallHangarEditor's C_PANEL/C_ACCENT/C_TEXT/C_DIM, nudged for a prettier read:
# the panel base a touch deeper, a second elevated tone for toolbars/buttons, one warm accent.
const BG := Color(0.10, 0.11, 0.135, 0.97)      ## panel base — deep anthracite, near-opaque
const BG2 := Color(0.15, 0.16, 0.195, 0.98)     ## elevated surface — toolbars, button faces
const ACCENT := Color(0.86, 0.40, 0.16)         ## the one warm element (orange), matches the props
const TEXT := Color(0.87, 0.88, 0.90)           ## primary label — warm off-white
const DIM := Color(0.60, 0.62, 0.66)            ## secondary / key labels — muted grey
const OK := Color(0.42, 0.78, 0.52)             ## success / valid-placement green

# A couple of derived tints for hover/press/borders/ghosts (kept here so callers stay consistent).
const ACCENT_SOFT := Color(0.86, 0.40, 0.16, 0.55)  ## translucent accent — ghosts, highlights
const BORDER := Color(0.27, 0.29, 0.34, 0.90)       ## subtle cool border on panels & buttons
const BORDER_ACCENT := Color(0.86, 0.40, 0.16, 0.85) ## accent border for the pressed/active state

# Font sizing — one scale for the whole editor chrome.
const FS_HEADING := 13
const FS_BODY := 12
const FS_BUTTON := 13

# ── StyleBox factories ────────────────────────────────────────────────
## The main floating panel (inspector, palette tray) — deep anthracite, soft rounded corners,
## a hairline cool border, generous inner margin. The calm surface the 3D scene reads against.
static func panel_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.set_corner_radius_all(7)
	sb.set_border_width_all(1)
	sb.border_color = BORDER
	sb.set_content_margin_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	return sb


## A slimmer surface for a top toolbar / palette bar — elevated tone, tighter margins, a thin
## accent rule along the top edge to anchor it (the Braun "one warm line").
static func toolbar_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG2
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(8)
	sb.set_border_width_all(1)
	sb.border_color = BORDER
	sb.border_width_top = 2
	sb.border_color = BORDER
	# A discreet warm top edge — readable as the accent without shouting.
	sb.expand_margin_top = 0.0
	return sb


## Button resting face — matte elevated panel, rounded, hairline border. Recedes until hovered.
static func button_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG2
	sb.set_corner_radius_all(5)
	sb.set_border_width_all(1)
	sb.border_color = BORDER
	sb.set_content_margin_all(8)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	return sb


## Button hover — lifts a step lighter and warms the border toward the accent.
static func button_hover() -> StyleBoxFlat:
	var sb := button_normal()
	sb.bg_color = BG2.lightened(0.10)
	sb.border_color = ACCENT_SOFT
	return sb


## Button pressed / active — accent-tinted fill + a full accent border (the selected palette piece).
static func button_pressed() -> StyleBoxFlat:
	var sb := button_normal()
	sb.bg_color = Color(0.32, 0.20, 0.12, 0.98)   # warm-tinted dark, reads as "armed"
	sb.set_border_width_all(2)
	sb.border_color = BORDER_ACCENT
	return sb


# ── Widget helpers ────────────────────────────────────────────────────
## Apply the full normal/hover/pressed/focus stylebox set + font colour + font size to a Button.
## After this the button reads as part of the Braun set with no per-call theming at the host.
static func style_button(b: Button) -> void:
	if b == null:
		return
	b.add_theme_stylebox_override("normal", button_normal())
	b.add_theme_stylebox_override("hover", button_hover())
	b.add_theme_stylebox_override("pressed", button_pressed())
	b.add_theme_stylebox_override("focus", button_hover())
	b.add_theme_stylebox_override("hover_pressed", button_pressed())
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color(0.95, 0.96, 0.98))
	b.add_theme_color_override("font_pressed_color", ACCENT)
	b.add_theme_color_override("font_focus_color", TEXT)
	b.add_theme_font_size_override("font_size", FS_BUTTON)


## A section heading label — accent colour, heading size. The "INSPECTOR" / "PALETTE" titles.
static func heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", ACCENT)
	l.add_theme_font_size_override("font_size", FS_HEADING)
	return l


## A key/value row: dimmed fixed-width key on the left, primary-text value on the right.
## Used for the inspector readout (piece / gravity / cell x / size …).
static func kv_row(k: String, v: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	var kl := Label.new()
	kl.text = k
	kl.custom_minimum_size = Vector2(74, 0)
	kl.add_theme_color_override("font_color", DIM)
	kl.add_theme_font_size_override("font_size", FS_BODY)
	r.add_child(kl)
	var vl := Label.new()
	vl.text = v
	vl.add_theme_color_override("font_color", TEXT)
	vl.add_theme_font_size_override("font_size", FS_BODY)
	r.add_child(vl)
	return r


# ── 3D ghost / selection visuals ──────────────────────────────────────
## A translucent accent material for a SIMPLE held-preview piece (a single mesh stand-in):
## unshaded so it floats free of scene lighting, ~0.45 alpha, a slight accent emission so it
## glows faintly as "not yet placed". For a full prop preview, prefer dim_for_ghost(node).
static func ghost_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.emission_enabled = true
	m.emission = ACCENT
	m.emission_energy_multiplier = 0.35
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# The overlay material every ghosted mesh shares — a single cached instance so dim/undim is cheap
# and so we can identify "is this node already ghosted?" by identity.
static var _ghost_overlay: StandardMaterial3D = null
static var _ghost_meta := "_whstyle_ghosted"


## The translucent accent OVERLAY laid on top of a real prop's materials while it is the held
## preview. material_overlay renders IN ADDITION to the prop's own materials and is wholly
## separate from material_override — so the prop's painted-metal look is never touched.
static func _ghost_overlay_material() -> StandardMaterial3D:
	if _ghost_overlay == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.42)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		m.emission_enabled = true
		m.emission = ACCENT
		m.emission_energy_multiplier = 0.25
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Draw the wash on top without z-fighting the surface it coats.
		m.no_depth_test = false
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		_ghost_overlay = m
	return _ghost_overlay


## Make every visible mesh under `node` read as a translucent accent GHOST (the held preview),
## without mutating any real material. We push a shared translucent accent `material_overlay`
## onto each MeshInstance3D / MultiMeshInstance3D — the overlay composites over the prop's own
## look, so the prop still reads as itself, just washed in accent. GPUParticles3D are skipped.
## Fully reversible via undim(node).
static func dim_for_ghost(node: Node3D) -> void:
	if node == null:
		return
	var overlay := _ghost_overlay_material()
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if n is GPUParticles3D:
			continue
		if (n is MeshInstance3D) or (n is MultiMeshInstance3D):
			var gi := n as GeometryInstance3D
			# Remember the prior overlay (almost always null) so undim restores it exactly.
			if not gi.has_meta(_ghost_meta):
				gi.set_meta(_ghost_meta, gi.material_overlay)
			gi.material_overlay = overlay


## Restore everything dim_for_ghost touched: put back each node's original material_overlay
## (usually null) and drop the marker meta. Safe to call on a node that was never ghosted.
static func undim(node: Node3D) -> void:
	if node == null:
		return
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if (n is MeshInstance3D) or (n is MultiMeshInstance3D):
			var gi := n as GeometryInstance3D
			if gi.has_meta(_ghost_meta):
				var prev = gi.get_meta(_ghost_meta)
				gi.material_overlay = prev if prev is Material else null
				gi.remove_meta(_ghost_meta)


## Unshaded translucent accent material for the SELECTION highlight box — the wireframe-thin
## glow drawn slightly larger than a selected piece's AABB. Double-sided so it reads from any
## angle in the orthographic view. (WallHangarEditor draws this around `_selected`.)
static func selection_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.18)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = ACCENT
	m.emission_energy_multiplier = 0.20
	return m
