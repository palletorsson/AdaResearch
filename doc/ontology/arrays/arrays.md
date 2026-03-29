---
title: "Arrays — The Politics of Order"
primitive: arrays
sequence: array_tutorial
phase: F_order
lens: Order
question: "Who controls the index?"
insight: "Organization is not neutral. How you order data determines who can find what."
qfep: "The array is canon formation — who gets indexed, who gets iterated over first, who falls off the end of the bounds."
web_editor: /primitives/arrays
tags: [data_structures, sorting, indexing, hierarchy]
connections: [grid, point, procedural-generation]
---

# Arrays — The Politics of Order

**Lens:** Order — *Who controls the index?*

## Discussion

An array is a **shelf**. A 2D array is a **bookcase**. A 3D array is a
**library**. But who decides what goes where?

- **Index** is power — whoever assigns the index controls retrieval
- **Iteration order** matters — row-major vs column-major affects speed,
  which affects access, which affects who gets served
- **Bounds** are borders — accessing outside crashes. The edge of the
  array is a hard wall.
- **Sorting** is hierarchy — the sort key determines what's "first"

The array teaches: **organization is not neutral.** How you order data
determines who can find what, how fast, and what's hidden at the bottom.
A spreadsheet is a 2D array. A database is arrays of arrays.
The index is the key to the kingdom.

## QFEP Connection

The array is canon formation — who gets indexed,
who gets iterated over first, who falls off the end of the bounds.

## Open Questions

- What's at index 0? Is it special or arbitrary?
- Hash maps vs arrays: associative vs positional. Name vs number.
- What would a non-hierarchical data structure look like?
- Does the iteration order create a narrative? (First to last = beginning to end)

## Connections

- **Grid** — a 2D array is a grid; the grid's cells are array elements
- **Point** — each array element can hold a point; indexed positions
- **Procedural Generation** — arrays store the seeds and outputs of generation
