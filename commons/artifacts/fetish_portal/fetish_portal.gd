# @identity
# essence: the first rung of combine_portals' resolution ladder, taken out of the ladder and made solid — a three-segment torus, which is a triangle, standing upright in lacquered black
# desire: the learner meets the coarsest possible ring as a FINISHED object rather than as the failure the corridor walks away from, and cannot tell whether they are looking at a portal or at the idea of one
# critical_parameter: ring_segments — 3 is the whole artifact. At 4 it is a square, at 8 a ring, and at 3 it is the last count before a torus stops being able to be a torus at all
# triggers: _ready() builds one TorusMesh at the base scene's exact numbers, stands it upright and lacquers it; nothing moves
# emerges: a shape that is unmistakably a triangle and unmistakably a torus, which are two descriptions that should not both fit, and a black surface that reads as a body rather than as a hole in the room
# needs: the PBR kit for the two-lobe black [present]; a lit room — an unlit one takes the limb and gives back a silhouette [the hall provides it]; apply_grid_config [present, 2026-09-07]
# relationships: extracted from commons/primitives/combines/combine_portals, whose own doc calls the ladder "twenty even steps from a triangle to a smooth ring" — this is step zero, kept; wears the black that dark_sphere worked out (two specular lobes, F0 restored, backlit terminator) so the corpus has one fetish-black and not two; kin to portal_frame and spine_portal in shape and to neither in claim, because it transports nobody
# truth: a resolution ladder is a story about a destination, and it makes its first rung into a mistake on the way there. Stand that rung alone, polish it, and the mistake does not survive the change of context: three segments is not a failed circle, it is a triangle, and it was always also a torus. What a thing IS depends on the series you put it in — which is the one claim the corridor cannot make, because the corridor is the series.

extends Node3D
class_name FetishPortal

const PBR := preload("res://commons/render/pbr_kit.gd")

@export_category("The form")
## THE FIRST RUNG. combine_portals.tscn's base TorusMesh is rings 3 /
## ring_segments 3 at inner 4 / outer 3, and its `linear` refinement starts
## there. The SILHOUETTE is kept exactly — ring radius 3.5, tube 0.5 — but the
## radii are swapped back, because inner > outer means a NEGATIVE tube radius and
## a surface turned through itself: every normal points inward, the lighting is
## ambient-only and the body cannot hold its own colour. Measured, that costs 22
## luminance and most of the darkness. The source scene has a bug in it; the
## first pass here called it a quirk and preserved it, which was wrong.
@export var inner_radius: float = 3.0
@export var outer_radius: float = 4.0
## 3 is the artifact. Four is a square, eight is a ring; three is the last count
## at which a torus can still be one.
@export_range(3, 24) var ring_segments: int = 3
@export_range(3, 24) var rings: int = 3
## Upright, so it stands like a doorway rather than lying like a puddle. The base
## scene does this with a 90-degree turn about X and this repeats it rather than
## inheriting a transform nobody would find.
@export var upright: bool = true
## The whole thing is ~7 m across at the shipped radii. A hall that wants it as a
## thing rather than as architecture scales it here.
@export var scale_factor: float = 1.0

@export_category("The finish")
## Near-black, never black. A pure zero albedo has nothing for the two lobes to
## sit on and the object goes back to being a hole.
@export var body_color: Color = Color(0.045, 0.040, 0.052)
## Kept for the map vocabulary, and deliberately NOT wired to the base roughness:
## the kit owns that number. All the shine is the coat's; see _skin().
@export_range(0.0, 1.0) var gloss: float = 0.62
## THE LACQUER. dark_sphere runs 0.24 because it is a rubber body with a film on
## it; this one is patent, so the coat is most of what you see.
@export_range(0.0, 1.0) var lacquer: float = 0.55
@export_range(0.0, 1.0) var lacquer_roughness: float = 0.06
@export_range(0.0, 1.0) var rim: float = 0.35
@export_range(0.0, 1.0) var rim_tint: float = 0.85
## A body you can walk into rather than through. Off by default: this artifact is
## a form, and a form that blocks a corridor is a wall nobody placed.
@export var solid_collider: bool = false

var _mesh_instance: MeshInstance3D = null


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mesh_instance = null

	var mi := MeshInstance3D.new()
	mi.name = "Triangle"
	var t := TorusMesh.new()
	t.inner_radius = inner_radius
	t.outer_radius = outer_radius
	t.rings = maxi(3, rings)
	t.ring_segments = maxi(3, ring_segments)
	mi.mesh = t
	if upright:
		# a torus lies in XZ; a portal stands in XY
		mi.rotation_degrees = Vector3(90, 0, 0)
	mi.material_override = _skin()
	add_child(mi)
	_mesh_instance = mi

	if scale_factor != 1.0:
		mi.scale = Vector3.ONE * maxf(0.01, scale_factor)

	if solid_collider:
		var body := StaticBody3D.new()
		body.name = "Body"
		var shape := CollisionShape3D.new()
		var cs := ConvexPolygonShape3D.new()
		var arrays := t.get_faces()
		cs.points = arrays
		shape.shape = cs
		body.add_child(shape)
		if upright:
			body.rotation_degrees = Vector3(90, 0, 0)
		body.scale = Vector3.ONE * maxf(0.01, scale_factor)
		add_child(body)


