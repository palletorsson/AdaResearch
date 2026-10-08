Current encounter, 2026-09-17

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Three-dimensional addresses
- Storage order
- Indexed reads and writes

array_flight_lab reuses the existing pickup-cube grid and the Menger flight enclosure. X/Y/Z selects an address. Collection writes zero without shifting other indices. Flight belongs to a locomotion region, not to the array data structure.

The step-by-step reading is in final.md. Earlier objects and layouts remain in the archive; they are not the current walkthrough.


<!-- study-spine:open_structures -->

## Return: A rule takes up space

Replace (column + row) % 5 with column; keep all 25 addresses. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses line, coordinates, transform, array. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`open`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-lewitt-reading-a-rule/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-spine:reference_suspension -->

## Return: A place still held

Change fragment roughness without changing any of the 75 positions. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses array, coordinates. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`suspension`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-hatoum-grid-under-load/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:open_structures -->

### One source change: A rule takes up space

In form_at(), replace the cyclic return with this expression. Read one row, then one column; every address remains occupied.

```gdscript
return column
```

Source: `commons/artifacts/spine_studies/open_rules.gd`. Use the prepared scene to run and compare.

<!-- study-edit:reference_suspension -->

### One source change: A place still held

This is the existing corner rule in fragment(). Change only the multiplier on offset, for example amount * 0.5. The enclosing loops still place 75 fragments.

```gdscript
corners.append(base + offset * amount)
```

Source: `commons/artifacts/reference_studies/suspension.gd`. Use the prepared scene to run and compare.
