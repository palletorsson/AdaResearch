# 3D Convex Hull with Queer Boundary Theory

## Algorithmic Overview

This implementation of 3D Convex Hull computation explores how computational boundaries define inclusion and exclusion in space, challenging the notion of "optimal" boundaries and embracing permeable membranes. Rather than treating the convex hull as a fixed, absolute boundary, this system investigates how boundaries are constructed, who they include or exclude, and how they might be made more permeable.

## Technical Implementation

### Core Algorithm
- **Incremental construction** using gift wrapping methodology
- **100+ point** cloud with multiple distribution patterns
- **Real-time classification** of points as included, excluded, or boundary-defining
- **Animated construction** showing how boundaries emerge incrementally
- **Multiple hull visualization** challenging the notion of "the" optimal boundary

### Boundary Types
1. **Random Distribution**: Traditional uniform point cloud
2. **Clustered Distribution**: Multiple communities with internal coherence
3. **Ring Distribution**: Points arranged in circular patterns
4. **Queer Space Distribution**: Non-binary arrangement resisting categorization

### Queer Boundary Framework

#### Permeable Zones
Around each boundary-defining point, the system creates permeable zones where the binary inside/outside classification becomes questionable:

```gdscript
# Create zones that question rigid inclusion/exclusion
var permeable_zone = MeshInstance3D.new()
permeable_zone.radius = boundary_permeability * 2.0
permeable_zone.material = permeable_material  # Semi-transparent, shifting
```

#### Inclusion Flexibility
The system tracks points that exist in liminal spaces - near boundaries but not clearly inside or outside, modeling how many identities resist binary classification.

#### Temporal Boundaries
Boundaries that shift over time, demonstrating how inclusion/exclusion categories are not fixed but contextual and temporal:

```gdscript
func update_temporal_deformation(delta: float):
    temporal_deformation_time += delta * 0.5
    var alpha = hull_transparency + sin(temporal_deformation_time) * 0.2
    hull_material.albedo_color.a = clamp(alpha, 0.1, 0.9)
```

## Queer Theory Integration

### Boundary as Violence
The convex hull algorithm traditionally seeks the "tightest" boundary that contains all points, but this implementation questions what it means to be contained or excluded:

- **Excluded Points** (red): Those left outside the boundary
- **Boundary Points** (gold): Those whose position determines inclusion for others
- **Included Points** (green): Those within the constructed boundary

### Spatial Politics of Inclusion
The visualization emphasizes how boundaries are not natural but constructed, and how they create hierarchies of belonging:

#### Color Coding as Political Analysis
- **Boundary-defining points** receive special highlighting and larger size, representing how certain positions gain power to determine others' inclusion
- **Excluded points** are visualized with cooler colors, emphasizing their marginalization
- **Included points** glow with warm colors, representing the privilege of belonging

### Alternative Boundary Construction
The system challenges the assumption that there is only one valid boundary by exploring:

1. **Multiple partial hulls** from different point subsets
2. **Permeable boundaries** that allow gradual rather than binary transitions
3. **Temporal boundaries** that acknowledge how inclusion criteria change over time

## Visual Metaphors

### Material Properties
- **Hull Material**: Semi-transparent with shifting opacity, emphasizing boundary permeability
- **Permeable Material**: Soft, shifting colors that question rigid categories
- **Point Materials**: Color-coded by relationship to boundary power dynamics

### Spatial Relationships
- **Influence Spheres**: Show how each point affects boundary construction
- **Exclusion Zones**: Visualize what spaces are rendered "outside"
- **Construction Animation**: Reveals how boundaries emerge through incremental inclusion/exclusion decisions

## Theoretical Implications

### Computational Geometry as Spatial Control
Traditional convex hull algorithms optimize for mathematical properties (minimal perimeter, maximal inclusion) without questioning the political implications of boundary construction. This implementation reveals how geometric algorithms embody assumptions about legitimate vs. illegitimate spatial occupancy.

### Boundary Permeability
By introducing permeable zones and temporal boundaries, the system models how queer spaces often exist in the margins, challenging fixed categories through their very existence.

### Algorithmic Inclusion/Exclusion
The step-by-step construction animation reveals how algorithmic decisions about inclusion compound, showing how early boundary-setting decisions determine later possibilities for belonging.

## Technical Features

### Distribution Analysis
```gdscript
func generate_queer_space_distribution():
    # Center cluster - the "norm" (40% of points)
    # Edge points - challenging the boundary (30% of points)  
    # Scattered points - the uncategorizable (30% of points)
```

### Boundary Classification
```gdscript
func classify_points():
    for point in input_points:
        if point in hull_vertices:
            boundary_points.append(point)  # Defines inclusion for others
        elif is_point_inside_hull(point):
            # Included within boundary
        else:
            excluded_points.append(point)  # Excluded from boundary
```

### Permeability Zones
```gdscript
func create_permeable_zones():
    for boundary_point in boundary_points:
        # Create semi-transparent zones questioning rigid boundaries
        var zone = create_permeable_sphere(boundary_point, boundary_permeability)
```

## Future Directions

### Non-Convex Boundaries
Implement algorithms that can create non-convex boundaries, allowing for more complex inclusion patterns that better model real spatial communities.

### Collective Boundary Construction
Allow points to participate in determining their own inclusion criteria, rather than having boundaries imposed algorithmically.

### Intersectional Boundaries
Create multiple overlapping boundary systems representing how individuals might be included in some communities while excluded from others.

## Usage

```gdscript
# Configure boundary analysis
var hull = ConvexHull3D.new()
hull.distribution_type = "queer_space"
hull.boundary_permeability = 0.5
hull.inclusion_flexibility = true
hull.temporal_boundaries = true

# Monitor boundary dynamics
hull.connect("boundary_constructed", _on_boundary_formed)
hull.connect("point_excluded", _on_exclusion_occurred)
```

## Research Applications

This implementation provides a foundation for:
- **Critical GIS** research examining how computational boundaries reproduce spatial inequalities
- **Queer geography** studies of belonging and exclusion in digital spaces
- **Algorithmic studies** investigating how geometric algorithms embody political assumptions
- **Spatial justice** applications analyzing inclusion/exclusion in urban planning algorithms

The system demonstrates how computational geometry, often seen as politically neutral, actually embeds assumptions about legitimate spatial arrangements and can be modified to question rather than reproduce existing boundary hierarchies. 