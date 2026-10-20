extends RefCounted
const SYMBOL_LIMIT := 4096
const STRIDE := 0.32

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

func direction(heading: Vector3, sideways: bool) -> Vector3:
	return Vector3(-heading.y, heading.x, 0) if sideways else heading

func read(sentence: String, angle: float, sideways: bool) -> Dictionary:
	var balance := 0
	for symbol in sentence:
		if symbol == "[": balance += 1
		if symbol == "]": balance -= 1
		if balance < 0:
			return {"accepted": false, "error": "Closing bracket has no saved state."}
	if balance != 0:
		return {"accepted": false, "error": "An opening bracket has no return."}
	var state := {"pos": Vector3.ZERO, "heading": Vector3.UP}
	var stack: Array[Dictionary] = []
	var ends: Array[Vector3] = []
	var frames: Array[Dictionary] = []
	frames.append(record(state, "START", 0, 0, sideways))
	for symbol in sentence:
		match symbol:
			"F":
				ends.append(state.pos)
				state.pos += direction(state.heading, sideways) * STRIDE
				ends.append(state.pos)
			"+", "-":
				var sign := 1.0 if symbol == "+" else -1.0
				state.heading = state.heading.rotated(Vector3.BACK, deg_to_rad(angle) * sign).normalized()
			"[": stack.append(state.duplicate(true))
			"]": state = stack.pop_back()
		frames.append(record(state, symbol, stack.size(), ends.size() / 2, sideways))
	return {"accepted": true, "frames": frames, "ends": ends}

func record(state: Dictionary, symbol: String, count: int, segments: int, sideways: bool) -> Dictionary:
	var frame := state.duplicate(true)
	frame.merge({"symbol": symbol, "stack_depth": count, "segments": segments,
		"direction": direction(state.heading, sideways)})
	return frame
