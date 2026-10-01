extends RefCounted
## Borrowed from Families (the stop where a body became a class with two fields):
## one member of the sphere family, as small as this chapter needs it.
##   const Member := preload("res://parts/member.gd")
##   var body: MeshInstance3D = Member.make(64)
## Contract:
##   make(segments)   a new sphere of 1 m across with `segments` cuts around and
##                    half as many rings, kept between 4 and 64. Its origin is
##                    lifted 0.5 m, so it stands on the ground of its parent. It
##                    has a collider, a sphere of the same size, so a walker is
##                    stopped by it. It has NO material: the chapter gives it one.
##                    It is turned half round, so that its seam, the line from
##                    pole to pole where UV.x runs out at 1 and starts again at
##                    0, is at the back, away from the fixed camera.
## Families built the member as a class, Globe. Here it is one function, so that
## this project names no class and needs no import step.

static func make(segments: int) -> MeshInstance3D:
	segments = clampi(segments, 4, 64)
	var body := MeshInstance3D.new()
	body.name = "Member"
	var sphere := SphereMesh.new()
	sphere.radial_segments = segments
	sphere.rings = segments / 2
	body.mesh = sphere
	body.position.y = 0.5
	body.rotation.y = PI
	var solid := StaticBody3D.new()
	solid.name = "Body"
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	collider.shape = shape
	solid.add_child(collider)
	body.add_child(solid)
	return body
