# AnimatedFoldingPast.gd - Frame-in-frame animation representing time collapsing into the present
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

# MultiMesh for efficient rendering
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _frame_mesh: ArrayMesh

# Animation state
var _animation_time: float = 0.0

func _ready():
	_create_frame_mesh()
	_setup_multimesh()
	_update_frames()

func _process(delta: float) -> void:
	_animation_time += delta
	_update_frames()

func _create_frame_mesh() -> ArrayMesh:
	# Create a single frame (rectangle outline) mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)

	var hw = frame_width / 2.0  # half width
	var hh = frame_height / 2.0  # half height

	# Top edge
	st.add_vertex(Vector3(-hw, hh, 0))
	st.add_vertex(Vector3(hw, hh, 0))

	# Bottom edge
	st.add_vertex(Vector3(-hw, -hh, 0))
	st.add_vertex(Vector3(hw, -hh, 0))

	# Left edge
	st.add_vertex(Vector3(-hw, -hh, 0))
	st.add_vertex(Vector3(-hw, hh, 0))

	# Right edge
	st.add_vertex(Vector3(hw, -hh, 0))
	st.add_vertex(Vector3(hw, hh, 0))

	_frame_mesh = st.commit()
	return _frame_mesh

func _setup_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = _frame_mesh
	_multimesh.instance_count = frame_count

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "FrameMultiMesh"
	_multimesh_instance.multimesh = _multimesh

	# Create material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = frame_color
	material.emission_enabled = true
	material.emission = frame_color
	material.emission_energy_multiplier = 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true

	_multimesh_instance.material_override = material
	add_child(_multimesh_instance)

func _update_frames() -> void:
	if not _multimesh:
		return

	# Calculate animation progress (0 to 1, loops)
	var cycle_progress = fmod(_animation_time, cycle_duration) / cycle_duration

	for i in range(frame_count):
		# Each frame has an offset in the cycle
		var frame_progress = fmod(cycle_progress + float(i) / float(frame_count), 1.0)

		# Scale: outer frames are larger, inner frames are smaller
		# frame_progress 0 = outermost (scale 1), frame_progress 1 = innermost (scale^frame_count)
		var scale = pow(scale_ratio, frame_progress * frame_count)

		# Z position: create depth (inner frames are further back)
		var z_offset = z_base_offset + (-frame_progress * 4.5)  # Base offset + depth animation

		# Build transform
		var transform = Transform3D()
		transform = transform.scaled(Vector3(scale, scale, 1.0))
		transform.origin = Vector3(0, 0, z_offset)

		_multimesh.set_instance_transform(i, transform)

		# Color: fade inner frames slightly
		var alpha = lerp(0.9, 0.3, frame_progress)
		var color = Color(frame_color.r, frame_color.g, frame_color.b, alpha)
		_multimesh.set_instance_color(i, color)
