# InfoBoard Centralized Content System

## Overview

The InfoBoard Content System provides a **single source of truth** for all educational content in AdaResearch. Instead of embedding content directly in InfoBoard scripts, all written material lives in one central JSON file that serves dual purposes:

1. **Runtime Content**: InfoBoards load their pages dynamically from JSON
2. **Readable Book**: The JSON can be exported as a linear "book" tracking your educational progression

## Philosophy

> *"What can be expressed in natural language, how that looks in code, and how that is represented in 3D."*

This system separates:
- **Content** (natural language, concepts) → JSON
- **Code** (visualization logic) → GDScript
- **Representation** (3D visualizations) → Scene files

## File Structure

```
commons/infoboards_3d/content/
├── infoboard_content.json          # Single source of truth for all content
├── InfoBoardContentLoader.gd       # Utility class for loading content
└── CONTENT_SYSTEM.md               # This file
```

## The Content JSON Structure

### Top-Level Structure

```json
{
  "_meta": {
    "title": "AdaResearch InfoBoard Book",
    "description": "Complete educational progression",
    "version": "1.0.0",
    "last_updated": "2025-10-22",
    "progression": ["point", "line", "triangle", ...]
  },
  "boards": {
    "point": { ... },
    "line": { ... },
    "triangle": { ... }
  }
}
```

### Board Structure

Each board in the `"boards"` object:

```json
"point": {
  "board_id": "point",
  "title": "The Point",
  "subtitle": "The Atom of Space",
  "category": "Fundamentals",
  "order": 1,
  "description": "Understanding points as the fundamental building block",
  "pages": [
    {
      "page_number": 1,
      "title": "The Point: The Atom of Space",
      "text": [
        "AXIOM 1: A point in 3D space is a vector...",
        "",
        "CODE:",
        "var point = Vector3(0, 0, 0)"
      ],
      "visualization": "origin",
      "concepts": ["Vector3", "position", "origin"]
    }
  ]
}
```

### Field Descriptions

#### Board-Level Fields
- `board_id`: Unique identifier (matches registry key)
- `title`: Display name of the board
- `subtitle`: Additional context
- `category`: Category name (Fundamentals, Mathematics, etc.)
- `order`: Numerical order in progression
- `description`: Detailed description of board content
- `pages`: Array of page objects

#### Page-Level Fields
- `page_number`: Page number (1-indexed for readability)
- `title`: Page title
- `text`: Array of text lines (each string is a paragraph/line)
- `visualization`: Visualization type identifier (matches visualization script)
- `concepts`: Array of key concepts taught on this page

## Using the Content System

### Step 1: Add Content to JSON

Edit `infoboard_content.json` and add your board:

```json
"myboard": {
  "board_id": "myboard",
  "title": "My Algorithm",
  "subtitle": "Learning by Doing",
  "category": "Algorithms",
  "order": 15,
  "description": "An introduction to my amazing algorithm",
  "pages": [
    {
      "page_number": 1,
      "title": "Introduction",
      "text": [
        "This is the first page.",
        "",
        "CODE:",
        "func my_algorithm():",
        "    pass"
      ],
      "visualization": "intro_viz",
      "concepts": ["algorithm", "introduction"]
    }
  ]
}
```

### Step 2: Create InfoBoard Script

Create your InfoBoard script using the content loader:

```gdscript
# MyAlgorithmInfoBoard.gd
extends Control

const BOARD_ID = "myboard"  # Match JSON key
var page_content: Array = []
var current_page := 0
var total_pages := 0

func _ready():
    load_content_from_json()
    update_page()

func load_content_from_json() -> void:
    # Load pages from centralized content
    page_content = InfoBoardContentLoader.get_pages(BOARD_ID)
    total_pages = page_content.size()

    # Load metadata
    var meta = InfoBoardContentLoader.get_board_meta(BOARD_ID)
    print("Loaded: %s - %s" % [meta.title, meta.subtitle])

func update_page():
    var current_page_data = page_content[current_page]

    # Use data from JSON
    var title = current_page_data.get("title", "")
    var text_lines = current_page_data.get("text", [])
    var visualization = current_page_data.get("visualization", "")

    # Display content...
```

