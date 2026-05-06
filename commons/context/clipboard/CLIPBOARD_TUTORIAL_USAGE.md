# Clipboard Tutorial Text Loading

The `clipboard.tscn` now supports loading tutorial text from `tutorial_text.json` using simple shorthand syntax.

## Primary Syntax (Recommended)

### Single Tutorial with Shorthand

**In map JSON:**
```json
"interactables": [
    ["clipboard#point_zero", " ", " "]
]
```

**With rotation, height, and scale:**
```json
"interactables": [
    ["clipboard#point_zero:15:-0.3:1.1", " ", " "]
]
```

Where:
- `point_zero` = tutorial ID
- `15` = rotation in degrees
- `-0.3` = height offset
- `1.1` = scale multiplier

### More Examples

```json
"interactables": [
    ["clipboard#line_axioms:90", " ", " "],           // Rotation only
    ["clipboard#the_trace:180:2", " ", " "],          // Rotation + height
    ["clipboard#sphere_axioms:0:1.5:0.8", " ", " "]   // All parameters
]
```

## Alternative Syntax Options

### 1. Single Tutorial via `content` parameter

```json
"interactables": [
    ["clipboard#content:tutorial:point_zero", " ", " "]
]
```

### 2. Single Tutorial via `pages` parameter

```json
"interactables": [
    ["clipboard#pages:tutorial:line_axioms", " ", " "]
]
```

### 3. Multiple Tutorials as Pages

Load multiple tutorials that can be paged through:

```json
"interactables": [
    ["clipboard#pages:tutorial:point_zero,tutorial:point_axioms,tutorial:the_trace", " ", " "]
]
```

This creates a multi-page clipboard where:
- Page 1: point_zero tutorial
- Page 2: point_axioms tutorial
- Page 3: the_trace tutorial

### 4. Mix Tutorials and Code Snippets

You can mix tutorial text with code snippets:

```json
"interactables": [
    ["clipboard#pages:tutorial:point_zero,vector_basics,tutorial:line_axioms", " ", " "]
]
```

This creates:
- Page 1: point_zero tutorial (from tutorial_text.json)
- Page 2: vector_basics code snippet (from code_snippet_library)
- Page 3: line_axioms tutorial (from tutorial_text.json)

## Example: Replace code_display with clipboard

**Before (using code_display):**
```json
"interactables": [
    ["code_display:180:-0.5#tutorial:line_axioms", " ", " "]
]
```

**After (using clipboard with shorthand):**
```json
"interactables": [
    ["clipboard#line_axioms:180:-0.5", " ", " "]
]
```

**Or using full syntax:**
```json
"interactables": [
    ["clipboard:180:-0.5#content:tutorial:line_axioms", " ", " "]
]
```

## Parameters Format

### Shorthand Syntax (Recommended)
```
clipboard#tutorial_id:rotation:height:scale
```

**Examples:**
```
clipboard#point_zero
clipboard#line_axioms:90
clipboard#the_trace:180:1.0
clipboard#sphere_axioms:90:0.5:1.5
```

### Full Syntax (Alternative)
```
clipboard:rotation:height:scale#parameter:value
```

**Examples:**
```
clipboard#content:tutorial:point_zero
clipboard:90#content:tutorial:line_axioms
clipboard:180:1.0#content:tutorial:the_trace
clipboard:90:0.5:1.5#pages:tutorial:point_zero,tutorial:point_axioms
```

## Available Tutorial IDs

All tutorial IDs from `tutorial_text.json` work:
- `point_zero`
- `point_axioms`
- `the_trace`
- `line_axioms`
- `sphere_axioms`
- `vectors_axioms`
- `bloom_filter_axioms`
- ...and many more (see tutorial_text.json for complete list)

## Error Handling

If a tutorial isn't found, the clipboard will display:
```
Error: Tutorial 'tutorial_name' not found
```

in red text, making it easy to spot configuration errors.

## Difference Between clipboard and code_display

**clipboard.tscn:**
- Grabbable (can be picked up and moved)
- Supports multiple pages
- Can mix tutorials and code snippets
- Has page navigation
- Awards XP when picked up

**codeDisplay.tscn:**
- Fixed in place (not grabbable)
- Single tutorial display
- Simpler, more focused presentation
- Used for permanent installation in scenes

## Usage Recommendation

**Use `clipboard` when:**
- You want players to pick up and carry the information
- You have multiple pages of related content
- You want to mix different content types
- Players need portable reference material

**Use `code_display` when:**
- Information should stay in a fixed location
- Single piece of content (one tutorial)
- Part of a permanent installation
- Used in gallery/museum style presentations

## Example Map Setup

```json
{
    "layers": {
        "structure": [
            ["1", "1", "1", "1", "1"],
            ["1", "1", "1", "1", "1"]
        ],
        "interactables": [
            ["clipboard#content:tutorial:point_zero", " ", " ", " ", " "],
            [" ", " ", "clipboard#pages:tutorial:point_axioms,tutorial:the_trace", " ", " "]
        ]
    }
}
```

This creates:
- Position (0,0): Grabbable clipboard showing point_zero tutorial
- Position (2,1): Grabbable clipboard with 2 pages (point_axioms and the_trace)
