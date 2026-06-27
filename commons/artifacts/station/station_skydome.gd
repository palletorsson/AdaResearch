extends Node3D
class_name StationSkydome

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the kit's ATMOSPHERE — a large UNLIT/emissive BACKDROP (an inward-facing bowed shell or a tall curved plane) set BEHIND a bay as void or sky, for the artifacts that have no scale: the dark_sphere, the fractal clouds, the things the curators had to float base-free because nothing should sit UNDER them. Origin at the floor centre; the shell rises to `height` and stands `depth_offset` back along −Z. Reads as air, not a surface — no shading, no edge, no horizon you could touch.
# desire: to be the air behind everything — where a thing has no edge, give it a sky; where a thing has no bottom, give it a void to hang in, so the eye never hunts for a floor that was never the point.
# critical_parameter: mode × top_color/bottom_color × depth_offset — whether the backdrop is flat void, a graded sky, or a two-band horizon, what colours it fades between, and how far back it stands so it never crowds the held thing.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new size, mode, or palette.
# emerges: "void" = one flat dark field (a thing hangs in nothing); "gradient" = a smooth vertical fade top→bottom on a bowed quad (a sky with no sun); "sky" = two stacked emissive bands with a soft seam (a horizon implied, never drawn). The curve makes it wrap the periphery so no straight edge betrays the flat plane.
# needs: a tall bowed shell of segment quads facing inward [present]; an unlit emissive material per row so it self-lights and casts no shadow [present]; a vertical colour ramp top_color→bottom_color [present]; standing depth_offset back along −Z [present]; NO Light3D, NO collision — it is scenery the body never reaches.
# relationships: the sibling of [[station_floorline]] (floor-as-relation) and [[station_luminaire]] (light) in the not-an-object set; the negative space behind [[station_plinth]] and the bay built by [[curation_station]] — where the plinth says "this one, here", the skydome says "and behind it, nothing / everything".
# truth: a backdrop is a refusal to put a base under a thing that has no underside. Some objects are not on the ground — they are IN a field; the skydome is the kit admitting that not everything is a specimen on a shelf, some things are weather.

@export_group("Size")
## Backdrop width in 1 m grid cells (X span of the shell).
@export var width_cells: int = 8
## Backdrop height in metres (top of the shell above the floor).
@export var height: float = 6.0

@export_group("Backdrop")
## "void" (one flat dark field) | "gradient" (smooth top→bottom fade) | "sky" (two stacked bands + soft seam).
@export var mode: String = "gradient"
## How far back the shell stands along −Z (metres). Larger = further behind the bay.
@export var depth_offset: float = 4.0
## How much the shell bows toward the viewer at its edges (metres of curve depth). 0 = a flat plane.
@export var curve: float = 1.6
## Number of vertical strips across the width — more = smoother curve + smoother gradient.
@export var segments: int = 14

@export_group("Color")
## Top of the vertical gradient. STRING "r,g,b,a" when set via config.
@export var top_color: Color = Color(0.05, 0.07, 0.12)
## Bottom of the vertical gradient. STRING "r,g,b,a" when set via config.
@export var bottom_color: Color = Color(0.02, 0.02, 0.03)
## Emissive energy — how brightly the backdrop self-lights (it takes no scene light).
@export var glow: float = 0.85

const CELL := 1.0
const BANDS := 18            # vertical colour bands per strip (the gradient resolution)
const QUAD_THICK := 0.02     # thin shell quads

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
	if has_meta("config_width_cells"): width_cells = int(str(get_meta("config_width_cells")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_mode"): mode = str(get_meta("config_mode")).to_lower()
	if has_meta("config_depth_offset"): depth_offset = float(str(get_meta("config_depth_offset")))
	if has_meta("config_curve"): curve = float(str(get_meta("config_curve")))
	if has_meta("config_segments"): segments = int(str(get_meta("config_segments")))
	if has_meta("config_top_color"): top_color = _pc(str(get_meta("config_top_color")), top_color)
	if has_meta("config_bottom_color"): bottom_color = _pc(str(get_meta("config_bottom_color")), bottom_color)
	if has_meta("config_glow"): glow = float(str(get_meta("config_glow")))


func _build() -> void:
	_built = true
	var wcells: int = maxi(width_cells, 1)
	var total_w: float = float(wcells) * CELL
	var h: float = maxf(height, 1.0)
	var segs: int = clampi(segments, 3, 48)
	var seg_w: float = total_w / float(segs)
	var bands: int = clampi(BANDS, 2, 48) if mode == "gradient" else (2 if mode == "sky" else 1)
	var back_z: float = -maxf(depth_offset, 0.0)
	var bow: float = maxf(curve, 0.0)

	# An inward-facing bowed shell: each vertical strip is pushed back by a parabolic amount of `bow`
	# toward the edges, so the centre is nearest and the wings wrap the periphery. No straight silhouette
	# edge betrays the flat plane; from inside the bay it reads as an enclosing field, not a billboard.
	for s in range(segs):
		var t_centre: float = (float(s) + 0.5) / float(segs)     # 0..1 across width
		var x: float = lerpf(-total_w * 0.5, total_w * 0.5, t_centre)
		var edge: float = absf(t_centre - 0.5) * 2.0              # 0 at centre, 1 at the wings
		var z: float = back_z - bow * edge * edge                 # parabolic bow back at the wings
		_build_strip(x, z, seg_w, h, bands)


func _build_strip(x: float, z: float, seg_w: float, h: float, bands: int) -> void:
	# A vertical strip of `bands` stacked emissive quads, each tinted by its height along the
	# top_color→bottom_color ramp. "void" = one band of bottom_color; "sky" = two bands meeting at a
	# soft mid seam; "gradient" = a fine ramp. All UNLIT so the shell self-lights and reads as air.
	var band_h: float = h / float(bands)
	for b in range(bands):
		# t = 0 at the bottom band, 1 at the top band (so top_color sits up high).
		var t_lo: float = float(b) / float(bands)
		var t_hi: float = float(b + 1) / float(bands)
		var t_mid: float = (t_lo + t_hi) * 0.5
		var col: Color = _band_color(t_mid, bands)
		var cy: float = (float(b) + 0.5) * band_h
		var mat := _sky_mat(col)
		var quad := _box(Vector3(x, cy, z), Vector3(seg_w + 0.01, band_h + 0.01, QUAD_THICK), mat)
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(quad)


func _band_color(t: float, bands: int) -> Color:
	# t in 0..1 along the height (0 = floor, 1 = top).
	match mode:
		"void":
			return bottom_color
		"sky":
			# Two flat fields with a short blended seam at the horizon (mid height).
			var seam: float = 0.12
			if t > 0.5 + seam:
				return top_color
			if t < 0.5 - seam:
				return bottom_color
			var k: float = clampf((t - (0.5 - seam)) / (seam * 2.0), 0.0, 1.0)
			return bottom_color.lerp(top_color, k)
		_:
			# gradient: smooth ramp, eased so the horizon glows a touch.
			var e: float = clampf(t, 0.0, 1.0)
			return bottom_color.lerp(top_color, e)


func _sky_mat(c: Color) -> StandardMaterial3D:
	# UNLIT emissive: takes NO scene light, casts NO shadow — it must read as air/void, never a lit
	# surface. (HangarKit.emissive uses PER_PIXEL shading, which still receives light; a backdrop must
	# not, or a luminaire elsewhere in the bay would "paint" the sky. So we build an unshaded one here.)
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = maxf(glow, 0.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED      # visible from either side (in case the bay wraps it)
	m.disable_receive_shadows = true
	return m


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
