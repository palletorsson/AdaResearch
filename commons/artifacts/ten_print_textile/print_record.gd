extends RefCounted
## A printed cloth record, deliberately separate from a Jacquard crossing record.
## Geometry, the fitting and the wardrobe all read these same retained samples.
const TITLES := ["RIBBON", "STITCH", "PIXEL"]
const PALETTES := [
	["25213b", "ed91be", "d9dfb4"],
	["183e48", "f6b775", "e6e7d8"],
	["f0dfd8", "713854", "307b83"],
]

static func make(seed_value: int = 41) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var samples: Array = []
	# Retain integers so JSON and the wardrobe's ConfigFile replay them exactly.
	for i in range(252): samples.append(rng.randi_range(0,65535))
	return {"version":2,"kind":"ten_print","name":"10 PRINT / RIBBON", "seed":seed_value,
		"columns":14,"rows":18,"samples":samples,"mark":0,"palette":0,"repeat":1}

static func valid(data: Dictionary) -> bool:
	if data.get("version") != 2 or data.get("kind") != "ten_print": return false
	for key in ["columns","rows","mark","palette","repeat","seed"]:
		if not (data.get(key) is int or data.get(key) is float): return false
		if not is_finite(float(data[key])) or float(data[key]) != floorf(float(data[key])): return false
	if int(data.columns) != 14 or int(data.rows) != 18: return false
	if int(data.mark) < 0 or int(data.mark) >= TITLES.size(): return false
	if int(data.palette) < 0 or int(data.palette) >= PALETTES.size(): return false
	if int(data.repeat) < 1 or int(data.repeat) > 3: return false
	if not data.get("samples") is Array or data.samples.size() != 252: return false
	for v in data.samples:
		if not (v is float or v is int) or not is_finite(float(v)) or v < 0 or v > 65535 or float(v)!=floorf(float(v)): return false
	return true

static func image(data: Dictionary) -> Image:
	var cell := 24
	var result := Image.create(14*cell,18*cell,false,Image.FORMAT_RGB8)
	var colors: Array = PALETTES[int(data.palette)]
	var ground := Color(colors[0])
	for row in range(18):
		for col in range(14):
			var slash: bool = int(data.samples[row*14+col]) < 32768
			var ink := Color(colors[1] if slash else colors[2])
			for py in range(cell):
				for px in range(cell):
					var x := (px+.5)/cell
					var y := (py+.5)/cell
					var coverage := 0.0
					match int(data.mark):
						0:
							var d := absf(x-y if slash else x+y-1.0)
							# Two slim rails leave a visible thread of ground between them.
							coverage = 1.0-smoothstep(.055,.10,absf(d-.13))
						1:
							var d := absf(y-.5) if slash else absf(x-.5)
							coverage = (1.0-smoothstep(.13,.17,d)) * float(x>.08 and x<.92 and y>.08 and y<.92)
						2:
							var border := .09 if slash else .30
							coverage = float(x>border and x<1-border and y>border and y<1-border)
					var color := ground.lerp(ink,coverage)
					# Quiet yarn-scale shading, not a physical weave claim.
					if px%3==0 or py%3==0: color=color.darkened(.09)
					result.set_pixel(col*cell+px,row*cell+py,color)
	result.generate_mipmaps()
	return result
