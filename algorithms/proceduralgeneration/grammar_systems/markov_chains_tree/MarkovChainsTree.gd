@tool
extends Node3D
class_name MarkovChainsTree

@export_group("Tree Settings")
@export var tree_height: float = 10.0
@export var max_iterations: int = 100
@export var branch_segments: int = 8
@export var initial_thickness: float = 0.3
@export var thickness_decay: float = 0.75

@export_group("Markov Chain")
@export var randomness: float = 0.3
@export_range(0.0, 1.0) var branch_probability: float = 0.4
@export_range(0.0, 1.0) var terminate_probability: float = 0.1
@export_range(0.0, 1.0) var vertical_bias: float = 0.6

@export_group("Growth Animation")
@export var animate_growth: bool = false
@export var growth_speed: float = 2.0

@export_group("Visual")
@export var bark_color: Color = Color(0.4, 0.25, 0.15)
@export var leaf_color: Color = Color(0.2, 0.6, 0.2)
@export var add_leaves: bool = true

@export var regenerate: bool = false:
    set(value):
        if value:
            grow_tree()
            regenerate = false

# Markov Chain States
enum State {
    GROW_STRAIGHT,
    GROW_UP,
    BRANCH_LEFT,
    BRANCH_RIGHT,
    BRANCH_BOTH,
    CURVE_LEFT,
    CURVE_RIGHT,
    TERMINATE
}

# Transition probability matrix
var transition_matrix = {}
var current_iteration = 0
var growth_timer = 0.0

class Branch:
    var position: Vector3
    var direction: Vector3
    var thickness: float
    var depth: int
    var state: State
    var parent: Branch = null
    var mesh_instance: MeshInstance3D = null
    var length: float = 1.0
    
    func _init(pos: Vector3, dir: Vector3, thick: float, d: int, s: State):
        position = pos
        direction = dir.normalized()
        thickness = thick
        depth = d
        state = s

var branches: Array[Branch] = []
var active_branches: Array[Branch] = []

func _ready():
    setup_markov_chain()
    grow_tree()

func _process(delta):
    if animate_growth and active_branches.size() > 0:
        growth_timer += delta * growth_speed
        if growth_timer >= 0.1:
            growth_timer = 0.0
            grow_iteration()

func setup_markov_chain():
    # Define transition probabilities for each state
    # Format: {current_state: {next_state: probability}}
    
    transition_matrix = {
        State.GROW_STRAIGHT: {
            State.GROW_STRAIGHT: 0.5,
            State.GROW_UP: 0.2,
            State.BRANCH_BOTH: 0.15,
            State.CURVE_LEFT: 0.05,
            State.CURVE_RIGHT: 0.05,
            State.TERMINATE: 0.05
        },
        State.GROW_UP: {
            State.GROW_STRAIGHT: 0.3,
            State.GROW_UP: 0.4,
            State.BRANCH_LEFT: 0.1,
            State.BRANCH_RIGHT: 0.1,
            State.TERMINATE: 0.1
        },
        State.BRANCH_LEFT: {
            State.GROW_STRAIGHT: 0.4,
            State.CURVE_LEFT: 0.3,
            State.BRANCH_RIGHT: 0.1,
            State.TERMINATE: 0.2
        },
        State.BRANCH_RIGHT: {
            State.GROW_STRAIGHT: 0.4,
            State.CURVE_RIGHT: 0.3,
            State.BRANCH_LEFT: 0.1,
            State.TERMINATE: 0.2
        },
        State.BRANCH_BOTH: {
            State.GROW_UP: 0.6,
            State.TERMINATE: 0.4
        },
        State.CURVE_LEFT: {
            State.CURVE_LEFT: 0.4,
            State.GROW_STRAIGHT: 0.3,
            State.BRANCH_RIGHT: 0.1,
            State.TERMINATE: 0.2
        },
        State.CURVE_RIGHT: {
            State.CURVE_RIGHT: 0.4,
            State.GROW_STRAIGHT: 0.3,
            State.BRANCH_LEFT: 0.1,
            State.TERMINATE: 0.2
        },
        State.TERMINATE: {
            State.TERMINATE: 1.0
        }
    }

