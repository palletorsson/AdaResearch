extends "res://commons/artifacts/force_play/play_body.gd"
## Existing museum prefab geometry, carried by one dynamic body.
## Chair parts have separate convex colliders; a crate keeps a box collider.
@export_enum("crate","chair","extinguisher") var prop_kind := "crate"
@export var size_multiplier := 1.0
var visual_bounds: AABB

func _ready() -> void:
	var source: Node3D
	var span: float
	match prop_kind:
		"chair":
			source=load("res://commons/artifacts/chair_kit/chair_kit.gd").new()
			source._build_assembled();span=1.05;mass=2.6
		"extinguisher":
			source=load("res://commons/artifacts/fire_extinguisher/fire_extinguisher.gd").new()
			source.wall_bracket=false;source.bake_label_into_body=false
			source._ready();span=0.8;mass=2.2
		_:
			source=load("res://commons/artifacts/crate/crate.gd").new()
			source.stamp_label="THIS WAY UP";source._ready();span=0.72;mass=1.5
	span*=size_multiplier;mass*=pow(size_multiplier,3)
	var visual=Node3D.new();visual.name="PrefabVisual";add_child(visual)
	copy_visuals(source,Transform3D.IDENTITY,visual)
	source.free() # Unparented construction template: no physics body or timers.
	var first=true
	for child in visual.get_children():
		if not child is MeshInstance3D:continue
		var bounds: AABB=child.transform*child.mesh.get_aabb()
		visual_bounds=bounds if first else visual_bounds.merge(bounds);first=false
	var scale_factor=span/maxf(visual_bounds.size.x,maxf(visual_bounds.size.y,visual_bounds.size.z))
	var centre=visual_bounds.get_center()
	for child in visual.get_children():
		child.position=(child.position-centre)*scale_factor;child.scale*=scale_factor
	visual_bounds=AABB((visual_bounds.position-centre)*scale_factor,visual_bounds.size*scale_factor)
	if prop_kind=="chair":
		for child in visual.get_children():
			if not child is MeshInstance3D:continue
			var collision=CollisionShape3D.new()
			# Bake visual scale into convex vertices; rigid-body scale stays one.
			var convex=ConvexPolygonShape3D.new();var points=PackedVector3Array()
			for p in child.mesh.get_faces():points.append(child.transform*p)
			convex.points=points;collision.shape=convex;add_child(collision)
	else:
		var collision=CollisionShape3D.new()
		if prop_kind=="crate":
			var shape=BoxShape3D.new();shape.size=visual_bounds.size;collision.shape=shape
		else:
			var shape=CapsuleShape3D.new();shape.height=visual_bounds.size.y
			shape.radius=maxf(visual_bounds.size.x,visual_bounds.size.z)*0.5;collision.shape=shape
		add_child(collision)
	set_meta("prefab_kind",prop_kind)
	super._ready()

func copy_visuals(node: Node,frame: Transform3D,host: Node3D) -> void:
	var here=frame*node.transform if node is Node3D else frame
	if node is MeshInstance3D and node.mesh!=null:
		var mesh=MeshInstance3D.new();mesh.mesh=node.mesh;mesh.material_override=node.material_override
		mesh.transform=here;host.add_child(mesh)
	elif node is Label3D:
		var text=Label3D.new();text.text=node.text;text.font_size=node.font_size;text.pixel_size=node.pixel_size
		text.modulate=node.modulate;text.outline_size=node.outline_size;text.transform=here;host.add_child(text)
	for child in node.get_children():copy_visuals(child,here,host)
