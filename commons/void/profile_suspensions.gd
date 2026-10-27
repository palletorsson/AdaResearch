extends RefCounted
## Architectural variants of the museum's real font outlines. The original six
## studies stay untouched; every new suspension is an independent editor part.
const Profiles = preload("res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.gd")
const Tyre = preload("res://commons/artifacts/glyph_profile_gallery/letter_tyre.gd")

static func build(hall: Node3D) -> void:
	var font := FontFile.new()
	assert(font.load_dynamic_font(Profiles.FONT_PATH)==OK)
	for kind in 4:
		var glyph: String = ["O","B","C","I"][kind]
		var section := Profiles.Sweep.profile(font,glyph)
		var frames := recipe(kind)
		var part := Node3D.new()
		part.name = ["SuspendedShaft_O","SuspendedShaft_B","HangingChannel_C","HangingSpool_I"][kind]
		part.position = [Vector3(-10,5.15,0),Vector3(10,5.15,0),Vector3(-17,4.0,1.5),Vector3(17,4.45,0)][kind]
		part.set_meta("editor_label",["O / Suspended shaft vessel","B / Suspended twisting wells","C / Hanging channel","I / Revolved ceiling spool"][kind])
		part.set_meta("profile_glyph",glyph)
		part.set_meta("void_source",Profiles.FONT_PATH)
		hall.add_child(part)
		var mesh := MeshInstance3D.new()
		mesh.name = "GlyphSweep"
		mesh.mesh = Profiles.Sweep.make(section,frames,kind==3)
		var finish := StandardMaterial3D.new()
		finish.albedo_color = Color(["e0cec0","bcc7b3","c1cdd6","c4b4ce"][kind])
		finish.roughness = .48
		finish.metallic = .18
		mesh.material_override = finish
		part.add_child(mesh)
		var body := StaticBody3D.new()
		body.name = "WalkableProfile"
		body.collision_layer = 1
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape := mesh.mesh.create_trimesh_shape()
		shape.backface_collision = true
		collision.shape = shape
		body.add_child(collision)
		mesh.add_child(body)
		_suspend(part,mesh.mesh,kind)
		var light := OmniLight3D.new()
		light.name = "ProfileLight"
		light.position = Vector3(0,-2,2) if kind<2 else Vector3(0,-1,1)
		light.light_color = Color("fff0d9")
		light.light_energy = 1.7
		light.omni_range = 6
		light.shadow_enabled = false
		part.add_child(light)
	var tyre := Tyre.new()
	tyre.name = "RollingTyre_O"
	tyre.position = Vector3(-4.4,.36,1.7)
	tyre.set_meta("editor_label","O / Roll the closed sweep")
	hall.add_child(tyre)

static func recipe(kind: int) -> Array[Transform3D]:
	var frames: Array[Transform3D] = []
	var steps := 80 if kind==3 else 48
	for i in range(steps if kind==3 else steps+1):
		var t := float(i)/steps
		var basis := Basis.IDENTITY
		var centre := Vector3.ZERO
		var width := 1.0
		match kind:
			0,1:
				# Cross-sections remain open, descending THROUGH the shaft slab.
				basis = Basis(Vector3.RIGHT,Vector3.FORWARD,Vector3.UP)
				if kind==1: basis *= Basis(Vector3.BACK,.35*PI*t)
				width = (4.1-.7*sin(PI*t)) if kind==0 else 3.7
				centre.y = -6.4*t
			2:
				# A readable upright C stretched along a shallow curved passage.
				width = 2.6
				centre = Vector3(.6*sin(PI*t),0,lerpf(-1.8,1.8,t))
			3:
				# Revolve the flanged I section; closing its path creates the hub hole.
				var angle := TAU*t
				var radial := Vector3(cos(angle),0,sin(angle))
				basis = Basis(radial,Vector3.UP,Vector3(-sin(angle),0,cos(angle)))
				width = 1.4
				centre = radial*2.1
		frames.append(Transform3D(basis.scaled_local(Vector3(width,width,1)),centre))
	return frames

static func _suspend(part: Node3D, mesh: Mesh, kind: int) -> void:
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bounds := mesh.get_aabb()
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("565c61")
	steel.metallic = .7
	steel.roughness = .4
	# Pick actual upper surface vertices, rather than attaching cables into holes.
	for side in [-1,1]:
		var best := Vector3.ZERO
		var score := -INF
		for p in vertices:
			if p.y<bounds.end.y-.07: continue
			var value: float = side*p.x-absf(p.z)*.1
			if value>score: best=p;score=value
		var anchor := best
		anchor.y = 5.62-part.position.y
		if kind<2: anchor.x = side*2.82 # solid ceiling outside the open shaft
		var cable := MeshInstance3D.new()
		cable.name = "CeilingHangerLeft" if side<0 else "CeilingHangerRight"
		var rod := CylinderMesh.new()
		rod.top_radius = .018
		rod.bottom_radius = .018
		rod.radial_segments = 8
		rod.height = best.distance_to(anchor)
		cable.mesh = rod
		cable.material_override = steel
		cable.position = (anchor+best)*.5
		cable.quaternion = Quaternion(Vector3.UP,(anchor-best).normalized())
		part.add_child(cable)