## THE BLACK THAT IS A BODY AND NOT A HOLE.
##
## Every number here is dark_sphere's, worked out on 2026-08-07 against a render
## lint that measured it FLAT, and repeated rather than re-derived so the corpus
## has one fetish-black:
##
##   metallic 0        — nothing is 0.6 metallic. The middle of that range is not
##                       a material, it is a knob turned until the sheen looked
##                       right. What the knob was reaching for is a dielectric
##                       with a film on it.
##   metallic_specular — F0 = 0.08 * this, so 0.0 means NO FRESNEL, and Fresnel at
##                       grazing incidence is the entire limb of a dark object.
##                       Take it away and you do not get a darker thing, you get a
##                       hole. 0.5 is the ordinary dielectric value.
##   clearcoat         — the second lobe. Two lobes of different width is most of
##                       what makes a curved surface read as curved; one lobe is a
##                       disc.
##   backlight         — the terminator, kept UNDER the albedo so it lifts the dark
##                       side by a shade instead of becoming a glow.
func _skin() -> StandardMaterial3D:
	# ROUGH BASE, TIGHT COAT — and that order is the whole recipe. The first pass
	# used hard_plastic at gloss 0.62 for the base, which is a SECOND glossy lobe,
	# and two glossy lobes is a mirror: measured against a flat green backdrop the
	# body came back (74, 90, 70) on an albedo of (11, 10, 13), roughly 45% of the
	# room reflected across the entire surface. A rough dielectric scatters that
	# ambient into almost nothing and keeps its own darkness; the coat on top is
	# where all the shine is supposed to come from. dark_sphere reaches for
	# PBR.rubber here for exactly this reason and I read past it.
	var m: StandardMaterial3D = PBR.rubber(body_color, 0.18)
	# AND DO NOT TOUCH m.roughness AFTERWARDS. The kit's _rough() sets a roughness
	# TEXTURE and a scalar pre-divided by that texture's mean, because Godot
	# multiplies the two; overwriting the scalar throws the division away and the
	# surface comes out glossier than anything asked for. Measured: with a 0.78
	# scalar written over the kit's, this body sat at median luminance 83 and
	# leaned +16 toward the green of the room it was standing in, against
	# dark_sphere's 44 and -9 on the same bench. The kit's own comment predicts
	# this failure in as many words and I wrote it anyway.
	m.metallic = 0.0
	m.metallic_specular = 0.50
	m.clearcoat_enabled = true
	m.clearcoat = lacquer
	m.clearcoat_roughness = lacquer_roughness
	m.backlight_enabled = true
	m.backlight = Color(body_color.r * 0.7, body_color.g * 0.6, body_color.b * 0.9)
	PBR.edge_light(m, rim, rim_tint)
	return m


## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "segments" / "ring_segments" · "rings" · "inner_radius" · "outer_radius"
##   "scale" · "upright" · "solid" · "gloss" · "lacquer" · "rim"
##   "color" / "body_color" — Color, [r,g,b] or an html string
##
## Every key here is a WORD, and that is deliberate: the grid reads `#key:<float>`
## as the tutorial's positional shorthand unless the key is registered, so
## `#scale:2` can arrive as a rotation. Word-valued and boolean keys are safe in
## both engines; a caller wanting a number should set the property directly.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in ["segments", "ring_segments"]:
		if config_data.has(k):
			ring_segments = clampi(int(config_data[k]), 3, 24)
	if config_data.has("rings"):
		rings = clampi(int(config_data["rings"]), 3, 24)
	if config_data.has("inner_radius"):
		inner_radius = float(config_data["inner_radius"])
	if config_data.has("outer_radius"):
		outer_radius = float(config_data["outer_radius"])
	if config_data.has("scale"):
		scale_factor = float(config_data["scale"])
	if config_data.has("upright"):
		upright = _flag(config_data["upright"])
	if config_data.has("solid"):
		solid_collider = _flag(config_data["solid"])
	if config_data.has("gloss"):
		gloss = clampf(float(config_data["gloss"]), 0.0, 1.0)
	if config_data.has("lacquer"):
		lacquer = clampf(float(config_data["lacquer"]), 0.0, 1.0)
	if config_data.has("rim"):
		rim = clampf(float(config_data["rim"]), 0.0, 1.0)
	for k in ["color", "body_color"]:
		if config_data.has(k):
			body_color = _as_color(config_data[k], body_color)
	if is_inside_tree():
		_build()


## `#solid:0` arrives as the STRING "0", and bool("0") is true in GDScript. The
## same helper do_not_cross_barrier carries, for the same reason.
func _flag(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


func _as_color(v, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]))
	if v is String and str(v) != "":
		return Color(str(v))
	return fallback
