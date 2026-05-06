# Math Gallery

Curated gallery of mathematical polyhedra arranged in a grid with labels and pedestals.

## Files

- `math_gallery.gd`: @tool gallery controller with MATH_OBJECTS array
- `grab_*.gd`: individual grabbable polyhedra scripts
- `pedestal.tscn`, `label_plate.tscn`: display furniture
- `color_variations_gallery.*`: color variant display

## Behavior

- Arranges polyhedra in configurable grid (grid_spacing, objects_per_row).
- Each object gets a pedestal, label plate, and formula display.
- Works as @tool for editor preview of layout.
