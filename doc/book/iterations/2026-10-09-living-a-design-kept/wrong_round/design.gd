extends RefCounted
const SYMBOL_LIMIT := 32768
const DRAW_LIMIT := 200

func parameters(record: Dictionary) -> Dictionary:
	return {"generations": clampi(floori(float(record.depth) * 0.5), 2, 5),
		"forks": clampi(roundi(float(record.forks)), 2, 5),
		"angle": clampf(float(record.angle), 15, 90)}

func rules_for(forks: int) -> Dictionary:
	var replacement := "S"
	for i in forks:
		var turn := "+" if i % 2 == 0 else "-"
		replacement += "[" + turn + "/".repeat(i / 2) + "F]"
	return {"F": replacement, "S": "FF"}

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

func build(record: Dictionary) -> Dictionary:
	var params := parameters(record)
	var rules := rules_for(params.forks)
	var sentence := "F"
	for generation in params.generations:
		var result := rewrite(sentence, rules)
		if not result.accepted:
			return {"accepted": false, "error": "Symbol budget refused this generation."}
		sentence = result.text
	var reading := read(sentence, params.angle)
	reading.merge({"accepted": true, "parameters": params, "sentence": sentence,
		"requested": sentence.count("F") + sentence.count("S")})
	return reading

func read(sentence: String, angle: float) -> Dictionary:
	# The bare, opposite-arranged subset of TreeMorphology's turtle.
	# Fixed inputs: step1.2m, taper.68, no droop, twist, leaves or roots.
	var state := {"pos": Vector3.ZERO, "dir": Vector3.UP,
		"right": Vector3.RIGHT, "up": Vector3.BACK, "length": 1.2}
	var stack: Array[Dictionary] = []
	var ends: Array[Vector3] = []
	var commands := 0
	var radians := deg_to_rad(angle)
	for symbol in sentence:
		if commands >= DRAW_LIMIT: break
		match symbol:
			"F", "S":
				var distance: float = state.length * (0.6 if symbol == "S" else 1.0)
				var finish: Vector3 = state.pos + state.dir * distance
				if distance >= 0.001:
					ends.append(state.pos); ends.append(finish)
				state.pos = finish
				if symbol == "F": state.length *= 0.68
				commands += 1
			"+", "-":
				var sign := 1.0 if symbol == "+" else -1.0
				state.dir = (state.dir * cos(radians) + state.right * sin(radians) * sign).normalized()
				state.right = state.dir.cross(state.up).normalized()
			"/":
				state.right = (state.right * cos(radians) + state.up * sin(radians)).normalized()
				state.up = state.right.cross(state.dir).normalized()
			"[": stack.append(state.duplicate(true))
			"]": state = stack.pop_back()
	return {"ends": ends, "drawn_commands": commands}
