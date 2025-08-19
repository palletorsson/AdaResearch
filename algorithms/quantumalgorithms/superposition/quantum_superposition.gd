extends Node3D

# Quantum Superposition Visualization
# Demonstrates quantum states, wave function collapse, and measurement effects

class_name QuantumSuperposition

# Quantum state parameters
@export var num_qubits: int = 3
@export var visualization_radius: float = 3.0
@export var wave_function_resolution: int = 50
@export var collapse_animation_speed: float = 2.0
@export var measurement_probability_threshold: float = 0.01

# Visualization components
var qubit_spheres: Array[MeshInstance3D] = []
var probability_clouds: Array[MeshInstance3D] = []
var entanglement_connections: Array[MeshInstance3D] = []
var wave_function_mesh: MeshInstance3D
var measurement_indicator: MeshInstance3D

# Quantum state representation
var quantum_state: Array[Vector2] = []  # Complex amplitudes (real, imaginary)
var is_collapsed: bool = false
var collapsed_state: int = -1
var time: float = 0.0

# UI and interaction
var ui_panel: Control
var measurement_button: Button
var reset_button: Button
var qubit_controls: Array[HSlider] = []

func _ready():
    randomize()
    initialize_quantum_state()
    setup_visualization_components()
    setup_ui()
    create_initial_superposition()

func initialize_quantum_state():
    """Initialize quantum state in equal superposition"""
    var num_states = pow(2, num_qubits)
    quantum_state.clear()
    
    # Create equal superposition: |000⟩ + |001⟩ + |010⟩ + ... + |111⟩
    var amplitude = 1.0 / sqrt(num_states)
    for i in range(num_states):
        quantum_state.append(Vector2(amplitude, 0.0))  # Real amplitude, no imaginary part initially

func setup_visualization_components():
    """Create 3D visualization elements"""
    
    # Create materials
    var qubit_material = StandardMaterial3D.new()
    qubit_material.albedo_color = Color.CYAN
    qubit_material.emission_enabled = true
    qubit_material.emission = Color.CYAN * 0.3
    qubit_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    
    var probability_material = StandardMaterial3D.new()
    probability_material.albedo_color = Color(1.0, 0.5, 1.0, 0.3)  # Translucent magenta
    probability_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    probability_material.emission_enabled = true
    probability_material.emission = Color(1.0, 0.5, 1.0) * 0.2
    
    var entanglement_material = StandardMaterial3D.new()
    entanglement_material.albedo_color = Color.YELLOW
    entanglement_material.emission_enabled = true
    entanglement_material.emission = Color.YELLOW * 0.4
    
    # Create qubit representations
    for i in range(num_qubits):
        var qubit_sphere = MeshInstance3D.new()
        var sphere_mesh = SphereMesh.new()
        sphere_mesh.radius = 0.2
        sphere_mesh.height = 0.4
        qubit_sphere.mesh = sphere_mesh
        qubit_sphere.material_override = qubit_material
        
        # Position qubits in a circle
        var angle = 2 * PI * i / num_qubits
        qubit_sphere.position = Vector3(
            cos(angle) * visualization_radius,
            0,
            sin(angle) * visualization_radius
        )
        
        add_child(qubit_sphere)
        qubit_spheres.append(qubit_sphere)
        
        # Create probability cloud for each qubit
        var cloud = MeshInstance3D.new()
        var cloud_mesh = SphereMesh.new()
        cloud_mesh.radius = 0.8
        cloud_mesh.height = 1.6
        cloud.mesh = cloud_mesh
        cloud.material_override = probability_material
        cloud.position = qubit_sphere.position
        add_child(cloud)
        probability_clouds.append(cloud)
    
    # Create wave function visualization mesh
    wave_function_mesh = MeshInstance3D.new()
    var wave_material = StandardMaterial3D.new()
    wave_material.albedo_color = Color(0.0, 1.0, 0.5, 0.6)
    wave_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    wave_material.vertex_color_use_as_albedo = true
    wave_function_mesh.material_override = wave_material
    add_child(wave_function_mesh)
    
    # Create measurement indicator
    measurement_indicator = MeshInstance3D.new()
    var indicator_mesh = CylinderMesh.new()
    indicator_mesh.top_radius = 0.1
    indicator_mesh.bottom_radius = 0.1
    indicator_mesh.height = 5.0
    measurement_indicator.mesh = indicator_mesh
    measurement_indicator.visible = false
    var indicator_material = StandardMaterial3D.new()
    indicator_material.albedo_color = Color.RED
    indicator_material.emission_enabled = true
    indicator_material.emission = Color.RED * 0.5
    measurement_indicator.material_override = indicator_material
    add_child(measurement_indicator)

