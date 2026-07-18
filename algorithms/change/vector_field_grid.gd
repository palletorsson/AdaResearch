# Vector Field Grid — a 2D/3D field of arrows
#
# A regular grid of small arrows over a plane. At each grid point, the arrow points along
# the field vector v(x, y) = (∂Ψ/∂y, -∂Ψ/∂x) for a stream function Ψ(x, y) = sin(x)cos(y).
# The result is a swirling field — circulation lines around saddle points. The arrows
# update gently over time as Ψ scrolls.
#
# Sets up the flow-along intuition for the next sequence (forces) and pairs with
# particle_flow_swarm where particles ride this same field.
#
# @qfep_term: F as a vector function over a domain.
#
# @identity
# essence: a regular grid of arrows over a plane, each pointing along a stream-function field v=(∂Ψ/∂y,−∂Ψ/∂x), the whole field slowly scrolling
# desire: to present a field — a vector assigned to every point of a domain — as a single seeable object
# critical_parameter: spacing — the grid density; too sparse and the circulation reads as noise, too dense and the arrows overlap into a smear
# triggers: _ready() builds the arrow grid; _process advances Ψ's phase and re-orients and re-colours each arrow by the local field vector
# emerges: circulation lines around saddle points — the flow-along intuition the forces sequence will inhabit
# needs: arrow grid [present]; stream-function field Ψ [present]; apply_grid_config for cols/rows/spacing [present]; class_name VectorFieldGrid [present]; @identity [present, 2026-07-12]
# relationships: paired with particle_flow_swarm (particles ride this same field); precursor to the forces sequence; sibling in the change sequence
# truth: a field is not one arrow but a rule that hands you an arrow wherever you stand — the world laid out before anything moves through it.

extends Node3D
class_name VectorFieldGrid

@export_category("Field Settings")
@export var arrow_color: Color = Color(0.85, 0.85, 1.0, 1.0)
@export var arrow_color_hot: Color = Color(1.0, 0.55, 0.25, 1.0)
@export var grid_cols: int = 12
@export var grid_rows: int = 8
@export var spacing: float = 0.22
@export var arrow_base_scale: float = 0.18
@export var phase_speed: float = 0.4

var _arrows: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build_grid()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("grid_cols"):
		grid_cols = int(config_data["grid_cols"])
	if config_data.has("grid_rows"):
		grid_rows = int(config_data["grid_rows"])
	if config_data.has("spacing"):
		spacing = float(config_data["spacing"])


func _process(delta: float) -> void:
	_t += delta * phase_speed
	_update_arrows()


func _build_grid() -> void:
	for i in grid_cols:
		for j in grid_rows:
			var arrow := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.025, 0.025, arrow_base_scale)
			arrow.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = arrow_color
			mat.emission_enabled = true
			mat.emission = arrow_color
			mat.emission_energy_multiplier = 1.0
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			arrow.material_override = mat
			var x: float = (float(i) - float(grid_cols - 1) * 0.5) * spacing
			var z: float = (float(j) - float(grid_rows - 1) * 0.5) * spacing
			arrow.position = Vector3(x, 0.05, z)
			add_child(arrow)
			_arrows.append({"node": arrow, "x": x, "z": z, "mat": mat})


func _update_arrows() -> void:
	for entry in _arrows:
		var arrow: MeshInstance3D = entry["node"]
		var x: float = entry["x"]
		var z: float = entry["z"]
		# v = (∂Ψ/∂z, -∂Ψ/∂x) where Ψ = sin(x*k + t)cos(z*k + t)
		var k: float = 2.5
		var phase := _t
		var psi_dz: float = -sin(x * k + phase) * sin(z * k + phase) * k
		var psi_dx: float = cos(x * k + phase) * cos(z * k + phase) * k
		var vx: float = psi_dz
		var vz: float = -psi_dx
		var v := Vector3(vx, 0.0, vz)
		var mag: float = v.length()
		if mag < 0.001:
			continue
		var dir := v.normalized()
		arrow.transform.basis = Basis().looking_at(dir, Vector3.UP)
		arrow.scale.z = clamp(mag * 0.35, 0.4, 2.0)
		# Tint with magnitude.
		var mat: StandardMaterial3D = entry["mat"]
		var t_mag: float = clamp(mag / 3.5, 0.0, 1.0)
		var col := arrow_color.lerp(arrow_color_hot, t_mag)
		mat.albedo_color = col
		mat.emission = col
		mat.emission_energy_multiplier = 1.0 + t_mag * 1.5
