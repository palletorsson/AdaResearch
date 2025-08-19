extends Node3D

# Levenshtein Distance: The Mathematics of Becoming & Identity Transformation
# Calculates the minimum edit operations needed to transform one string into another
# A profound metaphor for transition, chosen names, and the computational cost of authentic selfhood

@export_category("Identity Transformation")
@export var source_string: String = "deadname"
@export var target_string: String = "chosen_name"
@export var show_transformation_path: bool = true
@export var animate_transformation: bool = true
@export var operation_costs: Vector3 = Vector3(1, 1, 1)  # Insert, Delete, Substitute

@export_category("Algorithm Configuration")
@export var animation_speed: float = 1.2  # Seconds per operation
@export var show_dynamic_programming_table: bool = true
@export var highlight_optimal_path: bool = true
@export var auto_animate: bool = true

@export_category("Visualization")
@export var character_size: float = 1.0
@export var table_spacing: float = 1.5
@export var source_color: Color = Color(0.9, 0.4, 0.4)    # Reddish - representing past/old
@export var target_color: Color = Color(0.3, 0.9, 0.3)    # Green - representing future/new
@export var operation_color: Color = Color(0.9, 0.9, 0.3) # Yellow - transformation
@export var path_color: Color = Color(0.9, 0.3, 0.9)      # Magenta - the journey

@export_category("Transition Presets")
@export var transition_preset: String = "Name_Change"  # Name_Change, Pronoun_Shift, Identity_Evolution

# Algorithm state
var dp_table: Array[Array] = []
var source_chars: Array[String] = []
var target_chars: Array[String] = []
var transformation_operations: Array[Dictionary] = []
var current_operation_index: int = 0
var is_computing: bool = false
var is_animating_transformation: bool = false
var animation_timer: float = 0.0

# Visual elements
var table_display: Node3D
var source_display: Node3D
var target_display: Node3D
var transformation_display: Node3D
var path_visualization: Node3D
var ui_display: CanvasLayer
var camera_controller: Node3D

# Educational components
var computation_statistics: Dictionary = {
    "total_operations": 0,
    "insertions": 0,
    "deletions": 0,
    "substitutions": 0,
    "final_distance": 0
}

func _ready():
    setup_environment()
    setup_camera()
    load_transition_preset()
    compute_levenshtein_distance()
    create_visualization()
    setup_ui()
    if auto_animate:
        start_transformation_animation()

func _process(delta):
    if is_animating_transformation and auto_animate:
        animation_timer += delta
        if animation_timer >= animation_speed:
            perform_transformation_step()
            animation_timer = 0.0

func _input(event):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_SPACE:
                if not is_animating_transformation:
                    start_transformation_animation()
                else:
                    perform_transformation_step()
            KEY_R:
                restart_computation()
            KEY_1:
                load_transition_preset("Name_Change")
            KEY_2:
                load_transition_preset("Pronoun_Shift")
            KEY_3:
                load_transition_preset("Identity_Evolution")
            KEY_T:
                toggle_table_visibility()
            KEY_P:
                toggle_path_visibility()

func setup_environment():
    # Gentle, affirming lighting
    var light = DirectionalLight3D.new()
    light.light_energy = 1.2
    light.rotation_degrees = Vector3(-25, 30, 0)
    add_child(light)
    
    # Soft background representing hope and possibility
    var env = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.05, 0.1, 0.15)  # Deep blue
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.2, 0.2, 0.3)
    environment.ambient_light_energy = 0.4
    env.environment = environment
    add_child(env)

func setup_camera():
    camera_controller = Node3D.new()
    add_child(camera_controller)
    
    var camera = Camera3D.new()
    camera.position = Vector3(0, 10, 20)
    camera.look_at(Vector3(0, 0, 0), Vector3.UP)
    camera_controller.add_child(camera)

