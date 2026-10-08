extends RefCounted
## 2D cross-sections stacked along Z. Z is generation, not a third CA neighbour.
const W:int=25
const H:int=15
const G:int=28
const CELL:float=0.4
const DEPTH:float=0.5
var history:Array[PackedByteArray]=[]
var mode:int=0 # same history: straight, bend, breathe; changed history: sine rule
var phase:float=0.0
var reserve:bool=false
var forced_empty:int=0
var occupied:int=0
var birth_thresholds:Array[int]=[]

func generate(which:int=0,phi:float=0.0,keep_route:bool=false) -> void:
	mode=which;phase=phi;reserve=keep_route;history.clear();birth_thresholds.clear();forced_empty=0;occupied=0
	var first:=PackedByteArray();first.resize(W*H)
	for y in range(H):
		for x in range(W):
			var d:float=pow((x-12)/10.5,2)+pow((y-4)/7.5,2)
			first[y*W+x]=int(y==0 or (d>0.40 and d<1.14 and (x*17+y*29+x*y*3)%19>1))
	history.append(first);birth_thresholds.append(-1)
	for g in range(1,G):
		var old:PackedByteArray=history[g-1];var next:=PackedByteArray();next.resize(W*H)
		var birth:int=4+int(floor(2*sin(TAU*g/12.0+phase)+0.5)) if mode==3 else 5
		birth_thresholds.append(birth)
		for y in range(H):
			for x in range(W):
				var n:int=neighbors(old,x,y)
				var value:int=int(n>=(4 if old[y*W+x] else birth))
				if y==0:value=1 # declared, permanent foundation
				if reserve and abs(x-12)<=2 and y>=1 and y<=6:
					forced_empty+=value;value=0
				next[y*W+x]=value
		history.append(next)
	for row:PackedByteArray in history:
		for value:int in row:occupied+=value

func neighbors(row:PackedByteArray,x:int,y:int) -> int:
	var n:int=0
	for yy in range(maxi(0,y-1),mini(H,y+2)):
		for xx in range(maxi(0,x-1),mini(W,x+2)):
			if xx!=x or yy!=y:n+=row[yy*W+xx]
	return n

func solid(x:int,y:int,g:int,layers:int=G) -> bool:
	return x>=0 and x<W and y>=0 and y<H and g>=0 and g<layers and history[g][y*W+x]==1

func warp(p:Vector3) -> Vector3:
	var wave:float=sin(TAU*p.z/(G*DEPTH)+phase)
	if mode==1:return p+Vector3(1.4*wave,0,0)
	if mode==2:return Vector3(p.x*(1.0+0.5*wave),p.y*(1.0+0.25*wave),p.z)
	return p

func centre(z:float) -> Vector3:return warp(Vector3(0,0,z))

func cell_corner(x:int,y:int,g:int) -> Vector3:
	return warp(Vector3((x-W*0.5)*CELL,(y-1)*CELL,g*DEPTH))

func mesh(layers:int=G) -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Quad corners below use mathematical CCW order; emit Godot's clockwise faces.
	# Only the solid/empty boundary is drawn and collided.
	var faces:Array=[
		[Vector3i(-1,0,0),[Vector3i(0,0,0),Vector3i(0,0,1),Vector3i(0,1,1),Vector3i(0,1,0)]],
		[Vector3i(1,0,0),[Vector3i(1,0,1),Vector3i(1,0,0),Vector3i(1,1,0),Vector3i(1,1,1)]],
		[Vector3i(0,-1,0),[Vector3i(0,0,1),Vector3i(0,0,0),Vector3i(1,0,0),Vector3i(1,0,1)]],
		[Vector3i(0,1,0),[Vector3i(0,1,0),Vector3i(0,1,1),Vector3i(1,1,1),Vector3i(1,1,0)]],
		[Vector3i(0,0,-1),[Vector3i(1,0,0),Vector3i(0,0,0),Vector3i(0,1,0),Vector3i(1,1,0)]],
		[Vector3i(0,0,1),[Vector3i(0,0,1),Vector3i(1,0,1),Vector3i(1,1,1),Vector3i(0,1,1)]]]
	for g in range(layers):
		var colour:Color=Color("9bbeb5").lerp(Color("c1a9ce"),float(g)/float(G-1))
		if g%4==0:colour=colour.darkened(0.2)
		for y in range(H):
			for x in range(W):
				if not solid(x,y,g,layers):continue
				for face in faces:
					var offset:Vector3i=face[0]
					if solid(x+offset.x,y+offset.y,g+offset.z,layers):continue
					for i:int in [0,2,1,0,3,2]:
						var q:Vector3i=face[1][i];st.set_color(colour);st.add_vertex(cell_corner(x+q.x,y+q.y,g+q.z))
	st.generate_normals();return st.commit()

func report() -> Dictionary:
	var changed:Array[int]=[];var blocked:Array[int]=[]
	for g in range(G):
		var delta:int=0
		if g>0:
			for i in range(W*H):delta+=int(history[g][i]!=history[g-1][i])
		changed.append(delta)
		# Discrete centre column only; body clearance is established separately in physics.
		if solid(12,4,g) or solid(12,3,g) or solid(12,2,g) or solid(12,1,g):blocked.append(g)
	return {"mode":mode,"phase":phase,"reserve":reserve,"occupied":occupied,"forced_empty":forced_empty,"thresholds":birth_thresholds.duplicate(),"changed":changed,"blocked_centre_sections":blocked}
