extends XRToolsPickable
## The category stays with the chair. Contact changes its pose, not its inventory.
const Objects = preload("objects.gd")
var colour := Objects.PINK
var variant := 0
var chair_id := 0
var cohort := ""

func _init() -> void:
	mass=3.0
	freeze=false
	release_mode=ReleaseMode.UNFROZEN
	ranged_grab_method=RangedMethod.LERP
	# Also world-visible: the museum's desktop walker queries layer 1.
	collision_layer=7
	collision_mask=7 | (1<<19)
	continuous_cd=true
	linear_damp=0.65
	angular_damp=1.2
	physics_material_override=PhysicsMaterial.new()
	physics_material_override.friction=0.55
	physics_material_override.bounce=0.0

func _ready() -> void:
	var furniture:=Objects.chair(self,Vector3.ZERO,colour,variant)
	for child in furniture.get_children():
		if child is StaticBody3D:furniture.remove_child(child);child.free()
	# Open space under the seat and between the legs remains physically open.
	part(Vector3(0,0.46,0),Vector3(0.47,0.07,0.47))
	for x in [-0.19,0.19]:
		for z in [-0.19,0.19]:part(Vector3(x,0.22,z),Vector3(0.045,0.44,0.045))
		part(Vector3(x,0.68,-0.19),Vector3(0.045,0.50,0.045))
	part(Vector3(0,0.81,-0.19),Vector3(0.45,0.23,0.055))
	if variant&1:
		for x in [-0.28,0.28]:part(Vector3(x,0.64,0),Vector3(0.07,0.055,0.45))
	if not cohort.is_empty():
		var label:=Objects.ink(self,"%s-%02d" % [cohort,chair_id+1],Vector3(0,0.82,-0.155),22,0.002)
		label.modulate=Color("fff6e8")
	super._ready()

func part(at: Vector3, size: Vector3) -> void:
	var shape:=BoxShape3D.new();shape.size=size
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position=at
	add_child(collision)

func held() -> bool:
	return is_picked_up() or has_meta("capability_desktop_held")

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# A kinematic avatar has effectively infinite mass. Bound collision speeds
	# so entering a loaded stack makes a local disturbance, not flying furniture.
	var motion:=state.linear_velocity
	var horizontal:=Vector2(motion.x,motion.z).limit_length(1.5)
	state.linear_velocity=Vector3(horizontal.x,clampf(motion.y,-8.0,2.0),horizontal.y)
	state.angular_velocity=state.angular_velocity.limit_length(4.0)

func on_desktop_grab(_pointer: Node3D) -> void:
	set_meta("capability_desktop_held",true)
	picked_up.emit(self)

func on_desktop_drop(_pointer: Node3D) -> void:
	remove_meta("capability_desktop_held")
	freeze=false;sleeping=false
	dropped.emit(self)

func on_walk_push(incoming: Vector3, normal: Vector3, delta: float) -> void:
	if held() or freeze:return
	var direction:=Vector3(-normal.x,0,-normal.z)
	if direction.length_squared()<0.01:return # Standing on a chair is not a sideways shove.
	direction=direction.normalized()
	var closing_speed:=maxf(0.0,(incoming-linear_velocity).dot(direction))
	if closing_speed==0:return
	sleeping=false
	# Bounded horizontal force at seat height: gentle nudging, not a launch.
	apply_impulse(direction*minf(60.0,closing_speed*70.0)*delta,global_basis*Vector3(0,0.46,0))