func load_transition_preset(preset: String = ""):
    if preset != "":
        transition_preset = preset
    
    match transition_preset:
        "Name_Change":
            source_string = "deadname"
            target_string = "chosen_name"
            operation_costs = Vector3(1, 1, 1)  # Equal cost for all operations
            
        "Pronoun_Shift":
            source_string = "he/him"
            target_string = "they/them"
            operation_costs = Vector3(0.5, 1, 0.5)  # Lower cost for insertions and substitutions
            
        "Identity_Evolution":
            source_string = "confused"
            target_string = "authentic"
            operation_costs = Vector3(1, 2, 0.8)  # Higher cost for deletions (losing parts of self)
    
    restart_computation()

func compute_levenshtein_distance():
    """Compute the dynamic programming table for Levenshtein distance"""
    source_chars = []
    target_chars = []
    
    # Convert strings to character arrays
    for c in source_string:
        source_chars.append(c)
    for c in target_string:
        target_chars.append(c)
    
    var m = source_chars.size()
    var n = target_chars.size()
    
    # Initialize DP table
    dp_table = []
    for i in range(m + 1):
        dp_table.append([])
        for j in range(n + 1):
            dp_table[i].append(0)
    
    # Fill base cases
    for i in range(m + 1):
        dp_table[i][0] = i * operation_costs.y  # Deletions
    for j in range(n + 1):
        dp_table[0][j] = j * operation_costs.x  # Insertions
    
    # Fill DP table using recurrence relation
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if source_chars[i-1] == target_chars[j-1]:
                # Characters match - no operation needed
                dp_table[i][j] = dp_table[i-1][j-1]
            else:
                # Choose minimum cost operation
                var insert_cost = dp_table[i][j-1] + operation_costs.x
                var delete_cost = dp_table[i-1][j] + operation_costs.y
                var substitute_cost = dp_table[i-1][j-1] + operation_costs.z
                
                dp_table[i][j] = min(insert_cost, min(delete_cost, substitute_cost))
    
    computation_statistics.final_distance = dp_table[m][n]
    
    # Backtrack to find optimal transformation sequence
    build_transformation_sequence()
    
    print("Levenshtein distance from '", source_string, "' to '", target_string, "': ", computation_statistics.final_distance)

func build_transformation_sequence():
    """Backtrack through DP table to find optimal transformation sequence"""
    transformation_operations.clear()
    computation_statistics.insertions = 0
    computation_statistics.deletions = 0
    computation_statistics.substitutions = 0
    
    var i = source_chars.size()
    var j = target_chars.size()
    
    while i > 0 or j > 0:
        if i > 0 and j > 0 and source_chars[i-1] == target_chars[j-1]:
            # Characters match - no operation
            i -= 1
            j -= 1
            continue
        
        var current_cost = dp_table[i][j]
        var operation: Dictionary = {}
        
        if i > 0 and j > 0:
            # Check substitution
            var substitute_cost = dp_table[i-1][j-1] + operation_costs.z
            if current_cost == substitute_cost:
                operation = {
                    "type": "substitute",
                    "source_pos": i-1,
                    "target_pos": j-1,
                    "from_char": source_chars[i-1],
                    "to_char": target_chars[j-1],
                    "cost": operation_costs.z
                }
                computation_statistics.substitutions += 1
                i -= 1
                j -= 1
                transformation_operations.push_front(operation)
                continue
        
        if j > 0:
            # Check insertion
            var insert_cost = dp_table[i][j-1] + operation_costs.x
            if current_cost == insert_cost:
                operation = {
                    "type": "insert",
                    "target_pos": j-1,
                    "char": target_chars[j-1],
                    "cost": operation_costs.x
                }
                computation_statistics.insertions += 1
                j -= 1
                transformation_operations.push_front(operation)
                continue
        
        if i > 0:
            # Must be deletion
            operation = {
                "type": "delete",
                "source_pos": i-1,
                "char": source_chars[i-1],
                "cost": operation_costs.y
            }
            computation_statistics.deletions += 1
            i -= 1
            transformation_operations.push_front(operation)
    
    computation_statistics.total_operations = transformation_operations.size()
    print("Transformation requires: ", computation_statistics.insertions, " insertions, ", 
          computation_statistics.deletions, " deletions, ", 
          computation_statistics.substitutions, " substitutions")

