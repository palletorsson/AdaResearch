extends RefCounted
## Retained draws, then geometry. Rhino XY becomes Godot XZ; Godot Y is up.
const KINDS := ["columns", "spheres", "lattice", "tree"]
const DRAW_COUNT := 4096
var values: Array[float] = []
var draws: Array[int] = []

func reseed(value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	var record: Array[int]=[]
	for i in DRAW_COUNT: record.append(rng.randi())
	set_draws(record)

func set_draws(record: Array) -> void:
	draws.clear();values.clear()
	for value in record:
		draws.append(int(value))
		values.append(float(value)/4294967296.0)

func geometry(kind: String, amount: float, target: int = 2, probability: float = 0.4) -> Dictionary:
	assert(values.size() == DRAW_COUNT)
	var data := {"rods":[], "balls":[], "points":[], "edges":[]}
	var strength := clampf(amount,0.0,1.0)
	match kind:
		"columns":
			for z in 10:
				for x in 10:
					var i := z*10+x
					var h := lerpf(0.32,lerpf(0.06,0.82,values[2*i]),strength if target!=1 else 0.0)
					var r := lerpf(0.032,lerpf(0.012,0.047,values[2*i+1]),strength if target!=0 else 0.0)
					var p := Vector3((x-4.5)*0.108,0.0,(z-4.5)*0.108)
					data.rods.append({"a":p,"b":p+Vector3.UP*h,"r":r})
		"spheres":
			for z in 10:
				for x in 10:
					var i := z*10+x
					var p := Vector3((x-4.5)*0.108,0.07+strength*0.6*values[i],(z-4.5)*0.108)
					data.balls.append({"p":p,"r":0.07}) # Deliberately overlapping, as in the source.
		"lattice":
			for level in 4:
				for z in 7:
					for x in 7:
						var i := level*49+z*7+x
						var jitter := Vector3(values[3*i]-0.5,values[3*i+1]-0.5,values[3*i+2]-0.5)*0.09*strength
						if level==0: jitter=Vector3.ZERO
						data.points.append(Vector3((x-3)*0.16,0.025+level*0.28,(z-3)*0.16)+jitter)
			var choice := 1024
			for level in 3:
				for z in 7:
					for x in 7:
						var a := level*49+z*7+x
						add_edge(data,a,a+49,0.006)
						for dz in range(-1,2):
							for dx in range(-1,2):
								if dx==0 and dz==0: continue
								var nx := x+dx
								var nz := z+dz
								if nx<0 or nx>=7 or nz<0 or nz>=7: continue
								if values[choice]<clampf(probability,0.0,1.0):
									add_edge(data,a,(level+1)*49+nz*7+nx,0.004)
								choice+=1
			for p in data.points: data.balls.append({"p":p,"r":0.012})
		"tree":
			data.points=[Vector3(0,0.02,0),Vector3(0,0.25,0)]
			add_edge(data,0,1,0.028)
			branch(data,1,2,strength)
	return data

func add_edge(data: Dictionary, a: int, b: int, radius: float) -> void:
	data.edges.append(Vector2i(a,b))
	data.rods.append({"a":data.points[a],"b":data.points[b],"r":radius})

func branch(data: Dictionary, parent: int, level: int, strength: float) -> void:
	for child in 3:
		var id: int=data.points.size()
		var angle := child*TAU/3.0+parent*0.61
		var reach := 0.19*pow(0.78,level-2)
		var offset := Vector3(cos(angle)*reach,0.23,sin(angle)*reach)
		offset+=Vector3(values[2000+3*id]-0.5,(values[2001+3*id]-0.5)*0.45,values[2002+3*id]-0.5)*0.22*strength
		data.points.append(data.points[parent]+offset)
		add_edge(data,parent,id,0.028*pow(0.68,level-1))
		if level<4: branch(data,id,level+1,strength)
		else: data.balls.append({"p":data.points[id],"r":0.03})
