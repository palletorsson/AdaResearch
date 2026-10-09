extends Node3D
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const Point = preload("res://commons/artifacts/ignorance_gallery/resolution_catalyst.gd")
var point: XRToolsPickable
var specimens: Array[MeshInstance3D] = []
var moon_torus: Node3D

func _ready() -> void:
	# This last bay is an open court. Leave the museum floor exposed to the moon.
	moon_torus=preload("res://commons/artifacts/ignorance_gallery/moon_torus.gd").new()
	moon_torus.name="MoonStudy"
	add_child(moon_torus)
	# A suspended point at reachable height; no pedestal stands in the reach space.
	# Move it to the side and hang it from a small wall bracket; keep the shadow field clear.
	var point_at := Vector3(5.7,1.45,-3.5)
	Kit.block(self,Vector3(2.1,0.055,0.055),Vector3(6.72,3.15,-3.5),Kit.BLACK,false)
	var thread := Kit.cylinder(self,Vector3(5.7,2.37,-3.5),0.005,1.56,8,Kit.BLACK)
	thread.name = "Suspension"
	# The cable is a display convention, not a physical constraint on the hand.
	for child in thread.get_children(): child.queue_free()
	point = Point.new()
	point.position = point_at
	add_child(point)
	point.suspension = thread
	Kit.block(self,Vector3(3.7,1.10,0.06),Vector3(-4.1,2.45,4.86),Kit.WHITE,false)
	Kit.label(self,"A FORM IN THE HAND",Vector3(-4.1,2.78,4.82),0.0034,PI)
	Kit.label(self,"Hold: fewer divisions.\nTrigger: send this form.",Vector3(-4.1,2.43,4.81),0.0019,PI)
	Kit.label(self,"Release: return in two seconds.",Vector3(-4.1,2.08,4.80),0.0016,PI)
	point.readout = Kit.label(self,"",point_at+Vector3(0,-0.41,0.20),0.0015,PI)
	# Same sphere, same mesh counts: only the displayed direction differs.
	for i in 2:
		var at := Vector3(-6.2 if i==0 else 6.2,0,2.6)
		Kit.pedestal(self,at,0.9,1.15)
		var mesh := SphereMesh.new()
		mesh.radius=0.47; mesh.height=0.94; mesh.rings=8; mesh.radial_segments=16
		var ball := Kit.exhibit(self,mesh,at+Vector3.UP*1.375,Kit.WHITE)
		_direction_lines(ball,i==0)
		specimens.append(ball)
		Kit.label(self,"RINGS" if i==0 else "SEGMENTS",at+Vector3(0,0.68,-0.585),0.002,PI)
		Kit.label(self,"SAME MESH / DIFFERENT DIRECTION",at+Vector3(0,0.46,-0.586),0.001,PI)
	# No fill lamps in this court: extra light would wash out the changing lunar shadow.

func _direction_lines(ball: MeshInstance3D, rings: bool) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Read actual vertex latitudes; the engine's ring count is not a guessed band count.
	var latitudes: Array[float] = []
	for v: Vector3 in ball.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		if absf(v.y) >= 0.4699: continue
		var latitude := acos(clampf(v.y/0.47,-1.0,1.0))
		if not latitudes.any(func(value): return absf(value-latitude)<0.0001): latitudes.append(latitude)
	for j in latitudes.size() if rings else 16:
		for i in 64:
			for t in [float(i)/64.0,float(i+1)/64.0]:
				var latitude: float = latitudes[j] if rings else PI*t
				var longitude: float = TAU*t if rings else TAU*float(j)/16.0
				mesh.surface_add_vertex(Vector3(sin(latitude)*cos(longitude),cos(latitude),sin(latitude)*sin(longitude))*0.473)
	mesh.surface_end()
	var line := MeshInstance3D.new();line.mesh=mesh
	var mat := Kit.material(Kit.BLACK);mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override=mat;ball.add_child(line)
