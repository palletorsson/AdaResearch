# rotation.gd - minimal spin driver for the compact prism/capsule primitives
#
# @identity
# essence: a minimal spin driver that turns whatever it is attached to at a fixed degrees-per-second on each axis
# desire: learner sees that a solid's third dimension is only legible once it turns — a static silhouette hides depth
# critical_parameter: rotation_speed — the per-axis degrees/second vector; zero it and the form freezes into an ambiguous outline
# triggers: adds rotation_speed * delta to rotation_degrees every _process frame
# emerges: the understanding that motion is a reading aid — rotation is how a flat view recovers volume
# needs: [continuous spin from a speed vector [has], missing grab-to-turn so the learner sets the axis by hand]
# relationships: the animator behind the capsule and prism blocks — shared spin for the compact primitives
# truth: a solid seen from one angle is a silhouette; only turning it returns the depth the eye cannot infer
extends Node3D

# Rotation Settings
@export_group("Rotation")
@export var rotation_speed: Vector3 = Vector3(0, 45, 0)  # degrees per second


func _process(delta):
	_update_rotation(delta)
	
func _update_rotation(delta):
	"""Handle rotation animation"""
	self.rotation_degrees += rotation_speed * delta