func grow_tree():
    clear_tree()
    current_iteration = 0
    
    # Create trunk
    var root = Branch.new(
        Vector3.ZERO,
        Vector3.UP,
        initial_thickness,
        0,
        State.GROW_STRAIGHT
    )
    
    branches.append(root)
    active_branches.append(root)
    
    if not animate_growth:
        # Generate entire tree
        while active_branches.size() > 0 and current_iteration < max_iterations:
            grow_iteration()
    
    # Visualize
    visualize_tree()

func grow_iteration():
    if active_branches.size() == 0:
        return
    
    var new_branches: Array[Branch] = []
    
    for branch in active_branches:
        # Get next state from Markov chain
        var next_state = get_next_state(branch)
        
        # Modify probabilities based on context
        next_state = apply_growth_rules(branch, next_state)
        
        # Execute state action
        var created_branches = execute_state(branch, next_state)
        
        if created_branches.size() > 0:
            new_branches.append_array(created_branches)
    
    active_branches = new_branches
    current_iteration += 1

func get_next_state(branch: Branch) -> State:
    var transitions = transition_matrix[branch.state]
    var rand_val = randf()
    var cumulative = 0.0
    
    for state in transitions:
        cumulative += transitions[state]
        if rand_val <= cumulative:
            return state
    
    return State.TERMINATE

func apply_growth_rules(branch: Branch, next_state: State) -> State:
    # Modify state based on growth rules
    
    # Height limit
    if branch.position.y > tree_height:
        return State.TERMINATE
    
    # Thickness limit
    if branch.thickness < 0.05:
        return State.TERMINATE
    
    # Depth limit (prevent infinite branching)
    if branch.depth > branch_segments:
        return State.TERMINATE
    
    # Apply vertical bias (trees grow up)
    if randf() < vertical_bias and branch.position.y < tree_height * 0.7:
        if next_state in [State.CURVE_LEFT, State.CURVE_RIGHT]:
            return State.GROW_UP
    
    # Reduce branching at greater depths
    var branch_chance = branch_probability * (1.0 - float(branch.depth) / branch_segments)
    if next_state in [State.BRANCH_BOTH, State.BRANCH_LEFT, State.BRANCH_RIGHT]:
        if randf() > branch_chance:
            return State.GROW_STRAIGHT
    
    return next_state

func execute_state(parent: Branch, state: State) -> Array[Branch]:
    var new_branches: Array[Branch] = []
    var segment_length = tree_height / branch_segments
    
    match state:
        State.GROW_STRAIGHT:
            var new_dir = parent.direction
            new_dir += Vector3(
                randf_range(-randomness, randomness),
                0,
                randf_range(-randomness, randomness)
            ).normalized() * 0.1
            new_dir = new_dir.normalized()
            
            var new_branch = create_branch(
                parent,
                new_dir,
                segment_length,
                parent.thickness * 0.95,
                state
            )
            new_branches.append(new_branch)
        
        State.GROW_UP:
            var up_dir = parent.direction.lerp(Vector3.UP, 0.7)
            var new_branch = create_branch(
                parent,
                up_dir,
                segment_length,
                parent.thickness * 0.95,
                state
            )
            new_branches.append(new_branch)
        
        State.BRANCH_LEFT:
            var left_dir = parent.direction.rotated(Vector3.UP, deg_to_rad(45))
            left_dir.y += 0.3
            var new_branch = create_branch(
                parent,
                left_dir,
                segment_length * 0.8,
                parent.thickness * thickness_decay,
                state
            )
            new_branches.append(new_branch)
        
        State.BRANCH_RIGHT:
            var right_dir = parent.direction.rotated(Vector3.UP, deg_to_rad(-45))
            right_dir.y += 0.3
            var new_branch = create_branch(
                parent,
                right_dir,
                segment_length * 0.8,
                parent.thickness * thickness_decay,
                state
            )
            new_branches.append(new_branch)
        
        State.BRANCH_BOTH:
            # Continue straight
            var straight = create_branch(
                parent,
                parent.direction,
                segment_length * 0.9,
                parent.thickness * 0.8,
                State.GROW_UP
            )
            new_branches.append(straight)
            
            # Branch left
            var left_dir = parent.direction.rotated(Vector3.UP, deg_to_rad(40))
            left_dir.y += 0.2
            var left_branch = create_branch(
                parent,
                left_dir,
                segment_length * 0.7,
                parent.thickness * thickness_decay,
                State.BRANCH_LEFT
            )
            new_branches.append(left_branch)
            
            # Branch right
            var right_dir = parent.direction.rotated(Vector3.UP, deg_to_rad(-40))
            right_dir.y += 0.2
            var right_branch = create_branch(
                parent,
                right_dir,
                segment_length * 0.7,
                parent.thickness * thickness_decay,
                State.BRANCH_RIGHT
            )
            new_branches.append(right_branch)
        
        State.CURVE_LEFT:
            var curved_dir = parent.direction.rotated(Vector3.UP, deg_to_rad(15))
            var new_branch = create_branch(
                parent,
                curved_dir,
                segment_length,
                parent.thickness * 0.92,
                state
            )
            new_branches.append(new_branch)
        
        State.CURVE_RIGHT:
            var curved_dir = parent.direction.rotated(Vector3.UP, deg_to_rad(-15))
            var new_branch = create_branch(
                parent,
                curved_dir,
                segment_length,
                parent.thickness * 0.92,
                state
            )
            new_branches.append(new_branch)
        
        State.TERMINATE:
            # Add leaf if enabled
            if add_leaves:
                create_leaf(parent.position)
    
    return new_branches

