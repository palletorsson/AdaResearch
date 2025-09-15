@tool 
# PrideFlagVariations.gd - Utökad version med flera flaggor
extends Node3D

enum FlagType {
	RAINBOW,
	TRANS,
	BISEXUAL,
	NONBINARY,
	PANSEXUAL,
	LESBIAN,
	ASEXUAL
}

@export var flag_type: FlagType = FlagType.RAINBOW
@export var wind_strength: float = 1.0
@export var celebration_intensity: float = 1.0

@onready var skeleton: Skeleton3D
@onready var skinned_mesh:  MeshInstance3D
var flag_bones: Array[int] = []
var time_offset: float = 0.0
var celebration_mode: bool = false

# Flaggfärger för olika Pride-flaggor
var flag_colors: Dictionary = {
	FlagType.RAINBOW: [
		Color(0.91, 0.11, 0.14),    # Red
		Color(1.0, 0.5, 0.0),       # Orange  
		Color(1.0, 0.93, 0.0),      # Yellow
		Color(0.0, 0.51, 0.18),     # Green
		Color(0.0, 0.32, 0.73),     # Blue
		Color(0.46, 0.11, 0.53)     # Purple
	] as Array[Color],
	FlagType.TRANS: [
		Color(0.35, 0.8, 0.98),     # Light blue
		Color(0.96, 0.67, 0.81),    # Pink
		Color(1.0, 1.0, 1.0),       # White
		Color(0.96, 0.67, 0.81),    # Pink
		Color(0.35, 0.8, 0.98)      # Light blue
	] as Array[Color],
	FlagType.BISEXUAL: [
		Color(0.84, 0.2, 0.64),     # Magenta
		Color(0.84, 0.2, 0.64),     # Magenta (thicker)
		Color(0.61, 0.35, 0.71),    # Purple
		Color(0.0, 0.32, 0.73),     # Blue
		Color(0.0, 0.32, 0.73)      # Blue (thicker)
	] as Array[Color],
	FlagType.NONBINARY: [
		Color(0.99, 0.96, 0.0),     # Yellow
		Color(1.0, 1.0, 1.0),       # White
		Color(0.61, 0.35, 0.71),    # Purple
		Color(0.0, 0.0, 0.0)        # Black
	] as Array[Color],
	FlagType.PANSEXUAL: [
		Color(1.0, 0.13, 0.58),     # Pink
		Color(1.0, 0.85, 0.0),      # Yellow
		Color(0.13, 0.7, 1.0)       # Blue
	] as Array[Color],
	FlagType.LESBIAN: [
		Color(0.84, 0.33, 0.0),     # Orange
		Color(1.0, 0.58, 0.25),     # Light orange
		Color(1.0, 1.0, 1.0),       # White
		Color(0.85, 0.51, 0.74),    # Light pink
		Color(0.64, 0.0, 0.32)      # Dark pink
	] as Array[Color],
	FlagType.ASEXUAL: [
		Color(0.0, 0.0, 0.0),       # Black
		Color(0.64, 0.64, 0.64),    # Gray
		Color(1.0, 1.0, 1.0),       # White
		Color(0.5, 0.0, 0.5)        # Purple
	] as Array[Color]
}

func _ready() -> void:
	create_pride_flag_with_bones()
	setup_joyful_animation()
	var flag_name = FlagType.keys()[flag_type]
	print("🏳️‍🌈 %s Pride flag ready! Press SPACE for celebration! 🏳️‍🌈" % flag_name)

func create_pride_flag_with_bones() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "FlagSkeleton"
	add_child(skeleton)

	skinned_mesh =  MeshInstance3D.new()
	skinned_mesh.name = "FlagMesh"
	add_child(skinned_mesh)
	skinned_mesh.skeleton = skeleton.get_path()

	var colors: Array[Color] = flag_colors[flag_type]
	var flag_width := 6.0
	var flag_height := 4.0
	var segments_x := 16        # Ännu mjukare för vindeffekt
	var segments_y: int = colors.size()

	# Skapa ben för vindeffekt
	flag_bones.clear()
	for i in range(segments_x + 1):
		var bone_name := "flag_bone_%d" % i
		var bone_idx := skeleton.get_bone_count()
		skeleton.add_bone(bone_name)
		flag_bones.append(bone_idx)
		var x_pos := lerpf(-flag_width * 0.5, flag_width * 0.5, float(i) / float(segments_x))
		skeleton.set_bone_rest(bone_idx, Transform3D(Basis(), Vector3(x_pos, 0, 0)))

	# Bygg geometri med mjukare viktning mellan ben
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var verts_per_row := segments_x + 1
	for y in range(segments_y + 1):
		for x in range(segments_x + 1):
			var px := lerpf(-flag_width * 0.5, flag_width * 0.5, float(x) / float(segments_x))
			var py := lerpf(-flag_height * 0.5, flag_height * 0.5, float(y) / float(segments_y))
			var pos := Vector3(px, py, 0.0)

			# Färginterpolation mellan stripes
			var color_pos: float = float(y) / float(segments_y) * (colors.size() - 1)
			var color_idx := int(color_pos)
			var color_blend: float = color_pos - color_idx
			var vertex_color: Color
			
			if color_idx >= colors.size() - 1:
				vertex_color = colors[-1]
			else:
				vertex_color = colors[color_idx].lerp(colors[color_idx + 1], color_blend)

			st.set_color(vertex_color)
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(Vector2(float(x) / segments_x, float(y) / segments_y))

			# Mjukare bone weighting för naturligare deformation
			var bone_pos := float(x) / float(segments_x) * (flag_bones.size() - 1)
			var bone1 := int(bone_pos)
			var bone2 := mini(bone1 + 1, flag_bones.size() - 1)
			var blend := bone_pos - bone1
			
			var bone_indices := PackedInt32Array([bone1, bone2, 0, 0])
			var bone_weights := PackedFloat32Array([1.0 - blend, blend, 0.0, 0.0])
			
			st.set_bones(bone_indices)
			st.set_weights(bone_weights)
			st.add_vertex(pos)

	# Triangulering
	for y in range(segments_y):
		for x in range(segments_x):
			var i := y * verts_per_row + x
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + verts_per_row)
			st.add_index(i + 1)
			st.add_index(i + verts_per_row + 1)
			st.add_index(i + verts_per_row)

	skinned_mesh.mesh = st.commit()

