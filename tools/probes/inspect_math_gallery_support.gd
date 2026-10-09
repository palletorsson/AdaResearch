extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
    var gallery=load("res://commons/primitives/parametric/math_objects.tscn").instantiate()
    root.add_child(gallery)
    for i in range(3):await physics_frame
    for b in gallery.find_children("*","RigidBody3D",true,false):
        var shapes: Array=[]
        for c in b.get_children():
            if c is CollisionShape3D:shapes.append([str(c.shape),c.position,c.scale])
        print(b.name," pos=",b.position," scale=",b.scale," gravity=",b.gravity_scale," frozen=",b.freeze," mask=",b.collision_mask," shapes=",shapes)
    gallery.queue_free();await process_frame;quit()
