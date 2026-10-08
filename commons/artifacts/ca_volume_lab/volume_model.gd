extends RefCounted
## Genuine synchronous 3D CA. Flattened index is (z*N+y)*N+x; time is separate.
const N:int=13
const CELL:float=2.0
const LIMIT:int=16
var state:PackedByteArray=PackedByteArray()
var seed_id:int=0
var rule:int=0
var sine:bool=false
var generation:int=0
var births:int=0
var deaths:int=0
var history_counts:Array[int]=[]

func index(x:int,y:int,z:int) -> int:return (z*N+y)*N+x
func at(x:int,y:int,z:int) -> int:
	return int(state[index(x,y,z)]) if x>=0 and y>=0 and z>=0 and x<N and y<N and z<N else 0
func reset(which:int=0,which_rule:int=0,with_sine:bool=false) -> void:
	seed_id=which;rule=which_rule;sine=with_sine;generation=0;births=0;deaths=0
	state.resize(N*N*N);state.fill(0)
	for z in range(N):
		for y in range(N):
			for x in range(N):
				var active:bool=false
				if which==0:active=abs(x-6)<=1 and y<=2 and abs(z-6)<=1
				elif which==1:active=x>=2 and x<=10 and y<=8 and z>=2 and z<=10 and (x*73+y*151+z*199+x*y*17+y*z*23+x*z*29)%101<38
				else:active=(abs(x-3)<=1 or abs(x-9)<=1) and y<=2 and abs(z-6)<=1
				state[index(x,y,z)]=int(active)
	history_counts=[occupied()]
func occupied() -> int:
	var n:int=0
	for v:int in state:n+=v
	return n
func step() -> bool:
	if generation>=LIMIT:return false
	# Scatter from the frozen previous state into 26 spatial neighbours.
	var counts:=PackedByteArray();counts.resize(N*N*N);counts.fill(0)
	for z in range(N):
		for y in range(N):
			for x in range(N):
				if at(x,y,z)==0:continue
				for zz in range(maxi(0,z-1),mini(N,z+2)):
					for yy in range(maxi(0,y-1),mini(N,y+2)):
						for xx in range(maxi(0,x-1),mini(N,x+2)):
							if xx!=x or yy!=y or zz!=z:counts[index(xx,yy,zz)]+=1
	var next:=PackedByteArray();next.resize(N*N*N);births=0;deaths=0
	for z in range(N):
		for y in range(N):
			var shift:int=int(floor(2*sin(TAU*y/N+generation*PI/4)+0.5)) if sine else 0
			for x in range(N):
				var i:int=index(x,y,z);var n:int=counts[i]
				var alive:bool=n>=4 and (rule==0 or n<=7) if state[i] else n==(4 if rule==0 else 5)+shift
				next[i]=int(alive)
				births+=int(alive and state[i]==0);deaths+=int(not alive and state[i]==1)
	state=next;generation+=1;history_counts.append(occupied());return true
func report() -> Dictionary:
	# Components use face adjacency, separately from the CA's 26-neighbour update.
	var visited:=PackedByteArray();visited.resize(state.size());visited.fill(0)
	var components:int=0;var largest:int=0;var boundary:int=0
	for z in range(N):
		for y in range(N):
			for x in range(N):
				var i:int=index(x,y,z)
				if not state[i]:continue
				if x==0 or x==N-1 or y==0 or y==N-1 or z==0 or z==N-1:boundary+=1
				if visited[i]:continue
				components+=1;var size:int=0;var stack:Array[Vector3i]=[Vector3i(x,y,z)];visited[i]=1
				while not stack.is_empty():
					var p:Vector3i=stack.pop_back();size+=1
					for d:Vector3i in [Vector3i.LEFT,Vector3i.RIGHT,Vector3i.UP,Vector3i.DOWN,Vector3i(0,0,1),Vector3i(0,0,-1)]:
						var q:Vector3i=p+d
						if at(q.x,q.y,q.z) and not visited[index(q.x,q.y,q.z)]:visited[index(q.x,q.y,q.z)]=1;stack.append(q)
				largest=maxi(largest,size)
	return {"seed":seed_id,"rule":rule,"sine":sine,"generation":generation,"occupied":occupied(),"births":births,"deaths":deaths,"counts":history_counts.duplicate(),"components_6":components,"largest_component":largest,"boundary_cells":boundary}
