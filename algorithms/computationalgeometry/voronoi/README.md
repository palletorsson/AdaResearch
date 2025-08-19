# Voronoi Diagrams Visualization

## 🗺️ Spatial Justice & Territorial Organization

A comprehensive implementation of Voronoi Diagrams with Fortune's sweepline algorithm, spatial partitioning visualization, and territorial organization analysis. This implementation explores the mathematics of spatial division, the politics of territorial boundaries, and democratic principles in geometric space allocation.

## 🎯 Algorithm Overview

Voronoi Diagrams are fundamental geometric structures that partition a plane into regions based on distance to specific seed points (sites). Each region contains all points closer to its site than to any other site, creating natural territorial boundaries with applications ranging from ecology to urban planning to computer graphics.

### Key Concepts

1. **Spatial Partitioning**: Division of space based on proximity to control points
2. **Fortune's Sweepline Algorithm**: Efficient O(n log n) construction method
3. **Delaunay Triangulation**: Geometric dual providing connectivity information
4. **Territorial Boundaries**: Natural emergence of borders from distance relationships
5. **Spatial Equity**: Analysis of territory sizes and distribution fairness
6. **Democratic Geography**: Equal treatment of sites in space allocation

## 🔧 Technical Implementation

### Core Algorithm Features

- **Fortune's Sweepline Algorithm**: Efficient O(n log n) Voronoi construction
- **Dynamic Beach Line**: Real-time parabolic arc management during sweepline progression
- **Circle Event Processing**: Vertex creation through parabolic arc intersections
- **Spatial Partitioning**: Complete territorial division with boundary visualization
- **Delaunay Dual**: Simultaneous triangulation construction for connectivity analysis
- **Territorial Analysis**: Area calculation, equity metrics, and power concentration measurement

### Fortune's Sweepline Algorithm

#### Algorithm Overview
```
Fortune's algorithm constructs Voronoi diagrams using a sweepline approach:
1. Sort sites by y-coordinate
2. Sweep horizontal line from top to bottom
3. Maintain beach line of parabolic arcs
4. Process site events (new parabolas) and circle events (arc intersections)
5. Generate Voronoi edges at arc boundaries
```

#### Beach Line Management
```gdscript
class BeachLineArc:
    var site: VoronoiSite        # Site generating this parabolic arc
    var left_edge: VoronoiEdge   # Left boundary edge
    var right_edge: VoronoiEdge  # Right boundary edge

func handle_site_event(site):
    if beach_line.is_empty():
        # First site creates initial arc
        beach_line.append(BeachLineArc.new(site))
    else:
        # Find arc above new site and split it
        arc_index = find_arc_above_point(site.position)
        split_arc(arc_index, site)
```

#### Site Event Processing
```gdscript
func split_arc(arc_index: int, new_site: VoronoiSite):
    old_arc = beach_line[arc_index]
    
    # Create three new arcs from split
    left_arc = BeachLineArc.new(old_arc.site)
    middle_arc = BeachLineArc.new(new_site)
    right_arc = BeachLineArc.new(old_arc.site)
    
    # Create two new Voronoi edges
    left_edge = VoronoiEdge.new(old_arc.site, new_site)
    right_edge = VoronoiEdge.new(new_site, old_arc.site)
    
    # Update beach line structure
    beach_line[arc_index] = left_arc
    beach_line.insert(arc_index + 1, middle_arc)
    beach_line.insert(arc_index + 2, right_arc)
    
    # Check for potential circle events
    check_circle_events(arc_index, arc_index + 2)
```

#### Circle Event Processing
```gdscript
func handle_circle_event(event):
    # Three arcs converge to create Voronoi vertex
    arc = event.arc
    vertex = event.center
    
    # Remove disappearing arc
    arc_index = beach_line.find(arc)
    beach_line.remove_at(arc_index)
    
    # Create new edge connecting remaining arcs
    new_edge = VoronoiEdge.new()
    new_edge.start = vertex
    new_edge.site_left = beach_line[arc_index - 1].site
    new_edge.site_right = beach_line[arc_index].site
    
    edges.append(new_edge)
```

### Geometric Calculations

