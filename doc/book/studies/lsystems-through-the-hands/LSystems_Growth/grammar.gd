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

func read(sentence: String, ratio: float) -> Dictionary:
	# Check bracket pairs before accepting any drawing.
	var balance := 0
	for symbol in sentence:
		if symbol == "[": balance += 1
		if symbol == "]": balance -= 1
		if balance < 0:
			return {"accepted": false, "error": "Closing bracket has no saved state."}
	if balance != 0:
		return {"accepted": false, "error": "An opening bracket has no return."}
	var state := {"pos": Vector3.ZERO, "heading": Vector3.UP,
		"length": 0.8, "angle": 40.0, "depth": 0}
	var stack: Array[Dictionary] = []
	var ends: Array[Vector3] = []
	var frames: Array[Dictionary] = []
	frames.append(record(state, "START", 0, 0))
	for symbol in sentence:
		match symbol:
			"F", "G":
				ends.append(state.pos)
				state.pos += state.heading * state.length
				ends.append(state.pos)
			"f": state.pos += state.heading * state.length
			"+", "-":
				var sign := 1.0 if symbol == "+" else -1.0
				state.heading = state.heading.rotated(Vector3.FORWARD, deg_to_rad(state.angle) * sign).normalized()
			"[":
				stack.append(state.duplicate(true))
				state.depth += 1
				state.length *= ratio
				state.angle *= 0.95
			"]": state = stack.pop_back()
		frames.append(record(state, symbol, stack.size(), ends.size() / 2))
	return {"accepted": true, "frames": frames, "ends": ends}

func record(state: Dictionary, symbol: String, count: int, segments: int) -> Dictionary:
	var frame := state.duplicate(true)
	frame.merge({"symbol": symbol, "stack_depth": count, "segments": segments})
	return frame
