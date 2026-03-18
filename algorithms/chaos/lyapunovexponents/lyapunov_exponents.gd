extends Node3D

# Trans/Queer Pride Fluid Lyapunov Visualization (VR)
# Wall-mounted panel with flowing patterns in trans and queer pride colors

# Shader parameters
@export_group("Visual Parameters")
@export var flow_intensity: float = 3.5
@export var swirl_scale: float = 6.0
@export var animation_speed: float = 0.3
@export var smoothness: float = 10.0
@export var pride_mode: int = 0  # 0: Trans, 1: Pride, 2: Nonbinary, 3: Fluid

# Dynamical system parameters
@export_group("System Parameters")
@export var parameter_a: float = 0.96
@export var parameter_b: float = 2.8
@export var parameter_c: float = 0.5
@export var parameter_d: float = 3.6

# Internal variables
var time: float = 0.0
var shader_material: ShaderMaterial
var mesh_instance: MeshInstance3D
var label: Label3D

const MODE_NAMES: Array[String] = ["Trans Pride", "Pride", "Nonbinary", "Fluid"]
const PANEL_WIDTH: float = 0.8
const PANEL_HEIGHT: float = 0.6


func _ready() -> void:
	_setup_panel()
	_setup_label()


func _setup_panel() -> void:
	shader_material = ShaderMaterial.new()
	shader_material.shader = _create_spatial_shader()

	var quad := QuadMesh.new()
	quad.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = quad
	mesh_instance.material_override = shader_material
	add_child(mesh_instance)

	_update_shader_parameters()


func _setup_label() -> void:
	label = Label3D.new()
	label.text = "Lyapunov Flow — %s" % MODE_NAMES[pride_mode]
	label.font_size = 32
	label.position = Vector3(0.0, -(PANEL_HEIGHT * 0.5 + 0.05), 0.0)
	label.modulate = Color(0.9, 0.9, 0.9, 1.0)
	label.outline_size = 4
	add_child(label)


func _process(delta: float) -> void:
	time += delta * animation_speed

	# Animate parameters for fluid movement
	var t := time * 0.15
	parameter_a = 0.96 + 0.1 * sin(t * 0.8)
	parameter_b = 2.8 + 0.4 * cos(t * 0.6)
	parameter_c = 0.5 + 0.15 * sin(t * 0.4)
	parameter_d = 3.6 + 0.3 * cos(t * 0.7)

	_update_shader_parameters()


func _update_shader_parameters() -> void:
	if not shader_material:
		return
	shader_material.set_shader_parameter("time", time)
	shader_material.set_shader_parameter("flow_intensity", flow_intensity)
	shader_material.set_shader_parameter("swirl_scale", swirl_scale)
	shader_material.set_shader_parameter("smoothness", smoothness)
	shader_material.set_shader_parameter("parameter_a", parameter_a)
	shader_material.set_shader_parameter("parameter_b", parameter_b)
	shader_material.set_shader_parameter("parameter_c", parameter_c)
	shader_material.set_shader_parameter("parameter_d", parameter_d)
	shader_material.set_shader_parameter("aspect_ratio", PANEL_WIDTH / PANEL_HEIGHT)
	shader_material.set_shader_parameter("pride_mode", pride_mode)


func set_pride_mode(mode: int) -> void:
	pride_mode = clampi(mode, 0, 3)
	_update_shader_parameters()
	if label:
		label.text = "Lyapunov Flow — %s" % MODE_NAMES[pride_mode]


