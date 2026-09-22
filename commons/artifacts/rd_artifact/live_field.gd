extends RefCounted
## Incremental Gray–Scott, using the existing rd_displace_op five-point stencil.
## Two concentrations, synchronous buffers, periodic edges; no random forcing.
const N:int=32
const FEED:float=0.037
const KILL:float=0.06
var u:=PackedFloat32Array()
var v:=PackedFloat32Array()
var next_u:=PackedFloat32Array()
var next_v:=PackedFloat32Array()
var exchange:bool=true
var ticks:int=0

func _init() -> void:
	u.resize(N*N);v.resize(N*N);next_u.resize(N*N);next_v.resize(N*N)
	reset()

func reset() -> void:
	u.fill(1.0);v.fill(0.0);ticks=0
	# A held square rather than a random batch: same initial values in both fields.
	for y in range(13,19):
		for x in range(13,19):
			u[y*N+x]=0.5;v[y*N+x]=0.25

func inject() -> void:
	# A marked second address; both fields receive the same local intervention.
	for y in range(14,17):
		for x in range(3,6):
			u[y*N+x]=0.5;v[y*N+x]=0.25

func laplacian(a:PackedFloat32Array,x:int,y:int) -> float:
	return a[y*N+(x+N-1)%N]+a[y*N+(x+1)%N]+a[((y+N-1)%N)*N+x]+a[((y+1)%N)*N+x]-4.0*a[y*N+x]

func step() -> void:
	var coupling:float=1.0 if exchange else 0.0
	for y in range(N):
		for x in range(N):
			var i:int=y*N+x
			var a:float=u[i];var b:float=v[i]
			var uvv:float=a*b*b
			var lap_u:float=laplacian(u,x,y) if exchange else 0.0
			var lap_v:float=laplacian(v,x,y) if exchange else 0.0
			next_u[i]=clampf(a+coupling*0.16*lap_u-uvv+FEED*(1.0-a),0.0,1.0)
			next_v[i]=clampf(b+coupling*0.08*lap_v+uvv-(KILL+FEED)*b,0.0,1.0)
	var old_u:PackedFloat32Array=u;u=next_u;next_u=old_u
	var old_v:PackedFloat32Array=v;v=next_v;next_v=old_v
	ticks+=1
