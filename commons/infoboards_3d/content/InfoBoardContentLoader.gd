# InfoBoardContentLoader.gd
# Loads and manages InfoBoard content from centralized JSON file
# Single source of truth for all educational content
extends RefCounted
class_name InfoBoardContentLoader

# Path to the centralized content JSON
const CONTENT_JSON_PATH = "res://commons/infoboards_3d/content/infoboard_content.json"

# Cached content data
static var _content_cache: Dictionary = {}
static var _is_loaded: bool = false

# Load the content JSON file
static func load_content() -> bool:
	if _is_loaded:
		return true

	var file = FileAccess.open(CONTENT_JSON_PATH, FileAccess.READ)
	if file == null:
		push_error("InfoBoardContentLoader: Failed to open content file: %s" % CONTENT_JSON_PATH)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("InfoBoardContentLoader: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false

	_content_cache = json.data
	_is_loaded = true

	print("InfoBoardContentLoader: Loaded content for %d boards" % _content_cache.get("boards", {}).size())
	return true

# Get content for a specific board
static func get_board_content(board_id: String) -> Dictionary:
	if not _is_loaded:
		load_content()

	var boards = _content_cache.get("boards", {})
	if not boards.has(board_id):
		push_warning("InfoBoardContentLoader: Board '%s' not found in content" % board_id)
		return {}

	return boards[board_id]

# Get page content for a specific board
static func get_pages(board_id: String) -> Array:
	var board_content = get_board_content(board_id)
	return board_content.get("pages", [])

# Get specific page from a board
static func get_page(board_id: String, page_number: int) -> Dictionary:
	var pages = get_pages(board_id)

	# Pages are 1-indexed in JSON, 0-indexed in code
	var page_index = page_number

	if page_index < 0 or page_index >= pages.size():
		push_warning("InfoBoardContentLoader: Page %d not found for board '%s'" % [page_number, board_id])
		return {}

	return pages[page_index]

# Get a specific slide by its slide_id (e.g., "point_1", "line_3")
static func get_slide_by_id(slide_id: String) -> Dictionary:
	if not _is_loaded:
		load_content()

	var boards = _content_cache.get("boards", {})

	# Search through all boards for the slide_id
	for board_id in boards.keys():
		var board = boards[board_id]
		var pages = board.get("pages", [])

		for page in pages:
			if page.get("slide_id", "") == slide_id:
				# Return the slide with board context
				var slide_data = page.duplicate(true)
				slide_data["_board_id"] = board_id
				slide_data["_board_title"] = board.get("title", "")
				return slide_data

	push_warning("InfoBoardContentLoader: Slide '%s' not found" % slide_id)
	return {}

# Get all slides across all boards (for full navigation mode)
static func get_all_slides() -> Array:
	if not _is_loaded:
		load_content()

	var all_slides = []
	var progression = get_progression()
	var boards = _content_cache.get("boards", {})

	# Follow progression order for consistent navigation
	for board_id in progression:
		if not boards.has(board_id):
			continue

		var board = boards[board_id]
		var pages = board.get("pages", [])

		for page in pages:
			var slide_data = page.duplicate(true)
			slide_data["_board_id"] = board_id
			slide_data["_board_title"] = board.get("title", "")
			all_slides.append(slide_data)

	return all_slides

# Get slide IDs for a specific board
static func get_slide_ids(board_id: String) -> Array:
	var pages = get_pages(board_id)
	var slide_ids = []

	for page in pages:
		var slide_id = page.get("slide_id", "")
		if not slide_id.is_empty():
			slide_ids.append(slide_id)

	return slide_ids

# Get all slide IDs across all boards
static func get_all_slide_ids() -> Array:
	if not _is_loaded:
		load_content()

	var all_slide_ids = []
	var boards = _content_cache.get("boards", {})

	for board_id in boards.keys():
		all_slide_ids.append_array(get_slide_ids(board_id))

	return all_slide_ids

# Get board metadata
static func get_board_meta(board_id: String) -> Dictionary:
	var board_content = get_board_content(board_id)
	return {
		"title": board_content.get("title", "Unknown"),
		"subtitle": board_content.get("subtitle", ""),
		"category": board_content.get("category", "General"),
		"order": board_content.get("order", 999),
		"description": board_content.get("description", "")
	}

# Get total number of pages for a board
static func get_page_count(board_id: String) -> int:
	var pages = get_pages(board_id)
	return pages.size()

# Get the educational progression order
static func get_progression() -> Array:
	if not _is_loaded:
		load_content()

	var meta = _content_cache.get("_meta", {})
	return meta.get("progression", [])

# Get all board IDs
static func get_all_board_ids() -> Array:
	if not _is_loaded:
		load_content()

	var boards = _content_cache.get("boards", {})
	return boards.keys()

# Get boards by category
static func get_boards_by_category(category: String) -> Array:
	if not _is_loaded:
		load_content()

	var result = []
	var boards = _content_cache.get("boards", {})

	for board_id in boards.keys():
		var board_data = boards[board_id]
		if board_data.get("category", "") == category:
			result.append(board_id)

	return result

# Get all categories
static func get_all_categories() -> Array:
	if not _is_loaded:
		load_content()

	var categories = []
	var boards = _content_cache.get("boards", {})

	for board_id in boards.keys():
		var board_data = boards[board_id]
		var category = board_data.get("category", "")
		if not category.is_empty() and not categories.has(category):
			categories.append(category)

	return categories

# Search for boards by concept
static func search_by_concept(concept: String) -> Array:
	if not _is_loaded:
		load_content()

	var results = []
	var boards = _content_cache.get("boards", {})
	var search_lower = concept.to_lower()

	for board_id in boards.keys():
		var board_data = boards[board_id]
		var pages = board_data.get("pages", [])

		for page in pages:
			var concepts = page.get("concepts", [])
			for page_concept in concepts:
				if page_concept.to_lower().contains(search_lower):
					if not results.has(board_id):
						results.append(board_id)
					break

	return results

# Export content as readable "book" text
static func export_as_book(output_path: String = "res://infoboard_book.txt") -> bool:
	if not _is_loaded:
		load_content()

	var book_text = ""
	var meta = _content_cache.get("_meta", {})

	# Title page
	book_text += "=" 
	book_text += meta.get("title", "InfoBoard Book").to_upper() + "\n"
	book_text += "="
	book_text += meta.get("description", "") + "\n"
	book_text += "Version: " + str(meta.get("version", "1.0")) + "\n"
	book_text += "Last Updated: " + str(meta.get("last_updated", "")) + "\n\n"

	# Table of contents
	book_text += "-"
	book_text += "TABLE OF CONTENTS\n"
	book_text += "-"

	var progression = meta.get("progression", [])
	var boards = _content_cache.get("boards", {})

	var chapter_num = 1
	for board_id in progression:
		if boards.has(board_id):
			var board = boards[board_id]
			book_text += "Chapter %d: %s - %s\n" % [chapter_num, board.get("title", ""), board.get("subtitle", "")]
			chapter_num += 1

	book_text += "\n\n"

	# Content
	chapter_num = 1
	for board_id in progression:
		if not boards.has(board_id):
			continue

		var board = boards[board_id]

		# Chapter header
		book_text += "\n" 
		book_text += "CHAPTER %d: %s\n" % [chapter_num, board.get("title", "").to_upper()]
		book_text += "%s\n" % board.get("subtitle", "")
		book_text += "=" 
		book_text += "Category: %s\n" % board.get("category", "")
		book_text += "Description: %s\n\n" % board.get("description", "")

		# Pages
		var pages = board.get("pages", [])
		for page in pages:
			book_text += "-" 
			book_text += "Page %d: %s\n" % [page.get("page_number", 0), page.get("title", "")]
			book_text += "-" 

			# Text content
			var text_lines = page.get("text", [])
			for line in text_lines:
				book_text += line + "\n"

			book_text += "\n"

			# Concepts
			var concepts = page.get("concepts", [])
			if concepts.size() > 0:
				book_text += "Key Concepts: " + ", ".join(concepts) + "\n"

			book_text += "\n"

		chapter_num += 1

	# Write to file
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("InfoBoardContentLoader: Failed to write book to: %s" % output_path)
		return false

	file.store_string(book_text)
	file.close()

	print("InfoBoardContentLoader: Exported book to %s (%d characters)" % [output_path, book_text.length()])
	return true

# Validate content structure
static func validate_content() -> Dictionary:
	if not _is_loaded:
		load_content()

	var validation = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"stats": {
			"total_boards": 0,
			"total_pages": 0,
			"boards_by_category": {}
		}
	}

	var boards = _content_cache.get("boards", {})
	validation.stats.total_boards = boards.size()

	for board_id in boards.keys():
		var board = boards[board_id]

		# Check required fields
		if not board.has("title"):
			validation.errors.append("Board '%s' missing required field: title" % board_id)
			validation.valid = false

		if not board.has("pages"):
			validation.errors.append("Board '%s' missing required field: pages" % board_id)
			validation.valid = false
			continue

		# Count pages
		var pages = board.get("pages", [])
		validation.stats.total_pages += pages.size()

		# Track by category
		var category = board.get("category", "Uncategorized")
		if not validation.stats.boards_by_category.has(category):
			validation.stats.boards_by_category[category] = 0
		validation.stats.boards_by_category[category] += 1

		# Validate pages
		for i in range(pages.size()):
			var page = pages[i]

			if not page.has("title"):
				validation.warnings.append("Board '%s', page %d missing title" % [board_id, i])

			if not page.has("text"):
				validation.warnings.append("Board '%s', page %d missing text content" % [board_id, i])

			if not page.has("visualization"):
				validation.warnings.append("Board '%s', page %d missing visualization" % [board_id, i])

	return validation

# Print content statistics
static func print_stats() -> void:
	var validation = validate_content()
	var stats = validation.stats

	print("=== InfoBoard Content Statistics ===")
	print("Total Boards: %d" % stats.total_boards)
	print("Total Pages: %d" % stats.total_pages)
	print("\nBoards by Category:")
	for category in stats.boards_by_category.keys():
		print("  %s: %d" % [category, stats.boards_by_category[category]])

	if validation.errors.size() > 0:
		print("\nErrors: %d" % validation.errors.size())
		for error in validation.errors:
			print("  - %s" % error)

	if validation.warnings.size() > 0:
		print("\nWarnings: %d" % validation.warnings.size())
		for warning in validation.warnings:
			print("  - %s" % warning)

	print("===================================")