#### Circumcenter Computation
```gdscript
func calculate_circumcenter(p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
    # Calculate circumcenter of triangle for circle events
    var d = 2 * (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y))
    
    if abs(d) < precision_epsilon:
        return Vector2.INF  # Collinear points
    
    var ux = ((p1.x² + p1.y²) * (p2.y - p3.y) + 
              (p2.x² + p2.y²) * (p3.y - p1.y) + 
              (p3.x² + p3.y²) * (p1.y - p2.y)) / d
    
    var uy = ((p1.x² + p1.y²) * (p3.x - p2.x) + 
              (p2.x² + p2.y²) * (p1.x - p3.x) + 
              (p3.x² + p3.y²) * (p2.x - p1.x)) / d
    
    return Vector2(ux, uy)
```

#### Edge Clipping to Bounds
```gdscript
func clip_edges_to_bounds():
    var bounds = Rect2(-diagram_bounds/2, diagram_bounds)
    
    for edge in edges:
        if edge.is_infinite:
            # Calculate ray direction from bisector
            var direction = calculate_bisector_direction(edge.site_left, edge.site_right)
            
            # Find intersection with bounding rectangle
            var intersection = intersect_ray_with_bounds(edge.start, direction, bounds)
            edge.end = intersection
            edge.is_infinite = false
```

## 🎮 Interactive Controls

### Basic Operations
- **SPACE**: Generate new random site configuration
- **R**: Reset diagram to empty state
- **F**: Toggle between Fortune's algorithm and naive approach
- **D**: Toggle Delaunay triangulation display
- **T**: Toggle territory area visualization

### Site Count Controls
- **1**: 5 sites (minimal configuration)
- **2**: 10 sites (moderate density)
- **3**: 15 sites (standard configuration)
- **4**: 25 sites (high density)

### Visualization Features
- **Show Delaunay Dual**: Display triangulation connecting adjacent sites
- **Territory Colors**: Color-coded regions showing spatial ownership
- **Sweepline Animation**: Real-time Fortune's algorithm progression
- **Circle Events**: Visualization of vertex creation events
- **Infinite Edge Handling**: Proper boundary clipping for unbounded regions

## 📊 Visualization Features

### 3D Spatial Representation
- **Site Spheres**: Red spheres marking territorial control points
- **Voronoi Edges**: Blue cylinders showing territorial boundaries
- **Delaunay Edges**: Yellow cylinders displaying site connectivity
- **Territory Regions**: Semi-transparent colored areas showing spatial ownership
- **Sweepline**: Magenta plane showing algorithm progression

### Territorial Analysis Display
- **Territory Sizes**: Real-time area calculation for each region
- **Spatial Equity Index**: Measurement of territory size distribution fairness
- **Power Concentration**: Analysis of territorial inequality levels
- **Border Length**: Total perimeter of all territorial boundaries
- **Largest Territory**: Identification of dominant spatial regions

### Algorithm Animation
- **Beach Line Evolution**: Dynamic visualization of parabolic arc boundaries
- **Event Processing**: Step-by-step site and circle event handling
- **Edge Construction**: Progressive building of Voronoi diagram structure
- **Sweepline Movement**: Controlled or real-time algorithm progression

## 🏳️‍🌈 Spatial Justice Framework

### Territorial Politics in Computational Geometry
Voronoi Diagrams embody fundamental questions about space, territory, and democratic organization:

- **Who controls territorial boundaries?** Distance-based allocation vs. other distribution principles
- **What constitutes fair space allocation?** Equal areas vs. proportional representation
- **How are borders determined?** Natural emergence vs. imposed boundaries
- **What happens at territorial edges?** Conflict zones and shared resource access

### Algorithmic Justice Questions
1. **Spatial Equity**: Do all sites receive proportionally fair territorial allocations?
2. **Boundary Justice**: How do territorial borders affect resource access and mobility?
3. **Democratic Geography**: Does distance-based allocation serve all communities equally?
4. **Territorial Sovereignty**: What rights emerge from spatial proximity and control?

## 🔬 Educational Applications

