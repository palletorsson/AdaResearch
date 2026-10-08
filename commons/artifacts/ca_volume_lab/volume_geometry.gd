extends RefCounted
## State-to-architecture mappings. Rendered triangles also define real collision.
const Model=preload("res://commons/artifacts/ca_volume_lab/volume_model.gd")
const FACES:Array=[
	[Vector3i(-1,0,0),[Vector3i(0,0,0),Vector3i(0,0,1),Vector3i(0,1,1),Vector3i(0,1,0)]],
	[Vector3i(1,0,0),[Vector3i(1,0,1),Vector3i(1,0,0),Vector3i(1,1,0),Vector3i(1,1,1)]],
	[Vector3i(0,-1,0),[Vector3i(0,0,1),Vector3i(0,0,0),Vector3i(1,0,0),Vector3i(1,0,1)]],
	[Vector3i(0,1,0),[Vector3i(0,1,0),Vector3i(0,1,1),Vector3i(1,1,1),Vector3i(1,1,0)]],
	[Vector3i(0,0,-1),[Vector3i(1,0,0),Vector3i(0,0,0),Vector3i(0,1,0),Vector3i(1,1,0)]],
	[Vector3i(0,0,1),[Vector3i(0,0,1),Vector3i(1,0,1),Vector3i(1,1,1),Vector3i(0,1,1)]]]
var bent:bool=false
var faces:int=0
var bars:int=0
var apertures:int=0
var visible_cells:int=0
var triangles:int=0
var st:SurfaceTool
func warp(p:Vector3) -> Vector3:
	return p+Vector3(1.5*sin(TAU*p.z/(Model.N*Model.CELL)),0,0) if bent else p
func point(p:Vector3i) -> Vector3:return Vector3((p.x-Model.N*0.5)*Model.CELL,p.y*Model.CELL,p.z*Model.CELL)
func triangle(a:Vector3,b:Vector3,c:Vector3,colour:Color) -> void:
	for p:Vector3 in [a,c,b]:st.set_color(colour);st.add_vertex(warp(p))
	triangles+=1
func quad(q:Array,colour:Color) -> void:
	triangle(q[0],q[1],q[2],colour);triangle(q[0],q[2],q[3],colour)
func beam(a:Vector3,b:Vector3) -> void:
	var lo:Vector3=a.min(b)-Vector3.ONE*0.04;var hi:Vector3=a.max(b)+Vector3.ONE*0.04
	for face in FACES:
		var q:Array=[]
		for v:Vector3i in face[1]:q.append(Vector3(hi.x if v.x else lo.x,hi.y if v.y else lo.y,hi.z if v.z else lo.z))
		quad(q,Color("d985aa"))
func build(model:RefCounted,view:int=0,bend:bool=false,cut:bool=false) -> ArrayMesh:
	bent=bend;faces=0;bars=0;apertures=0;visible_cells=0;triangles=0;st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges:Dictionary={}
	for z in range(Model.N):
		for y in range(Model.N):
			for x in range(Model.N):
				if not included(model,x,y,z,cut):continue
				visible_cells+=1
				for face in FACES:
					var d:Vector3i=face[0]
					if included(model,x+d.x,y+d.y,z+d.z,cut):continue
					faces+=1;var corners:Array=[];var q:Array=[]
					for v:Vector3i in face[1]:corners.append(Vector3i(x,y,z)+v);q.append(point(corners[-1]))
					var colour:Color=Color("dedbd0").lerp(Color("9ebdaf"),float(y)/Model.N)
					if view==0:quad(q,colour);continue
					for i in range(4):
						var a:Vector3i=corners[i];var b:Vector3i=corners[(i+1)%4]
						var ia:int=(a.z*(Model.N+1)+a.y)*(Model.N+1)+a.x;var ib:int=(b.z*(Model.N+1)+b.y)*(Model.N+1)+b.x
						var key:Vector2i=Vector2i(mini(ia,ib),maxi(ia,ib))
						edges[key]=[q[i],q[(i+1)%4]]
					if view==2:
						# One third of side faces are deliberate apertures. Horizontal faces retain panels.
						if d.y==0 and (x+y+z)%3==0:apertures+=1;continue
						var centre:Vector3=(q[0]+q[1]+q[2]+q[3])*0.25+Vector3(d)*0.18
						for i in range(4):triangle(q[i],q[(i+1)%4],centre,colour if (x+y+z)%2==0 else Color("706099"))
	for edge in edges.values():beam(edge[0],edge[1]);bars+=1
	if triangles==0:return null
	st.generate_normals();return st.commit()
func included(model:RefCounted,x:int,y:int,z:int,cut:bool) -> bool:
	return bool(model.at(x,y,z)) and (not cut or x>=6)