### Step 3: Register in InfoBoardRegistry

Add to `InfoBoardRegistry.gd`:

```gdscript
"myboard": {
    "name": "My Algorithm Info Board",
    "category": "Algorithms",
    "scene": "MyAlgorithm/MyAlgorithmInfoBoard.tscn",
    "description": "Learn my algorithm",
    "color": Color(0.5, 0.8, 0.3),
    "supports_parameters": true
}
```

## Content Loader API

### Loading Content

```gdscript
# Load all content (done automatically on first access)
InfoBoardContentLoader.load_content()

# Get content for a specific board
var board_content = InfoBoardContentLoader.get_board_content("point")

# Get pages array
var pages = InfoBoardContentLoader.get_pages("point")

# Get specific page
var page = InfoBoardContentLoader.get_page("point", 0)  # 0-indexed

# Get board metadata
var meta = InfoBoardContentLoader.get_board_meta("point")
# Returns: {title, subtitle, category, order, description}

# Get total page count
var count = InfoBoardContentLoader.get_page_count("point")
```

### Discovery and Search

```gdscript
# Get educational progression order
var progression = InfoBoardContentLoader.get_progression()
# Returns: ["point", "line", "triangle", ...]

# Get all board IDs
var all_boards = InfoBoardContentLoader.get_all_board_ids()

# Get boards by category
var fundamentals = InfoBoardContentLoader.get_boards_by_category("Fundamentals")

# Get all categories
var categories = InfoBoardContentLoader.get_all_categories()

# Search by concept
var results = InfoBoardContentLoader.search_by_concept("Vector3")
# Returns board IDs that teach this concept
```

### Validation and Statistics

```gdscript
# Validate content structure
var validation = InfoBoardContentLoader.validate_content()
# Returns: {valid: bool, errors: [], warnings: [], stats: {...}}

# Print statistics
InfoBoardContentLoader.print_stats()
# Output:
# === InfoBoard Content Statistics ===
# Total Boards: 5
# Total Pages: 23
# Boards by Category:
#   Fundamentals: 3
#   Mathematics: 2
```

### Export as Book

```gdscript
# Export content as readable text book
InfoBoardContentLoader.export_as_book("res://my_progress_book.txt")

# Creates a formatted text file with:
# - Title page
# - Table of contents
# - All chapters in progression order
# - All pages with full text content
```

## Migration Guide

### Before (Hardcoded Content)

```gdscript
# OLD: Content embedded in script
var page_content = [
    {
        "title": "The Point",
        "text": ["AXIOM 1: A point is..."],
        "visualization": "origin"
    }
]
```

### After (Centralized Content)

```gdscript
# NEW: Content loaded from JSON
const BOARD_ID = "point"
var page_content: Array = []

func _ready():
    page_content = InfoBoardContentLoader.get_pages(BOARD_ID)
    # Rest of code unchanged
```

### Changes Required

1. **Add `const BOARD_ID`**: Identifier matching JSON key
2. **Change `page_content` initialization**: From hardcoded array to empty array
3. **Add `load_content_from_json()` function**: Loads from JSON
4. **Call loader in `_ready()`**: Before using content

That's it! The rest of your code (page navigation, visualization, etc.) works identically.

## Benefits

### Single Source of Truth
- All content in one place
- Easy to update and maintain
- No duplicated text across files
- Version control friendly (one file to track)

### Readable as a Book
- Can be read linearly outside the game
- Export to text file for documentation
- Track your educational progression
- Share content with others

### Better Organization
- Clear separation of content and code
- Content writers don't need to edit GDScript
- Easy to add new boards
- Searchable by concept

### Future-Proof
- Easy to add translations (multiple JSON files)
- Could generate from Markdown/other sources
- Can be edited by non-programmers
- Enables content tools/editors

## Content Writing Guidelines

### Text Formatting

```json
"text": [
    "Regular paragraph text.",
    "",  // Empty line for spacing
    "AXIOM 1: Use AXIOM for principles",
    "",
    "CODE:",  // Prefix for code blocks
    "var example = 123",
    "func my_function():",
    "    pass",
    "",
    "• Bullet point 1",
    "• Bullet point 2"
]
```