### Computational Geometry Fundamentals
- **Spatial Data Structures**: Understanding planar subdivisions and spatial partitioning
- **Geometric Algorithms**: Sweepline techniques and computational efficiency
- **Duality Relationships**: Voronoi-Delaunay correspondence and geometric duals
- **Robustness Issues**: Numerical precision and degenerate case handling

### Applications Across Disciplines
- **Ecology**: Territory modeling, resource competition, habitat analysis
- **Urban Planning**: Service area analysis, facility location, accessibility studies
- **Computer Graphics**: Procedural texture generation, natural pattern simulation
- **Meteorology**: Weather station coverage, interpolation schemes
- **Epidemiology**: Disease spread modeling, healthcare facility planning

## 📈 Performance Characteristics

### Complexity Analysis

#### Time Complexity
| Algorithm | Construction | Space | Applications |
|-----------|-------------|-------|--------------|
| Fortune's | O(n log n) | O(n) | Large datasets |
| Naive | O(n²) | O(n) | Small datasets |
| Incremental | O(n²) | O(n) | Dynamic updates |

#### Space Requirements
- **Site Storage**: O(n) for n input points
- **Edge Storage**: O(n) edges in planar graph
- **Event Queue**: O(n) maximum events during construction
- **Beach Line**: O(n) maximum arcs during sweepline progression

### Geometric Properties

#### Voronoi Diagram Characteristics
```
For n sites in general position:
- Maximum vertices: 2n - 5
- Maximum edges: 3n - 6
- Each site has average degree 6 in Delaunay triangulation
- Total edge length minimizes weighted perimeter
```

#### Spatial Distribution Analysis
- **Territory Area Variance**: Measure of spatial inequality
- **Circumradius Distribution**: Analysis of site spacing patterns
- **Border Complexity**: Perimeter-to-area ratios across territories
- **Connectivity Patterns**: Delaunay graph structure and clustering

## 🎓 Learning Objectives

### Primary Goals
1. **Master spatial partitioning algorithms** and their geometric foundations
2. **Understand Fortune's sweepline technique** and its computational elegance
3. **Analyze territorial organization** and spatial justice implications
4. **Explore geometric duality** between Voronoi diagrams and Delaunay triangulations

### Advanced Topics
- **Weighted Voronoi Diagrams**: Power diagrams with variable site influence
- **Higher-Dimensional Voronoi**: 3D and n-dimensional generalizations
- **Dynamic Voronoi**: Incremental updates and site movement
- **Curved Voronoi**: Non-Euclidean metrics and distance functions

## 🔍 Experimental Scenarios

### Recommended Explorations

1. **Territorial Equity Studies**
   - Analyze territory size distribution under different site patterns
   - Compare random vs. regular vs. clustered site arrangements
   - Study impact of boundary conditions on territorial fairness

2. **Algorithm Performance Analysis**
   - Benchmark Fortune's vs. naive approaches across dataset sizes
   - Analyze numerical robustness under different precision settings
   - Study degenerate cases and algorithm stability

3. **Spatial Pattern Investigation**
   - Generate natural patterns using Voronoi-based textures
   - Model biological territory formation and competition
   - Simulate urban service area optimization problems

4. **Democratic Geography Experiments**
   - Design equitable facility location schemes
   - Analyze voting district fairness using spatial metrics
   - Study resource allocation under distance-based distribution

## 🚀 Advanced Features

### Algorithm Extensions
- **Weighted Voronoi Diagrams**: Site influence based on importance weights
- **Constrained Voronoi**: Boundaries with obstacles and barriers
- **Dynamic Updates**: Efficient site addition and removal
- **Approximate Voronoi**: Fast construction with quality guarantees

### Visualization Enhancements
- **Interactive Site Editing**: Drag-and-drop site positioning
- **Real-Time Updates**: Dynamic diagram reconstruction during editing
- **Multi-Scale Visualization**: Zoom-dependent detail levels
- **Animation Controls**: Fine-grained algorithm stepping and replay

### Application-Specific Features
- **Ecological Modeling**: Territory competition and resource optimization
- **Urban Analysis**: Service accessibility and facility optimization
- **Graphics Applications**: Procedural pattern generation and natural textures
- **Scientific Visualization**: Data interpolation and spatial analysis

## 🎯 Critical Questions for Reflection

