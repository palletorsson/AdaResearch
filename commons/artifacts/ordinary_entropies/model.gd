extends RefCounted
## Explicit finite models. Visual irregularity is never used as an entropy value.
static func shannon(counts: Array) -> float:
	var total: float=0.0
	for c in counts: total+=float(c)
	var result:=0.0
	for c in counts:
		if c>0:
			var p: float=float(c)/total
			result-=p*log(p)/log(2.0)
	return result

static func choose(n: int,k: int) -> int:
	var result:=1
	for i in range(1,k+1): result=result*(n-i+1)/i
	return result

static func multiplicity(k: int) -> int:
	return choose(4,k)*choose(4,4-k)

static func door_step(x: float, expanding: bool) -> float:
	return fposmod(2*x,1.0) if expanding else x*0.5

static func word_entropy(n: int, expanding: bool) -> float:
	# 1024 equiprobable midpoint starts. Record entropy saturates at 10 bits.
	var counts: Dictionary={}
	for i in 1024:
		var x: float=(i+0.5)/1024.0
		var word:=0
		for j in n:
			word=word*2+int(x>=0.5)
			x=door_step(x,expanding)
		counts[word]=counts.get(word,0)+1
	return shannon(counts.values())

static func thermal(seconds: float) -> Dictionary:
	# Two finite, internally uniform bodies; constant heat capacities, no phase change.
	var equilibrium: float=(400.0*353.0+4000.0*293.0)/4400.0
	var difference: float=60.0*exp(-seconds/15.0)
	var hot: float=equilibrium+difference*4000.0/4400.0
	var cold: float=equilibrium-difference*400.0/4400.0
	var ds_hot: float=400.0*log(hot/353.0)
	var ds_cold: float=4000.0*log(cold/293.0)
	return {"hot":hot,"cold":cold,"hot_entropy":ds_hot,"cold_entropy":ds_cold,"total":ds_hot+ds_cold,"energy":400.0*hot+4000.0*cold}

static func conditional(mode: int) -> float:
	# Eight equally likely identities: colour, arms, lower back rail (three bits).
	# Mode 3 additionally retains colour + arms; old modes keep their receipt meaning.
	var joint: Dictionary={}
	for x in 8:
		var y: int=x if mode==0 else (x/4 if mode==1 else (2*(x/4)+(x%2) if mode==3 else 0))
		joint[y]=joint.get(y,0)+1
	return 3.0-shannon(joint.values())

static func pit_weights(mode: int) -> Array:
	var result: Array=[]
	for i in 16: result.append(15.0 if mode==2 and i==15 else 1.0)
	return result

static func pit_probabilities(mode: int) -> Array:
	if mode==1: return [15.0/16.0,1.0/16.0]
	var weights:=pit_weights(mode)
	var total: float=30.0 if mode==2 else 16.0
	return weights.map(func(w):return w/total)

static func min_entropy(probabilities: Array) -> float:
	return -log(float(probabilities.max()))/log(2.0)

static func chairs(seed_value: int, group: int) -> Array[Transform3D]:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var result: Array[Transform3D]=[]
	var motif: Array=[]
	for i in 3: motif.append(Vector3(rng.randf_range(-0.22,0.22),0,rng.randf_range(-0.23,0.23)))
	for i in 6:
		var p:=Vector3((i%3-1)*0.88,0,(i/3-0.5)*1.05)
		var angle:=0.0
		if group==1 and i==4: p.z+=0.32;angle=0.45
		if group==2: p+=motif[i%3];angle=[-0.35,0.35,0.0][i%3]
		if group==3:
			p+=Vector3(rng.randf_range(-0.22,0.22),0,rng.randf_range(-0.28,0.28));angle=rng.randf_range(-1.1,1.1)
		result.append(Transform3D(Basis(Vector3.UP,angle),p))
	return result
