# @identity
# essence: a shader surface that procedurally generates Leopard, Tiger, Zebra, Dalmatian, and Snake skin patterns — each is a different parameter set of the same underlying reaction-diffusion mathematics
# desire: to make Turing's morphogenesis thesis legible as material — to stand beside a wall wearing leopard skin is to stand beside a solved differential equation that biology ran for four million years
# critical_parameter: preset (enum of 5 species) — each preset is a distinct parameterization; the scale, spot_density, rosette_ring, and color channels are the only things separating a leopard from a zebra
# triggers: _ready() calls apply_preset(); preset setter triggers live re-parameterization of the ShaderMaterial; the GPU runs the reaction-diffusion shader per fragment
# emerges: pattern as taxonomy — the five presets reveal that species-specific markings are not identities but parameter regions in a continuous mathematical space; evolution tuned numbers, not equations
# needs: VR preset-switching (grab-and-dial) [missing]; live parameter sliders [missing]; apply_grid_config [missing]; side-by-side display of all 5 presets [missing]
# relationships: paired conceptually with reaction_diffusion and turing_pattern — all three are morphogenesis algorithms; animatematerial is the material application of the same math shown abstractly in those exhibits
# truth: a leopard's rosette and a zebra's stripe are the same equation with different numbers — Turing proved in 1952 that skin patterns need no blueprint, only two chemicals diffusing at different rates

# AnimalPrintMaterial.gd
# Attach this script to a MeshInstance3D (or any Node3D with a ShaderMaterial).
# The shader must be the "AnimalPrint.gdshader" from before.

extends Node3D

@export_enum("Leopard", "Tiger", "Zebra", "Dalmatian", "Snake") var preset : String = "Leopard":
	set(value):
		preset = value
		apply_preset()

@onready var mat: ShaderMaterial = $".".material_override

func _ready() -> void:
	apply_preset()

func apply_preset() -> void:
	if not mat:
		return

	match preset:
		"Leopard":
			mat.set_shader_parameter("pattern", 0)
			mat.set_shader_parameter("scale", 16.2)
			mat.set_shader_parameter("spot_density", 1.3)
			mat.set_shader_parameter("rosette_ring", 0.42)
			mat.set_shader_parameter("base_col", Color("#f4c460"))
			mat.set_shader_parameter("mark_col", Color("#2a1b10"))
			mat.set_shader_parameter("rough", 0.8)
			mat.set_shader_parameter("normal_amount", 0.3)

		"Tiger":
			mat.set_shader_parameter("pattern", 1)
			mat.set_shader_parameter("scale", 20.6)
			mat.set_shader_parameter("stripe_thickness", 0.55)
			mat.set_shader_parameter("stripe_curve", 1.3)
			mat.set_shader_parameter("base_col", Color("#f28c2b"))
			mat.set_shader_parameter("mark_col", Color("#0d0c0b"))
			mat.set_shader_parameter("contrast", 1.1)
			mat.set_shader_parameter("rough", 0.7)

		"Zebra":
			mat.set_shader_parameter("pattern", 2)
			mat.set_shader_parameter("scale", 25.2)
			mat.set_shader_parameter("stripe_thickness", 0.5)
			mat.set_shader_parameter("stripe_curve", 1.75)
			mat.set_shader_parameter("base_col", Color.WHITE)
			mat.set_shader_parameter("mark_col", Color.BLACK)
			mat.set_shader_parameter("contrast", 1.5)
			mat.set_shader_parameter("rough", 0.6)

		"Dalmatian":
			mat.set_shader_parameter("pattern", 3)
			mat.set_shader_parameter("scale", 23.4)
			mat.set_shader_parameter("spot_density", 1.1)
			mat.set_shader_parameter("base_col", Color.WHITE)
			mat.set_shader_parameter("mark_col", Color.BLACK)
			mat.set_shader_parameter("rough", 0.85)

		"Snake":
			mat.set_shader_parameter("pattern", 4)
			mat.set_shader_parameter("scale", 4.0)
			mat.set_shader_parameter("snake_scale_round", 0.7)
			mat.set_shader_parameter("snake_checker", 0.28)
			mat.set_shader_parameter("base_col", Color("#7a9a5c")) # greenish
			mat.set_shader_parameter("mark_col", Color("#3a2b1b"))
			mat.set_shader_parameter("accent_col", Color("#8a3dbb")) # funky purple alt
			mat.set_shader_parameter("rough", 0.45)
			mat.set_shader_parameter("metallic_amt", 0.05)
			mat.set_shader_parameter("normal_amount", 0.4)

func apply_grid_config(config: Dictionary) -> void:
	pass
