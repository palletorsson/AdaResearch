extends RefCounted
## Uniform selection of a stable chair ID. Entropies describe the declared category.
const Model = preload("model.gd")
const CATEGORY_NAMES = ["PINK", "BLACK", "BLACK + ARMS"]
var baseline: Array = [8,8,0]
var categories: Array = []
var rng := RandomNumberGenerator.new()
var guess := -1
var selected := -1
var draws := 0

func _init() -> void: reset()

func configure(counts: Array) -> void:
	assert(valid_counts(counts))
	baseline=counts.duplicate()
	reset()

func reset() -> void:
	categories.clear()
	for category in 3:
		for i in int(baseline[category]): categories.append(category)
	rng.seed=435
	guess=-1;selected=-1;draws=0

static func valid_counts(counts: Variant) -> bool:
	if not counts is Array or counts.size()!=3:return false
	var total:=0
	for n in counts:
		if not (n is int or n is float) or not is_finite(n) or n!=int(n) or n<0 or n>16:return false
		total+=int(n)
	return total==16

func counts() -> Array:
	var result: Array=[0,0,0]
	for category in categories:result[int(category)]+=1
	return result

func readings() -> Dictionary:
	var inventory:=counts()
	var best: float=float(inventory.max())/16
	return {"counts":inventory,"best":best,"min":maxf(0.0,-log(best)/log(2.0)),"shannon":Model.shannon(inventory),"colour_shannon":Model.shannon([inventory[0],inventory[1]+inventory[2]])}

func choose(category: int) -> void:
	if category>=0 and category<3:guess=category;selected=-1

func draw() -> bool:
	if guess<0:return false
	selected=rng.randi_range(0,15)
	draws+=1
	return true

func change_one() -> bool:
	for i in range(15,-1,-1):
		if categories[i]!=0:
			categories[i]=0;selected=-1;guess=-1
			return true
	return false

func capture() -> Dictionary:
	return {"schema":"chair-guess/1","baseline":baseline.duplicate(),"categories":categories.duplicate(),"guess":guess,"selected":selected,"draws":draws,"rng_state":str(rng.state),"seed":"435","draw":"uniform-chair-id-with-replacement","record":"colour-and-arms"}

func restore(record: Variant) -> bool:
	if not record is Dictionary or record.get("schema")!="chair-guess/1":return false
	if record.get("draw")!="uniform-chair-id-with-replacement" or record.get("record")!="colour-and-arms" or record.get("seed")!="435":return false
	if not valid_counts(record.get("baseline")):return false
	var ids: Variant=record.get("categories")
	if not ids is Array or ids.size()!=16:return false
	for id in ids:
		if not (id is int or id is float) or not is_finite(id) or id!=int(id) or id<0 or id>2:return false
	for key in ["guess","selected","draws"]:
		var n: Variant=record.get(key)
		if not (n is int or n is float) or not is_finite(n) or n!=int(n):return false
	if record.guess< -1 or record.guess>2 or record.selected< -1 or record.selected>15 or record.draws<0:return false
	var state: Variant=record.get("rng_state")
	if not state is String or not state.is_valid_int() or str(int(state))!=state:return false
	baseline=record.baseline.map(func(n):return int(n));categories=ids.map(func(n):return int(n));guess=int(record.guess);selected=int(record.selected);draws=int(record.draws)
	rng.seed=435;rng.state=int(state)
	return true
