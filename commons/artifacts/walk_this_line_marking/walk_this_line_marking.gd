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
## Stripe length, metres. Was 2.9 — three cells of floor for one instruction,
## which read as a runway rather than a mark. Shorter is also more like the
## thing it imitates: real floor markings are read at the feet, not down a hall.
@export var stripe_len_m: float = 1.6
## Stripe height, metres. Paint at 6 mm is invisible from standing height in a
## museum hall — the whole artifact vanished into the floor at eye level. This
## raises the mark into a kerb you can actually see approaching. 0 keeps it flat
## paint, which is what it was.
@export var height_m: float = 0.28
## A body in the kerb.
##
## THIS CHANGES WHAT THE ARTIFACT ARGUES, so it is a switch and not a constant.
## The line was paint: "nothing about paint prevents anything, it works by being
## read and obeyed", and it paired with do_not_cross_barrier as the obligatory
## line against the forbidden one — two rules that hold by being read. A kerb
## with a collider HOLDS BY BEING SOLID, which is a different claim about how a
## rule works. #solid:0 restores the paint that only asks.
@export var solid: bool = true
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
	if config_data.has("height_m"):
		height_m = clampf(float(config_data["height_m"]), 0.0, 1.2)
	if config_data.has("solid"):
		solid = _flag(config_data["solid"], solid)
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


func _flag(v: Variant, fallback: bool) -> bool:
	# `#solid:0` arrives as the STRING "0", and bool("0") in GDScript is true.
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	var t: String = str(v).strip_edges().to_lower()
	if t in ["0", "false", "no", "off"]:
		return false
	if t in ["1", "true", "yes", "on"]:
		return true
	return fallback


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

	# The top face of the mark — where the legend now lies, whether the mark is
	# paint (0) or a kerb.
	var top: float = maxf(0.0, height_m) + LIFT

	if show_stripe:
		var stripe := MeshInstance3D.new()
		if height_m > 0.0:
			var bar := BoxMesh.new()
			bar.size = Vector3(stripe_len_m, height_m, stripe_w_m)
			stripe.mesh = bar
			stripe.position = Vector3(0, height_m * 0.5 + LIFT, 0)
		else:
			var quad := PlaneMesh.new()
			quad.size = Vector2(stripe_len_m, stripe_w_m)
			stripe.mesh = quad
			stripe.position = Vector3(0, LIFT, 0)
		stripe.material_override = mat
		mount.add_child(stripe)

		if solid and height_m > 0.0:
			var body := StaticBody3D.new()
			var col := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(stripe_len_m, height_m, stripe_w_m)
			col.shape = box
			col.position = Vector3(0, height_m * 0.5 + LIFT, 0)
			body.add_child(col)
			mount.add_child(body)

	if legend_text.strip_edges() != "":
		var label: MeshInstance3D = HangarKit.stencil(legend_text,
			Vector2(minf(stripe_len_m * 0.62, 2.2), 0.17), rgba)
		if label:
			# Lying flat, reading from above, standing off toward the approach.
			label.rotation_degrees.x = -90.0
			# STAYS ON THE FLOOR. Moving it onto the kerb's top face put white
			# letters on a white bar and they vanished — the legend has always
			# needed the dark floor to read against, and standoff_m already
			# holds it clear of the mark, "so the words announce the line
			# before the feet reach it". It only needs lifting if the standoff
			# is inside the bar's own width.
			var legend_y: float = LIFT
			if standoff_m < stripe_w_m * 0.5:
				legend_y = top
			label.position = Vector3(0, legend_y, standoff_m)
			if rgba.a < 0.999 and label.material_override is StandardMaterial3D:
				(label.material_override as StandardMaterial3D).transparency = \
					BaseMaterial3D.TRANSPARENCY_ALPHA
			mount.add_child(label)
