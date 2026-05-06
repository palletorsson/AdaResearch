# Clipboard System

Grabbable code/tutorial display artifact for VR. The clipboard is a central teaching tool that renders formatted text, code snippets, tutorial content, and inline diagrams on a 3D tablet surface.

## Key Files
- `clipboard.gd` — Main clipboard artifact (Node3D); manages code/tutorial display; implements `apply_grid_config()`; references snippet and tutorial libraries
- `clipboard.tscn` — 3D GrabPlane with clipboard display, ViewportDisplay, and Label3D page numbers
- `clipboard_large.tscn` — Large variant for better readability
- `codeDisplay.gd` — Tutorial text display component; supports `tt:name` format from `tutorial_text.json`; renders via Viewport2Din3D
- `codeDisplay.tscn` — Scene with Viewport2Din3D and HandPoseArea
- `code_snippet_library.gd` — RefCounted class loading snippets from `snippets.json`; pattern `code[:#]key`
- `tutorial_text_library.gd` — RefCounted class loading from `tutorial_text.json`; pattern `tt:name`
- `DiagramGenerator.gd` — Static diagram creation (bloom filter, skip list, Hilbert curve, Dijkstra graph, binary tree); caches textures
- `DiagramProvider.gd` — Integrates DiagramGenerator with RichTextLabel; intercepts `diagram://` URLs
- `TutorialTextEditor.gd` — @tool editor for managing tutorial_text.json entries with live BBCode preview
- `CodeStyleTester.gd` — Tests 6 code block style presets (Matrix, Dracula, Monokai, Solarized, Cyberpunk, Rainbow)
- `smart_screen_reveal.gdshader` — Screen-space reveal effect shader
- `snippets.json` — Code snippet library data
- `tutorial_text.json` — Master tutorial text definitions

## Subdirectories
- `bbcode_effects/` — Custom RichTextEffect for inline diagrams
- `code/` — Markdown reference files for code snippet topics
- `tutorial_text/` — ~433 axiom/tutorial GDScript files covering algorithms, audio, UI, math concepts

## Content Syntax
- `code:key` or `code#key` — Load a code snippet by key
- `tt:name` — Load a tutorial text entry by name
- `diagram://type` — Generate an inline diagram
