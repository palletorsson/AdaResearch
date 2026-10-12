extends RefCounted
## A small authored colour sett, not a named or registered historical tartan.
const PALETTE := ["bb2949", "203b65", "238661", "f3e6c8", "e1b946", "282831", "e84b7e", "83919c"]
const NAMES := ["RED", "NAVY", "GREEN", "CREAM", "GOLD", "BLACK", "PINK", "GREY"]
const SETT := ["203b65","203b65","238661","238661","f3e6c8","bb2949","bb2949","f3e6c8","238661","238661","203b65","203b65"]

static func uniform(hex: String) -> Array:
	var colours: Array=[]; colours.resize(12); colours.fill(hex); return colours

static func next(hex: String) -> String:
	return PALETTE[(PALETTE.find(hex)+1)%PALETTE.size()]

static func colour_name(hex: String) -> String:
	var i:=PALETTE.find(hex)
	return NAMES[i] if i>=0 else hex

static func top_colour(record: Dictionary, col: int) -> String:
	var warp: Array = record.get("warp_colors",uniform("f3e6c8"))
	return str(warp[posmod(col,warp.size())]) if int(record.bits[posmod(col,record.bits.size())])==1 else str(record.get("weft_color","e84b7e"))
