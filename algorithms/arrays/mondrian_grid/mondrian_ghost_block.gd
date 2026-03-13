extends CSGBox3D

# MondrianGhostBlock.gd
# Animates the block from opaque white to transparent fading in and out.

var time_offset: float = 0.0

func _ready() -> void:
	# Random start time for variety
	time_offset = randf() * 10.0
	
	# Ensure unique material so we don't fade everything at once if we want independence
	# But actually, Mondrian style might benefit from distinct pulses.
	# If we want them to "go from white to transparent", maybe a loop?
	
	var mat = material_override
	if mat and mat is StandardMaterial3D:
		material_override = mat.duplicate()

func _process(_delta):
	var t = Time.get_ticks_msec() / 1000.0 + time_offset
	
	# Smooth sine wave opacity: 0.1 to 0.8
	var alpha = (sin(t * 1.5) * 0.5 + 0.5) * 0.7 + 0.1
	
	if material_override is StandardMaterial3D:
		var color = material_override.albedo_color
		color.a = alpha
		material_override.albedo_color = color
