# AnimatedFoldingPast.gd - Frame-in-frame animation representing time collapsing into the present
#
# @identity
# essence: nested wireframe frames march inward, each 0.85 the size of the last â€” time collapsing toward the present
# desire: learner watches the past recede frame-by-frame and feels duration as a spatial nesting, not a line
# critical_parameter: recession â€” what shape the past takes behind the present (nested / collapsed / abreast / strata); under it scale_ratio (0.85) and cycle_duration (4s) set how tightly and how fast the nesting folds inward
# triggers: animates automatically every _process frame; no interaction, it is a standing meditation on time
# emerges: the intuition that "the present" is only the innermost frame of an endless regress of prior moments
# needs: [renders and animates on ready [has], missing a way for the learner to scrub or freeze the fold]
# relationships: a temporal sibling of the static point â€” where Point_One fixes a place, this fixes a now
# truth: the past does not vanish â€” it recedes, each moment nesting inside the one that follows
extends Node3D

## Frame Configuration
@export var frame_width: float = 0.10  # 10 units scaled down
@export var frame_height: float = 0.08  # 8 units scaled down
@export var frame_count: int = 10  # Number of visible frames
@export var frame_thickness: float = 0.003  # Line thickness

## Animation Configuration
@export var cycle_duration: float = 4.0  # Time for one frame to travel from outer to inner
@export var scale_ratio: float = 0.85  # Each inner frame is this ratio of the outer
@export var z_base_offset: float = -8.0  # Base z offset for the entire effect

## Visual Configuration
@export var frame_color: Color = Color(0.7, 0.8, 0.9, 0.8)
@export var wireframe_only: bool = true

## GLOW â€” 2026-08-31, Palle: "can we use some shader on the lines on folding
## past so that they glow more."
##
## The edges were PRIMITIVE_LINES. A line rasterises one pixel wide whatever a
## shader says, so no material could put light beside one; the usual source of
## that light is screen-space bloom, and this project has none â€”
## commons/scenes/vr_staging.tscn sets `glow_intensity = 1.67` and never sets
## `glow_enabled`, so the effect is configured and off. Switching it on is one
## line and it would change every artifact in every map, which is not this
## artifact's call.
##
## So each edge is a quad instead, widened into a band by
## folding_past_glow.gdshader, with a hot core down its middle falling off to
## the sides and blend_add so the nested frames accumulate. Set `glow` false to
## get the shipped one-pixel lines and the old material back, unchanged.
@export var glow: bool = true
## Half-width of the band in WORLD metres. Held constant across the nest by the
## shader, so the deep frames recede by getting smaller and dimmer rather than
## thinner.
@export var glow_width: float = 0.04
## One knob over the shader's core and halo together. The energies it scales are
## calibrated against ACES at `tonemap_exposure = 0.16`, which is what both
## commons/scenes/vr_staging.tscn and grid.tscn tonemap with â€” it is why the old
## `emission_energy_multiplier = 0.8` read as a grey scratch. Raise the room's
## exposure and this comes down.
@export var glow_energy: float = 1.0

const GLOW_SHADER: Shader = preload("res://commons/primitives/temporal/folding_past_glow.gdshader")

## STAGE-2 DNA â€” promoted 2026-08-03.
##
## `recession` â€” what shape the past takes behind the present.
##
## The file's own truth line is "the past does not vanish â€” it recedes, each
## moment nesting inside the one that follows". That nesting is a CLAIM about
## time, and until now it was the only claim this object could make: every one
## of its seven exports was a rate, a size or a colour, so a map could make the
## fold faster or bluer but never make it argue anything else. Each value here
## is a different figure of time, and each is legible in one still frame:
##
##   nested    â€” the shipped arrangement. Each frame `scale_ratio` of the one
##               before, marching inward: the present contains everything that
##               came before it. Containment.
##   collapsed â€” the whole nest driven to its innermost term. The past folded
##               completely into the present â€” one small dim frame where ten
##               were, with nothing behind it left to read. Compression.
##   abreast   â€” the moments laid side by side at equal size. Succession
##               WITHOUT containment: the timeline, which is precisely the
##               figure this artifact's nesting was built to refuse. No moment
##               sits inside another and none is smaller than another.
##   strata    â€” the moments stacked one above the next at equal size. The past
##               underneath rather than behind: deposition, read as sediment.
##
## Age still fades in every value (alpha 0.9 -> 0.3 by index), so the four stay
## comparable: only the arrangement changes, never what the fading means.
@export_enum("nested", "collapsed", "abreast", "strata") var recession: String = "nested"

