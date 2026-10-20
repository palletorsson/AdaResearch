extends RefCounted
const SYMBOL_LIMIT := 4096

func rewrite(sentence: String, rules: Dictionary) -> Dictionary:
	var size := 0
	for symbol in sentence:
		size += str(rules.get(symbol, symbol)).length()
		if size > SYMBOL_LIMIT:
			return {"accepted": false, "text": sentence}
	var next := ""
	for symbol in sentence:
		next += str(rules.get(symbol, symbol))
	return {"accepted": true, "text": next}

func read(sentence: String, angle: float) -> Array[Vector3]:
	var ends: Array[Vector3] = []
	var position := Vector3.ZERO
	var heading := Vector3.UP
	for symbol in sentence:
		match symbol:
			"F", "G":
				ends.append(position)
				position += heading
				ends.append(position)
			"f": position += heading
			"+": heading = heading.rotated(Vector3.FORWARD, -deg_to_rad(angle))
			"-": heading = heading.rotated(Vector3.FORWARD, deg_to_rad(angle))
			"[", "]": assert(false, "Branch states belong to the next lesson.")
	return ends
