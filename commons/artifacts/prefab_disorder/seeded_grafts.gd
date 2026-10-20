extends RefCounted
## Seeded recombination, with small recognisable bundles as the joining units.
## Four display pads are fixed; membership, attachment order and turns are not.
const VERSION="seeded-grafts/2"
const Codec=preload("hybrid_recipe.gd")
const BUNDLES=[
	[["BottomPanel","FrontWall","BackWall","LeftWall","RightWall"],["FrontFlap"],["BackFlap"],["LeftFlap","RightFlap"]],
	[["StandBase","PivotNeck"],["FrontCasing","Bezel*","Screen","PowerLED","Button_*"],["TubeHousingNear"],["TubeHousingFar"]],
	[["Hub","Leg_*","Foot_*"],["Post"],["Seat","AccentStrip"]],
	[["Base","Column","AccentStrip"],["Stage","Clamp_*","Illuminator"],["TurretDisc","Objective_*"],["Eyepiece_*"]]
]
const DIRECTIONS=[Vector3.UP,Vector3.UP,Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]

func build(parts: Array[Dictionary], inventory: Array[Dictionary], side: float, seed_value: int) -> Array[Dictionary]:
	# Separate stream: changing this grammar cannot consume the separation draws.
	var rng:=RandomNumberGenerator.new()
	rng.seed=(str(seed_value)+"|"+VERSION).sha256_text().substr(0,15).hex_to_int()
	var groups: Array=[[],[],[],[]]
	var used: Dictionary={}
	for item in BUNDLES.size():
		var slots: Array=[0,1,2,3];shuffle(slots,rng)
		for b in BUNDLES[item].size():
			var indices: Array=[]
			for i in parts.size():
				if parts[i].item!=item: continue
				for pattern in BUNDLES[item][b]:
					if not String(parts[i].label).match(pattern): continue
					assert(not used.has(i),"Each mesh must join exactly one bundle")
					used[i]=true;indices.append(i);break
			assert(not indices.is_empty(),"Missing source bundle")
			groups[slots[b]].append(indices)
	assert(used.size()==parts.size(),"Every source mesh must enter a hybrid")
	var result: Array[Dictionary]=[];result.resize(parts.size())
	for group in groups.size():
		shuffle(groups[group],rng)
		var placed: Array[AABB]=[]
		var poses: Dictionary={}
		for indices in groups[group]:
			var turn:=Basis(Vector3.UP,rng.randi_range(0,3)*PI/2)
			if rng.randf()<0.4:
				turn=turn*Basis(Vector3.RIGHT if rng.randf()<0.5 else Vector3.FORWARD,PI/2)
			var rotated:=Transform3D(turn,Vector3.ZERO)
			var bounds: AABB=rotated*parts[indices[0]].home*parts[indices[0]].bounds
			for i in indices: bounds=bounds.merge(rotated*parts[i].home*parts[i].bounds)
			var offset: Vector3=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
			if not placed.is_empty(): offset=join_offset(bounds,placed,rng)
			var transform:=Transform3D(turn,offset)
			for i in indices: poses[i]=transform*parts[i].home
			placed.append(AABB(bounds.position+offset,bounds.size))
		var total: AABB=placed[0]
		for bounds in placed: total=total.merge(bounds)
		var factor:=0.55/maxf(total.size.x,maxf(total.size.y,total.size.z))
		var home: Vector3=inventory[group].grid+Vector3(side,0,0)
		var shift:=Vector3(-total.get_center().x,-total.position.y,-total.get_center().z)*factor
		var fit:=Transform3D(Basis.from_scale(Vector3.ONE*factor),home+shift)
		for i in poses:
			result[i]={"item":parts[i].item,"key":parts[i].key,"group":group,"pose":Codec.pack(fit*poses[i])}
	return result

func join_offset(bounds: AABB, placed: Array[AABB], rng: RandomNumberGenerator) -> Vector3:
	# Try joining a bounding face with a small lateral offset. Retain the first
	# non-overlapping placement. This is a geometric grammar, not a joint solver.
	for attempt in 16:
		var parent: AABB=placed[rng.randi_range(0,placed.size()-1)]
		var direction: Vector3=DIRECTIONS[rng.randi_range(0,DIRECTIONS.size()-1)]
		var jitter:=Vector3(rng.randf_range(-0.15,0.15),rng.randf_range(-0.15,0.15),rng.randf_range(-0.15,0.15))
		jitter*=parent.size.min(bounds.size)*(Vector3.ONE-direction.abs())
		var center:=parent.get_center()+direction*(parent.size+bounds.size)*0.5+jitter
		var candidate:=AABB(center-bounds.size*0.5,bounds.size)
		var clear:=true
		for other in placed:
			if candidate.intersection(other).get_volume()>0.0000001: clear=false;break
		if clear: return center-bounds.get_center()
	# Crowded joins fall back to the topmost supporting bundle, deterministically.
	var top:=placed[0]
	for other in placed:
		if other.end.y>top.end.y: top=other
	return Vector3(top.get_center().x,top.end.y+bounds.size.y/2,top.get_center().z)-bounds.get_center()

func shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size()-1,0,-1):
		var j:=rng.randi_range(0,i);var value=values[i];values[i]=values[j];values[j]=value