func _create_spatial_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode unshaded;

	// Time and animation parameters
	uniform float time;
	uniform float flow_intensity;
	uniform float swirl_scale;
	uniform float smoothness;

	// System parameters for the dynamical system
	uniform float parameter_a;
	uniform float parameter_b;
	uniform float parameter_c;
	uniform float parameter_d;

	// Aspect ratio of the panel
	uniform float aspect_ratio;

	// Pride flag mode: 0=Trans, 1=Pride, 2=Nonbinary, 3=Fluid
	uniform int pride_mode;

	// Trans flag colors (light blue, pink, white)
	const vec3 TRANS_COLORS[5] = vec3[5](
		vec3(0.4, 0.8, 0.94),  // Light blue
		vec3(0.95, 0.7, 0.83), // Pink
		vec3(1.0, 1.0, 1.0),   // White
		vec3(0.95, 0.7, 0.83), // Pink
		vec3(0.4, 0.8, 0.94)   // Light blue
	);

	// Pride flag colors (red, orange, yellow, green, blue, purple)
	const vec3 PRIDE_COLORS[6] = vec3[6](
		vec3(0.93, 0.2, 0.2),   // Red
		vec3(0.96, 0.6, 0.0),   // Orange
		vec3(1.0, 0.95, 0.0),   // Yellow
		vec3(0.0, 0.8, 0.2),    // Green
		vec3(0.0, 0.4, 0.8),    // Blue
		vec3(0.6, 0.0, 0.6)     // Purple
	);

	// Nonbinary flag colors (yellow, white, purple, black)
	const vec3 NONBINARY_COLORS[4] = vec3[4](
		vec3(1.0, 0.95, 0.1),   // Yellow
		vec3(1.0, 1.0, 1.0),    // White
		vec3(0.7, 0.3, 0.7),    // Purple
		vec3(0.1, 0.1, 0.1)     // Black
	);

	// Gender fluid flag colors (pink, purple, blue, black, white)
	const vec3 FLUID_COLORS[5] = vec3[5](
		vec3(0.95, 0.4, 0.7),   // Pink
		vec3(0.7, 0.3, 0.7),    // Purple
		vec3(0.3, 0.3, 0.8),    // Blue
		vec3(0.1, 0.1, 0.1),    // Black
		vec3(1.0, 1.0, 1.0)     // White
	);

	// Get color from pride flag based on position
	vec3 get_pride_color(float pos, int mode) {
		// Ensure pos is between 0 and 1
		pos = fmod(pos, 1.0);

		if (mode == 0) { // Trans flag
			float idx = pos * 5.0;
			int i = int(floor(idx));
			int j = int(ceil(idx)) % 5;
			float t = fmod(idx, 1.0);
			return mix(TRANS_COLORS[i], TRANS_COLORS[j], t);
		}
		else if (mode == 1) { // Pride flag
			float idx = pos * 6.0;
			int i = int(floor(idx));
			int j = int(ceil(idx)) % 6;
			float t = fmod(idx, 1.0);
			return mix(PRIDE_COLORS[i], PRIDE_COLORS[j], t);
		}
		else if (mode == 2) { // Nonbinary flag
			float idx = pos * 4.0;
			int i = int(floor(idx));
			int j = int(ceil(idx)) % 4;
			float t = fmod(idx, 1.0);
			return mix(NONBINARY_COLORS[i], NONBINARY_COLORS[j], t);
		}
		else { // Gender fluid flag
			float idx = pos * 5.0;
			int i = int(floor(idx));
			int j = int(ceil(idx)) % 5;
			float t = fmod(idx, 1.0);
			return mix(FLUID_COLORS[i], FLUID_COLORS[j], t);
		}
	}

	// Smooth wave function (no grain)
	vec2 smooth_wave(vec2 uv) {
		float x = sin(uv.x * smoothness + time * 0.4) *
				 cos(uv.y * smoothness * 0.8 + time * 0.3) * 0.5;

		float y = cos(uv.x * smoothness * 0.9 + time * 0.5) *
				 sin(uv.y * smoothness * 1.2 + time * 0.4) * 0.5;

		return vec2(x, y);
	}

	// Flow field calculation based on queer-inspired dynamical system
	vec2 calculate_flow(vec2 uv) {
		// Add flowing movement over time
		uv += vec2(sin(time * 0.1), cos(time * 0.12)) * 0.1;

		// System parameters
		float a = parameter_a;
		float b = parameter_b;
		float c = parameter_c;
		float d = parameter_d;

		// Fluid-like flow direction with curvature and swirls
		vec2 dir = vec2(
			sin(a * uv.y * swirl_scale + time * 0.3) + cos(b * uv.x * swirl_scale),
			sin(c * uv.x * swirl_scale + time * 0.2) + cos(d * uv.y * swirl_scale - time * 0.25)
		);

		// Add subtle spiraling motion
		float spiral = atan(uv.y - 0.5, uv.x - 0.5);
		dir += vec2(cos(spiral + time * 0.1), sin(spiral + time * 0.1)) * 0.2;

		// Normalize and adjust strength
		return normalize(dir) * flow_intensity * 0.01;
	}

	// Creates fluid-like motion with pride colors
	vec3 pride_fluid(vec2 uv) {
		vec3 col = vec3(0.0);

		// Sample multiple layers for more detailed flow
		for (int i = 0; i < 4; i++) {
			// Get flow direction
			vec2 flow = calculate_flow(uv);

			// Create wave pattern
			vec2 wave = smooth_wave(uv * (1.0 + float(i) * 0.3));

			// Create dynamic value for color selection
			float value = length(wave) +
					  sin(uv.x * 12.0 + time + float(i)) * 0.05 +
					  cos(uv.y * 15.0 + time * 0.9 + float(i)) * 0.05;

			// Position in the pride flag
			float flag_pos;

			// Create different patterns based on layer
			if (i == 0) {
				flag_pos = uv.y + value * 0.3 + time * 0.05;
			} else if (i == 1) {
				flag_pos = (uv.x + uv.y) * 0.5 + value * 0.4 - time * 0.04;
			} else if (i == 2) {
				float dist = length(uv - vec2(0.5));
				flag_pos = dist * 2.0 + value * 0.3 + time * 0.06;
			} else {
				float angle = atan(uv.y - 0.5, uv.x - 0.5);
				flag_pos = angle / (3.14 * 2.0) + value * 0.5 - time * 0.03;
			}

			// Get color from the appropriate pride flag
			vec3 layer_color = get_pride_color(flag_pos, pride_mode);

			// Add shine/glow effect
			layer_color += pow(value, 3.0) * 0.3;

			// Accumulate color with layer weight
			col += layer_color * (1.0 - float(i) * 0.2);

			// Advect UV by flow for next layer
			uv += flow;
		}

		// Normalize the accumulated color
		col /= 2.5;

		// Apply gentle vignette
		float vignette = 1.0 - length(uv - vec2(0.5)) * 0.3;
		col *= vignette;

		// Add subtle sparkling effect
		float sparkle = sin(uv.x * 50.0 + time * 2.0) * sin(uv.y * 50.0 + time * 1.5);
		sparkle = pow(max(0.0, sparkle), 20.0) * 0.5;
		col += vec3(sparkle);

		return col;
	}

	void fragment() {
		// Convert UV to aspect-corrected coordinates
		vec2 uv = UV - 0.5;
		uv.x *= aspect_ratio;
		uv += 0.5;

		// Get color from pride fluid simulation
		ALBEDO = pride_fluid(uv);
	}
	"""
	return shader


func apply_grid_config(config: Dictionary) -> void:
	pass


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
