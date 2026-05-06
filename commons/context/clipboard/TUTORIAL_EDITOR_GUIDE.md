# BBCode Tutorial Text Editor - Usage Guide

## 📖 Overview

A visual editor for creating and managing BBCode tutorial texts stored in `tutorial_text.json`.

## 🚀 Quick Start

### Opening the Editor

1. **In Godot Editor:**
   - Navigate to `res://commons/context/clipboard/`
   - Double-click `TutorialTextEditor.tscn`
   - The editor opens in the Godot editor viewport

2. **Alternative - Add to Project:**
   - Create a new scene with Node2D root
   - Instance `TutorialTextEditor.tscn` as a child
   - Run the scene (F6)

---

## 🎨 Interface Layout

```
┌─────────────────────────────────────────────────┐
│       📝 BBCode Tutorial Text Editor            │
├──────────────┬──────────────────────────────────┤
│ Tutorial List│  ◀ Prev  Name: [____]  Next ▶   │
│ ┌──────────┐ ├──────────────────────────────────┤
│ │line      │ │ 📄 BBCode Content (edit here):   │
│ │vectors   │ │ ┌────────────────────────────┐  │
│ │point_... │ │ │ [b]Example[/b]            │  │
│ │          │ │ │ Edit content here...       │  │
│ └──────────┘ │ └────────────────────────────┘  │
│ [➕New] [🗑Del]├──────────────────────────────────┤
│              │ 👁 Preview (with tt: expanded):  │
│              │ ┌────────────────────────────┐  │
│              │ │ **Example**                │  │
│              │ │ Preview renders here...    │  │
│              │ └────────────────────────────┘  │
├──────────────┴──────────────────────────────────┤
│ [💾 SAVE TO FILE] [🔄 Reload]        Status: OK │
└─────────────────────────────────────────────────┘
```

---

## ✏️ Basic Workflow

### 1. Create New Tutorial

1. Click **➕ New** button
2. A new tutorial appears (e.g., `new_tutorial`)
3. Edit the name in the **Name:** field
4. Press Enter to confirm rename
5. Edit content in the BBCode editor
6. Watch live preview update
7. Click **💾 SAVE TO FILE** when done

### 2. Edit Existing Tutorial

1. Click tutorial name in the list
2. Edit content in the text editor
3. Preview updates automatically
4. Click **💾 SAVE TO FILE** to save changes

### 3. Navigate Between Tutorials

**Method 1: Click in List**
- Click any tutorial name

**Method 2: Prev/Next Buttons**
- Click **◀ Prev** or **Next ▶**
- Keyboard: (future enhancement)

### 4. Delete Tutorial

1. Select tutorial from list
2. Click **🗑 Delete**
3. Tutorial removed (unsaved until you save)
4. Click **💾 SAVE TO FILE** to persist deletion

---

## 🎯 BBCode Features

### Basic Formatting

```bbcode
[b]Bold text[/b]
[i]Italic text[/i]
[u]Underline text[/u]
[s]Strikethrough[/s]
[code]monospace code[/code]
```

### Colors

```bbcode
[color=red]Red text[/color]
[color=#ff6600]Hex color[/color]
[color=aqua]Aqua text[/color]
```

### Layout

```bbcode
[center]Centered text[/center]
[right]Right-aligned[/right]
[indent]Indented paragraph[/indent]
```

### Lists

```bbcode
• Bullet point
• Another point

1. Numbered item
2. Another item
```

### Special

```bbcode
[url=https://example.com]Link text[/url]
[img]res://path/to/image.png[/img]
```

---

## 🔗 Tutorial References

### Using `tt:` References

Reference other tutorials inline:

```bbcode
For more details, see tt:point_axioms

This expands the entire content of the "point_axioms" tutorial.
```

**Example:**

**Tutorial: "intro"**
```bbcode
[b]Welcome![/b]
See the basics: tt:basic_concepts
```

**Tutorial: "basic_concepts"**
```bbcode
• Point
• Line
• Plane
```

**When "intro" is displayed:**
```
Welcome!
See the basics: • Point
• Line
• Plane
```

---

## 💾 File Management

### Save

- **Button:** Click **💾 SAVE TO FILE**
- **What it does:**
  - Writes all tutorials to `tutorial_text.json`
  - Overwrites existing file
  - Creates file if doesn't exist
- **Format:** Pretty-printed JSON with tabs

### Reload

- **Button:** Click **🔄 Reload**
- **What it does:**
  - Discards unsaved changes
  - Reloads from `tutorial_text.json`
  - Useful if file edited externally

### Status Indicator

Bottom-right shows current state:
- **Green:** Saved successfully
- **Yellow:** Modified (unsaved)
- **Red:** Error occurred
- **Cyan:** Action completed

---

## 📂 File Format

**Location:** `res://commons/context/clipboard/tutorial_text.json`

