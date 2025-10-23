# test_universal_infoboard_2d.gd
# Simple test scene for flipping through InfoBoard slides
extends Control

@onready var infoboard = $UniversalInfoBoard

func _ready():
	print("=")
	print("TEST UNIVERSAL INFOBOARD - ALL SLIDES MODE")
	print("=")
	print("Controls:")
	print("  - Click 'PREVIOUS' / 'NEXT' buttons to navigate")
	print("  - Press LEFT/RIGHT arrow keys to navigate")
	print("  - Press ESC to exit")
	print("  - Press 1 for SINGLE_SLIDE mode (line_3)")
	print("  - Press 2 for SINGLE_BOARD mode (triangle)")
	print("  - Press 3 for ALL_SLIDES mode")
	print("=")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				print("Exiting test scene...")
				get_tree().quit()

			KEY_LEFT:
				if infoboard:
					infoboard._on_prev_button_pressed()

			KEY_RIGHT:
				if infoboard:
					infoboard._on_next_button_pressed()

			KEY_1:
				# Test SINGLE_SLIDE mode
				print("\n[TEST] Switching to SINGLE_SLIDE mode: line_3")
				if infoboard:
					infoboard.load_slide("line_3")

			KEY_2:
				# Test SINGLE_BOARD mode
				print("\n[TEST] Switching to SINGLE_BOARD mode: triangle")
				if infoboard:
					infoboard.load_board("triangle")

			KEY_3:
				# Test ALL_SLIDES mode
				print("\n[TEST] Switching to ALL_SLIDES mode")
				if infoboard:
					infoboard.load_all_slides()

			KEY_D:
				# Debug: Print current slide info
				if infoboard and infoboard.page_content.size() > 0:
					var current_slide = infoboard.page_content[infoboard.current_page]
					print("\n[DEBUG] Current Slide Info:")
					print("  Slide ID: ", current_slide.get("slide_id", "N/A"))
					print("  Title: ", current_slide.get("title", "N/A"))
					print("  Board: ", current_slide.get("_board_id", "N/A"))
					print("  Page: ", infoboard.current_page + 1, " / ", infoboard.total_pages)
