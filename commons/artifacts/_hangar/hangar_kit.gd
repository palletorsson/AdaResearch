@tool
extends RefCounted
class_name HangarKit

## Shared style toolkit for the artifact "packaging" prop family — the sci-fi maintenance-bay
## look: weathered painted metal, hazard stripes, stencilled labels/branding, and small self-lit
## framed readout screens. All static; props call HangarKit.painted_metal(...), HangarKit.readout(...)
## so the whole family reads as one set. Stencils/screens are baked via BakedTextAlbedo (headless-safe).

# ── Dieter Rams / Braun palette (the family DEFAULT — "less, but better") ──
# Light matte housing that RECEDES so the artifact is the expressive thing; one warm accent;
# a calm anthracite display (no glow, no green); dark functional type. From toy_console.gd.
const BODY_LIGHT := Color(0.81, 0.79, 0.75)     # warm off-white body
const PANEL_TRIM := Color(0.70, 0.68, 0.64)     # slightly darker light grey
const BRAUN_ACCENT := Color(0.86, 0.34, 0.11)   # the one warm element
const DISPLAY_DARK := Color(0.12, 0.12, 0.135)  # calm anthracite screen
const TEXT_DARK := Color(0.17, 0.17, 0.19)      # functional labels on the light housing
const TEXT_DISPLAY := Color(0.90, 0.89, 0.85)   # warm off-white readout on the dark screen
# A clean three-colour accent triad (the "three colour bar").
const BAR_TRIAD := [Color(0.86, 0.34, 0.11), Color(0.20, 0.22, 0.26), Color(0.82, 0.80, 0.75)]

# Alternate DARK "terminal" finish — the heavy charcoal-console look (the dark-terminal refs).
# A non-default DNA finish: dark worn-metal housing, signal-red accent, a green CRT screen.
const TERMINAL_BODY := Color(0.14, 0.14, 0.155)
const TERMINAL_PANEL := Color(0.09, 0.09, 0.10)
const TERMINAL_ACCENT := Color(0.85, 0.30, 0.12)
const TERMINAL_SCREEN := Color(0.05, 0.10, 0.06)   # dark green-black CRT
const TERMINAL_TEXT := Color(0.45, 0.95, 0.50)     # green CRT text


## The palette for a named finish: "rams" (light Braun default) | "terminal" (dark console).
## Returns { body, panel, accent, screen, text, header, wear }.
static func finish_palette(finish: String) -> Dictionary:
	if finish.to_lower() == "terminal":
		return {"body": TERMINAL_BODY, "panel": TERMINAL_PANEL, "accent": TERMINAL_ACCENT,
			"screen": TERMINAL_SCREEN, "text": TERMINAL_TEXT, "header": TERMINAL_ACCENT, "wear": 0.32}
	return {"body": BODY_LIGHT, "panel": PANEL_TRIM, "accent": BRAUN_ACCENT,
		"screen": DISPLAY_DARK, "text": TEXT_DISPLAY, "header": BRAUN_ACCENT, "wear": 0.08}


## Body material for a finish — light matte (rams) or dark worn metal (terminal).
static func finish_body(finish: String, c: Color, wear: float) -> StandardMaterial3D:
	if finish.to_lower() == "terminal":
		return terminal_body(c, wear)
	return rams_body(c, wear)


