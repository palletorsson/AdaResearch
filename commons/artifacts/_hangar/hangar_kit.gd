@tool
extends RefCounted
class_name HangarKit

## Shared style toolkit for the artifact "packaging" prop family — the sci-fi maintenance-bay
## look: weathered painted metal, hazard stripes, stencilled labels/branding, and small self-lit
## framed readout screens. All static; props call HangarKit.painted_metal(...), HangarKit.readout(...)
## so the whole family reads as one set. Stencils/screens are baked via BakedTextAlbedo (headless-safe).

# ── Materials ─────────────────────────────────────────────────────────
## Weathered painted metal — the family default surface. `wear` (0..1) darkens + roughens
## toward bare scuffed metal.
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
		screen_bg: Color = Color(0.04, 0.08, 0.06), text_color: Color = Color(0.40, 0.95, 0.55),
		header_color: Color = Color(0.97, 0.78, 0.22)) -> Node3D:
	var root := Node3D.new()
	root.name = "Readout"
	var w: float = size.x
	var h: float = size.y
	var ft: float = maxf(w, h) * 0.06          # frame bar thickness
	var fd: float = 0.05                         # frame depth
	var bez := worn_metal(Color(0.20, 0.21, 0.24))
	# four bezel bars
	root.add_child(box(Vector3(0, h * 0.5 + ft * 0.5, 0), Vector3(w + ft * 2.0, ft, fd), bez))
	root.add_child(box(Vector3(0, -h * 0.5 - ft * 0.5, 0), Vector3(w + ft * 2.0, ft, fd), bez))
	root.add_child(box(Vector3(-w * 0.5 - ft * 0.5, 0, 0), Vector3(ft, h, fd), bez))
	root.add_child(box(Vector3(w * 0.5 + ft * 0.5, 0, 0), Vector3(ft, h, fd), bez))
	# screen face (thin box, emissive dark)
	var face_mat := emissive(screen_bg, 0.6)
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
