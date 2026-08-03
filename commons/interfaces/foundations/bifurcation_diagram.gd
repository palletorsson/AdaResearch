# bifurcation_diagram.gd
# Interactive 3D bifurcation diagram from the logistic map
# x(n+1) = r * x(n) * (1 - x(n))
#
# As r increases: stable → period doubling → chaos → windows of order
# This IS the edge of chaos visualized
# The λ parameter in QFEP maps directly to r here
#
# Walk through the phase transition from order to chaos

extends Node3D

class_name BifurcationDiagram

# @identity
# essence: x(n+1) = r·x(n)·(1 - x(n)); period doubling cascade → chaos at r ≈ 3.57
# desire: walk through the phase transition from order to chaos as r sweeps right
# critical_parameter: r (mapped to current_r) — the ONE number that controls the entire regime
# triggers: r crossing 3.0 → bifurcation; r crossing 3.57 → chaos onset; r ≈ 3.83 → window of order inside chaos
# emerges: Feigenbaum universality — the same constants appear in ALL period-doubling systems
# needs: VR slider for r [missing] — highlight plane tracks current_r but no physical controller
# relationships: unlocks lambda_slider (r IS the QFEP lambda); contrasts florensky_sphere (holding contradiction vs cascading into it)
# truth: the edge of chaos is not a metaphor — it is a precise mathematical boundary where computation is maximized

signal r_changed(r_value: float)
signal regime_changed(regime: String)

## Diagram parameters
@export var width: float = 4.0       # X axis (r parameter)
@export var height: float = 2.0      # Y axis (x value)
@export var depth: float = 0.5       # Z thickness

## R parameter range
@export var r_min: float = 2.5
@export var r_max: float = 4.0

## WHICH CLAIM about the map is on the wall. Each value crops the r axis onto one
## qualitative behaviour class; "all" leaves r_min/r_max exactly as exported.
@export_enum("all", "stable", "cascade", "chaos", "period3") var regime: String = "all"
## WHAT COUNTS AS THE PICTURE. The diagram normally throws the first iterations away and
## draws only where the orbit ends up; transient draws the whole orbit, approach draws
## only the discarded run-in.
@export_enum("attractor", "transient", "approach") var trace: String = "attractor"

## Resolution
@export var r_steps: int = 200       # Points along r axis
@export var iterations: int = 100    # Iterations per r value
@export var skip_transient: int = 50 # Skip initial transient

## Point visualization
@export var point_size: float = 0.015
@export var order_color: Color = Color(0.2, 0.5, 1.0)    # Blue for order
@export var chaos_color: Color = Color(1.0, 0.3, 0.2)    # Red for chaos
@export var edge_color: Color = Color(0.2, 1.0, 0.5)     # Green for edge

## Current highlighted r value
@export var current_r: float = 3.0:
	set(v):
		current_r = clamp(v, r_min, r_max)
		_update_highlight()
		emit_signal("r_changed", current_r)

# Internal
var _points_multimesh: MultiMeshInstance3D
var _highlight_plane: MeshInstance3D
var _r_label: Label3D
var _regime_label: Label3D
var _r_min_label: Label3D
var _r_max_label: Label3D
var _edge_label: Label3D
var _axis_labels: Array[Label3D] = []
var _total_points: int = 0
var _built: bool = false
# The z scatter was an unseeded randf_range, so no two runs of the same diagram were the
# same cloud. Same range, same look, now reproducible — a variant sweep can only compare
# frames that are comparable.
var _rng := RandomNumberGenerator.new()

# Key r values for regime transitions
const R_STABLE = 3.0
const R_PERIOD2 = 3.449
const R_PERIOD4 = 3.544
const R_CHAOS_START = 3.57
const R_WINDOW_START = 3.83
const R_WINDOW_END = 3.86

const REGIMES := ["all", "stable", "cascade", "chaos", "period3"]
const TRACES := ["attractor", "transient", "approach"]
# The r window each regime crops to. "all" is absent on purpose: it means "do not touch
# r_min/r_max", which is how the four maps that place this artifact keep their exact framing.
const REGIME_WINDOWS := {
	"stable": [2.5, R_STABLE],
	"cascade": [R_STABLE, R_CHAOS_START],
	"chaos": [R_CHAOS_START, 4.0],
	"period3": [3.82, 3.87],
}

func _ready() -> void:
	_apply_regime()
	_generate_bifurcation_data()
	_create_axes()
	_create_highlight()
	_create_labels()
	_built = true
	print("BifurcationDiagram: Ready — walk through the edge of chaos")

func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("regime"):
		var want_regime: String = str(config_data["regime"])
		if REGIMES.has(want_regime) and want_regime != regime:
			regime = want_regime
			changed = true
	if config_data.has("trace"):
		var want_trace: String = str(config_data["trace"])
		if TRACES.has(want_trace) and want_trace != trace:
			trace = want_trace
			changed = true
	if config_data.has("current_r"):
		set_r_value(float(config_data["current_r"]))
	# Nothing to do if nothing moved, and nothing to rebuild before _ready has built
	# once — the new values are simply what _ready will build with.
	if not changed or not _built:
		return
	_apply_regime()
	_rebuild_points()
	_refresh_labels()
	_update_highlight()

