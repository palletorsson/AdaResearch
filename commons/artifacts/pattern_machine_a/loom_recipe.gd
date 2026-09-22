extends RefCounted
## Versioned resolved state; no random regeneration on import.
const FORMAT := "ada.loom.recipe"
const VERSION := 1

static func encode_band(band: Dictionary) -> Dictionary:
	var colours: Array = []
	for c: Color in band.palette: colours.append([c.r,c.g,c.b,c.a])
	return {"group_index":band.group_index,"size":band.size,"card":band.card.duplicate(true),"palette":colours}

static func decode_band(band: Dictionary) -> Dictionary:
	var colours: Array[Color] = []
	for c in band.palette: colours.append(Color(c[0],c[1],c[2],c[3]))
	var card: Array = []
	for row in band.card:
		var cells: Array = []
		for cell in row: cells.append(int(cell))
		card.append(cells)
	return {"group_index":int(band.group_index),"size":int(band.size),"card":card,"palette":colours}

static func number(v: Variant, low: float, high: float) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v)>=low and float(v)<=high

static func integer(v: Variant, low: int, high: int) -> bool:
	return number(v,low,high) and float(v)==floorf(float(v))

static func valid_band(b: Variant, size: int) -> bool:
	if not b is Dictionary: return false
	if not integer(b.get("size"),size,size) or not integer(b.get("group_index"),0,16): return false
	var colours = b.get("palette")
	if not colours is Array or colours.size()!=6: return false
	for c in colours:
		if not c is Array or c.size()!=4: return false
		for channel in c:
			if not number(channel,0,1): return false
	var card = b.get("card")
	if not card is Array or card.size()!=size: return false
	for row in card:
		if not row is Array or row.size()!=size: return false
		for cell in row:
			if not integer(cell,0,5): return false
	return true

static func valid(r: Variant, size: int) -> bool:
	if not r is Dictionary or r.get("format")!=FORMAT or r.get("version")!=VERSION: return false
	if not valid_band(r.get("live"),size): return false
	var bands = r.get("bands")
	if not bands is Array or bands.is_empty() or bands.size()>6: return false
	for b in bands:
		if not valid_band(b,size): return false
	if bands.back()!=r.live: return false
	if not integer(r.get("paint"),1,5) or not integer(r.get("seed"),0,2147483647): return false
	if not number(r.get("density"),0,1) or not number(r.get("scroll_speed"),-2,2): return false
	if not number(r.get("elapsed"),0,1e10) or not number(r.get("phase"),0,1): return false
	# Earlier version-one saves used fixed 30 cm surface repetition.
	if not number(r.get("repeat_metres",0.3),0.15,0.6):return false
	if not number(r.get("offset_metres",0.0),0.0,0.3):return false
	return true
