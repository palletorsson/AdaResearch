# Primitives_Irregular: Beyond Perfect Symmetry

## Layout
A 9×10 grid platform featuring a central container structure (rows 4-7, columns 2-6) with walls at height 3 and an opening at the bottom.

## Key Elements

### The Container
A crate built from height-3 walls demonstrates spatial containment. The opening at row 7, column 4 allows viewing the settled rocks from below.

### Rock Factory (Center of Container)
30 procedural rocks spawn above the container and fall under gravity, settling into the available space. Each rock is unique:
- Icosphere base with noise deformation
- Varied size (0.12-0.25 units radius)
- Randomized roughness and shape
- Physics-enabled with collision

### Display Primitives (Around Container)
- **Roughrock** - Irregular polyhedron from noise-perturbed vertices
- **Crystal** - Faceted quartz-style form
- **Diamond** - Multi-faceted gem shape
- **Capsule** - Rounded cylinder primitive
- **Square Pyramid (J1)** - Johnson solid
- **Truncated Tetrahedron** - Archimedean solid
- **Bipyramid** - Double pyramid structure

## Learning Sequence

1. **Enter from spawn** - See the container structure ahead
2. **Observe the rock fall** - Watch 30 irregular rocks tumble and settle
3. **Notice the gaps** - Unlike stacked cubes, irregular forms cannot fill space perfectly
4. **Examine the display** - Compare various irregular primitives around the container
5. **Walk around the container** - View the settled rocks from different angles
6. **Look through the opening** - See the packing from below
7. **Exit via teleporter** - Row 5, column 7

## Design Intent

This map contrasts **perfect packing** (cubes, regular grids) with **irregular packing** (organic forms, unavoidable voids). The falling rocks create a dynamic demonstration of the **sphere packing problem** and natural settling patterns.

The container itself is a primitive form—a rectangular prism built from discrete units—containing forms that resist discretization.