## The same list as the @export_enum above. The enum is what the editor and the
## declaration gate read; this is what an incoming map token is checked against.
const RECESSIONS: Array[String] = ["nested", "collapsed", "abreast", "strata"]

## Neighbour offset for the two spread arrangements, as a fraction of one
## frame. A fifth of a frame keeps ten moments overlapping into a single legible
## band instead of a scattered row the camera has to zoom out to hold.
const SPREAD_STEP: float = 0.2

# MultiMesh for efficient rendering
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _frame_mesh: ArrayMesh

# Animation state
var _animation_time: float = 0.0
var _built: bool = false

func _ready():
	_create_frame_mesh()
	_setup_multimesh()
	_update_frames()
	_built = true
	# A no-op at the default: `nested` is the animated arrangement and _process
	# was already running. The three static arrangements have nothing to advance.
	set_process(recession == "nested")

## Contract: this runs AFTER _ready(), via call_deferred from
## GridInteractablesComponent. A config that does not name `recession`, or names
## the value already in force, must touch nothing â€” the 51 maps that place this
## artifact pass no config at all, and curation_station passes framing keys that
## have no business restarting the fold.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("recession"):
		return
	var want: String = _pick_axis(str(config_data["recession"]), RECESSIONS, recession)
	if want == recession:
		return
	recession = want
	if not _built:
		return   # _ready has not run yet; it will lay the frames out with this value.
	set_process(recession == "nested")
	_animation_time = 0.0
	# Arrangement is per-instance transform only â€” no mesh and no MultiMesh to
	# rebuild, so there is nothing here that can strand a grounded placement.
	_update_frames()

