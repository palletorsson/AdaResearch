# sdf_blend_demo.gd
# Autonomous demo that proves the SDF transition bus works end-to-end.
# Attach to a Node3D with its own camera/light/environment (or open the
# accompanying .tscn). The CA ↔ Growth blend sweeps t ∈ [0,1] once every
# few seconds so you can watch the transition happen.

extends Node3D

const CASurfaceSDFClass = preload("res://commons/morphology/sdf/ca_surface_sdf.gd")
const GrowthSDFClass = preload("res://commons/morphology/sdf/growth_sdf.gd")
const BlendedSDFClass = preload("res://commons/morphology/sdf/blended_sdf.gd")
const SDFVoxelPreviewClass = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")

var _ca
var _growth
var _blend
var _preview
var _time: float = 0.0
var _last_rebuild: float = -INF


func _ready() -> void:
	# CA form — seq 9 principle
	_ca = CASurfaceSDFClass.new()
	_ca.grid_size = Vector2i(20, 20)
	_ca.iterations = 4
	_ca.seed_density = 0.35
	_ca.cell_size = 0.45
	_ca.cell_height = 0.35
	_ca.origin = Vector3.ZERO
	_ca.seed = 42
	_ca.rebuild()

	# L-system growth — seq 11 principle
	_growth = GrowthSDFClass.new()
	_growth.axiom = "F"
	_growth.rules = {"F": "F[+F]F[-F]F"}
	_growth.iterations = 3
	_growth.step_length = 0.5
	_growth.angle_degrees = 22.5
	_growth.branch_radius = 0.22  # Beefier branches so they survive voxel sampling
	_growth.origin = Vector3.ZERO
	_growth.rebuild()

	# Blended transition — weighted mode keeps both forms visible, fading
	# in/out by t. Plain linear lerp of two non-overlapping SDFs collapses
	# to nothing in the middle, which is not the transition we want.
	_blend = BlendedSDFClass.new()
	_blend.a = _ca
	_blend.b = _growth
	_blend.t = 0.0
	_blend.mode = "weighted"
	_blend.smoothness = 0.4
	_blend.weighted_inflation = 0.6

	_preview = SDFVoxelPreviewClass.new()
	_preview.sdf = _blend
	_preview.resolution = Vector3i(36, 24, 36)
	_preview.surface_threshold = 0.15
	_preview.auto_rebuild_on_ready = false
	add_child(_preview)
	_preview.rebuild()
	print("[SDF demo] Initial render: voxels=%d" % _preview._mmi.multimesh.instance_count if _preview._mmi else "[SDF demo] No preview mesh built")


func _process(delta: float) -> void:
	_time += delta
	var phase: float = 0.5 + 0.5 * sin(_time * 0.6)  # ping-pong 0 ↔ 1 slowly
	_blend.t = phase
	# Rebuild preview at ~3 Hz — field resample is cheap at this resolution
	if _time - _last_rebuild > 0.33:
		_last_rebuild = _time
		_preview.rebuild()