## Dark worn-metal "terminal" housing — the alternate finish (heavy charcoal console).
static func terminal_body(c: Color = TERMINAL_BODY, wear: float = 0.3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c.darkened(wear * 0.18)
	m.metallic = 0.55
	m.roughness = clampf(0.42 + wear * 0.2, 0.05, 1.0)
	return m


# ── Materials ─────────────────────────────────────────────────────────
## Light matte Braun/Rams housing — the family DEFAULT surface. Plastic-painted, calm; `wear`
## (0..1) only LIGHTLY darkens/roughens (subtle dust, not heavy grime).
static func rams_body(c: Color = BODY_LIGHT, wear: float = 0.08) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c.darkened(wear * 0.12)
	m.metallic = 0.04
	m.roughness = clampf(0.58 + wear * 0.18, 0.05, 1.0)
	return m


## A crisp Dieter-Rams accent bar split into 3 colour segments along X. Returns a +Z facing
## Node3D centred on origin — place it proud of a face (z += small). Default = the Braun triad.
static func three_color_bar(length: float, thickness: float = 0.05, cols: Array = []) -> Node3D:
	var c: Array = cols if cols.size() >= 3 else BAR_TRIAD
	var root := Node3D.new()
	root.name = "ThreeColorBar"
	var seg: float = length / 3.0
	for i in range(3):
		var m := StandardMaterial3D.new()
		m.albedo_color = c[i]
		m.metallic = 0.0
		m.roughness = 0.5
		var x: float = -length * 0.5 + seg * (float(i) + 0.5)
		root.add_child(box(Vector3(x, 0.0, 0.0), Vector3(seg, thickness, 0.02), m))
	return root


## A faint darker band where dust settles (a prop's base). Restrained — a thin low-contrast strip
## just proud of the +Z face. Not heavy grime, but reads as "this has sat a while".
static func grime_band(length: float, height: float, z: float, base: Color = BODY_LIGHT) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base.darkened(0.28)
	m.metallic = 0.0
	m.roughness = 0.92
	return box(Vector3(0.0, height * 0.5, z), Vector3(length, height, 0.006), m)


## Faint vertical dust streaks running DOWN a face (below vents/seams) — the restrained dirt the
## refs asked for. Returns a +Z facing Node3D centred on its origin within a w×h rect; place it at
## a face centre (z baked in). Deterministic (varies by index), translucent, dark — barely there.
static func dust_streaks(w: float, h: float, z: float, count: int = 4) -> Node3D:
	var root := Node3D.new()
	root.name = "DustStreaks"
	for i in range(count):
		var t: float = (float(i) + 0.5) / float(count)
		var x: float = lerpf(-w * 0.40, w * 0.40, t)
		var ln: float = h * (0.30 + 0.34 * fmod(float(i) * 0.61, 1.0))
		var sw: float = 0.010 + 0.012 * fmod(float(i) * 0.43, 1.0)
		var cy: float = h * 0.5 - ln * 0.5 - h * 0.05   # hang from near the top of the face
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.13, 0.12, 0.11, 0.22)  # faint, dark, low alpha
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.95
		m.metallic = 0.0
		var s := box(Vector3(x, cy, z), Vector3(sw, ln, 0.004), m)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(s)
	return root


## Weathered painted metal — the heavier alternate finish (kept for non-default DNA / dirty variants).
## `wear` (0..1) darkens + roughens toward bare scuffed metal.
static func painted_metal(base: Color, wear: float = 0.15, metal: float = 0.35, rough: float = 0.62) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base.darkened(wear * 0.35)
	m.metallic = clampf(metal + wear * 0.4, 0.0, 1.0)
	m.roughness = clampf(rough + wear * 0.25, 0.05, 1.0)
	m.metallic_specular = 0.4
	return m


