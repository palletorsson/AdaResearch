extends MeshInstance3D
## An opt-in image on the existing floor. It owns no collision or player movement.
const PATTERN_SHADER = preload("res://commons/artifacts/regularity/super_triangle.gdshader")
const FAMILIES := ["DIAGONALS", "CHEVRONS", "DIAMONDS", "TURNING WAVES", "LARGE DIAMONDS", "SUPER DIAMONDS"]
var receiver: Node3D
var _layout: Array = []
var _pulse_texture: ImageTexture
var _pulse_data := PackedByteArray()

func _ready() -> void:
	name = "SuperTriangleSurface"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = PlaneMesh.new()
	var material := ShaderMaterial.new()
	material.shader = PATTERN_SHADER
	material_override = material

func update_pattern(clock: float, ink: Color, paper: Color, columns: Array) -> void:
	if not is_instance_valid(receiver): return
	var layout := [receiver.grid_width, receiver.grid_depth, receiver.tile_size, receiver.floor_y_offset, receiver.floor_height, receiver.tile_gap]
	if layout != _layout:
		_layout = layout
		(mesh as PlaneMesh).size = Vector2(receiver.grid_width, receiver.grid_depth) * receiver.tile_size
		position.y = receiver.floor_y_offset + receiver.floor_height + 0.003
		material_override.set_shader_parameter("tile_count", Vector2(receiver.grid_width, receiver.grid_depth))
		material_override.set_shader_parameter("tile_size", receiver.tile_size)
		material_override.set_shader_parameter("gap_fraction", receiver.tile_gap / receiver.tile_size * 0.5)
		_pulse_data.resize(receiver.grid_width)
		_pulse_data.fill(0)
		_pulse_texture = ImageTexture.create_from_image(Image.create_from_data(receiver.grid_width, 1, false, Image.FORMAT_R8, _pulse_data))
		material_override.set_shader_parameter("column_pulses", _pulse_texture)
	var pulses := PackedByteArray()
	pulses.resize(receiver.grid_width)
	pulses.fill(0)
	for column in columns:
		if column >= 0 and column < pulses.size(): pulses[column] = 255
	if pulses != _pulse_data:
		_pulse_data = pulses
		_pulse_texture.update(Image.create_from_data(receiver.grid_width, 1, false, Image.FORMAT_R8, _pulse_data))
	material_override.set_shader_parameter("motion", fposmod(clock, 24.0))
	material_override.set_shader_parameter("ink", ink)
	material_override.set_shader_parameter("paper", paper)