func _apply_regime() -> void:
	if regime == "all" or not REGIME_WINDOWS.has(regime):
		return
	var span_r: Array = REGIME_WINDOWS[regime]
	r_min = float(span_r[0])
	r_max = float(span_r[1])
	current_r = clamp(current_r, r_min, r_max)

func _rebuild_points() -> void:
	var old: MultiMeshInstance3D = _points_multimesh
	if old != null and is_instance_valid(old):
		remove_child(old)
		old.queue_free()
	_points_multimesh = null
	_generate_bifurcation_data()

func _keeps_iteration(j: int) -> bool:
	match trace:
		"transient":
			return true
		"approach":
			return j < skip_transient
		_:
			return j >= skip_transient

func _generate_bifurcation_data() -> void:
	# Collect all points first
	var all_points: Array[Vector3] = []
	var all_colors: Array[Color] = []
	_rng.seed = 20260803

	for i in range(r_steps):
		var r = r_min + (float(i) / float(r_steps - 1)) * (r_max - r_min)
		var x = 0.5  # Initial condition
		
		# Run iterations, skip transient
		for j in range(iterations):
			x = r * x * (1.0 - x)
			
			if _keeps_iteration(j):
				# Map to 3D position
				var pos_x = (r - r_min) / (r_max - r_min) * width - width / 2
				var pos_y = x * height - height / 2
				var pos_z = _rng.randf_range(-depth/2, depth/2) * 0.1  # Slight z variation
				
				all_points.append(Vector3(pos_x, pos_y, pos_z))
				all_colors.append(_get_color_for_r(r))
	
	_total_points = all_points.size()
	
	# Create MultiMesh
	_points_multimesh = MultiMeshInstance3D.new()
	_points_multimesh.name = "BifurcationPoints"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = _total_points
	
	var sphere = SphereMesh.new()
	sphere.radius = point_size
	sphere.height = point_size * 2
	sphere.radial_segments = 8
	sphere.rings = 4
	mm.mesh = sphere
	
	# Set transforms and colors
	for i in range(_total_points):
		mm.set_instance_transform(i, Transform3D(Basis(), all_points[i]))
		mm.set_instance_color(i, all_colors[i])
	
	_points_multimesh.multimesh = mm
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	_points_multimesh.material_override = mat
	
	add_child(_points_multimesh)
	print("BifurcationDiagram: Generated %d points" % _total_points)

func _get_color_for_r(r: float) -> Color:
	if r < R_STABLE:
		return order_color
	elif r < R_CHAOS_START:
		# Period doubling region - transition
		var t = (r - R_STABLE) / (R_CHAOS_START - R_STABLE)
		return order_color.lerp(edge_color, t)
	elif r >= R_WINDOW_START and r <= R_WINDOW_END:
		# Window of order within chaos
		return edge_color
	else:
		# Chaos. maxf guards a cropped window whose r_max sits on the chaos onset —
		# without it the divisor is zero and every point in that frame is a NaN colour.
		var t = (r - R_CHAOS_START) / maxf(r_max - R_CHAOS_START, 0.0001)
		return edge_color.lerp(chaos_color, t)

func _create_axes() -> void:
	# X axis (r parameter)
	var x_axis = MeshInstance3D.new()
	var x_mesh = BoxMesh.new()
	x_mesh.size = Vector3(width + 0.2, 0.01, 0.01)
	x_axis.mesh = x_mesh
	x_axis.position.y = -height / 2 - 0.05
	
	var axis_mat = StandardMaterial3D.new()
	axis_mat.albedo_color = Color(0.5, 0.5, 0.5)
	x_axis.material_override = axis_mat
	add_child(x_axis)
	
	# Y axis (x value)
	var y_axis = MeshInstance3D.new()
	var y_mesh = BoxMesh.new()
	y_mesh.size = Vector3(0.01, height + 0.2, 0.01)
	y_axis.mesh = y_mesh
	y_axis.position.x = -width / 2 - 0.05
	y_axis.material_override = axis_mat
	add_child(y_axis)

func _create_highlight() -> void:
	# Vertical plane showing current r value
	_highlight_plane = MeshInstance3D.new()
	var plane_mesh = BoxMesh.new()
	plane_mesh.size = Vector3(0.02, height + 0.4, depth + 0.2)
	_highlight_plane.mesh = plane_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.3
	_highlight_plane.material_override = mat
	
	add_child(_highlight_plane)
	_update_highlight()