func create_visualization():
    """Create the complete visualization of the algorithm"""
    clear_previous_visualization()
    
    create_source_string_display()
    create_target_string_display()
    create_dp_table_display()
    create_transformation_display()
    
    if highlight_optimal_path:
        create_path_visualization()
    
    adjust_camera_for_content()

func create_source_string_display():
    """Create visual representation of source string"""
    source_display = Node3D.new()
    source_display.name = "SourceDisplay"
    add_child(source_display)
    
    var title_label = create_floating_text("Original Identity:", Vector3(-5, 8, 0), source_color, 1.2)
    source_display.add_child(title_label)
    
    for i in range(source_chars.size()):
        var char_mesh = create_character_mesh(source_chars[i], 
                                            Vector3(-5 + i * character_size * 1.2, 6, 0), 
                                            source_color)
        char_mesh.name = "source_char_" + str(i)
        source_display.add_child(char_mesh)

func create_target_string_display():
    """Create visual representation of target string"""
    target_display = Node3D.new()
    target_display.name = "TargetDisplay"
    add_child(target_display)
    
    var title_label = create_floating_text("Authentic Self:", Vector3(-5, 4, 0), target_color, 1.2)
    target_display.add_child(title_label)
    
    for i in range(target_chars.size()):
        var char_mesh = create_character_mesh(target_chars[i], 
                                            Vector3(-5 + i * character_size * 1.2, 2, 0), 
                                            target_color)
        char_mesh.name = "target_char_" + str(i)
        target_display.add_child(char_mesh)

func create_dp_table_display():
    """Create visual representation of the dynamic programming table"""
    table_display = Node3D.new()
    table_display.name = "TableDisplay"
    add_child(table_display)
    
    if not show_dynamic_programming_table:
        table_display.visible = false
        return
    
    var title_label = create_floating_text("Transformation Matrix:", Vector3(5, 8, 0), Color.WHITE, 1.0)
    table_display.add_child(title_label)
    
    # Create table cells
    for i in range(dp_table.size()):
        for j in range(dp_table[i].size()):
            var cost = dp_table[i][j]
            var cell_position = Vector3(5 + j * table_spacing, 6 - i * table_spacing, 0)
            
            # Color based on cost value (gradient from low to high cost)
            var max_cost = computation_statistics.final_distance
            var normalized_cost = cost / max_cost if max_cost > 0 else 0
            var cell_color = Color(0.2 + normalized_cost * 0.6, 0.8 - normalized_cost * 0.6, 0.9 - normalized_cost * 0.4)
            
            var cell_mesh = create_table_cell(str(cost), cell_position, cell_color)
            cell_mesh.name = "table_cell_" + str(i) + "_" + str(j)
            table_display.add_child(cell_mesh)

func create_transformation_display():
    """Create display area for showing transformation operations"""
    transformation_display = Node3D.new()
    transformation_display.name = "TransformationDisplay"
    add_child(transformation_display)
    
    var title_label = create_floating_text("Transformation Journey:", Vector3(-8, -2, 0), operation_color, 1.1)
    transformation_display.add_child(title_label)

func create_path_visualization():
    """Create visualization of the optimal path through the DP table"""
    path_visualization = Node3D.new()
    path_visualization.name = "PathVisualization"
    add_child(path_visualization)
    
    # This would show the path through the DP table
    # Implementation would trace back through the optimal decisions

