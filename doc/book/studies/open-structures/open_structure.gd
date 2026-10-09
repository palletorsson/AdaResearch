extends RefCounted
## Supplied display machinery: the Line lesson's segment between two positions,
## batched into square-section bars. Coordinates/connectivity remain separate.
## No inferred solid faces, no collision, no claim to LeWitt's joint construction.

const EDGES := [[0,1],[1,2],[2,3],[3,0], [4,5],[5,6],[6,7],[7,4], [0,4],[1,5],[2,6],[3,7]]

static func corners(width: float=1.0, top_fraction: float=1.0, top_shift: float=0.0) -> Array[Vector3]:
	var p: Array[Vector3]=[
		Vector3(-.5,0,-.5), Vector3(.5,0,-.5), Vector3(.5,0,.5), Vector3(-.5,0,.5),
		Vector3(-.5,1,-.5), Vector3(.5,1,-.5), Vector3(.5,1,.5), Vector3(-.5,1,.5)]
	for i in p.size():
		if i>=4:
			p[i].x=p[i].x*top_fraction+top_shift
			p[i].z*=top_fraction
		p[i].x*=width
		p[i].z*=width
	return p

static func segments(points: Array[Vector3]) -> Array:
	var result: Array=[]
	for pair in EDGES:
		var a: Vector3=points[pair[0]]
		var b: Vector3=points[pair[1]]
		# Four top addresses coincide at the pyramid's apex. Skip zero lengths.
		if a.distance_squared_to(b)>0.00000001:result.append([a,b])
	return result

static func bar_transform(a: Vector3,b: Vector3) -> Transform3D:
	var d := b-a
	return Transform3D(Basis(Quaternion(Vector3.UP,d.normalized()))*Basis.from_scale(Vector3(1,d.length(),1)),(a+b)*0.5)

static func display(lines: Array, thickness: float=0.055) -> MultiMeshInstance3D:
	var result:=MultiMeshInstance3D.new()
	var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	var bar:=BoxMesh.new()
	bar.size=Vector3(thickness,1,thickness)
	batch.mesh=bar
	batch.instance_count=lines.size()
	for i in lines.size():batch.set_instance_transform(i,bar_transform(lines[i][0],lines[i][1]))
	result.multimesh=batch
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color(.92,.92,.88)
	material.roughness=.65
	result.material_override=material
	return result
