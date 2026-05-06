# InfoBoard Content System - Quick Start

## 5-Minute Setup

### 1. Add Your Content to JSON

Edit `commons/infoboards_3d/content/infoboard_content.json`:

```json
"boards": {
  "myboard": {
    "board_id": "myboard",
    "title": "My Topic",
    "subtitle": "Learning Something New",
    "category": "Algorithms",
    "order": 10,
    "description": "Description here",
    "pages": [
      {
        "page_number": 1,
        "title": "Introduction",
        "text": [
          "First line of text.",
          "",
          "CODE:",
          "var example = 123"
        ],
        "visualization": "intro",
        "concepts": ["example", "introduction"]
      }
    ]
  }
}
```

### 2. Create InfoBoard Script

```gdscript
# MyTopicInfoBoard.gd
extends Control

const BOARD_ID = "myboard"
var page_content: Array = []
var current_page := 0
var total_pages := 0

func _ready():
    # Load content from JSON
    page_content = InfoBoardContentLoader.get_pages(BOARD_ID)
    total_pages = page_content.size()

    # Your setup code...
    update_page()

func update_page():
    var page_data = page_content[current_page]
    var title = page_data.get("title", "")
    var text_lines = page_data.get("text", [])

    # Display content...
```

### 3. Register Board

In `InfoBoardRegistry.gd`:

```gdscript
"myboard": {
    "name": "My Topic Info Board",
    "category": "Algorithms",
    "scene": "MyTopic/MyTopicInfoBoard.tscn",
    "description": "Learn my topic",
    "color": Color(0.5, 0.8, 0.3)
}
```

Done! Your board now loads content from the centralized JSON.

## Export Your Book

```gdscript
# In any script or console:
InfoBoardContentLoader.export_as_book("res://my_book.txt")
```

Creates a readable text file with all your content!

## Key Functions

```gdscript
# Load content
var pages = InfoBoardContentLoader.get_pages("myboard")
var meta = InfoBoardContentLoader.get_board_meta("myboard")

# Search
var boards = InfoBoardContentLoader.search_by_concept("Vector3")

# Export
InfoBoardContentLoader.export_as_book("res://book.txt")

# Stats
InfoBoardContentLoader.print_stats()
```

## See Full Documentation

Read `CONTENT_SYSTEM.md` for complete guide.