func create_character_mesh(character: String, position: Vector3, color: Color) -> MeshInstance3D:
    """Create a 3D character mesh with emotional resonance"""
    var mesh_instance = MeshInstance3D.new()
    
    var sphere = SphereMesh.new()
    sphere.radius = character_size * 0.4
    sphere.height = character_size * 0.8
    mesh_instance.mesh = sphere
    
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color * 0.3
    material.metallic = 0.1
    material.roughness = 0.7
    mesh_instance.material_override = material
    
    mesh_instance.position = position
    
    # Add character label
    var label = Label3D.new()
    label.text = character
    label.font_size = 48
    label.position = Vector3(0, 0, character_size * 0.5)
    mesh_instance.add_child(label)
    
    return mesh_instance

func create_table_cell(value: String, position: Vector3, color: Color) -> MeshInstance3D:
    """Create a cell for the DP table visualization"""
    var mesh_instance = MeshInstance3D.new()
    
    var box = BoxMesh.new()
    box.size = Vector3(table_spacing * 0.8, table_spacing * 0.8, 0.2)
    mesh_instance.mesh = box
    
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color * 0.2
    mesh_instance.material_override = material
    
    mesh_instance.position = position
    
    # Add value label
    var label = Label3D.new()
    label.text = value
    label.font_size = 32
    label.position = Vector3(0, 0, 0.2)
    mesh_instance.add_child(label)
    
    return mesh_instance

func create_floating_text(text: String, position: Vector3, color: Color, scale: float) -> Label3D:
    """Create floating text labels"""
    var label = Label3D.new()
    label.text = text
    label.font_size = int(48 * scale)
    label.position = position
    label.modulate = color
    return label

func start_transformation_animation():
    """Begin animated visualization of the transformation sequence"""
    current_operation_index = 0
    is_animating_transformation = true
    animation_timer = 0.0
    
    # Clear previous transformation visualizations
    for child in transformation_display.get_children():
        if "operation_" in child.name:
            child.queue_free()
    
    update_ui()
    print("Starting transformation animation...")

func perform_transformation_step():
    """Perform one step of the transformation animation"""
    if current_operation_index >= transformation_operations.size():
        is_animating_transformation = false
        print("Transformation complete!")
        update_ui()
        return
    
    var operation = transformation_operations[current_operation_index]
    
    # Create visual representation of this operation
    create_operation_visualization(operation, current_operation_index)
    
    current_operation_index += 1
    update_ui()

func create_operation_visualization(operation: Dictionary, step_index: int):
    """Create visual representation of a single transformation operation"""
    var operation_text = ""
    var operation_position = Vector3(-8, -4 - step_index * 0.8, 0)
    
    match operation.type:
        "insert":
            operation_text = "Insert '" + operation.char + "' → " + str(operation.cost)
        "delete":
            operation_text = "Delete '" + operation.char + "' → " + str(operation.cost)
        "substitute":
            operation_text = "Change '" + operation.from_char + "' to '" + operation.to_char + "' → " + str(operation.cost)
    
    var operation_label = create_floating_text(operation_text, operation_position, operation_color, 0.7)
    operation_label.name = "operation_" + str(step_index)
    transformation_display.add_child(operation_label)
    
    # Add visual effect
    create_operation_effect(operation, operation_position)

func create_operation_effect(operation: Dictionary, position: Vector3):
    """Create visual effect for transformation operation"""
    var effect = MeshInstance3D.new()
    var cylinder = CylinderMesh.new()
    cylinder.height = 0.3
    cylinder.top_radius = 0.2
    cylinder.bottom_radius = 0.2
    effect.mesh = cylinder
    
    var material = StandardMaterial3D.new()
    material.albedo_color = operation_color
    material.emission_enabled = true
    material.emission = operation_color * 0.8
    effect.material_override = material
    
    effect.position = position + Vector3(0, 0, 0.2)
    transformation_display.add_child(effect)
    
    # Animate the effect
    var tween = create_tween()
    tween.tween_property(effect, "scale", Vector3(1.5, 1.5, 1.5), 0.5)
    tween.tween_property(effect, "modulate:a", 0.0, 0.5)
    tween.tween_callback(func(): effect.queue_free())

