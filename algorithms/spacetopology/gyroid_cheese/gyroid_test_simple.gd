extends Node3D

func _ready() -> void:
	print("=== SIMPLE GYROID TEST ===")
	print("Setting up basic gyroid visualization...")

	var gyroid_box := $GyroidBox
	if gyroid_box:
		print("✓ Found GyroidBox mesh")

		# Create a simple shader that just shows a solid color first
		var shader := Shader.new()
		shader.code = """
shader_type spatial;
render_mode unshaded;

uniform vec3 test_color : source_color = vec3(0.3, 0.7, 1.0);

void fragment() {
	ALBEDO = test_color;
	ALPHA = 0.8;
}
"""

		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("test_color", Vector3(0.3, 0.7, 1.0))

		gyroid_box.material_override = material
		print("✓ Applied test shader")
	else:
		print("✗ GyroidBox not found!")

	# Add collision for testing
	var static_body := StaticBody3D.new()
	static_body.name = "TestCollider"
	add_child(static_body)

	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(4, 4, 4)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)

	print("✓ Added collision box")
	print("=== TEST SETUP COMPLETE ===")
	print("")
	print("You should see:")
	print("  - A light blue semi-transparent box")
	print("  - A label saying 'Simple Gyroid Test'")
	print("  - Camera looking at the box from an angle")
	print("")
	print("If you see this, the basic setup works!")
