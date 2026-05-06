# Clipboard

Grabbable clipboard that displays code snippets with page navigation. Integrates with the CodeSnippetLibrary from commons/context/clipboard.

## Behavior

- Loads description_sets as pages, navigated by interaction
- Renders BBCode via RichTextLabel
- Resets to initial position when dropped (item_dropped signal)
- Awards XP (addxp) and adjusts desperation (dessp) on use

## Files

| File | Purpose |
|------|---------|
| clipboard.gd | Page display, grab interaction, snippet rendering |
| clipboard.tscn | Scene with GrabCube and labels |
