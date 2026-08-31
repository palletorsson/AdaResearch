extends SceneTree

## IS THE FITTER'S HEIGHT ESTIMATE TRUE?
##
## 2026-08-31. Palle, on the three rendered options: "one need bigger canvas and
## the second needs bigger text." The second is the interesting one — it says the
## text in a big frame is smaller than it needs to be, and if that is true the
## fitter is shrinking further than the frame requires.
##
## em_detail's rule estimates the block like this:
##
##     lines = ceil(chars * (font * 0.5) / 400)     # chars per line = 800/font
##     height = lines * 65.0 * pixel_size           # 65 PIXELS PER LINE, FIXED
##
## The 65 is a constant. A line of 28 pt type is not the same height as a line of
## 52 pt type, so if that number was calibrated at 52 it over-states the height of
## everything the shrink loop produces — and the loop would keep shrinking past
## the point where the text already fitted.
##
## This does not argue about it. It builds the label, asks the font for the real
## wrapped size, and prints both.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_label_height.gd

const ROBOTO := "res://commons/font/Roboto-VariableFont_wdth,wght.ttf"
const SENTENCE := "Point One. The first point keeps escalating, inviting your hands. - “Show me what you can do with those hands” but really the hands are no different from the ball, they just code. It is us  that sit with the perspective from here to that dark shiny thing. - Grab the ball. This is the first point but it has already broken the promise of taking it wóne step at the time. We are already Alice in wonderland."


func _initialize() -> void:
	_run()


func _run() -> void:
	var font: Font = load(ROBOTO) if ResourceLoader.exists(ROBOTO) else null
	if font == null:
		print("no Roboto at %s — cannot measure" % ROBOTO)
		quit(2)
		return

	print("")
	print("LABEL HEIGHT — the fitter's estimate against the font's own answer")
	print("  wrap width 400 px, the value em_detail sets on every speak label")
	print("")
	print("  %-6s %-7s %-9s %-9s %-9s %s" % ["font", "chars", "est lines", "est px", "real px", "estimate is"])

	for font_size in [52, 44, 36, 28, 20, 14]:
		for chars in [71, 406]:
			var s: String = SENTENCE.substr(0, chars)
			var est_lines: int = int(ceil(float(chars) * (float(font_size) * 0.5) / 400.0))
			var est_px: float = float(est_lines) * 65.0
			var real: Vector2 = font.get_multiline_string_size(
				s, HORIZONTAL_ALIGNMENT_CENTER, 400.0, font_size)
			var ratio: float = est_px / maxf(real.y, 0.001)
			print("  %-6d %-7d %-9d %-9.0f %-9.0f %.2fx %s"
				% [font_size, chars, est_lines, est_px, real.y, ratio,
				   "OVER-states" if ratio > 1.05 else ("under-states" if ratio < 0.95 else "true")])

	print("")
	print("  A fitter that over-states shrinks the text further than the frame needs.")
	print("  A fitter that under-states lets it run off the frame.")
	quit(0)
