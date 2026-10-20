extends RefCounted
const N := 12
const START_SEED := 1010
const ALPHABETS := ["diagonals", "orthogonals", "blocks"]
const ODDS := [0.5, 0.75, 1.0, 0.0, 0.25]
var rng := RandomNumberGenerator.new()
var data := {"seed":START_SEED, "odds":0.5, "alphabet":"diagonals", "rows":[]}

func _init() -> void:
	reset()

func new_row() -> Array:
	var row: Array=[]
	for c in N:
		# Keep both draws: the museum also draws a tint after each sample.
		var sample:=rng.randf()
		var tint:=rng.randf()
		row.append({"sample":sample, "tint":tint})
	return row

func new_sheet(seed_value: int) -> void:
	rng.seed=seed_value
	data.seed=seed_value
	data.rows=[]
	# Index zero is the oldest, bottom row.
	for r in N: data.rows.append(new_row())

func reset() -> void:
	data.odds=0.5; data.alphabet="diagonals"
	new_sheet(START_SEED)

func step() -> void:
	data.rows.pop_front()
	data.rows.append(new_row())

func keep() -> Dictionary:
	return data.duplicate(true)

static func choices(record: Dictionary) -> Array:
	var result: Array=[]
	for row in record.rows:
		var bits: Array=[]
		for cell in row: bits.append(cell.sample < record.odds)
		result.append(bits)
	return result

static func glyph(a: bool, alphabet: String) -> Dictionary:
	var width:=1.0/N
	if alphabet=="blocks":
		var amount:=0.3 if a else 0.9
		return {"size":Vector3(width*amount,0.07*amount,0.03), "angle":0.0}
	var angle: float=(PI/4 if a else -PI/4)
	if alphabet=="orthogonals": angle=0.0 if a else PI/2
	return {"size":Vector3(width*0.9,0.07*0.42,0.03), "angle":angle}
