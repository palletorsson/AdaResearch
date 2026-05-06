# Curriculum Audit Framework

A structured audit of each sequence in Ada Research to verify it functions as a coherent curriculum — concepts flowing from simple to complex, artifacts in place to teach each concept, ordering that builds understanding.

## The Audit Template

Every sequence audit file `<sequence_id>.md` follows this structure:

### 1. Core Concept
One paragraph: what is this sequence teaching at its deepest level?

### 2. The Red Thread
An ordered list of concept-atoms, from simplest to most complex. Each concept:
- Name
- One-line essence
- What it captures (affordance)
- What it cannot capture (capture leak → where that question goes)

### 3. Map-to-Concept Mapping
For each map in the sequence:
- Which concept does this map teach?
- Which artifact is the anchor?
- Is the map ordered correctly in the flow?

### 4. Artifact Inventory
For each concept-atom:
- Does an artifact exist? (filename + lookup_name)
- Is it adequate for teaching?
- What's missing or weak?

### 5. Gap Analysis
- Concepts without artifacts → what needs building
- Maps out of order → what needs reordering
- Missing transitions → where the thread breaks
- Redundancies → what could be consolidated

### 6. Forward Leaks
What this sequence cannot hold that is addressed later. The ontological edges.

### 7. Proposed Ordering
If the current map order doesn't match the concept flow, propose the ideal order.

## Example

See `primitives.md` and `fractals.md` for worked examples.

## How to Use

These audits are living documents. As evolutions get written and artifacts get built, the audits update. The encyclopedia `/curriculum-audit` page reads all these files and shows progress.
