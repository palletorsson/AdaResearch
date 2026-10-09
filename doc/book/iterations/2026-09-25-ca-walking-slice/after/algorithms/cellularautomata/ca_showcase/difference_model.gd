extends RefCounted
## Paired local averaging with the same address-indexed forcing.
## No measured critical point, Lyapunov exponent or rule-table lambda.
const N:int=11
const COUNT:int=N*N*N
const CENTER:int=5+N*5+N*N*5
const LIMIT:int=100
var a:PackedFloat64Array=[]
var b:PackedFloat64Array=[]
var tick:int=0
var coupling:float=0.25
var disturbance:float=1.0
var integer_storage:bool=true
var scattered:bool=true
var changed:bool=true
var history:Array=[]
var neighbours:Array[PackedInt32Array]=[]

func _init() -> void:
	for z in range(N):
		for y in range(N):
			for x in range(N):
				var ns:=PackedInt32Array()
				for dz in range(-1,2):
					for dy in range(-1,2):
						for dx in range(-1,2):
							if dx==0 and dy==0 and dz==0:continue
							var xx:int=x+dx;var yy:int=y+dy;var zz:int=z+dz
							if xx>=0 and xx<N and yy>=0 and yy<N and zz>=0 and zz<N:ns.append(xx+N*yy+N*N*zz)
				neighbours.append(ns)
	reset()

static func sample(i:int,g:int) -> float:
	# A deterministic finite forcing schedule, shared by A and B. Not iid noise.
	var h:int=((i+1)*73856093+(g+1)*19349663+83492791)%2147483647
	h=(h*48271)%2147483647
	return float(h%2001)/1000.0-1.0

func reset() -> void:
	tick=0;a.resize(COUNT)
	for i in range(COUNT):a[i]=float((i*73+i*i*19+17)%10) if scattered else 4.0
	b=a.duplicate()
	if changed:b[CENTER]=a[CENTER]+1.0
	history=[report()]

func step() -> void:
	if tick>=LIMIT:return
	var na:=PackedFloat64Array();var nb:=PackedFloat64Array();na.resize(COUNT);nb.resize(COUNT)
	for i in range(COUNT):
		var sa:float=0.0;var sb:float=0.0
		for j in neighbours[i]:sa+=a[j];sb+=b[j]
		var drive:float=disturbance*sample(i,tick)
		var va:float=clampf(a[i]*(1.0-coupling)+sa/neighbours[i].size()*coupling+drive,0.0,9.0)
		var vb:float=clampf(b[i]*(1.0-coupling)+sb/neighbours[i].size()*coupling+drive,0.0,9.0)
		na[i]=float(int(va)) if integer_storage else va
		nb[i]=float(int(vb)) if integer_storage else vb
	a=na;b=nb;tick+=1;history.append(report())

func report() -> Dictionary:
	var different:int=0;var maximum:float=0;var total:float=0;var ma:float=0;var mb:float=0
	for i in range(a.size()):
		var d:float=absf(a[i]-b[i]);maximum=maxf(maximum,d);total+=d;ma+=a[i];mb+=b[i]
		if d>0.000001:different+=1
	return {"tick":tick,"different":different,"max_difference":maximum,"mean_difference":total/COUNT,"mean_a":ma/COUNT,"mean_b":mb/COUNT,"coupling":coupling,"disturbance":disturbance,"integer_storage":integer_storage,"scattered":scattered,"changed":changed}
