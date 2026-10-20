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

func read(sentence: String) -> Dictionary:
	var balance := 0
	for symbol in sentence:
		if symbol == "[": balance += 1
		if symbol == "]": balance -= 1
		if balance < 0: return {"accepted": false}
	if balance != 0: return {"accepted": false}
	var state := {"pos": Vector2.ZERO, "heading": Vector2.UP}
	var stack: Array[Dictionary] = []
	var segments: Array = []
	var rooms: Array[Vector2] = []
	for symbol in sentence:
		match symbol:
			"F":
				var next: Vector2 = state.pos + state.heading * 4.0
				segments.append([state.pos, next])
				state.pos = next
			"R": rooms.append(state.pos)
			"+": state.heading = Vector2(-state.heading.y, state.heading.x)
			"-": state.heading = Vector2(state.heading.y, -state.heading.x)
			"[": stack.append(state.duplicate(true))
			"]": state = stack.pop_back()
	return {"accepted": true, "segments": segments, "rooms": rooms}