## Darker scuffed metal for trim, bolts, edges, frames.
static func worn_metal(base: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base.darkened(0.3)
	m.metallic = 0.7
	m.roughness = 0.45
	return m


## Self-lit accent (status lights, screen glow, edge strips).
static func emissive(c: Color, energy: float = 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


# ── Primitives ────────────────────────────────────────────────────────
static func box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


## A StaticBody3D box collider (default layer 1, matching the grid's structure
## cubes) so a prop is SOLID in-game — the player can't walk through it. size /
## center are in the prop's local metres. Ignored by mesh-AABB framing.
static func box_collider(size: Vector3, center: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Collider"
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = center
	body.add_child(cs)
	return body


## A row of small bolt cylinders along a line — the bolted-panel detail.
static func bolts(a: Vector3, b: Vector3, count: int, radius: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	for i in range(count):
		var t: float = 0.0 if count <= 1 else float(i) / float(count - 1)
		var cyl := CylinderMesh.new()
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		cyl.height = radius * 1.2
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = mat
		mi.rotation_degrees = Vector3(90, 0, 0)   # cap faces +Z
		mi.position = a.lerp(b, t)
		root.add_child(mi)
	return root


# ── Hazard stripes ────────────────────────────────────────────────────
## A PEDESTAL built DOWNWARD from y = 0.
##
## The artifact keeps its own origin and every coordinate it already has; the
## pedestal hangs below, and the grid's auto-grounding (base -> floor) lifts
## the whole assembly so the pedestal's foot meets the ground. That is the
## cheap way to fix an artifact whose controls sit below the VR reach band
## (~0.75-1.35 m): raise the object, do not redesign its face.
##
## Reads as station furniture: recessed toe kick, a shaft inset from the cap,
## a cap plate the machine stands on, an ember line under the lip, and an
## optional asset code stencilled on the front.
static func plinth(w: float, d: float, h: float, finish: String = "rams",
		wear_amount: float = 0.10, accent_col: Color = BRAUN_ACCENT,
		code_text: String = "") -> Node3D:
	var root := Node3D.new()
	root.name = "Plinth"
	root.set_meta("housing", true)
	if h <= 0.05:
		return root
	var pal: Dictionary = finish_palette(finish)
	var cap_mat: StandardMaterial3D = finish_body(finish, pal["body"], wear_amount)
	var body_mat: StandardMaterial3D = finish_body(finish, pal["panel"], wear_amount)
	var dark_mat: StandardMaterial3D = painted_metal(Color(0.09, 0.09, 0.105), wear_amount, 0.4, 0.5)

	var cap_h: float = 0.035
	var kick: float = 0.055
	var shaft_h: float = maxf(h - cap_h - kick, 0.02)
	var front_z: float = d * 0.5

	# cap plate — the machine stands on this
	root.add_child(box(Vector3(0, -cap_h * 0.5, 0), Vector3(w, cap_h, d), cap_mat))
	# ember line under the cap lip
	root.add_child(box(Vector3(0, -cap_h - 0.005, front_z - 0.004),
		Vector3(w * 0.98, 0.006, 0.006), emissive(accent_col, 2.0)))
	# shaft, inset so the cap reads as a lip
	root.add_child(box(Vector3(0, -cap_h - shaft_h * 0.5, 0),
		Vector3(w - 0.06, shaft_h, d - 0.06), body_mat))
	# recessed toe kick
	root.add_child(box(Vector3(0, -h + kick * 0.5, 0),
		Vector3(w - 0.14, kick, d - 0.14), dark_mat))
	# grime where the floor meets the base
	var gb: MeshInstance3D = grime_band(w * 0.85, 0.05, (d - 0.06) * 0.5 + 0.004, pal["panel"])
	if gb:
		gb.position.y = -h + kick + 0.004
		root.add_child(gb)
	if code_text.strip_edges() != "":
		var code: MeshInstance3D = stencil(code_text, Vector2(0.10, 0.026),
			accent_col.lightened(0.25))
		if code:
			code.position = Vector3(-w * 0.5 + 0.10, -cap_h - 0.075, front_z - 0.028)
			root.add_child(code)
	return root


## A right-triangle prism SHOULDER: a sloped shelf a control pad rests on, so
## the pad meets the body instead of hanging in air. Faces +Z, origin at the
## centre; `d_bottom` > `d_top` gives the forward-leaning console slope.
## (Palle 2026-07-19: "the buttons interface part need a wedge profile so it
## does not hang in the air.")
static func wedge(w: float, h: float, d_bottom: float, d_top: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: float = -w / 2.0
	var x1: float = w / 2.0
	var y0: float = -h / 2.0
	var y1: float = h / 2.0
	var bbl := Vector3(x0, y0, 0.0)
	var bbr := Vector3(x1, y0, 0.0)
	var btl := Vector3(x0, y1, 0.0)
	var btr := Vector3(x1, y1, 0.0)
	var fbl := Vector3(x0, y0, d_bottom)
	var fbr := Vector3(x1, y0, d_bottom)
	var ftl := Vector3(x0, y1, d_top)
	var ftr := Vector3(x1, y1, d_top)
	var faces := [
		[fbl, fbr, ftr, ftl], [bbr, bbl, btl, btr], [bbl, fbl, ftl, btl],
		[fbr, bbr, btr, ftr], [btl, ftl, ftr, btr], [bbl, bbr, fbr, fbl],
	]
	for f in faces:
		st.add_vertex(f[0]); st.add_vertex(f[1]); st.add_vertex(f[2])
		st.add_vertex(f[0]); st.add_vertex(f[2]); st.add_vertex(f[3])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


## A SPECIMEN DOCK — the containment-tank vocabulary for a specimen you can
## still LIFT OUT.
##
## The sealed tank (see surreal_lab's specimen mode: tapered base, strut cage,
## domed cap, rim lights) is the right idiom for a jar — but a dome traps the
## specimen, and some specimens are meant to be picked up and shaken. So the
## dock is that vocabulary with the cap removed: a tapered base, a lit cradle
## ring the vessel seats into, struts rising to an OPEN collar, an angled
## readout inset in the base front, a glowing seal ring, and feet.
##
## Origin at floor level; the cradle seat is returned via `seat_y` in the
## node's meta so the caller can sit its vessel exactly on it.
static func specimen_dock(base_r: float, dock_r: float, base_h: float,
		collar_h: float, finish: String = "rams", wear_amount: float = 0.10,
		accent_col: Color = BRAUN_ACCENT, glow_col: Color = Color(0.35, 0.75, 0.95)) -> Node3D:
	var root := Node3D.new()
	root.name = "SpecimenDock"
	var pal: Dictionary = finish_palette(finish)
	var dark := painted_metal(Color(0.09, 0.09, 0.105), wear_amount, 0.5, 0.5)
	var mid := painted_metal(pal["panel"].darkened(0.35), wear_amount, 0.45, 0.55)
	var steel := worn_metal(pal["panel"])

	# tapered base
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = base_r * 0.92
	bm.bottom_radius = base_r
	bm.height = base_h
	bm.radial_segments = 32
	base.mesh = bm
	base.material_override = dark
	base.position = Vector3(0, base_h * 0.5, 0)
	root.add_child(base)

	# cradle shoulder the vessel sits in
	var seat_y: float = base_h + 0.035
	var shoulder := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = dock_r + 0.02
	sm.bottom_radius = base_r * 0.88
	sm.height = 0.07
	sm.radial_segments = 32
	shoulder.mesh = sm
	shoulder.material_override = mid
	shoulder.position = Vector3(0, base_h + 0.035, 0)
	root.add_child(shoulder)

	# glowing seal ring at the cradle — the "powered dock" read
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = dock_r
	tm.outer_radius = dock_r + 0.018
	ring.mesh = tm
	ring.material_override = emissive(glow_col, 2.4)
	ring.position = Vector3(0, seat_y + 0.030, 0)
	root.add_child(ring)

	# struts to an OPEN collar — the cage that does not close
	var collar_y: float = seat_y + collar_h
	for i in range(3):
		var ang: float = TAU * (float(i) / 3.0) + 0.5
		var sx: float = cos(ang) * (dock_r + 0.045)
		var sz: float = sin(ang) * (dock_r + 0.045)
		var strut := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.010
		cm.bottom_radius = 0.012
		cm.height = collar_h
		cm.radial_segments = 10
		strut.mesh = cm
		strut.material_override = steel
		strut.position = Vector3(sx, seat_y + collar_h * 0.5, sz)
		root.add_child(strut)
	var collar := MeshInstance3D.new()
	var cot := TorusMesh.new()
	cot.inner_radius = dock_r + 0.030
	cot.outer_radius = dock_r + 0.055
	collar.mesh = cot
	collar.material_override = steel
	collar.position = Vector3(0, collar_y, 0)
	root.add_child(collar)

	# angled readout inset in the base front
	var panel := Node3D.new()
	panel.name = "DockReadout"
	panel.position = Vector3(0.0, base_h * 0.62, base_r - 0.012)
	panel.rotation_degrees = Vector3(-22.0, 0.0, 0.0)
	root.add_child(panel)
	panel.add_child(box(Vector3.ZERO, Vector3(base_r * 1.15, 0.135, 0.025), dark))
	panel.add_child(box(Vector3(0, 0.012, 0.016),
		Vector3(base_r * 0.92, 0.088, 0.006), emissive(DISPLAY_DARK, 0.45)))
	panel.add_child(box(Vector3(0, 0.070, 0.016),
		Vector3(base_r * 1.05, 0.005, 0.005), emissive(accent_col, 2.0)))
	for i in range(3):
		# One warm ember + two neutral keys (family rule: one ember, no stray
		# cool/warm saturated accents on structural surfaces).
		var lamp := box(Vector3(-base_r * 0.36 + float(i) * base_r * 0.36, -0.048, 0.016),
			Vector3(0.016, 0.016, 0.006),
			emissive([accent_col, Color(0.55, 0.57, 0.62), Color(0.30, 0.31, 0.35)][i], 1.6))
		panel.add_child(lamp)

	# feet
	for i in range(3):
		var ang2: float = TAU * (float(i) / 3.0) + 0.4
		var foot := MeshInstance3D.new()
		var fm := CylinderMesh.new()
		fm.top_radius = 0.032
		fm.bottom_radius = 0.040
		fm.height = 0.035
		fm.radial_segments = 12
		foot.mesh = fm
		foot.material_override = dark
		foot.position = Vector3(cos(ang2) * base_r * 0.78, 0.017, sin(ang2) * base_r * 0.78)
		root.add_child(foot)

	root.set_meta("housing", true)      # so the grammar probe scopes its rules here
	root.set_meta("seat_y", seat_y + 0.035)
	root.set_meta("readout_path", "DockReadout")
	return root


## Diagonal warning-stripe texture (caution yellow / dark), cached per colour pair.
static var _stripe_cache: Dictionary = {}
static func hazard_stripe_texture(a: Color = Color(0.95, 0.75, 0.05), b: Color = Color(0.10, 0.10, 0.12), bands: int = 8) -> ImageTexture:
	var key := "%s|%s|%d" % [a, b, bands]
	if _stripe_cache.has(key):
		return _stripe_cache[key]
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var period: float = float(n) / float(bands)
	for y in range(n):
		for x in range(n):
			# diagonal: stripe index from (x+y)
			var s: int = int(floor(float(x + y) / period))
			img.set_pixel(x, y, a if (s % 2 == 0) else b)
	var tex := ImageTexture.create_from_image(img)
	_stripe_cache[key] = tex
	return tex


## A hazard-striped material (diagonal caution stripes). Apply to a thin box face / trim.
static func striped_mat(a: Color = Color(0.95, 0.75, 0.05), b: Color = Color(0.10, 0.10, 0.12)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = hazard_stripe_texture(a, b)
	m.roughness = 0.7
	m.metallic = 0.1
	m.uv1_scale = Vector3(2, 2, 1)
	return m


# ── Stencils / branding (baked text, the integrated-text principle) ───
## Painted-on stencil text that TAKES scene light (unshaded=false) — IDs, labels, branding
## printed onto a surface instead of a floating Label3D. Returns a +Z quad; place it just
## proud of the surface (z += 0.004) where the old label sat.
static func stencil(text: String, world_size: Vector2, color: Color = Color(0.86, 0.87, 0.90)) -> MeshInstance3D:
	return BakedTextAlbedo.make_label_mesh(text, color, world_size, 1400, false)


## An opaque printed-patch label (bg colour + text), e.g. "VALLEY LABORATORIES" or "EMPLOYEES ONLY".
static func brand_patch(text: String, world_size: Vector2, bg: Color = Color(0.12, 0.13, 0.16), fg: Color = Color(0.90, 0.92, 0.96)) -> MeshInstance3D:
	return BakedTextAlbedo.make_panel_mesh(text, bg, fg, world_size, 1400, false)


# ── Framed readout screen (the curated 2D-in-3D label, replacing floats) ──
## A small self-lit framed screen facing +Z, origin at the face centre: worn-metal bezel + a
## dark emissive face + a baked amber header + green text lines. The reusable "screen" used by
## artifact_readout_screen and by cabinets/consoles. `lines` is an Array of short strings.
static func readout(header: String, lines: Array, size: Vector2 = Vector2(0.5, 0.34),
		screen_bg: Color = DISPLAY_DARK, text_color: Color = TEXT_DISPLAY,
		header_color: Color = BRAUN_ACCENT) -> Node3D:
	var root := Node3D.new()
	root.name = "Readout"
	var w: float = size.x
	var h: float = size.y
	var ft: float = maxf(w, h) * 0.06          # frame bar thickness
	var fd: float = 0.05                         # frame depth
	var bez := rams_body(PANEL_TRIM, 0.06)       # light matte bezel (Braun, recedes)
	# four bezel bars
	root.add_child(box(Vector3(0, h * 0.5 + ft * 0.5, 0), Vector3(w + ft * 2.0, ft, fd), bez))
	root.add_child(box(Vector3(0, -h * 0.5 - ft * 0.5, 0), Vector3(w + ft * 2.0, ft, fd), bez))
	root.add_child(box(Vector3(-w * 0.5 - ft * 0.5, 0, 0), Vector3(ft, h, fd), bez))
	root.add_child(box(Vector3(w * 0.5 + ft * 0.5, 0, 0), Vector3(ft, h, fd), bez))
	# Face: a light background reads as a MATTE printed label (black-on-off-white); a dark
	# background stays a softly-lit screen. Auto-switch on luminance.
	var face_mat: Material = rams_body(screen_bg, 0.04) if screen_bg.get_luminance() > 0.45 else emissive(screen_bg, 0.32)
	root.add_child(box(Vector3(0, 0, 0), Vector3(w, h, 0.03), face_mat))
	var face_z: float = 0.018
	# header (top strip)
	if header.strip_edges() != "":
		var hq := BakedTextAlbedo.make_label_mesh(header, header_color, Vector2(w * 0.9, h * 0.2), 1400, true)
		if hq:
			hq.position = Vector3(0, h * 0.5 - h * 0.14, face_z + 0.004)
			root.add_child(hq)
	# body lines
	if lines.size() > 0:
		var line_h: float = (h * 0.62) / float(maxi(lines.size(), 1))
		var block := BakedTextAlbedo.make_text_block(lines, text_color, minf(line_h, h * 0.16), w * 0.84, line_h * 0.25, true)
		if block:
			block.position = Vector3(0, -h * 0.08, face_z + 0.004)
			root.add_child(block)
	return root


# ── Systems (STEP 7): visible flow edges from a source to a sink ───────
# A system is rendered as the EDGE between two points: power/data run on the FLOOR as a lit strip
# (the "light on the floor" idea); vent/fluid/waste run as a PIPE up to a ceiling carry height and
# across. Colour per kind. See doc/GENERATIVE_MAPS.md §5.
const SYS_COLOR := {
	"power": Color(0.86, 0.34, 0.11), "data": Color(0.30, 0.72, 0.95),
	"fluid": Color(0.32, 0.55, 0.95), "vent": Color(0.72, 0.74, 0.80), "waste": Color(0.45, 0.40, 0.30),
}


## A framed 2D-in-3D readout panel mounted on a VISIBLE BRACKET, so the text reads as PART of the
## artifact (a sign on a wall bracket, a screen on a stalk) rather than floating beside it. Origin =
## the MOUNT POINT on the artifact surface; the panel sits `reach` away along `dir`, joined by two
## struts off a mount plate. dir: (0,0,1) boom toward viewer · (0,1,0) stalk up · (±1,0,0) side arm.
static func signage(header: String, lines: Array, size: Vector2 = Vector2(0.5, 0.18), reach: float = 0.14, dir: Vector3 = Vector3(0, 0, 1), tilt_deg: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Signage"
	var d: Vector3 = dir.normalized()
	if d == Vector3.ZERO:
		d = Vector3(0, 0, 1)
	var panel_pos: Vector3 = d * reach
	var steel := worn_metal(PANEL_TRIM)
	# Mount plate flush on the artifact surface.
	root.add_child(box(Vector3.ZERO, Vector3(0.07, 0.07, 0.022), steel))
	# Two struts from the mount to just behind the panel, offset perpendicular to the reach.
	var perp: Vector3 = Vector3(0, 1, 0) if absf(d.dot(Vector3(0, 1, 0))) < 0.85 else Vector3(1, 0, 0)
	var off: float = clampf(size.y * 0.34, 0.04, size.y * 0.5)
	var back: Vector3 = panel_pos - d * 0.03
	for s in [1.0, -1.0]:
		root.add_child(_pipe(perp * (s * off), back + perp * (s * off), 0.012, steel))
	# Framed 2D-in-3D panel at the bracket end — black text on a matte off-white label.
	var panel: Node3D = readout(header, lines, size, Color(0.88, 0.86, 0.80), Color(0.09, 0.09, 0.11), Color(0.09, 0.09, 0.11))
	panel.position = panel_pos
	if tilt_deg != 0.0:
		panel.rotation_degrees.x = tilt_deg
	root.add_child(panel)
	return root


## A boundary fixture where a system enters the room (a wall outlet, a ceiling intake). +Z faces out.
static func system_source(kind: String, size: float = 0.3) -> Node3D:
	var root := Node3D.new()
	root.name = "Source_" + kind
	var c: Color = SYS_COLOR.get(kind, BRAUN_ACCENT)
	root.add_child(box(Vector3(0, 0, 0), Vector3(size, size, 0.12), rams_body(PANEL_TRIM, 0.12)))
	root.add_child(box(Vector3(0, 0, 0.07), Vector3(size * 0.62, size * 0.34, 0.03), emissive(c, 1.5)))
	return root


## A routed visible edge a -> b for a system `kind`. power/data: a lit strip on the floor (Manhattan
## L) + a riser to the sink. vent/fluid/waste: a pipe up to a ceiling carry height, across, and down.
static func system_edge(a: Vector3, b: Vector3, kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Edge_" + kind
	var c: Color = SYS_COLOR.get(kind, BRAUN_ACCENT)
	if kind == "power" or kind == "data":
		var y := 0.02
		var w := 0.055 if kind == "power" else 0.028
		var mat := emissive(c, 1.5)
		var p0 := Vector3(a.x, y, a.z)
		var corner := Vector3(b.x, y, a.z)
		var p2 := Vector3(b.x, y, b.z)
		root.add_child(_strip(p0, corner, w, mat))
		root.add_child(_strip(corner, p2, w, mat))
		root.add_child(_pipe(p2, b, w * 0.45, worn_metal(Color(0.10, 0.10, 0.12))))   # riser to the sink
	else:
		var r := 0.075 if kind == "vent" else 0.055
		var mat := rams_body(PANEL_TRIM, 0.14)
		var ch := maxf(a.y, b.y) + 1.1                                                 # ceiling carry height
		var a1 := Vector3(a.x, ch, a.z)
		var b1 := Vector3(b.x, ch, b.z)
		root.add_child(_pipe(a, a1, r, mat))
		root.add_child(_pipe(a1, b1, r, mat))
		root.add_child(_pipe(b1, b, r, mat))
	return root


# an axis-aligned thin lit/material strip lying on the floor between a and b
static func _strip(a: Vector3, b: Vector3, w: float, mat: Material) -> MeshInstance3D:
	var ln: float = maxf(a.distance_to(b), 0.001)
	var d := b - a
	var size: Vector3 = Vector3(ln, 0.014, w) if absf(d.x) >= absf(d.z) else Vector3(w, 0.014, ln)
	return box((a + b) * 0.5, size, mat)


# a cylinder pipe between a and b (any orientation)
static func _pipe(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
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
