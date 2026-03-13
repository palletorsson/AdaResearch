extends WorldEnvironment
class_name AxiomEnvironment

# The Axiom Garden - Iteration 8: The Aesthetic
# Sets up the neon-void atmosphere.

func _ready() -> void:
	environment = Environment.new()
	
	# 1. Background: The Void
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.08) # Deep dark blue-black
	
	# 2. Glow: The Neon
	environment.glow_enabled = true
	environment.glow_intensity = 1.5
	environment.glow_strength = 1.1
	environment.glow_bloom = 0.2
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	
	# 3. Fog: Depth
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.01
	environment.volumetric_fog_albedo = Color(0.1, 0.2, 0.3)
