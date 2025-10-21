# ForcesInfoBoard.gd
# Info board for Forces concepts
extends AlgorithmInfoBoardBase

# Preload visualization
const ForcesVis = preload("res://commons/infoboards_3d/boards/Forces/ForcesVisualization.gd")

func initialize_content() -> void:
	"""Set up content pages for Forces"""
	board_title = "Forces"
	category_color = Color(0.9, 0.5, 0.6, 1.0)  # Red-pink for forces

	page_content = [
		{
			"title": "Forces: The Building Blocks of Motion",
			"text": [
				"Forces are vectors that cause objects to accelerate according to Newton's Second Law: F = ma.",
				"",
				"In nature, the complex behaviors we observe emerge from simple forces interacting with objects over time.",
				"",
				"This info board explores how forces create dynamic, natural motion through five key principles:",
				"1. Force accumulation: Multiple forces combine to create complex behaviors",
				"2. Force-based acceleration: Forces change velocity, which changes position",
				"3. Mass influence: Heavier objects require more force to accelerate at the same rate",
				"4. Force types: From fundamental forces like gravity to emergent forces like springs",
				"5. Equilibrium: When forces balance, motion reaches a steady state",
				"",
				"CODE EXAMPLE:",
				"",
				"# Force application core loop",
				"func apply_force(force: Vector2):",
				"    # F = ma, so a = F/m",
				"    acceleration += force / mass",
				"",
				"func update(delta: float):",
				"    velocity += acceleration * delta",
				"    position += velocity * delta",
				"    acceleration = Vector2.ZERO  # Reset for next frame"
			],
			"visualization": "gravity"
		},
		{
			"title": "Gravity & Orbital Mechanics",
			"text": [
				"Gravity comes in two main forms in simulations: constant downward acceleration and orbital attraction.",
				"",
				"CONSTANT GRAVITY (g ≈ 9.8 m/s²):",
				"Creates predictable parabolic trajectories, useful for:",
				"• Projectile motion in games (jump arcs, missile trajectories)",
				"• Rain, snow, and falling debris effects",
				"• Platformer game physics",
				"",
				"UNIVERSAL GRAVITATION:",
				"Follows Newton's formula: F = G(m₁m₂)/r²",
				"This creates more complex behaviors:",
				"• Orbital mechanics (planets, satellites)",
				"• N-body simulations (star clusters, galaxies)",
				"• Gravitational slingshot effects",
				"",
				"CODE EXAMPLE:",
				"",
				"# Constant gravity",
				"var GRAVITY = Vector2(0, 9.8)",
				"",
				"# Universal gravitation",
				"func calculate_gravity(body1, body2):",
				"    var direction = body2.position - body1.position",
				"    var distance = direction.length()",
				"    direction = direction.normalized()",
				"    ",
				"    # Newton's gravitational formula",
				"    var G = 6.67e-11  # Gravitational constant",
				"    var force = G * body1.mass * body2.mass / (distance * distance)",
				"    return direction * force"
			],
			"visualization": "gravity"
		},
		{
			"title": "Friction & Dampening Forces",
			"text": [
				"Friction transforms kinetic energy into heat, slowing objects to rest.",
				"",
				"Simulating friction improves realism by:",
				"• Preventing perpetual motion (objects eventually stop)",
				"• Creating differences between surfaces (ice, grass, concrete)",
				"• Enabling controlled movement (like car steering)",
				"",
				"FRICTION TYPES:",
				"• Coulomb friction: F = μN (proportional to normal force)",
				"• Drag friction: F = -cv (proportional to velocity)",
				"• Squared drag: F = -cv² (proportional to velocity squared)",
				"",
				"The animation shows particles with varying mass sliding across surfaces with different friction coefficients.",
				"",
				"CODE EXAMPLE:",
				"",
				"# Coulomb friction (simplified)",
				"func apply_friction():",
				"    var friction_coefficient = 0.05",
				"    var friction = velocity.normalized() * -1.0",
				"    friction *= friction_coefficient * mass",
				"    apply_force(friction)",
				"",
				"# Air resistance (squared drag)",
				"func apply_air_resistance():",
				"    var drag_coefficient = 0.01",
				"    var speed_squared = velocity.length_squared()",
				"    var drag_magnitude = drag_coefficient * speed_squared",
				"    var drag = velocity.normalized() * -drag_magnitude",
				"    apply_force(drag)"
			],
			"visualization": "friction"
		},
		{
			"title": "Attraction & Repulsion Fields",
			"text": [
				"Attraction and repulsion forces create some of the most interesting dynamic behaviors in nature:",
				"",
				"EXAMPLES:",
				"• Electromagnetism (charged particles, magnets)",
				"• Molecular bonds (attraction at certain distances, repulsion when too close)",
				"• Animal behaviors (flocking, predator avoidance)",
				"",
				"These forces typically follow variations of inverse square law: F ∝ 1/r²",
				"",
				"The animation demonstrates particles responding to multiple attraction points, creating:",
				"• Stable orbits when velocity and attraction balance",
				"• Chaotic paths when multiple attractors compete",
				"• Oscillations around equilibrium points",
				"",
				"CODE EXAMPLE:",
				"",
				"func apply_attraction(particle, attractor, strength):",
				"    var direction = attractor.position - particle.position",
				"    # Prevent extreme forces at very close distances",
				"    var distance = max(direction.length(), 5.0)",
				"    ",
				"    direction = direction.normalized()",
				"    ",
				"    # Calculate attraction using inverse square law",
				"    var force_magnitude = strength * particle.mass",
				"    force_magnitude *= attractor.mass / (distance * distance)",
				"    ",
				"    # Apply the force",
				"    var attraction_force = direction * force_magnitude",
				"    particle.apply_force(attraction_force)",
				"    ",
				"    # Optional: Add minimum distance repulsion to prevent collapse",
				"    if distance < 25.0:",
				"        var repulsion = direction * -1 * force_magnitude * 2.0",
				"        particle.apply_force(repulsion)"
			],
			"visualization": "attraction"
		},
		{
			"title": "Complex Force Fields & Emergent Behaviors",
			"text": [
				"When forces vary across space, they create force fields that produce complex, emergent behaviors.",
				"",
				"FLOW FIELDS:",
				"Direct objects along vector currents, simulating:",
				"• Wind and fluid dynamics",
				"• Crowd movement patterns",
				"• Procedural terrain-aligned movement",
				"",
				"Perlin noise creates organic, natural-looking flow patterns by generating smooth random variations over space.",
				"",
				"The simulation shows emergent phenomena:",
				"• Particles moving through a wind field generated with Perlin noise",
				"• Particles responding to fluid resistance (stronger drag in \"water\" areas)",
				"• Particles following a radial field with turbulence",
				"",
				"CODE EXAMPLE:",
				"",
				"# Generate flow field with Perlin noise",
				"func generate_flow_field(resolution, strength):",
				"    var field = []",
				"    for y in range(resolution):",
				"        var row = []",
				"        for x in range(resolution):",
				"            # Use Perlin noise for organic force directions",
				"            var angle = noise.get_noise_2d(x * 0.1, y * 0.1) * TAU",
				"            var force = Vector2(cos(angle), sin(angle)) * strength",
				"            row.append(force)",
				"        field.append(row)",
				"    return field",
				"",
				"# Apply force from flow field to particle",
				"func apply_flow_field_force(particle, flow_field, resolution):",
				"    # Find grid position",
				"    var grid_x = int(particle.position.x / cell_size) % resolution",
				"    var grid_y = int(particle.position.y / cell_size) % resolution",
				"    ",
				"    # Get force at that position",
				"    var force = flow_field[grid_y][grid_x]",
				"    particle.apply_force(force)"
			],
			"visualization": "wind"
		}
	]

# VR input handling is now handled by the base class
# Override these methods for custom VR behavior if needed

func _on_vr_scroll_changed(scroll_value: float):
	"""Handle VR scroll changes - Forces-specific behavior"""
	# Optional: Add visual feedback or sound effects for forces
	pass

func _on_vr_input_detected(controller: XRController3D):
	"""Handle VR input detection - Forces-specific behavior"""
	print("ForcesInfoBoard: VR input detected from controller: ", controller.name)

func create_visualization(vis_type: String) -> Control:
	"""Create appropriate visualization for the given type"""
	var vis = Control.new()
	vis.set_script(ForcesVis)
	vis.visualization_type = vis_type
	vis.custom_minimum_size = Vector2(400, 400)
	return vis
