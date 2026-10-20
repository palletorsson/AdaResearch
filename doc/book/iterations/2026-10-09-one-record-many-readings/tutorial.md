# One record, different readings

## Optional return: one record, different readings

**Learning elements:** RGB8 records; row-major addresses; channel permutation; a colour-to-height mapping; unsigned and signed integers; layout validation; source identity.

The pattern lesson stays first. Then go to the existing camera instrument and press **READ RECORD**. Its left screen retains an 8 × 8 colour record. EFFECT now selects five readings on the right. The original FORM and PIXELS effects remain available through the bank button, or by leaving READ RECORD.

Press **SAVE 8 × 8** to sample the current camera view. The instrument takes one pixel at the centre of each of 64 regions; it does not average the region or recover depth. Each sample contributes red, green and blue bytes, giving 192 bytes in row-major RGB order. Moving the camera afterwards does not update this record. Saving again deliberately replaces it. This snapshot lasts while the instrument is loaded; it is not written to disk.

Choose **FIXTURE** for known values. Red increases across its columns through 0, 1, 63, 127, 128, 192, 254 and 255. Blue uses those values down the rows; green alternates 0 and 255. This supplied pattern makes boundaries easy to inspect before returning to a captured image.

In **RGB**, read each triplet as colour. In **BGR**, exchange red and blue in the receiver. Apply the exchange twice and the original order returns. The source stays untouched throughout. The small checksum is an identity witness, not a measure of the image's quality or meaning.

In **UNSIGNED HEIGHT**, choose R, G or B with CHANNEL. A byte divided by 255 becomes a height, multiplied by the strength setting and 1.2 metres. In **SIGNED HEIGHT**, the same eight bits use two's-complement interpretation: 0–127 remain, while 128–255 mean −128 through −1. Height now uses the signed value divided by 128. Both scales are declared. The witness follows cell (4, 0): its red byte is 128 in the fixture, so the second reading crosses below zero. This is a chosen mapping from colour data, not measured camera depth.

The fifth reading requests **7 × 8 RGB**. It would require 168 bytes, but the record has 192. This lesson's strict decoder returns an invalid result instead of truncating, wrapping or reading past the buffer. Other contracts are possible; this one must be explicit. RESET VIEW restores RGB, channel R and 80% strength without replacing the saved bytes.

### Reconstruct the data operation

You bring arrays, loops, coordinates, colour components and functions. The museum camera, console, display meshes and XRTools input are supplied. The following is the complete data core used by this installed study. Save it as **saved_record.gd**. Its `capture(image)` method accepts a supplied Godot Image; `fixture()` provides a complete known input when testing without the museum renderer. The code rebuilds the record and its interpretations, not the camera or the console.

```gdscript
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
```

The cell address is `y * 8 + x`; multiply by three and add 0, 1 or 2 to select red, green or blue. `bytes()` and the receiver image use copies. That makes it possible to interpret or exchange channels without accidentally rewriting the retained source. The decoder checks dimensions and byte count before looking at values. A sign change belongs to decoding; the height scale belongs to the receiver.

Save **record_check.gd** beside the first file. In a Godot project, run `godot --headless --path <project-folder> --script res://record_check.gd` using your Godot executable. This small check requires no `.tscn`, add-on or hidden scene reference. The spatial encounter remains in Endless Museum.

```gdscript
extends SceneTree
const Record = preload("res://saved_record.gd")

func _initialize() -> void:
	var record = Record.new()
	record.fixture()
	var original: PackedByteArray = record.bytes()
	var checksum: String = record.digest()
	assert(original.size() == 192)
	var unsigned: Dictionary = Record.decode(original, 8, 8)
	var signed_values: Dictionary = Record.decode(original, 8, 8, true)
	assert(unsigned.valid and signed_values.valid)
	assert(unsigned.values[12] == 128)
	assert(signed_values.values[12] == -128)
	assert(is_equal_approx(record.heights(0, true, 1)[4], -1.2))
	var exchanged = Record.new()
	exchanged.load_bytes(record.colour_image(true).get_data())
	assert(exchanged.colour_image(true).get_data() == original)
	assert(not Record.decode(original, 7, 8).valid)
	assert(record.digest() == checksum and record.bytes() == original)
	print("RECORD EXAMPLE: 8 assertions passed")
	quit()
```

**Independent variation:** choose the blue channel at full strength. Predict which direction the fixture's slope runs, then compare it with red. Copy the saved bytes, set byte 12 to 255, and load that copy into another record. Unsigned reading gives 255; signed reading gives −1. Check that the original record and its checksum remain unchanged. This time you changed data deliberately; that is a different operation from switching receivers.

**Carry onward:** a bounded record, its address convention, an explicit interpretation and a way to detect whether it changed. The next uncertainty study can ask what happens when a reading returns to influence an action.