### Code Blocks

Indicate code with "CODE:" prefix, then indent subsequent lines:

```json
"text": [
    "Here's how to create a point:",
    "",
    "CODE:",
    "var point = Vector3(0, 0, 0)",
    "add_child(point)"
]
```

### Concepts Array

List key concepts taught on each page:

```json
"concepts": [
    "Vector3",
    "position",
    "origin",
    "coordinate system"
]
```

These enable search functionality and concept tracking.

### Progression Order

Update `_meta.progression` when adding boards:

```json
"progression": [
    "point",
    "line",
    "triangle",
    "mesh",      // <- New board
    "primitives"
]
```

This defines the educational sequence.

## Examples

### Accessing Metadata in Game

```gdscript
func show_board_info(board_id: String):
    var meta = InfoBoardContentLoader.get_board_meta(board_id)
    print("Title: %s" % meta.title)
    print("Subtitle: %s" % meta.subtitle)
    print("Category: %s" % meta.category)
    print("Description: %s" % meta.description)
```

### Creating a Board Index

```gdscript
func create_board_index():
    var categories = InfoBoardContentLoader.get_all_categories()

    for category in categories:
        print("\n=== %s ===" % category)
        var boards = InfoBoardContentLoader.get_boards_by_category(category)

        for board_id in boards:
            var meta = InfoBoardContentLoader.get_board_meta(board_id)
            print("  - %s: %s" % [meta.title, meta.description])
```

### Searching for Concepts

```gdscript
func find_where_concept_is_taught(concept: String):
    var boards = InfoBoardContentLoader.search_by_concept(concept)

    print("Concept '%s' is taught in:" % concept)
    for board_id in boards:
        var meta = InfoBoardContentLoader.get_board_meta(board_id)
        print("  - %s" % meta.title)
```

## Book Export Format

The `export_as_book()` function creates a formatted text file:

```
============================================================
ADARESEARCH INFOBOARD BOOK
============================================================

The complete educational progression from points to complex systems
Version: 1.0.0
Last Updated: 2025-10-22

------------------------------------------------------------
TABLE OF CONTENTS
------------------------------------------------------------

Chapter 1: The Point - The Atom of Space
Chapter 2: The Line - Connecting Points
Chapter 3: The Triangle - The First Surface
...

============================================================
CHAPTER 1: THE POINT
The Atom of Space
============================================================

Category: Fundamentals
Description: Understanding points as the fundamental building block

------------------------------------------------------------
Page 1: The Point: The Atom of Space
------------------------------------------------------------

AXIOM 1: A point in 3D space is a vector defining a position (x, y, z).

CODE:[point]
var point_position_zero = Vector3(0, 0, 0)

Key Concepts: Vector3, position, origin, coordinate system

...
```

## Future Enhancements

### Planned Features
- [ ] Markdown support for rich text formatting
- [ ] Multiple language support (separate JSON per language)
- [ ] Visual content editor tool
- [ ] Auto-generation from README files
- [ ] Cross-referencing between boards
- [ ] Embedded images/diagrams
- [ ] Quiz questions per page

### Possible Extensions
- Export to HTML/PDF
- Interactive book reader in-game
- Progress tracking (which pages visited)
- Bookmarking favorite pages
- User annotations/notes

## Troubleshooting

### Content not loading

Check:
1. JSON file exists at correct path
2. JSON syntax is valid (use JSON validator)
3. Board ID matches between JSON and script
4. `InfoBoardContentLoader.load_content()` returns true

### Missing pages

Check:
1. Board ID is correct
2. Pages array is not empty
3. Page indices are 0-based in code
4. Call `get_page_count()` to verify

### Validation errors

Run validation and check output:
```gdscript
var validation = InfoBoardContentLoader.validate_content()
if not validation.valid:
    for error in validation.errors:
        print("ERROR: %s" % error)
```

---

**The centralized content system transforms your InfoBoards from scattered scripts into a cohesive, readable "book" of knowledge that serves both players and developers.**
