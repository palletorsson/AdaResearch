extends RefCounted
## A finite RGB8 record. Receivers borrow copies; they do not rewrite the source.
const SIDE := 8
const LENGTH := SIDE * SIDE * 3
var _bytes := PackedByteArray()

func load_bytes(source: PackedByteArray) -> bool:
	if source.size() != LENGTH: return false
	_bytes = source.duplicate()
	return true

func bytes() -> PackedByteArray:
	return _bytes.duplicate()

func digest() -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256);hash.update(_bytes)
	return hash.finish().hex_encode()

func capture(image: Image) -> bool:
	if image == null or image.is_empty(): return false
	var result := PackedByteArray()
	for y in SIDE:
		for x in SIDE:
			# One centre sample per region; this is not an average or depth scan.
			var px := mini(image.get_width()-1, floori((x+.5)*image.get_width()/SIDE))
			var py := mini(image.get_height()-1, floori((y+.5)*image.get_height()/SIDE))
			var colour := image.get_pixel(px,py)
			for value in [colour.r,colour.g,colour.b]: result.append(roundi(clampf(value,0,1)*255))
	return load_bytes(result)

func fixture() -> void:
	var levels := [0,1,63,127,128,192,254,255]
	var result := PackedByteArray()
	for y in SIDE:
		for x in SIDE:
			result.append(levels[x]);result.append(255 if (x+y)%2 else 0);result.append(levels[y])
	load_bytes(result)

static func decode(source: PackedByteArray, width: int, height: int, signed_values := false) -> Dictionary:
	if width <= 0 or height <= 0 or width > 64 or height > 64 or source.size() != width*height*3:
		return {"valid":false,"error":"RGB8 layout requires exactly width * height * 3 bytes","values":[]}
	var values: Array[int] = []
	for value in source:
		values.append(value if not signed_values or value < 128 else value-256)
	return {"valid":true,"error":"","values":values}

func colour_image(swapped := false) -> Image:
	var result := _bytes.duplicate()
	if swapped:
		for i in range(0,result.size(),3):
			result[i] = _bytes[i+2];result[i+2] = _bytes[i]
	return Image.create_from_data(SIDE,SIDE,false,Image.FORMAT_RGB8,result)

func heights(channel: int, signed_values: bool, gain: float) -> PackedFloat32Array:
	assert(channel >= 0 and channel < 3)
	var decoded := decode(_bytes,SIDE,SIDE,signed_values)
	assert(decoded.valid)
	var result := PackedFloat32Array()
	for cell in SIDE*SIDE:
		var value: int = decoded.values[cell*3+channel]
		result.append(value / (128.0 if signed_values else 255.0) * clampf(gain,0,1) * 1.2)
	return result