**Format:**
```json
{
	"point_axioms": "[b]Point Axioms[/b]\n\nA point has:\n• Position\n• No dimension",
	"line": "[b]Line[/b]\n\nA line is tt:point_axioms extended infinitely.",
	"vectors": "[center][b]Vectors[/b][/center]\n\nDirected quantities..."
}
```

**Key Rules:**
- Keys must be valid identifiers (lowercase, underscores)
- Values are BBCode strings
- Newlines use `\n`
- Use `tt:key` to reference other tutorials

---

## 🎨 Use Cases

### 1. In-Game Tutorials

Create tutorial displays that reference each other:

```gdscript
# In your game
var display = codeDisplay.new()
display.apply_grid_config({"tutorial": "vectors"})
```

### 2. Hierarchical Content

**Root concept:**
```bbcode
[b]Mathematics[/b]
tt:geometry
tt:algebra
```

**Sub-concepts expand when referenced.**

### 3. Reusable Snippets

Create common snippets once, reference everywhere:

**Snippet: "controls"**
```bbcode
WASD - Move
Space - Jump
```

**Usage everywhere:**
```bbcode
Game Controls:
tt:controls
```

---

## ⌨️ Keyboard Shortcuts (Future)

*(Not yet implemented - coming soon)*

- `Ctrl+S` - Save
- `Ctrl+N` - New tutorial
- `Ctrl+F` - Find in list
- `Ctrl+Up/Down` - Navigate prev/next

---

## 🐛 Troubleshooting

### "No tutorial file found"

**Cause:** First time using editor, file doesn't exist yet

**Fix:** Create a tutorial and click **💾 SAVE TO FILE**

### "JSON parse error"

**Cause:** Corrupted or invalid JSON in file

**Fix:**
1. Check file manually in text editor
2. Fix JSON syntax errors
3. Or delete file and recreate from editor

### Preview doesn't update

**Cause:** UI not connected properly

**Fix:**
1. Close and reopen scene
2. Check script is attached
3. Verify node paths in script

### Can't rename tutorial

**Cause:** Name already exists

**Fix:**
- Choose a different unique name
- Delete conflicting tutorial first

### Changes not saving

**Cause:** Forgot to click Save button

**Fix:**
- Click **💾 SAVE TO FILE** after editing
- Status bar shows "Modified (unsaved)" reminder

---

## 💡 Tips & Best Practices

### Naming Conventions

✅ **Good names:**
- `point_axioms`
- `vector_basics`
- `control_help`

❌ **Bad names:**
- `Point Axioms` (spaces)
- `Vector-Basics` (hyphens)
- `123tutorial` (starts with number)

### Content Organization

**Atomic concepts** - One concept per tutorial:
```
geometry_point
geometry_line
geometry_plane
```

**Compose with references:**
```
geometry_overview: tt:geometry_point tt:geometry_line...
```

### Preview Testing

Always check preview before saving:
- Verify formatting renders correctly
- Check `tt:` references expand properly
- Test color codes work

### Version Control

If using Git:
```bash
# Track the JSON file
git add commons/context/clipboard/tutorial_text.json
git commit -m "Added vector tutorial"
```

---

## 🔧 Advanced Usage

### External Editing

You can edit `tutorial_text.json` directly:

1. Open file in text editor
2. Edit JSON
3. Save file
4. Click **🔄 Reload** in editor

**When to use:**
- Bulk renaming keys
- Regex find/replace
- Merging from other sources

### Integration with Code

Reference tutorials in your map JSON:

```json
"utilities": [
    ["tt:point_axioms:180:-0.2", " ", " "]
]
```

Or in code:
```gdscript
var text_library = TutorialTextLibrary.new()
var content = text_library.get_tutorial_content("vectors")
```

---

## 🎓 Example Workflow

### Creating a Math Tutorial Series

1. **Create base concepts:**
   ```
   ➕ New → "math_point"
   ➕ New → "math_line"
   ➕ New → "math_plane"
   ```

2. **Add content:**
   ```bbcode
   # math_point
   [b]Point[/b]
   Zero-dimensional location in space.

   # math_line
   [b]Line[/b]
   Infinite extension through two tt:math_point

   # math_plane
   [b]Plane[/b]
   Flat surface through three non-collinear tt:math_point
   ```

3. **Create overview:**
   ```bbcode
   # math_overview
   [center][b]Geometry Basics[/b][/center]

   tt:math_point
   tt:math_line
   tt:math_plane
   ```

4. **Save:** Click **💾 SAVE TO FILE**

5. **Use in game:**
   ```gdscript
   display.apply_grid_config({"tutorial": "math_overview"})
   ```

---

## 📚 Reference

**File:** `TutorialTextEditor.gd` - Main script
**Scene:** `TutorialTextEditor.tscn` - UI layout
**Data:** `tutorial_text.json` - Content storage
**Library:** `TutorialTextLibrary.gd` - Runtime loader

---

**Version:** 1.0
**Last Updated:** 2025-01-30