func setup_ui():
    """Create user interface controls"""
    ui_panel = Control.new()
    ui_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    ui_panel.position = Vector2(20, -200)
    ui_panel.size = Vector2(300, 180)
    
    var panel_background = Panel.new()
    panel_background.set_anchors_preset(Control.PRESET_FULL_RECT)
    ui_panel.add_child(panel_background)
    
    var vbox = VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 10)
    ui_panel.add_child(vbox)
    
    # Title label
    var title = Label.new()
    title.text = "Quantum Superposition Visualization"
    title.add_theme_font_size_override("font_size", 16)
    vbox.add_child(title)
    
    # Measurement button
    measurement_button = Button.new()
    measurement_button.text = "Perform Measurement"
    measurement_button.pressed.connect(_on_measurement_pressed)
    vbox.add_child(measurement_button)
    
    # Reset button
    reset_button = Button.new()
    reset_button.text = "Reset to Superposition"
    reset_button.pressed.connect(_on_reset_pressed)
    vbox.add_child(reset_button)
    
    # Qubit phase controls
    for i in range(num_qubits):
        var hbox = HBoxContainer.new()
        vbox.add_child(hbox)
        
        var label = Label.new()
        label.text = "Qubit " + str(i) + " Phase:"
        label.custom_minimum_size.x = 100
        hbox.add_child(label)
        
        var slider = HSlider.new()
        slider.min_value = 0.0
        slider.max_value = 2 * PI
        slider.step = 0.1
        slider.value = 0.0
        slider.custom_minimum_size.x = 150
        slider.value_changed.connect(_on_phase_changed.bind(i))
        hbox.add_child(slider)
        qubit_controls.append(slider)
    
    add_child(ui_panel)

func create_initial_superposition():
    """Create visual representation of initial superposition"""
    update_wave_function_visualization()
    update_probability_clouds()

func _process(delta):
    time += delta
    
    if not is_collapsed:
        # Animate superposition state
        animate_superposition(delta)
        update_wave_function_visualization()
        update_probability_clouds()
    else:
        # Animate collapsed state
        animate_collapsed_state(delta)

func animate_superposition(delta):
    """Animate the superposition state with quantum oscillations"""
    for i in range(quantum_state.size()):
        # Add small phase oscillations to demonstrate quantum dynamics
        var phase_oscillation = sin(time * 2.0 + i * 0.5) * 0.1
        var current_amplitude = quantum_state[i].length()
        var current_phase = atan2(quantum_state[i].y, quantum_state[i].x) + phase_oscillation * delta
        
        quantum_state[i] = Vector2(
            current_amplitude * cos(current_phase),
            current_amplitude * sin(current_phase)
        )
    
    # Animate qubit spheres
    for i in range(qubit_spheres.size()):
        var qubit = qubit_spheres[i]
        qubit.rotation.y += delta * 2.0
        
        # Scale based on probability amplitude
        var probability = calculate_qubit_probability(i)
        var scale = 0.5 + probability * 1.5
        qubit.scale = Vector3.ONE * scale

func animate_collapsed_state(delta):
    """Animate the state after measurement collapse"""
    # Flash measurement indicator
    measurement_indicator.visible = sin(time * 10.0) > 0
    
    # Highlight measured state
    for i in range(qubit_spheres.size()):
        var qubit = qubit_spheres[i]
        var is_measured_qubit = ((collapsed_state >> i) & 1) == 1
        
        if is_measured_qubit:
            qubit.material_override.emission = Color.RED * (0.5 + 0.3 * sin(time * 5.0))
        else:
            qubit.material_override.emission = Color.BLUE * 0.1

func update_wave_function_visualization():
    """Create 3D mesh showing wave function amplitude"""
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var num_states = quantum_state.size()
    
    # Create circular arrangement of wave function components
    for i in range(num_states):
        var angle = 2 * PI * i / num_states
        var amplitude = quantum_state[i].length()
        var phase = atan2(quantum_state[i].y, quantum_state[i].x)
        
        # Create vertex at amplitude height
        var radius = 2.0
        var height = amplitude * 3.0  # Scale for visibility
        var position = Vector3(
            cos(angle) * radius,
            height,
            sin(angle) * radius
        )
        
        # Color based on phase
        var color = Color.from_hsv(phase / (2 * PI), 1.0, amplitude * 2.0)
        
        # Create triangle: current vertex, center, next vertex
        var next_index = (i + 1) % num_states
        var next_angle = 2 * PI * next_index / num_states
        var next_amplitude = quantum_state[next_index].length()
        var next_position = Vector3(
            cos(next_angle) * radius,
            next_amplitude * 3.0,
            sin(next_angle) * radius
        )
        var next_phase = atan2(quantum_state[next_index].y, quantum_state[next_index].x)
        var next_color = Color.from_hsv(next_phase / (2 * PI), 1.0, next_amplitude * 2.0)
        
        # Add triangle vertices (current, center, next)
        surface_tool.set_color(color)
        surface_tool.set_normal(Vector3.UP)
        surface_tool.add_vertex(position)
        
        surface_tool.set_color(Color.WHITE)
        surface_tool.set_normal(Vector3.UP)
        surface_tool.add_vertex(Vector3.ZERO)
        
        surface_tool.set_color(next_color)
        surface_tool.set_normal(Vector3.UP)
        surface_tool.add_vertex(next_position)
    
    surface_tool.generate_normals()
    wave_function_mesh.mesh = surface_tool.commit()