func clear_previous_visualization():
    """Clear all previous visualization elements"""
    if source_display:
        source_display.queue_free()
    if target_display:
        target_display.queue_free()
    if table_display:
        table_display.queue_free()
    if transformation_display:
        transformation_display.queue_free()
    if path_visualization:
        path_visualization.queue_free()

func adjust_camera_for_content():
    """Adjust camera to show all content optimally"""
    var content_bounds = calculate_content_bounds()
    var camera_distance = max(content_bounds.x, content_bounds.y) * 1.5
    camera_controller.position = Vector3(0, content_bounds.y / 2, camera_distance)

func calculate_content_bounds() -> Vector2:
    """Calculate bounds of all visualization content"""
    var max_x = max(source_chars.size() * character_size, dp_table[0].size() * table_spacing) + 10
    var max_y = 10 + transformation_operations.size() * 0.8
    return Vector2(max_x, max_y)

func restart_computation():
    """Restart the entire computation and visualization"""
    clear_previous_visualization()
    compute_levenshtein_distance()
    create_visualization()
    is_animating_transformation = false
    current_operation_index = 0
    update_ui()

func toggle_table_visibility():
    """Toggle visibility of the DP table"""
    show_dynamic_programming_table = !show_dynamic_programming_table
    if table_display:
        table_display.visible = show_dynamic_programming_table
    update_ui()

func toggle_path_visibility():
    """Toggle visibility of the optimal path"""
    highlight_optimal_path = !highlight_optimal_path
    if path_visualization:
        path_visualization.visible = highlight_optimal_path
    update_ui()

func setup_ui():
    """Create comprehensive user interface"""
    ui_display = CanvasLayer.new()
    add_child(ui_display)
    
    var panel = Panel.new()
    panel.custom_minimum_size = Vector2(450, 600)
    panel.position = Vector2(20, 20)
    ui_display.add_child(panel)
    
    var vbox = VBoxContainer.new()
    vbox.position = Vector2(15, 15)
    vbox.custom_minimum_size = Vector2(420, 570)
    panel.add_child(vbox)
    
    # Title
    var title = Label.new()
    title.text = "Levenshtein Distance: Mathematics of Becoming"
    title.add_theme_font_size_override("font_size", 16)
    vbox.add_child(title)
    
    # Information labels
    for i in range(18):
        var label = Label.new()
        label.name = "info_label_" + str(i)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        vbox.add_child(label)
    
    update_ui()

func update_ui():
    """Update user interface with current state"""
    if not ui_display:
        return
    
    var labels = []
    for i in range(18):
        var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
        if label:
            labels.append(label)
    
    if labels.size() >= 18:
        labels[0].text = "Transition Type: " + transition_preset.replace("_", " ")
        labels[1].text = "From: '" + source_string + "'"
        labels[2].text = "To: '" + target_string + "'"
        labels[3].text = ""
        labels[4].text = "Edit Distance: " + str(computation_statistics.final_distance)
        labels[5].text = "Total Operations: " + str(computation_statistics.total_operations)
        labels[6].text = "- Insertions: " + str(computation_statistics.insertions)
        labels[7].text = "- Deletions: " + str(computation_statistics.deletions)
        labels[8].text = "- Substitutions: " + str(computation_statistics.substitutions)
        labels[9].text = ""
        labels[10].text = "Operation Costs: Insert(" + str(operation_costs.x) + "), Delete(" + str(operation_costs.y) + "), Substitute(" + str(operation_costs.z) + ")"
        labels[11].text = ""
        labels[12].text = "Animation Progress: " + str(current_operation_index) + "/" + str(transformation_operations.size())
        labels[13].text = "Status: " + ("Transforming" if is_animating_transformation else "Ready")
        labels[14].text = ""
        labels[15].text = "Controls: SPACE=Step/Start, R=Restart"
        labels[16].text = "1-3=Presets, T=Toggle Table, P=Toggle Path"
        labels[17].text = "Every edit operation represents growth toward authenticity" 