extends "res://commons/primitives/parametric/math_objects_gallery.gd"

## Some source surfaces already are pickables, but remain on physics layer 1.
## Add the shared grab layer without changing their existing world collisions.
func _spawn_object(obj_def: Dictionary, variation_idx: int) -> Node3D:
	var object: Node3D = super._spawn_object(obj_def, variation_idx)
	if object is CollisionObject3D and object.has_method("pick_up"):
		object.set_collision_layer_value(3, true)
	return object