func create_branch(parent: Branch, direction: Vector3, length: float, thickness: float, state: State) -> Branch:
    var new_pos = parent.position + direction.normalized() * length
    var new_branch = Branch.new(
        new_pos,
        direction,
        thickness,
        parent.depth + 1,
        state
    )
    new_branch.parent = parent
    new_branch.length = length
    
    branches.append(new_branch)
    return new_branch

func visualize_tree():
    clear_visualization()
    
    for branch in branches:
        if branch.parent != null:
            create_branch_mesh(branch)

func create_branch_mesh(branch: Branch):
    var mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)
    branch.mesh_instance = mesh_instance
    
    # Create cylinder mesh for branch
    var mesh = create_cylinder_mesh(
        branch.parent.position,
        branch.position,
        branch.parent.thickness,
        branch.thickness
    )
    
    mesh_instance.mesh = mesh
    
    # Apply material
    var material = StandardMaterial3D.new()
    material.albedo_color = bark_color
    material.roughness = 0.9
    mesh_instance.material_override = material

func create_cylinder_mesh(start: Vector3, end: Vector3, start_radius: float, end_radius: float) -> ArrayMesh:
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var direction = (end - start).normalized()
    var length = start.distance_to(end)
    var radial_segments = 8
    
    # Create tapered cylinder
    for i in range(radial_segments + 1):
        var angle = float(i) / radial_segments * TAU
        var perpendicular = Vector3(cos(angle), 0, sin(angle))
        
        # Rotate perpendicular to be perpendicular to direction
        if abs(direction.dot(Vector3.UP)) < 0.99:
            var right = direction.cross(Vector3.UP).normalized()
            var up = right.cross(direction).normalized()
            perpendicular = right * cos(angle) + up * sin(angle)
        
        # Start circle
        var start_point = start + perpendicular * start_radius
        # End circle
        var end_point = end + perpendicular * end_radius
        
        if i < radial_segments:
            var next_angle = float(i + 1) / radial_segments * TAU
            var next_perp = Vector3(cos(next_angle), 0, sin(next_angle))
            if abs(direction.dot(Vector3.UP)) < 0.99:
                var right = direction.cross(Vector3.UP).normalized()
                var up = right.cross(direction).normalized()
                next_perp = right * cos(next_angle) + up * sin(next_angle)
            
            var start_next = start + next_perp * start_radius
            var end_next = end + next_perp * end_radius
            
            # Create quad (2 triangles)
            surface_tool.add_vertex(start_point)
            surface_tool.add_vertex(end_point)
            surface_tool.add_vertex(start_next)
            
            surface_tool.add_vertex(start_next)
            surface_tool.add_vertex(end_point)
            surface_tool.add_vertex(end_next)
    
    surface_tool.generate_normals()
    return surface_tool.commit()

func create_leaf(position: Vector3):
    var leaf = MeshInstance3D.new()
    add_child(leaf)
    
    var sphere = SphereMesh.new()
    sphere.radius = 0.3
    sphere.height = sphere.radius
    leaf.mesh = sphere
    leaf.position = position
    
    var material = StandardMaterial3D.new()
    material.albedo_color = leaf_color
    leaf.material_override = material

func clear_tree():
    branches.clear()
    active_branches.clear()
    clear_visualization()

func clear_visualization():
    for child in get_children():
        child.queue_free()