func update_probability_clouds():
    """Update visual representation of measurement probabilities"""
    for i in range(probability_clouds.size()):
        var cloud = probability_clouds[i]
        var probability = calculate_qubit_probability(i)
        
        # Scale cloud based on probability
        var scale = 0.3 + probability * 1.4
        cloud.scale = Vector3.ONE * scale
        
        # Adjust transparency
        var material = cloud.material_override as StandardMaterial3D
        material.albedo_color.a = 0.1 + probability * 0.4

func calculate_qubit_probability(qubit_index: int) -> float:
    """Calculate probability of measuring qubit in |1⟩ state"""
    var probability = 0.0
    var num_states = quantum_state.size()
    
    for state in range(num_states):
        if (state >> qubit_index) & 1 == 1:  # Qubit is in |1⟩ state
            var amplitude_squared = quantum_state[state].length_squared()
            probability += amplitude_squared
    
    return probability

func _on_measurement_pressed():
    """Perform quantum measurement and collapse wave function"""
    if is_collapsed:
        return
    
    # Calculate measurement probabilities
    var probabilities = []
    for i in range(quantum_state.size()):
        probabilities.append(quantum_state[i].length_squared())
    
    # Perform weighted random selection
    var random_value = randf()
    var cumulative_probability = 0.0
    
    for i in range(probabilities.size()):
        cumulative_probability += probabilities[i]
        if random_value <= cumulative_probability:
            collapsed_state = i
            break
    
    # Collapse wave function
    quantum_state.fill(Vector2.ZERO)
    quantum_state[collapsed_state] = Vector2.ONE
    is_collapsed = true
    
    # Show measurement indicator
    measurement_indicator.visible = true
    measurement_indicator.position = Vector3(0, 2, 0)
    
    print("Measurement collapsed to state: |", format_binary_state(collapsed_state), "⟩")

func _on_reset_pressed():
    """Reset to superposition state"""
    initialize_quantum_state()
    is_collapsed = false
    collapsed_state = -1
    measurement_indicator.visible = false
    
    # Reset qubit materials
    for qubit in qubit_spheres:
        qubit.material_override.emission = Color.CYAN * 0.3
    
    print("Reset to equal superposition")

func _on_phase_changed(qubit_index: int, value: float):
    """Update quantum state when phase sliders change"""
    if is_collapsed:
        return
    
    # Apply phase rotation to states where this qubit is |1⟩
    for state in range(quantum_state.size()):
        if (state >> qubit_index) & 1 == 1:
            var current_amplitude = quantum_state[state].length()
            quantum_state[state] = Vector2(
                current_amplitude * cos(value),
                current_amplitude * sin(value)
            )

func format_binary_state(state_number: int) -> String:
    """Convert state number to binary string representation"""
    var binary_string = ""
    for i in range(num_qubits):
        var bit = (state_number >> (num_qubits - 1 - i)) & 1
        binary_string += str(bit)
    return binary_string

func create_entanglement_visualization():
    """Create visual connections showing quantum entanglement"""
    # Clear existing connections
    for connection in entanglement_connections:
        connection.queue_free()
    entanglement_connections.clear()
    
    # Calculate entanglement between qubit pairs
    for i in range(num_qubits):
        for j in range(i + 1, num_qubits):
            var entanglement_strength = calculate_entanglement(i, j)
            
            if entanglement_strength > 0.1:  # Only show significant entanglement
                var connection = create_connection_line(
                    qubit_spheres[i].position,
                    qubit_spheres[j].position,
                    entanglement_strength
                )
                add_child(connection)
                entanglement_connections.append(connection)

func calculate_entanglement(qubit_a: int, qubit_b: int) -> float:
    """Calculate entanglement strength between two qubits"""
    # Simplified entanglement measure based on correlation
    var correlation = 0.0
    var num_states = quantum_state.size()
    
    for state in range(num_states):
        var bit_a = (state >> qubit_a) & 1
        var bit_b = (state >> qubit_b) & 1
        var amplitude = quantum_state[state].length()
        
        if bit_a == bit_b:
            correlation += amplitude
        else:
            correlation -= amplitude
    
    return abs(correlation)

func create_connection_line(pos_a: Vector3, pos_b: Vector3, strength: float) -> MeshInstance3D:
    """Create visual connection between two points"""
    var line = MeshInstance3D.new()
    var cylinder_mesh = CylinderMesh.new()
    cylinder_mesh.top_radius = 0.02 * strength
    cylinder_mesh.bottom_radius = 0.02 * strength
    cylinder_mesh.height = pos_a.distance_to(pos_b)
    line.mesh = cylinder_mesh
    
    # Position and orient the cylinder
    line.position = (pos_a + pos_b) / 2
    line.look_at(pos_b, Vector3.UP)
    
    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.YELLOW
    material.emission_enabled = true
    material.emission = Color.YELLOW * strength
    line.material_override = material
    
    return line 