## Accept an axis value only if it names an arrangement we actually lay out.
func _pick_axis(raw: String, allowed: Array[String], fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback

func _process(delta: float) -> void:
	_animation_time += delta
	_update_frames()

func _create_frame_mesh() -> ArrayMesh:
	# One frame: the same four edges either way â€” a closed rectangle. The old
	# path lists them as separate segments (top, bottom, left, right); walking
	# the corners as a loop is the same four edges in a different order.
	var st := SurfaceTool.new()
	var hw: float = frame_width / 2.0
	var hh: float = frame_height / 2.0
	var corners: Array[Vector3] = [
		Vector3(-hw, hh, 0.0),
		Vector3(hw, hh, 0.0),
		Vector3(hw, -hh, 0.0),
		Vector3(-hw, -hh, 0.0),
	]

	if glow:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(4):
			_add_ring_quad(st, corners[i], corners[(i + 1) % 4])
	else:
		st.begin(Mesh.PRIMITIVE_LINES)
		for i in range(4):
			st.add_vertex(corners[i])
			st.add_vertex(corners[(i + 1) % 4])

	_frame_mesh = st.commit()
	return _frame_mesh


## One SIDE of the closed band, carrying no thickness of its own. Each vertex
## sits on a corner and gets that corner's MITRE â€” NORMAL along the bisector,
## UV.y the distance out along it where the band's edge falls, UV.x which side
## (+1 outer, -1 inner). The shader widens it from there, so glow_width stays
## tunable without rebuilding the mesh and the band keeps the same width in the
## room however far the instance transform shrinks the frame.
##
## THE MITRE IS THE POINT. Four separate quads, one per edge, is the obvious
## build and it was the first one; under blend_add the overlap at each corner
## adds to itself and photographs as a bright cross. A closed ring has no
## overlap, so a corner is exactly as bright as the edge running into it.
##
## Why UV.y and not a longer NORMAL: SurfaceTool compresses normals, which
## normalises them, so a vector's LENGTH cannot carry a number through. UV
## survives, and putting the mitre length there keeps this general â€” a non-right
## corner would just carry a different one.
func _add_ring_quad(st: SurfaceTool, a: Vector3, b: Vector3) -> void:
	var na: Vector3 = _mitre(a)
	var nb: Vector3 = _mitre(b)
	var pts: Array[Vector3] = [a, a, b, b]
	var nrm: Array[Vector3] = [na, na, nb, nb]
	var side: Array[float] = [1.0, -1.0, -1.0, 1.0]
	var tris: Array[int] = [0, 1, 2, 0, 2, 3]
	for k in tris:
		st.set_normal(nrm[k])
		# UV.y = sqrt(2): on a right-angled corner the bisector has to run that
		# much further out for the two edges to meet flush.
		st.set_uv(Vector2(side[k], sqrt(2.0)))
		st.add_vertex(pts[k])


## The outward bisector at a rectangle corner, from the sign of the corner
## itself. The rectangle is centred on the origin, so that is all it takes.
func _mitre(c: Vector3) -> Vector3:
	return Vector3(signf(c.x), signf(c.y), 0.0).normalized()

func _setup_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = _frame_mesh
	_multimesh.instance_count = frame_count

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "FrameMultiMesh"
	_multimesh_instance.multimesh = _multimesh

	_multimesh_instance.material_override = _build_material()
	add_child(_multimesh_instance)


## The glow shader, or the shipped material untouched when `glow` is false.
## Only two of the shader's uniforms are set from here; the rest keep their
## declared defaults, so the core/halo ratio lives in exactly one file. Writing
## it in both would be two copies of one number, which is how a ratio drifts the
## first time either half is tuned.
func _build_material() -> Material:
	if glow:
		var sm := ShaderMaterial.new()
		sm.shader = GLOW_SHADER
		sm.set_shader_parameter("line_width", glow_width)
		sm.set_shader_parameter("energy", glow_energy)
		return sm

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = frame_color
	material.emission_enabled = true
	material.emission = frame_color
	material.emission_energy_multiplier = 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	return material

func _update_frames() -> void:
	if not _multimesh:
		return

	# Calculate animation progress (0 to 1, loops)
	var cycle_progress = fmod(_animation_time, cycle_duration) / cycle_duration

	for i in range(frame_count):
		# Each frame has an offset in the cycle
		var frame_progress = fmod(cycle_progress + float(i) / float(frame_count), 1.0)
		if recession != "nested":
			# The static arrangements read age off the instance index, not off
			# the clock â€” otherwise the whole row would breathe in place, which
			# is a motion no still can photograph.
			frame_progress = float(i) / float(frame_count)

		# Scale: outer frames are larger, inner frames are smaller
		# frame_progress 0 = outermost (scale 1), frame_progress 1 = innermost (scale^frame_count)
		var scale = pow(scale_ratio, frame_progress * frame_count)

		# Z position: create depth (inner frames are further back)
		var z_offset = z_base_offset + (-frame_progress * 4.5)  # Base offset + depth animation
		var origin: Vector3 = Vector3(0.0, 0.0, float(z_offset))

		# `nested` deliberately has no case: it is the export default and the
		# arrangement computed above, character for character what shipped.
		var rank: float = float(i) - float(frame_count - 1) * 0.5
		match recession:
			"collapsed":
				scale = pow(scale_ratio, float(frame_count))
				origin = Vector3(0.0, 0.0, z_base_offset - 4.5)
			"abreast":
				scale = 1.0
				origin = Vector3(rank * frame_width * SPREAD_STEP, 0.0, z_base_offset)
			"strata":
				# Stacked UPWARD from the same base plane the nested arrangement
				# sits on, newest on top: the bed keeps its floor contact, so
				# auto-grounding lands this value exactly where `nested` lands,
				# and no layer is buried under the floor of the room.
				scale = 1.0
				origin = Vector3(0.0, float(frame_count - 1 - i) * frame_height * SPREAD_STEP, z_base_offset)

		# Build transform
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale, scale, 1.0))
		transform.origin = origin

		_multimesh.set_instance_transform(i, transform)

		# Color: fade inner frames slightly
		var alpha = lerp(0.9, 0.3, frame_progress)
		var color = Color(frame_color.r, frame_color.g, frame_color.b, alpha)
		_multimesh.set_instance_color(i, color)
