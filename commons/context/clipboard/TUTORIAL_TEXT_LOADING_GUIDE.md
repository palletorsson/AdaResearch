# Tutorial Text Loading System - Debug Guide

## What I Fixed

### 1. **Missing 2D Scene for codeDisplay**
- **Problem**: `codeDisplay.tscn` had a `Viewport2Din3D` but no scene assigned to display content
- **Fix**: Created `tutorial_display_2d.tscn` with a RichTextLabel named "TutorialContent"
- **Location**: `res://commons/context/clipboard/tutorial_display_2d.tscn`

### 2. **Parser Combined Syntax Support**
- **Problem**: `code_display:90:0.5:1.0#tutorial:line_axioms` wasn't parsing correctly
- **Fix**: Updated `GridInteractablesComponent._parse_config_token()` to handle `:overrides` + `#config` syntax
- **Location**: GridInteractablesComponent.gd:520-567

### 3. **Extensive Debug Logging**
- Added comprehensive logging throughout the loading chain
- Now you can trace exactly where/why content loading fails

## Loading Flow

```
Map JSON
  ↓
GridInteractablesComponent.gd
  → Parses: "code_display:90:0.5:1.0#tutorial:line_axioms"
  → Result: {
      lookup_name: "code_display",
      overrides: {rotation_y: 90, y_position: 0.5, uniform_scale: 1.0},
      config_data: {tutorial: "line_axioms"}
    }
  ↓
codeDisplay.gd - apply_grid_config()
  → Receives: {tutorial: "line_axioms"}
  → Calls: set_tutorial("line_axioms")
  ↓
TutorialTextLibrary.gd - get_tutorial_content()
  → Loads: tutorial_text.json
  → Finds: {"line_axioms": {"content_file": "res://..."}}
  → Reads: tutorial_text/line_axioms.txt
  ↓
RichTextLabel (in Viewport2Din3D)
  → Displays BBCode content with colors, formatting, etc.
```

## How to Debug

### Run the game and check the Console Output:

1. **GridInteractablesComponent parsing**:
   ```
   GridInteractablesComponent: Parsed combined syntax - artifact='code_display', overrides={...}
   ```

2. **codeDisplay receiving config**:
   ```
   CodeDisplay: apply_grid_config() called with: {tutorial: line_axioms}
   CodeDisplay: tutorial_library initialized? YES
   CodeDisplay: rich_text_label found? YES
   ```

3. **TutorialTextLibrary loading**:
   ```
   TutorialTextLibrary: get_tutorial_content() called for 'line_axioms'
   TutorialTextLibrary: Found tutorial data: {content_file: res://...}
   TutorialTextLibrary: Loading from external file: res://...
   TutorialTextLibrary: Loaded 1234 characters from file
   ```

4. **Content displayed**:
   ```
   CodeDisplay: Updated content (length: 1234)
   ```

### Common Issues:

#### Issue: "Tutorial ID 'line_axioms' not found"
- **Cause**: tutorial_text.json not loading or malformed
- **Check**: Console for "Loaded N tutorials" message
- **Fix**: Verify JSON structure has "tutorials" key

#### Issue: "File does not exist: res://..."
- **Cause**: External .txt file not found
- **VR/Export Note**: Text files must be included in export settings!
- **Fix**:
  - Check file exists at exact path
  - Add `*.txt` to export filters (Project → Export → Resources tab)

#### Issue: "Could not find RichTextLabel"
- **Cause**: tutorial_display_2d.tscn not loading correctly
- **Check**: `_find_rich_text_label()` logs
- **Fix**: Verify codeDisplay.tscn has `scene = ExtResource("2_tutorial_display")`

#### Issue: "Default text still showing"
- **Possible Causes**:
  1. Config not being applied (check parsing logs)
  2. File loading failed (check TutorialTextLibrary logs)
  3. RichTextLabel not found (check _find_rich_text_label logs)
- **Debug**: Read all console output in order to find where flow breaks

## VR / Export Considerations

### ⚠️ IMPORTANT: External .txt Files in Builds

When exporting your game (especially for VR):

1. **Include in Export Settings**:
   - Project → Project Settings → Export
   - Resources tab → Filters to export non-resource files
   - Add: `*.txt`

2. **File Paths in Builds**:
   - Use `res://` paths (not absolute OS paths)
   - Files are packed into .pck file
   - `FileAccess.file_exists()` works in exported builds
   - `FileAccess.open()` reads from .pck automatically

3. **Testing**:
   - Test in editor first (what you're doing now)
   - Export a test build and verify .txt files load
   - Check console logs in exported build

### Alternative: Inline Content

If external files cause issues in VR:

```json
{
  "tutorials": {
    "line_axioms": {
      "content": "[b]Inline BBCode here...[/b]"
    }
  }
}
```

This avoids file system entirely (everything in JSON).

## Syntax Reference

### Map JSON Format:

```json
// Full syntax with overrides + config
"code_display:90:0.5:1.0#tutorial:line_axioms"
// rotation=90°, height=0.5, scale=1.0, tutorial="line_axioms"

// Shorthand (no 'tutorial:' key needed)
"code_display:90:0.5:1.0#line_axioms"
// Same result

// Just rotation + tutorial
"code_display:90#tutorial:line_axioms"

// Multiple configs
"code_display:90#tutorial:line_axioms#color:cyan"
```

### tutorial_text.json Format:

```json
{
  "_metadata": {
    "description": "Tutorial text content for codeDisplay system",
    "version": "1.0"
  },
  "tutorials": {
    "line_axioms": {
      "content_file": "res://commons/context/clipboard/tutorial_text/line_axioms.txt"
    },
    "welcome": {
      "content": "[b]Welcome![/b]\n\nInline content here..."
    }
  }
}
```

## Next Steps

1. **Run the game** and watch console output
2. **Look for the log messages** listed above
3. **Find where the flow breaks** (if it does)
4. **Report back** with the exact console output

The extensive logging will show exactly what's happening at each step!
