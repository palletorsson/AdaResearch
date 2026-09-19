extends SceneTree

## DOES THE CARD'S LINE FIT THE CARD?
##
## 2026-09-19, Palle: "fix the card label overflow". The showing card is 0.14 x 0.09 m and its
## label was drawn at font_size 40, pixel_size 0.0009 — 0.036 m a line, about 0.50 m across for
## the 28 characters the text is cut to. It overflowed its own plate by 3.6x and always had.
##
## EmDetail.card_fit measures the line once with the real font and chooses the metres per pixel
## that lands the larger dimension exactly inside the plate. This asserts that, for every line
## the museum can actually put on a card — the "NN\nchapter · pearl" fallback, a real sentence,
## the longest 28-character cut, a single character, an empty string — the drawn block is
## inside the field on BOTH axes, and reports what the old fixed type would have done.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_card_fit.gd

const EmDetail := preload("res://commons/scenes/em/em_detail.gd")

var _checks := 0
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  FAIL  %s" % msg)


func _init() -> void:
	var font: Font = ThemeDB.fallback_font
	_check(font != null, "a font to measure with")
	var lines: Array[String] = [
		"01\nprimitives · point one",
		"07\nprimitives · point triangle ",
		"12\nthe line is a point that decided to travel",
		"99\nWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
		"01\n",
		"1",
		"",
	]
	var fieldw := 0.0
	var fieldh := 0.0
	for t in lines:
		var fit: Dictionary = EmDetail.card_fit(font, t)
		var needs: Vector2 = fit["needs"]
		var field: Vector2 = fit["field"]
		fieldw = field.x
		fieldh = field.y
		var label := t.replace("\n", "\n")
		if t == "":
			_check(float(fit["pixel_size"]) > 0.0, "empty line still returns a usable type size")
			continue
		_check(needs.x <= field.x + 1e-6, "%s: %.4f m wide fits the %.4f m field" % [label, needs.x, field.x])
		_check(needs.y <= field.y + 1e-6, "%s: %.4f m tall fits the %.4f m field" % [label, needs.y, field.y])
		_check(float(fit["pixel_size"]) > 0.0, "%s: a positive pixel size" % label)
		# and it should USE the plate, not shrink to nothing: the longer axis lands on the edge
		var used: float = maxf(needs.x / field.x, needs.y / field.y)
		_check(used > 0.90, "%s: fills the plate (longer axis at %.0f%% of the field)" % [label, 100.0 * used])
		print("    %-46s %5.3f x %5.3f m  ps %.6f" % [label, needs.x, needs.y, float(fit["pixel_size"])])
	# what the old fixed type did, for the record
	var old_px := 0.0009
	var old: Vector2 = font.get_multiline_string_size("01\nprimitives · point one",
		HORIZONTAL_ALIGNMENT_CENTER, -1.0, 40) * old_px
	print("    the OLD fixed type would have drawn that line %.3f x %.3f m on a %.3f x %.3f m field (%.1fx wide)"
		% [old.x, old.y, fieldw, fieldh, old.x / maxf(fieldw, 0.0001)])
	_check(old.x > fieldw, "the old fixed type DID overflow — this probe would have caught it")
	print("[probe_card_fit] %d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)
