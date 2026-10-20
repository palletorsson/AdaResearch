extends RefCounted
const TARGETS := [8.0, 16.0, 32.0]

static func opening() -> Array:
	var candidates: Array=[]
	for i in 6:
		var size: float=[0.7,1.0,1.25,1.5,1.75,2.0][i]
		candidates.append({"id":i,"genes":[{"type":"box",
			"position":Vector3(0,size/2,0),"rotation":Vector3.ZERO,"scale":Vector3.ONE*size}]})
	return candidates

static func estimate(candidate: Dictionary) -> float:
	var total:=0.0
	for gene in candidate.genes:
		var s: Vector3=gene.scale
		match gene.type:
			"sphere": total+=(4.0/3.0)*PI*s.x*s.y*s.z
			"box": total+=s.x*s.y*s.z*8.0
			"cylinder": total+=PI*s.x*s.z*s.y*2.0
	# This reproduces the museum's proxy, including its omitted torus.
	return total

static func score(candidate: Dictionary, target: float) -> float:
	return 100.0/(1.0+abs(estimate(candidate)-target))

static func rank(candidates: Array, target: float) -> Array:
	# Sort references in a NEW list. Do not reorder or edit the input list.
	var ordered: Array=candidates.duplicate()
	ordered.sort_custom(func(a,b):
		var sa: float=score(a,target);var sb: float=score(b,target)
		return a.id<b.id if sa==sb else sa>sb)
	return ordered

static func toggle_ring(candidate: Dictionary) -> void:
	for i in candidate.genes.size():
		if candidate.genes[i].type=="torus":
			candidate.genes.remove_at(i)
			return
	candidate.genes.append({"type":"torus","position":Vector3(0,1.8,0),
		"rotation":Vector3.ZERO,"scale":Vector3.ONE*1.4})
