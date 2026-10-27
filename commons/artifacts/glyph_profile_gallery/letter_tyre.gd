extends XRToolsPickable
## An actual O outline swept around a closed circle. A compound rim collision
## retains the central hole; one convex hull would turn it into a solid disk.
const Profiles = preload("res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.gd")
const SEGMENTS := 32
var section: Dictionary
var frames: Array[Transform3D] = []

func _ready() -> void:
	var font := FontFile.new()
	assert(font.load_dynamic_font(Profiles.FONT_PATH)==OK)
	section = Profiles.Sweep.profile(font,"O")
	set_meta("profile_glyph","O")
	set_meta("sweep_closed",true)
	# Include world layer 1: the desktop walker intentionally ignores other props.
	collision_layer = 7
	collision_mask = 7
	mass = 3.0
	continuous_cd = true
	freeze = false
	release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	linear_damp = .015
	angular_damp = .015
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = .85
	physics_material_override.bounce = .03
	for i in SEGMENTS:
		var angle := TAU*float(i)/SEGMENTS
		var radial := Vector3(cos(angle),sin(angle),0)
		var axial := Vector3.BACK
		var basis := Basis(radial,axial,radial.cross(axial))
		# About 70 cm outside diameter and 22 cm wide: a hand-pushable car tire.
		frames.append(Transform3D(basis.scaled_local(Vector3(.22,.22,1)),radial*.285))
	var visual := MeshInstance3D.new()
	visual.name = "RubberGlyph"
	visual.mesh = Profiles.Sweep.make(section,frames,true)
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color("272b2c")
	rubber.roughness = .82
	rubber.metallic = 0.0
	visual.material_override = rubber
	add_child(visual)
	for i in SEGMENTS:
		var points := PackedVector3Array()
		for frame: Transform3D in [frames[i],frames[(i+1)%SEGMENTS]]:
			for p: Vector2 in section.points: points.append(frame*Vector3(p.x,p.y,0))
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var collision := CollisionShape3D.new()
		collision.name = "RimSegment%02d"%i
		collision.shape = shape
		add_child(collision)
	super()

func _physics_process(_delta: float) -> void:
	# CharacterBody motion does not transfer momentum to rigid bodies by itself.
	# Only a real visitor contact pushes this wheel; there is no automatic spin.
	if freeze or is_picked_up() or linear_velocity.length()>5: return
	var tower := get_tree().get_first_node_in_group("void_game")
	if tower==null or not tower.ready_for_play or tower.recovering: return
	var visitor: CharacterBody3D = tower.body
	if visitor.global_position.distance_to(global_position)>2.5: return
	for i in visitor.get_slide_collision_count():
		var contact := visitor.get_slide_collision(i)
		if contact.get_collider()!=self: continue
		var direction := -contact.get_normal()
		direction.y = 0
		if direction.length_squared()<.01: continue
		direction = direction.normalized()
		# Last-frame travel is used because move_and_slide removes the blocked velocity.
		if visitor.get_real_velocity().dot(direction)<.03: continue
		sleeping = false
		apply_force(direction*35,contact.get_position()-global_position)
