# The pattern crosses over

**Learning elements — proposed focus**

_The labels below set the revision focus; the existing lesson still needs alignment._

- Coordinate transforms
- Tile addresses
- Local coordinates


<!-- study-spine:reference_pattern_garden -->

## Return: The pattern crosses over

Change pattern phase while retaining every flower position. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses array, shader. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`garden`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-five-reference-rooms/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:reference_pattern_garden -->

### One source change: The pattern crosses over

In surface(), halve the original 0.5 phase range. Watch the same petal through the parameter change; keep density and flower positions.

```gdscript
result.set_shader_parameter("phase", amount * 0.25)
```

Source: `commons/artifacts/reference_studies/pattern_garden.gd`. Use the prepared scene to run and compare.