1. **How do distance-based territorial allocations reflect and reinforce spatial inequalities?**
2. **What are the democratic implications of algorithmic boundary determination?**
3. **When might computational efficiency conflict with spatial justice principles?**
4. **How do geometric abstractions shape our understanding of territorial organization?**

## 📚 Further Reading

### Foundational Papers
- Fortune, S. (1987). A sweepline algorithm for Voronoi diagrams
- Aurenhammer, F. (1991). Voronoi diagrams—a survey of a fundamental geometric data structure
- Preparata, F. P., & Shamos, M. I. (1985). Computational Geometry: An Introduction

### Computational Geometry Literature
- de Berg, M., et al. (2008). Computational Geometry: Algorithms and Applications
- O'Rourke, J. (1998). Computational Geometry in C
- Okabe, A., et al. (2000). Spatial Tessellations: Concepts and Applications of Voronoi Diagrams

### Critical Spatial Studies
- Lefebvre, H. (1991). The Production of Space
- Harvey, D. (2006). Spaces of Global Capitalism
- Massey, D. (2005). For Space

## 🔧 Technical Implementation Details

### Data Structure Design
```gdscript
class VoronoiSite:
    var position: Vector2        # Spatial coordinates
    var index: int              # Unique identifier
    var territory_area: float   # Calculated territorial size
    var mesh_instance: MeshInstance3D  # 3D visualization

class VoronoiEdge:
    var start: Vector2          # Edge starting point
    var end: Vector2           # Edge ending point
    var site_left: VoronoiSite # Left territorial owner
    var site_right: VoronoiSite # Right territorial owner
    var is_infinite: bool      # Unbounded edge flag

class VoronoiCell:
    var site: VoronoiSite      # Central control point
    var vertices: Array[Vector2] # Cell boundary vertices
    var edges: Array[VoronoiEdge] # Cell boundary edges
    var area: float            # Territorial area
```

### Event Queue Management
```gdscript
func insert_event_sorted(event: Dictionary):
    # Maintain sorted order by y-coordinate
    for i in range(event_queue.size()):
        if event.y > event_queue[i].y:
            event_queue.insert(i, event)
            return
    event_queue.append(event)

func process_next_event():
    if event_queue.is_empty():
        return null
    
    var event = event_queue[0]
    event_queue.remove_at(0)
    sweepline_y = event.y
    
    return event
```

### Spatial Metrics Calculation
```gdscript
func calculate_spatial_equity_index() -> float:
    if sites.is_empty():
        return 1.0
    
    var total_area = diagram_bounds.x * diagram_bounds.y
    var average_area = total_area / sites.size()
    var variance_sum = 0.0
    
    for site in sites:
        var deviation = site.territory_area - average_area
        variance_sum += deviation * deviation
    
    var variance = variance_sum / sites.size()
    var coefficient_of_variation = sqrt(variance) / average_area
    
    # Convert to equity index (1.0 = perfect equality)
    return max(0.0, 1.0 - coefficient_of_variation)
```

## 📊 Performance Metrics

### Algorithm Efficiency Analysis
- **Construction Time**: Milliseconds for diagram generation
- **Event Processing**: Number of site and circle events handled
- **Memory Usage**: Peak memory consumption during construction
- **Numerical Precision**: Robustness under floating-point limitations

### Spatial Quality Metrics
- **Territory Area Distribution**: Statistical analysis of size equity
- **Border Complexity**: Average edges per territory
- **Circumradius Variation**: Delaunay triangle quality measures
- **Connectivity Patterns**: Graph-theoretic analysis of territorial adjacency

### Real-World Applications Performance
- **Ecological Modeling**: Territory size vs. resource availability correlation
- **Urban Planning**: Service accessibility optimization effectiveness
- **Computer Graphics**: Pattern quality and visual appeal assessment
- **Scientific Computing**: Interpolation accuracy and computational efficiency

---

**Status**: ✅ Complete - Production Ready  
**Complexity**: Advanced Computational Geometry  
**Prerequisites**: Computational Geometry, Spatial Data Structures, Algorithm Analysis  
**Estimated Learning Time**: 6-8 hours for basic concepts, 25+ hours for spatial analysis mastery 