func setup_joyful_animation() -> void:
	time_offset = randf() * TAU

func _process(_delta: float) -> void:
	if skeleton == null or flag_bones.is_empty():
		return

	var t := float(Time.get_ticks_msec()) * 0.001 + time_offset

	if Input.is_action_just_pressed("ui_accept"):
		celebration_mode = !celebration_mode
		var flag_name = FlagType.keys()[flag_type]
		print("🎉 %s flag celebration: %s! 🎉" % [flag_name, "ON" if celebration_mode else "OFF"])

	# Vindeffekt med noise för mer naturlig rörelse
	var noise_seed := int(time_offset * 1000) % 1000
	
	for i in range(flag_bones.size()):
		var bone_idx := flag_bones[i]
		var rest := skeleton.get_bone_rest(bone_idx)
		
		# Grundvåg + noise för mer naturlig vind
		var wave_offset := i * 0.25
		var progress := float(i) / float(flag_bones.size())
		
		# Grundvågor
		var base_wave := sin(t * 2.0 + wave_offset) * 0.4 * wind_strength
		var wind_noise := sin(t * 3.7 + progress * 8.0) * 0.15 * wind_strength
		
		var stretch_x := 1.0
		var stretch_y := 1.0
		
		if celebration_mode:
			var celebration_factor := celebration_intensity
			stretch_x = 1.0 + sin(t * 5.0 + wave_offset) * 0.4 * celebration_factor
			stretch_y = 1.0 + cos(t * 4.0 + wave_offset) * 0.25 * celebration_factor
			base_wave *= 1.5 * celebration_factor
			wind_noise *= 2.0 * celebration_factor
		else:
			stretch_x = 1.0 + sin(t * 2.0 + wave_offset) * 0.15
			stretch_y = 1.0 + cos(t * 1.5 + wave_offset) * 0.08

		var xform := rest
		xform.origin.z = base_wave + wind_noise
		# Lägg till lite rotation för mer dramatisk effekt
		if celebration_mode:
			xform.basis = xform.basis.rotated(Vector3.FORWARD, sin(t * 3.0 + wave_offset) * 0.1)
		xform.basis = xform.basis.scaled(Vector3(stretch_x, stretch_y, 1.0))

		skeleton.set_bone_pose(bone_idx, xform)

	# Global rotation för känsla av vind
	var wind_sway := sin(t * 0.8) * 0.03 * wind_strength
	if celebration_mode:
		wind_sway += sin(t * 2.0) * 0.05 * celebration_intensity
	rotation.z = wind_sway

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		create_themed_particles()

func create_themed_particles() -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 80
	particles.lifetime = 2.5
	particles.emission_sphere_radius = 2.5
	particles.gravity = Vector3(0, -1.5, 0)
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 10.0
	
	# Använd flaggans färger för partiklar
	var colors: Array[Color] = flag_colors[flag_type]
	var ramp := Gradient.new()
	for i in range(colors.size()):
		var point := float(i) / float(colors.size() - 1)
		ramp.add_point(point, colors[i])
	particles.color_ramp = ramp

	add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(3.5).timeout
	particles.queue_free()

# Scene setup helper (run from script or use as autoload)
func create_flag_parade() -> void:
	var flag_types = [FlagType.RAINBOW, FlagType.TRANS, FlagType.BISEXUAL, FlagType.NONBINARY]
	for i in range(flag_types.size()):
		var flag_scene = preload("res://algorithms/physicssimulation/softbodies/flagdancer/flagdancer.gd").new()
		flag_scene.flag_type = flag_types[i]
		flag_scene.position.x = i * 8.0 - 12.0
		flag_scene.wind_strength = randf_range(0.8, 1.2)
		add_child(flag_scene)
