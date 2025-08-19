extends Node2D

# N-Body Gravitational Attraction
# Based on The Nature of Code by Daniel Shiffman
# Converted from p5.js to Godot

class_name GravitationalSimulation

# Simulation settings
@export var num_bodies: int = 30
@export var screen_margin: int = 50
@export var random_velocity_range: float = 1.0

# Body properties
@export var min_mass: float = 5.0
@export var max_mass: float = 30.0
@export var g_constant: float = 0.5  # Gravitational constant

# References to nodes
var bodies = []
var viewport_size = Vector2.ZERO

func _ready():
	randomize()  # Initialize random number generator
	viewport_size = get_viewport_rect().size
	
	# Create initial bodies
	create_bodies(num_bodies)

func create_bodies(count):
	# Remove any existing bodies
	for body in bodies:
		body.queue_free()
	bodies.clear()
	
	# Create new bodies
	for i in range(count):
		var x = randf_range(screen_margin, viewport_size.x - screen_margin)
		var y = randf_range(screen_margin, viewport_size.y - screen_margin)
		var mass = randf_range(min_mass, max_mass)
		
		var body = Body.new(x, y, mass)
		
		# Random initial velocity
		var vel_x = randf_range(-random_velocity_range, random_velocity_range)
		var vel_y = randf_range(-random_velocity_range, random_velocity_range)
		body.velocity = Vector2(vel_x, vel_y)
		
		add_child(body)
		bodies.append(body)

func _process(delta):
	# Apply gravitational forces between all bodies
	for i in range(bodies.size()):
		for j in range(bodies.size()):
			if i != j:  # Don't attract self
				bodies[i].attract(bodies[j], g_constant)
	
	# Update all bodies
	for body in bodies:
		body.update()

# Handle input for interaction
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			# Reset simulation with new random bodies
			create_bodies(num_bodies)
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Add a new body at mouse position
			var body = Body.new(event.position.x, event.position.y, randf_range(min_mass, max_mass))
			add_child(body)
			bodies.append(body)

# Body class implementation
class Body extends Node2D:
	var velocity = Vector2.ZERO
	var acceleration = Vector2.ZERO
	var mass = 8.0
	var radius = 0.0
	
	func _init(x, y, m):
		position = Vector2(x, y)  # Using Node2D's built-in position property
		mass = m
		radius = sqrt(mass) * 2
	
	func attract(body, G):
		# Calculate gravitational force
		var force = position - body.position
		var distance = force.length()
		# Constrain distance to avoid extreme forces
		distance = clamp(distance, 5.0, 25.0)
		
		# Calculate strength of force with Newton's gravity equation
		var strength = (G * (mass * body.mass)) / (distance * distance)
		force = force.normalized() * strength
		
		# Apply force to the other body
		body.apply_force(force)
	
	func apply_force(force):
		# F = ma, so a = F/m
		var f = force / mass
		acceleration += f
	
	func update():
		# Update velocity, position, and reset acceleration
		velocity += acceleration
		position += velocity  # Using Node2D's built-in position property
		acceleration = Vector2.ZERO
		queue_redraw()  # Request redraw to update the visual
	
	func _draw():
		# Draw the body as a circle
		draw_circle(Vector2.ZERO, radius * 2, Color(0.5, 0.5, 0.5, 0.4))
		draw_arc(Vector2.ZERO, radius * 2, 0, TAU, 32, Color(0, 0, 0), 2.0)

# Main scene instructions
# 1. Create a new Godot project
# 2. Create a new 2D scene with a Node2D as root
# 3. Attach this script to the root node
# 4. Run the scene
#
# Controls:
# - Left-click to add a new body
# - Space key to reset the simulation
