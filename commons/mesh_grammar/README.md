# Mesh Grammar Artifacts

This folder contains procedural mesh grammar systems and demo artifacts.

## Core Scenes
- `mesh_grammar_demo.tscn`: General mesh grammar demonstration artifact.
- `facade_grammar_demo.tscn`: Facade-focused grammar artifact used in array tutorial content.
- `mesh_grammar_node.tscn`: Reusable node wrapper for grammar execution.

## Scripts
- Grammar cores: `mesh_grammar.gd`, `facade_grammar.gd`, `mesh_rule.gd`, `mesh_selector.gd`, `mesh_data.gd`.
- Operation library: `operations/*.gd` (extrusion, split, inset, scatter, transforms, and branching ops).
- Demo controllers: `mesh_grammar_demo.gd`, `facade_grammar_demo.gd`, `mesh_grammar_node.gd`, `facade_grammar_node.gd`.

## Used By
- `Array_Patterns` via `facade_grammar_demo`.