func _create_labels() -> void:
	# R value label
	_r_label = Label3D.new()
	_r_label.font_size = 24
	_r_label.position.y = height / 2 + 0.2
	_r_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_r_label.modulate = Color.WHITE
	_r_label.outline_size = 4
	_r_label.outline_modulate = Color.BLACK
	add_child(_r_label)
	
	# Regime label
	_regime_label = Label3D.new()
	_regime_label.font_size = 20
	_regime_label.position.y = height / 2 + 0.35
	_regime_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_regime_label.modulate = Color(0.8, 0.8, 0.8)
	_regime_label.outline_size = 3
	_regime_label.outline_modulate = Color.BLACK
	add_child(_regime_label)
	
	# Axis labels
	_r_min_label = Label3D.new()
	_r_min_label.text = _r_axis_text(r_min)
	_r_min_label.font_size = 16
	_r_min_label.position = Vector3(-width/2, -height/2 - 0.15, 0)
	_r_min_label.modulate = Color(0.7, 0.7, 0.7)
	add_child(_r_min_label)

	_r_max_label = Label3D.new()
	_r_max_label.text = _r_axis_text(r_max)
	_r_max_label.font_size = 16
	_r_max_label.position = Vector3(width/2, -height/2 - 0.15, 0)
	_r_max_label.modulate = Color(0.7, 0.7, 0.7)
	add_child(_r_max_label)
	
	# Title
	var title = Label3D.new()
	title.text = "Bifurcation Diagram\nLogistic Map: x → rx(1-x)"
	title.font_size = 28
	title.position = Vector3(0, height/2 + 0.55, 0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color.WHITE
	title.outline_size = 5
	title.outline_modulate = Color.BLACK
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	
	# Edge of chaos marker. Held as a member now so a cropped r window can move it — or
	# hide it, when the chaos onset is not inside the window on the wall at all.
	_edge_label = Label3D.new()
	_edge_label.text = "← EDGE OF CHAOS"
	_edge_label.font_size = 14
	_edge_label.modulate = edge_color
	_edge_label.outline_size = 3
	_edge_label.outline_modulate = Color.BLACK
	add_child(_edge_label)
	_place_edge_label()

func _r_axis_text(value: float) -> String:
	# One decimal is what the diagram has always printed, and on the default 2.5..4.0 span
	# that is what this still returns. A cropped window can be narrower than a tenth of r,
	# where "r=3.8" at both ends of the period-3 window would read as a bug.
	if (r_max - r_min) < 0.5:
		return "r=%.2f" % value
	return "r=%.1f" % value

func _place_edge_label() -> void:
	if _edge_label == null:
		return
	# The marker is a claim about a specific r. If that r is off the cropped axis the
	# honest thing is to withhold it rather than park it past the end of the plot.
	var inside: bool = R_CHAOS_START >= r_min and R_CHAOS_START <= r_max
	_edge_label.visible = inside
	if not inside:
		return
	var frac: float = (R_CHAOS_START - r_min) / maxf(r_max - r_min, 0.0001)
	_edge_label.position = Vector3(
		frac * width - width/2 + 0.3,
		-height/2 - 0.25,
		0
	)

func _refresh_labels() -> void:
	# Only ever reached from apply_grid_config after the r window actually moved; on the
	# shipped default nothing calls this and the labels stay exactly as _create_labels
	# wrote them.
	if _r_min_label != null:
		_r_min_label.text = _r_axis_text(r_min)
	if _r_max_label != null:
		_r_max_label.text = _r_axis_text(r_max)
	_place_edge_label()

func _update_highlight() -> void:
	if not _highlight_plane:
		return
	
	# Position highlight at current r
	var x_pos = (current_r - r_min) / (r_max - r_min) * width - width / 2
	_highlight_plane.position.x = x_pos
	
	# Update labels
	if _r_label:
		_r_label.text = "r = %.3f (λ ≈ %.2f)" % [current_r, (current_r - r_min) / (r_max - r_min)]
		_r_label.position.x = x_pos
	
	if _regime_label:
		_regime_label.text = _get_regime_name(current_r)
		_regime_label.position.x = x_pos
		_regime_label.modulate = _get_color_for_r(current_r)
		emit_signal("regime_changed", _regime_label.text)

func _get_regime_name(r: float) -> String:
	if r < R_STABLE:
		return "STABLE (single attractor)"
	elif r < R_PERIOD2:
		return "PERIOD-2 (bifurcation)"
	elif r < R_PERIOD4:
		return "PERIOD-4"
	elif r < R_CHAOS_START:
		return "PERIOD-DOUBLING CASCADE"
	elif r >= R_WINDOW_START and r <= R_WINDOW_END:
		return "WINDOW OF ORDER (period-3)"
	else:
		return "CHAOS"

func _process(_delta: float) -> void:
	# Could add interactive r adjustment here
	pass

# Public API
func set_r_value(r: float) -> void:
	current_r = r

func get_regime() -> String:
	return _get_regime_name(current_r)

func animate_r(from_r: float, to_r: float, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(self, "current_r", to_r, duration).from(from_r)
