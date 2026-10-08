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
	# Meet it near the entrance to the court, before the much larger form overhead.
	# A slim stand keeps the point and its instructions together, outside the through-route.
	var point_at := Vector3(-3.6,1.45,-3.5)
	Kit.block(self,Vector3(0.38,0.06,0.38),Vector3(-4.45,0.03,-2.9),Kit.WHITE)
	Kit.block(self,Vector3(0.055,3.12,0.055),Vector3(-4.45,1.62,-2.9),Kit.BLACK)
	Kit.block(self,Vector3(0.90,0.055,0.055),Vector3(-4.025,3.15,-2.9),Kit.BLACK,false)
	Kit.block(self,Vector3(0.055,0.055,0.66),Vector3(-3.6,3.15,-3.2),Kit.BLACK,false)
	var thread := Kit.cylinder(self,Vector3(-3.6,2.37,-3.5),0.005,1.56,8,Kit.BLACK)
	thread.name = "Suspension"
	# The cable is a display convention, not a physical constraint on the hand.
	for child in thread.get_children(): child.queue_free()
	point = Point.new()
	point.position = point_at
	add_child(point)
	point.suspension = thread
	var guide := Kit.block(self,Vector3(1.4,0.90,0.06),Vector3(-4.45,1.83,-2.94),Kit.WHITE,false)
	guide.name = "CatalystGuide"
	Kit.label(self,"THE POINT\nFIRST CATALYST",Vector3(-4.45,2.10,-2.98),0.0015,PI)
	Kit.label(self,"Hold: fewer rings and segments.\nTrigger: send this form.",Vector3(-4.45,1.82,-2.98),0.0013,PI)
	Kit.label(self,"Release: return\nin two seconds.",Vector3(-4.45,1.54,-2.98),0.0012,PI)
	Kit.block(self,Vector3(1.4,0.25,0.04),Vector3(-4.45,1.12,-2.94),Kit.WHITE,false)
	point.readout = Kit.label(self,"",Vector3(-4.45,1.12,-2.97),0.0013,PI)
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
