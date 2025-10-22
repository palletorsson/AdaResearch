# InfoBoard Centralized Content System

## Complete System Overview

This system provides **one place** for all InfoBoard educational content and **one template** for all InfoBoard displays.

```
┌─────────────────────────────────────────────┐
│  infoboard_content.json                     │
│  Single source of truth for ALL content    │
│  (Point, Line, Triangle, etc.)              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  InfoBoardContentLoader.gd                  │
│  Loads content from JSON                    │
│  Search, validate, export                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  UniversalInfoBoard.gd                      │
│  ONE template for ALL boards                │
│  Just set board_id!                         │
└─────────────────────────────────────────────┘
```

## The Complete Solution

### 1. Centralized Content
**All written content in one JSON file**
- `infoboard_content.json` - Single source of truth
- Readable as a "book" tracking your educational progression
- Easy to edit, version control, and share

### 2. Universal Template
**One script for all InfoBoards**
- `UniversalInfoBoard.gd` - Works for ANY board
- Just set `board_id` and it loads the right content
- No need for separate scripts per board

### 3. Content Loader
**Utility for loading and managing content**
- `InfoBoardContentLoader.gd` - Load, search, validate
- Export as book, search by concept, get stats
- Auto-registered as global class

## Files Created

```
commons/infoboards_3d/content/
├── infoboard_content.json              # 📚 ALL content (point, line, triangle, etc.)
├── InfoBoardContentLoader.gd           # 🔧 Loader utility
├── README.md                           # 📖 This file
├── CONTENT_SYSTEM.md                   # 📘 Full documentation
├── TEMPLATE_USAGE.md                   # 📗 Template guide
└── QUICKSTART.md                       # 🚀 5-minute setup

commons/infoboards_3d/base/
└── UniversalInfoBoard.gd               # 🎯 Universal template
```

## Quick Examples

### Add a New InfoBoard (Zero Code!)

1. **Add to JSON:**
```json
"myboard": {
  "board_id": "myboard",
  "title": "My Topic",
  "pages": [{"title": "Page 1", "text": ["Content..."], "visualization": "viz"}]
}
```

2. **Use it:**
```gdscript
var board = UniversalInfoBoard.new()
board.board_id = "myboard"
add_child(board)
```

Done! No script writing needed.

### Export as Book

```gdscript
InfoBoardContentLoader.export_as_book("res://my_book.txt")
```

Creates a formatted text file with all your educational content!

### Search by Concept

```gdscript
var boards = InfoBoardContentLoader.search_by_concept("Vector3")
# Returns: ["point", "line"] - boards teaching Vector3
```

### Switch Boards Dynamically

```gdscript
info_board.switch_to_board("triangle")  # Now showing Triangle
```

## Current Content

The JSON currently contains:

- ✅ **Point** (5 pages) - The atom of space, Vector3, visualization, instantiation
- ✅ **Line** (5 pages) - Connecting points, direction, distance, drawing
- ✅ **Triangle** (5 pages) - First surface, plane, normal, area, meshes
- ✅ **RandomWalk** (1 page) - Randomness and emergent patterns

All matching your comprehensive Point, Line, and Triangle documentation!

## Educational Progression

Defined in JSON's `_meta.progression`:

```
point → line → triangle → primitives → transformation → color → arrays
→ vectors → forces → unitcircle → randomwalk → procedural_generation
```

This sequence forms the "book" of your educational journey.

## Benefits

### Single Source of Truth
- ✅ All content in one place
- ✅ No scattered text across scripts
- ✅ Easy to update and maintain
- ✅ Version control friendly

### Universal Template
- ✅ One script for all boards
- ✅ Zero code for new boards
- ✅ Consistent behavior
- ✅ Runtime board switching

### Readable Book
- ✅ Export entire progression as text
- ✅ Track your educational journey
- ✅ Share content with others
- ✅ Read outside the game

### Future-Proof
- ✅ Easy translations (multiple JSON files)
- ✅ Content tools/editors possible
- ✅ Non-programmers can add content
- ✅ Generate from Markdown/other sources

## Documentation

- **QUICKSTART.md** - Get started in 5 minutes
- **CONTENT_SYSTEM.md** - Complete content guide
- **TEMPLATE_USAGE.md** - Universal template guide
- **This file** - System overview

## Next Steps

### Option 1: Add More Boards
Continue the progression:
- Mesh/Primitives
- Transformation
- Color
- Arrays

Just add to JSON, no code needed!

### Option 2: Generate Your Book
```gdscript
InfoBoardContentLoader.export_as_book("res://my_educational_journey.txt")
```

See your complete progression as readable text.

### Option 3: Migrate Existing Boards
Update existing InfoBoards to use:
- Content from `infoboard_content.json`
- `UniversalInfoBoard.gd` template

Simpler maintenance and consistency!

## Philosophy

> *"What can be expressed in natural language, how that looks in code, and how that is represented in 3D."*

This system embodies that philosophy:

- **Natural Language** → JSON content
- **Code** → GDScript visualization logic
- **3D Representation** → Visualization scenes

Content, code, and representation are **cleanly separated**.

---

## Complete Workflow

### Traditional Way (Before)
```
1. Write PointInfoBoard.gd with embedded content (200 lines)
2. Write LineInfoBoard.gd with embedded content (200 lines)
3. Write TriangleInfoBoard.gd with embedded content (200 lines)
4. Update text? Edit 3+ scripts
5. Add board? Write another 200-line script
```

### New Way (After)
```
1. Edit infoboard_content.json (add any board)
2. Use UniversalInfoBoard.gd (works for all)
3. Done!
```

**From 200+ lines per board → 1 line: `board_id = "myboard"`**

That's the power of separation: content in JSON, logic in one template!
