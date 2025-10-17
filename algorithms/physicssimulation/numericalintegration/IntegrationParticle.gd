extends Node3D

class_name IntegrationParticle

@export var particle_color: Color = Color.WHITE
@export var integration_method: String = "euler"
@export var initial_position: Vector3 = Vector3.ZERO
@export var initial_velocity: Vector3 = Vector3.ZERO

var particle_position: Vector3  # Renamed to avoid conflict with Node3D.position
var velocity: Vector3
var trail_points = []
var max_trail_points = 200
var trail_material: StandardMaterial3D

func _ready():
	_create_particle_mesh()
	_create_trail_material()

func _create_particle_mesh():
	# Create the particle sphere
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.2
	sphere.material = StandardMaterial3D.new()
	sphere.material.albedo_color = particle_color
	sphere.material.emission_enabled = true
	sphere.material.emission = particle_color * 0.3
	
	add_child(sphere)

func _create_trail_material():
	trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = particle_color
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.albedo_color.a = 0.7

func initialize():
	particle_position = initial_position
	velocity = initial_velocity
	trail_points.clear()

func update_physics(delta: float, gravity: Vector3, damping: float):
	match integration_method:
		"euler":
			_euler_integration(delta, gravity, damping)
		"rk4":
			_rk4_integration(delta, gravity, damping)
		"analytical":
			_analytical_solution(delta, gravity, damping)
	
	# Update node position
	self.position = particle_position

func _euler_integration(delta: float, gravity: Vector3, damping: float):
	# Simple Euler method: x(t+dt) = x(t) + v(t)*dt
	particle_position += velocity * delta
	velocity += gravity * delta
	velocity *= damping

func _rk4_integration(delta: float, gravity: Vector3, damping: float):
	# Runge-Kutta 4th order method
	var k1_pos = velocity
	var k1_vel = gravity
	
	var k2_pos = velocity + k1_vel * delta * 0.5
	var k2_vel = gravity
	
	var k3_pos = velocity + k2_vel * delta * 0.5
	var k3_vel = gravity
	
	var k4_pos = velocity + k3_vel * delta
	var k4_vel = gravity
	
	# Update position and velocity
	particle_position += (k1_pos + 2*k2_pos + 2*k3_pos + k4_pos) * delta / 6.0
	velocity += (k1_vel + 2*k2_vel + 2*k3_vel + k4_vel) * delta / 6.0
	velocity *= damping

func _analytical_solution(delta: float, gravity: Vector3, damping: float):
	# Analytical solution for projectile motion with damping
	var t = delta
	
	# Position: x(t) = x0 + v0*t + 0.5*a*t^2
	particle_position += velocity * t + 0.5 * gravity * t * t
	
	# Velocity: v(t) = v0 + a*t
	velocity += gravity * t
	velocity *= damping

func update_trail():
	# Add current position to trail
	trail_points.append(particle_position)
	
	# Limit trail length
	if trail_points.size() > max_trail_points:
		trail_points.pop_front()
	
	# Clear existing trail segments
	for child in get_children():
		if child.name.begins_with("TrailSegment"):
			child.queue_free()
	
	# Draw trail
	for i in range(1, trail_points.size()):
		var start = trail_points[i-1]
		var end = trail_points[i]
		
		var trail_segment = CSGBox3D.new()
		trail_segment.name = "TrailSegment" + str(i)
		trail_segment.size = Vector3(0.02, 0.02, start.distance_to(end))
		trail_segment.position = (start + end) / 2
		trail_segment.look_at(end, Vector3.UP)
		trail_segment.material = trail_material
		
		# Add to trails parent
		get_parent().get_parent().get_node("Trails").add_child(trail_segment)

func reset_to_initial():
	particle_position = initial_position
	velocity = initial_velocity
	trail_points.clear()
	
	# Clear trail segments
	for child in get_children():
		if child.name.begins_with("TrailSegment"):
			child.queue_free()
