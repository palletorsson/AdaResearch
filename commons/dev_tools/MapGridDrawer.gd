class_name MapGridDrawer
extends Control

## Draws a 2D visualization of map_data.json grid layers
## Set metadata: structure, interactables, utilities, artifact_status

const CELL_SIZE := 24
const COLORS := {
	"void": Color(0.1, 0.1, 0.1),
	"floor": Color(0.25, 0.25, 0.3),
	"wall": Color(0.4, 0.4, 0.45),
	"spawn": Color(0.2, 0.6, 0.2),
	"teleporter": Color(0.6, 0.2, 0.6),
	"artifact_ok": Color(0.2, 0.5, 0.8),
	"artifact_warn": Color(0.8, 0.6, 0.2),
	"artifact_error": Color(0.8, 0.2, 0.2),
}

func _draw():
	var structure = get_meta("structure", []) as Array
	var interactables = get_meta("interactables", []) as Array
	var utilities = get_meta("utilities", []) as Array
	var artifact_status = get_meta("artifact_status", {}) as Dictionary
	
	if structure.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(10, 20), "No map data", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
		return
	
	var rows = structure.size()
	var cols = structure[0].size() if rows > 0 else 0
	
	# Calculate offset to center
	var grid_width = cols * CELL_SIZE
	var grid_height = rows * CELL_SIZE
	var offset = Vector2(
		max(0, (size.x - grid_width) / 2),
		max(0, (size.y - grid_height) / 2)
	)
	
	# Draw structure layer
	for row in range(rows):
		for col in range(cols):
			var cell_pos = offset + Vector2(col * CELL_SIZE, row * CELL_SIZE)
			var cell_rect = Rect2(cell_pos, Vector2(CELL_SIZE - 1, CELL_SIZE - 1))
			
			# Structure
			var height = "0"
			if row < structure.size() and col < structure[row].size():
				height = str(structure[row][col]).strip_edges()
			
			var color = COLORS.void
			match height:
				"1": color = COLORS.floor
				"2": color = COLORS.wall
				"3", "4", "5": color = COLORS.wall.lightened(0.1)
			
			draw_rect(cell_rect, color)
			
			# Utilities
			if row < utilities.size() and col < utilities[row].size():
				var util = str(utilities[row][col]).strip_edges()
				if util == "s":
					_draw_marker(cell_pos, COLORS.spawn, "S")
				elif util == "t":
					_draw_marker(cell_pos, COLORS.teleporter, "T")
			
			# Interactables (artifacts)
			if row < interactables.size() and col < interactables[row].size():
				var artifact_key = str(interactables[row][col]).strip_edges()
				if artifact_key != "" and artifact_key != " ":
					var base_key = artifact_key.split(":")[0].split("#")[0]
					var art_color = COLORS.artifact_ok
					
					if artifact_status.has(base_key):
						var status = artifact_status[base_key]
						if status is ContentValidator.ArtifactStatus:
							if not status.in_registry:
								art_color = COLORS.artifact_error
							elif not status.scene_exists:
								art_color = COLORS.artifact_warn
					
					_draw_artifact_marker(cell_pos, art_color)
	
	# Draw legend
	_draw_legend(offset + Vector2(0, grid_height + 10))

func _draw_marker(pos: Vector2, color: Color, text: String):
	var center = pos + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
	draw_circle(center, CELL_SIZE / 3, color)
	draw_string(ThemeDB.fallback_font, pos + Vector2(7, 17), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _draw_artifact_marker(pos: Vector2, color: Color):
	var rect = Rect2(pos + Vector2(4, 4), Vector2(CELL_SIZE - 9, CELL_SIZE - 9))
	draw_rect(rect, color)
	draw_rect(rect, Color.WHITE, false, 1.0)

func _draw_legend(pos: Vector2):
	var items = [
		[COLORS.floor, "Floor"],
		[COLORS.wall, "Wall"],
		[COLORS.spawn, "Spawn"],
		[COLORS.teleporter, "Exit"],
		[COLORS.artifact_ok, "✓"],
		[COLORS.artifact_warn, "⚠"],
		[COLORS.artifact_error, "❌"],
	]
	
	var x = pos.x
	var y = pos.y
	var item_width = 55
	var max_width = size.x - 10
	
	for item in items:
		# Wrap to next line if needed
		if x + item_width > max_width and x > pos.x:
			x = pos.x
			y += 18
		
		draw_rect(Rect2(x, y, 10, 10), item[0])
		draw_string(ThemeDB.fallback_font, Vector2(x + 14, y + 9), item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.GRAY)
		x += item_width
