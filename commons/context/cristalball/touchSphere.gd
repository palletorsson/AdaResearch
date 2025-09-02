extends Area3D

@export var cooldown_time: float = 3.5  # Cooldown time in seconds
var is_on_cooldown: bool = false  # To track whether the sphere is on cooldown

@onready var material = $MeshInstance3D.material_override
var cooldown_timer: Timer  # Timer for cooldown handling

func _ready():
	# Ensure the material is an instance for dynamic parameter changes
	if material:
		material = material.duplicate()
		$MeshInstance3D.material_override = material

	# Create a Timer node for the cooldown
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.one_shot = true
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_timeout"))
	add_child(cooldown_timer)

func _on_area_entered(area: Area3D) -> void:
	if not is_on_cooldown:
		# Activate glowing color
		if material:
			material.set("shader_param/is_touched", true)

		# Start cooldown
		is_on_cooldown = true
		cooldown_timer.start()

func _on_cooldown_timeout():
	# Reset glowing effect after cooldown
	if material:
		material.set("shader_param/is_touched", false)

	# Reset cooldown flag
	is_on_cooldown = false
