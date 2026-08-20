extends Node3D
class_name WalkThisLineMarking

## The floor half of the pair — REBUILT PROCEDURALLY. No glb: a painted stripe
## and a stencilled legend, both built in _ready() like the rest of the corpus.
##
## The tape (do_not_cross_barrier) forbids crossing the line; this paint
## commands FOLLOWING it. Perpendicular relations to one line — a body meeting
## both has been told the line is impassable in one direction and obligatory in
## the other, which is what a line does when it is also a rule:
##
##   "Measure is also violence. What doesn't fit the grid is remainder, error,
##    erased. The line inherits this: efficient, relentless, forgetting
##    everything but endpoints."   — Point_Lines/blurb.md
##
## The LEGEND IS A PARAMETER — the glb froze the words in the mesh; here they
## are stencilled at build time, so the paint can say anything a map needs.

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## The words painted on the floor. Empty means stripe only.
@export var legend_text: String = "WALK THIS LINE"
## Stripe length, metres.
@export var stripe_len_m: float = 2.9
## Stripe width, metres.
@export var stripe_w_m: float = 0.075
## Metres the legend sits behind the stripe (toward the reader), so the words
## announce the line before the feet reach it.
@export var standoff_m: float = 0.42
## Draw the stripe. Without it the legend is a statement; with it the line has a
## position — and the two are different claims, which is why this artifact and
## the barrier are a pair rather than one object.
@export var show_stripe: bool = true
## Paint colour. WHITE, because a floor marking is white in the world and white
## is legible on pale and dark floors alike.
@export var paint_color: Color = Color.WHITE
## Wear, 0 (fresh) to 1 (nearly gone), as paint transparency. A rule nobody has
## repainted is still a rule; this says how long it has been one.
@export_range(0.0, 1.0, 0.01) var wear: float = 0.0

const LIFT := 0.006      # metres the paint floats above the floor, against z-fighting

var _built: bool = false


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("legend_text"):
		legend_text = str(config_data["legend_text"])
	if config_data.has("stripe_len_m"):
		stripe_len_m = clampf(float(config_data["stripe_len_m"]), 0.4, 12.0)
	if config_data.has("stripe_w_m"):
		stripe_w_m = clampf(float(config_data["stripe_w_m"]), 0.02, 0.5)
	if config_data.has("standoff_m"):
		standoff_m = float(config_data["standoff_m"])
	if config_data.has("show_stripe"):
		show_stripe = bool(config_data["show_stripe"])
	if config_data.has("paint_color"):
		var raw: String = str(config_data["paint_color"])
		if raw.is_valid_html_color():
			paint_color = Color(raw)
		else:
			push_warning("walk_this_line_marking: '%s' is not a colour; keeping %s"
				% [raw, paint_color.to_html(false)])
	if config_data.has("wear"):
		wear = clampf(float(config_data["wear"]), 0.0, 1.0)
	if _built:
		_built = false
		_build()


func _build() -> void:
	if _built:
		return
	_built = true
	for child in get_children():
		child.queue_free()

	var rgba: Color = paint_color
	rgba.a = clampf(paint_color.a * (1.0 - wear), 0.0, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = rgba
	# Paint on a floor is matte: it must not take a highlight from the room's key
	# light, so roughness is pinned rather than inherited from any kit finish.
	mat.roughness = 1.0
	mat.metallic = 0.0
	if rgba.a < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mount := Node3D.new()
	mount.name = "Marking"
	add_child(mount)

	if show_stripe:
		var stripe := MeshInstance3D.new()
		var quad := PlaneMesh.new()
		quad.size = Vector2(stripe_len_m, stripe_w_m)
		stripe.mesh = quad
		stripe.material_override = mat
		stripe.position = Vector3(0, LIFT, 0)
		mount.add_child(stripe)

	if legend_text.strip_edges() != "":
		var label: MeshInstance3D = HangarKit.stencil(legend_text,
			Vector2(minf(stripe_len_m * 0.62, 2.2), 0.17), rgba)
		if label:
			# Lying flat, reading from above, standing off toward the approach.
			label.rotation_degrees.x = -90.0
			label.position = Vector3(0, LIFT, standoff_m)
			if rgba.a < 0.999 and label.material_override is StandardMaterial3D:
				(label.material_override as StandardMaterial3D).transparency = \
					BaseMaterial3D.TRANSPARENCY_ALPHA
			mount.add_child(label)
