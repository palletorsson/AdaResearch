# Space Topology & Computational Geometry

This directory contains 3D visualizations of computational geometry algorithms, spatial data structures, and topological analysis techniques used in computer graphics, robotics, and spatial computing.

## Algorithms

### 1. Convex Hull (`convexhull/`)
- **Description**: Finds the smallest convex polygon that contains all given points
- **Algorithms Implemented**:
  - **Graham Scan**: O(n log n) complexity, sorts by polar angle
  - **Jarvis March**: O(nh) complexity where h is hull size
  - **Quick Hull**: O(n log n) average case, divide-and-conquer approach
- **Features**:
  - 3D point cloud generation with multiple distributions
  - Real-time hull computation
  - Interactive point manipulation
  - Multiple algorithm comparison
  - Visual hull boundary representation

### 2. Marching Cubes (Existing implementation)
- **Description**: Extracts polygonal mesh from 3D scalar field
- **Inventor**: William E. Lorensen, Harvey E. Cline (1987)
- **Features**: Isosurface extraction, medical imaging support, 3D rendering

### 3. Space Colonization (Existing implementation)
- **Description**: Algorithm for generating organic structures like trees and veins
- **Features**: Growth pattern simulation, organic network generation

### 4. Riemann Surface Torus (`riemann_torus/`)
- **Description**: Interactive VR demonstration of how lattice vectors define a genus-1 Riemann surface
- **Mathematical Concepts**:
  - **Complex Tori**: Quotient space ℂ/Λ from lattice Λ = {m·ω₁ + n·ω₂}
  - **Modular Parameter τ**: Complex ratio τ = ω₂/ω₁ determining torus shape
  - **Double Periodicity**: Two independent cycles visualized with animated stripes
  - **Fundamental Parallelogram**: Edge identification topology
- **Features**:
  - Grabbable lattice vectors (ω₁, ω₂) on XZ plane
  - Real-time τ computation and display
  - Lattice tiling visualization
  - Animated torus with double-periodic stripe patterns
  - Optional 3-torus wrapping for player motion
- **VR Compatible**: Uses grab_sphere_point primitives for VR interaction

### 5. π(x) and Riemann Zeta Landscape (`riemann_pi/`)
- **Description**: Spatial journey through the prime numbers, from discrete to continuous
- **Mathematical Concepts**:
  - **Prime Counting Function π(x)**: Cumulative count of primes ≤ x
  - **Prime Number Theorem**: π(x) ~ x/ln(x) as x → ∞
  - **Riemann Zeta Function ζ(s)**: Connection via Euler product over primes
  - **Critical Line**: Zeros of ζ(s) encode prime distribution fine structure
  - **Emergence**: Continuous patterns arising from discrete chaos
- **Features**:
  - Golden glowing spheres marking each prime number
  - Translucent π(x) staircase ribbon showing accumulation
  - Animated wave surface representing ζ(s) at infinity
  - Journey mode for automatic travel through number line
  - Sieve of Eratosthenes prime generation (O(n log log n))
  - Atmospheric fog creating sense of infinity
- **VR Compatible**: Walk through the number line in VR or desktop mode

### 6. Gyroid Cheese - Deleuzian Rhizome (`gyroid_cheese/`)
- **Description**: Walkable triply periodic minimal surface (TPMS) embodying Deleuze's rhizome concept
- **Mathematical Concepts**:
  - **Gyroid Equation**: sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = 0
  - **Minimal Surface**: Zero mean curvature everywhere (H = 0)
  - **Triply Periodic**: Infinite repetition in three orthogonal directions
  - **Two Labyrinths**: Divides space into two intertwined, non-intersecting volumes
  - **Cubic Symmetry**: I4₁32 gyroid group symmetry
- **Philosophical Framework**:
  - **Rhizome Structure**: No center, hierarchy, or privileged direction
  - **Lines of Flight**: Continuous escape and deterritorialization
  - **Multiplicity**: Neither solid nor void is primary
  - **Anti-Arborescent**: Network without tree-like organization
- **Features**:
  - Ray-marched implicit surface rendering (96 steps/pixel)
  - Sphere-based collision scaffold for walkable tunnels
  - Real-time parameter control (frequency, threshold, noise)
  - Animated phase creating "breathing" effect
  - Organic noise perturbation for irregularity
  - Two complementary tunnel networks
- **VR Compatible**: Walk through infinite interconnected maze
- **Applications**: Materials science, butterfly wings, photonic crystals, architectural design

### 7. Entropy Morphogenesis (`entropy_morphogenesis/`)
- **Description**: Living gyroid that morphs through time driven by entropy S(t) as morphological gradient
- **Thermodynamic Concept**:
  - **Entropy as Driver**: S(t) ∈ [0,1] controls topological transformation
  - **Phase Space Exploration**: Low S = crystalline order, High S = organic chaos
  - **Morphological Gradient**: Continuous path through form-space
  - **Dynamic Equilibrium**: Oscillating between states without settling
- **Coupled Transformations** (driven by S):
  - **Frequency**: 0.9 → 1.6 (spatial complexity multiplication)
  - **Thickness**: 0.20 → 0.06 (solid → lacy perforation)
  - **Noise Amplitude**: 0.05 → 0.35 (crystalline → organic)
  - **Isosurface Shift**: -0.15 → +0.15 (void/solid balance)
- **Features**:
  - Automatic entropy oscillation S(t) = 0.5 + 0.5sin(ωt)
  - Dynamic collision rebuilding when ΔS > threshold
  - Real-time morphological breathing
  - Choreographable entropy curves for exhibitions
  - Ray-marched temporal field with 100 steps/pixel
  - Smooth easing between entropy states
- **VR Compatible**: Walk through unfolding topology as it transforms
- **Applications**: Morphogenesis visualization, phase transition modeling, generative art, time-based installations

## Technical Details

### Convex Hull Algorithms

#### Graham Scan
- **Complexity**: O(n log n)
- **Method**: Sort points by polar angle, then scan for left turns
- **Best for**: General purpose, most efficient for most cases

#### Jarvis March (Gift Wrapping)
- **Complexity**: O(nh) where h is hull size
- **Method**: Find leftmost point, then repeatedly find next hull point
- **Best for**: Small hulls, simple implementation

#### Quick Hull
- **Complexity**: O(n log n) average case
- **Method**: Divide-and-conquer using extreme points
- **Best for**: Large datasets, parallel implementation

### Point Distributions
- **Uniform**: Random points across the entire space
- **Normal**: Gaussian distribution around the center
- **Clustered**: Points grouped in several clusters

### Visualization Features
- **Point Representation**: 3D spheres with configurable materials
- **Hull Visualization**: Connected lines showing the convex boundary
- **Real-time Updates**: Dynamic computation and display
- **Interactive Controls**: Parameter adjustment and regeneration

## Usage

Each algorithm scene can be:
1. **Opened independently** in Godot 4
2. **Integrated into larger projects** for spatial analysis
3. **Used for educational purposes** to understand computational geometry
4. **Extended** with additional algorithms or visualization methods

## Controls

### Point Generation
- **Point Count**: Number of points to generate (5-50)
- **Distribution**: Type of spatial distribution
- **Generate**: Create new random point set

### Hull Computation
- **Algorithm**: Choose hull computation method
- **Compute Hull**: Execute the selected algorithm
- **Clear All**: Reset the visualization

## File Structure

```
spacetopology/
├── convexhull/
│   ├── convexhull.tscn
│   ├── ConvexHull.gd
│   └── ConvexHullVisualizer.gd
├── entropy_morphogenesis/
│   ├── entropy_morphogenesis_vr.tscn   # Living evolving gyroid
│   ├── entropy_morphogenesis_vr.gd     # Entropy-driven morphology
│   └── README.md                       # Thermodynamics & morphogenesis
├── gyroid_cheese/
│   ├── gyroid_cheese_vr.tscn           # Walkable gyroid maze
│   ├── gyroid_cheese_vr.gd             # Ray marching + collision generation
│   └── README.md                       # TPMS and Deleuzian philosophy
├── marchingcubes/
│   ├── Various existing implementations
│   └── README_MarchingCubes.md
├── riemann_torus/
│   ├── torus_vr.tscn                   # Complex torus VR scene
│   ├── torus_vr.gd                     # Lattice math and visualization
│   └── README.md                       # Complex analysis background
├── riemann_pi/
│   ├── pi_infinity_surface.tscn        # Prime landscape scene
│   ├── pi_infinity_surface.gd          # Prime generation and visualization
│   └── README.md                       # Number theory background
├── spacecolonization/
│   └── Various existing implementations
└── README.md
```

## Dependencies

- **Godot 4.4+**: Required for all scenes
- **Standard 3D nodes**: CSGSphere3D, CSGBox3D, Camera3D, DirectionalLight3D
- **Math functions**: Built-in mathematical and geometric functions
- **Random generation**: Built-in random number generators

## Mathematical Concepts

### Convex Hull Properties
- **Convexity**: All interior angles ≤ 180°
- **Minimality**: Smallest convex set containing all points
- **Uniqueness**: Only one convex hull for a given point set

### Geometric Operations
- **Cross Product**: Used for orientation testing
- **Polar Angles**: For sorting in Graham scan
- **Left Turn Test**: Determines if three points form a left turn

### Riemann Surface & Topology
- **Lattice Structure**: Points identified by Λ = {m·ω₁ + n·ω₂ | m,n ∈ ℤ}
- **Modular Parameter**: τ = ω₂/ω₁ encodes the torus shape
- **Edge Identification**: Gluing opposite sides creates closed surfaces
- **Complex Division**: (a + bi)/(c + di) = [(ac+bd) + (bc-ad)i]/(c²+d²)
- **Double Periodicity**: Functions with f(z+ω₁)=f(z+ω₂)=f(z)
- **Fundamental Domain**: Minimal region that tiles the entire space

### Number Theory & Prime Distribution
- **Sieve of Eratosthenes**: O(n log log n) ancient prime generation algorithm
- **Prime Counting Function**: π(x) = |{p prime : p ≤ x}|
- **Prime Number Theorem**: π(x) ~ x/ln(x), asymptotic density of primes
- **Euler Product**: ζ(s) = Σ(1/n^s) = Π(1/(1-p^(-s))) connects sums to primes
- **Riemann Hypothesis**: All non-trivial zeros of ζ(s) lie on Re(s) = 1/2
- **Zero Oscillations**: Deviations π(x) - Li(x) encoded by ζ-zeros
- **Discrete → Continuous**: Emergence of smooth patterns from chaotic primes

### Minimal Surfaces & Implicit Geometry
- **Triply Periodic Minimal Surfaces**: Zero mean curvature, infinite 3D repetition
- **Gyroid**: sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = 0
- **Mean Curvature**: H = (κ₁ + κ₂)/2 = 0 for soap film equilibrium
- **Implicit Surfaces**: Defined by f(x,y,z) = c rather than parametric mesh
- **Ray Marching**: Rendering technique for implicit surfaces via sphere tracing
- **Isosurface**: Level set of scalar field, rendered via distance estimation
- **Cubic Symmetry**: Space group I4₁32 (gyroid) with 3-fold rotation axes

### Thermodynamics & Morphogenesis
- **Entropy as Morphogen**: S(t) drives continuous topological transformation
- **Phase Space**: Parameter space of all possible forms at different S values
- **Morphological Gradient**: Path through form-space as S varies
- **Temporal Field**: f(x,y,z,S,t) with coupled spatial and temporal evolution
- **Dynamic Equilibrium**: Oscillating systems that never settle
- **Coupled Parameters**: Frequency, thickness, noise, threshold all vary with S
- **Dissipative Structures**: Far-from-equilibrium order (Prigogine)
- **Thompson Transformations**: Continuous morphing between forms

### Algorithm Analysis
- **Time Complexity**: Varies by algorithm and input characteristics
- **Space Complexity**: Generally O(n) for storage
- **Optimality**: Graham scan and Quick Hull are optimal for general cases

## Future Enhancements

- [ ] Add more computational geometry algorithms (Voronoi diagrams, Delaunay triangulation)
- [ ] Implement 3D convex hull algorithms
- [ ] Add point cloud manipulation tools
- [ ] Create algorithm performance comparison visualizations
- [ ] Add export functionality for computed hulls
- [ ] Implement parallel versions of algorithms

## Applications

### Computer Graphics
- **Collision Detection**: Bounding volume computation
- **Mesh Simplification**: Reducing polygon count
- **Level of Detail**: Adaptive mesh complexity

### Robotics & Navigation
- **Path Planning**: Obstacle avoidance
- **Localization**: Environment mapping
- **SLAM**: Simultaneous localization and mapping

### Scientific Visualization
- **Data Clustering**: Group identification
- **Outlier Detection**: Boundary analysis
- **Spatial Analysis**: Geographic data processing

### Complex Analysis & Topology
- **Elliptic Functions**: Understanding doubly-periodic functions
- **Modular Forms**: Number theory and algebraic geometry
- **String Theory**: Worldsheet topology in physics
- **VR Education**: Interactive topology and complex analysis learning
- **Differential Geometry**: Riemann surface visualization

### Number Theory & Cryptography
- **Prime Generation**: Cryptographic key generation (RSA, ECC)
- **Distribution Analysis**: Understanding randomness in primes
- **Pattern Recognition**: Identifying gaps, twins, and clusters
- **Computational Number Theory**: Testing conjectures and theorems
- **Mathematical Visualization**: Making abstract concepts tangible

### Materials Science & Nanotechnology
- **Block Copolymers**: Self-assembled gyroid nanostructures
- **Photonic Crystals**: Gyroid bandgap materials for light control
- **Biomimetic Materials**: Butterfly wing structures and structural color
- **Porous Materials**: Zeolites and filtration membranes
- **Metamaterials**: Negative refractive index and acoustic cloaking
- **3D Printing**: Lightweight structural lattices

### Philosophy & Critical Theory
- **Deleuzian Ontology**: Rhizome as model of thought and being
- **Post-Structuralism**: Non-hierarchical knowledge structures
- **Spatial Theory**: Alternative topologies of space and movement
- **Embodied Mathematics**: Physical experience of abstract concepts
- **VR Phenomenology**: Perception of non-Euclidean spaces

### Biological & Generative Systems
- **Morphogenesis Simulation**: Visualizing developmental biology processes
- **Reaction-Diffusion**: Turing patterns and chemical morphogens
- **Growth Modeling**: D'Arcy Thompson transformations
- **Tissue Folding**: Gastrulation and invagination simulations
- **Phase Transitions**: Solid/liquid/gas transformations
- **Self-Organization**: Spontaneous pattern emergence
- **Temporal Installations**: Time-based generative art
- **Interactive Exhibitions**: Audience-controlled morphological evolution

## References

### Computational Geometry
- Graham, R.L. "An efficient algorithm for determining the convex hull of a finite planar set." Information Processing Letters 1.4 (1972): 132-133
- Jarvis, R.A. "On the identification of the convex hull of a finite set of points in the plane." Information Processing Letters 2.1 (1973): 18-21
- Preparata, F.P., and Shamos, M.I. "Computational Geometry: An Introduction." Springer-Verlag (1985)

### Complex Analysis & Topology
- Ahlfors, L.V. "Complex Analysis." McGraw-Hill (1979)
- Miranda, R. "Algebraic Curves and Riemann Surfaces." American Mathematical Society (1995)
- Farkas, H.M., and Kra, I. "Riemann Surfaces." Springer-Verlag (1992)
- Silverman, J.H. "The Arithmetic of Elliptic Curves." Springer-Verlag (2009)

### Number Theory & Prime Distribution
- Riemann, B. "On the Number of Primes Less Than a Given Magnitude" (1859)
- Hardy, G.H. and Wright, E.M. "An Introduction to the Theory of Numbers" (1938)
- Edwards, H.M. "Riemann's Zeta Function." Dover (2001)
- Derbyshire, J. "Prime Obsession: Bernhard Riemann and the Greatest Unsolved Problem in Mathematics" (2003)
- Tao, T. "Structure and Randomness in the Prime Numbers" (2007)

### Minimal Surfaces & Differential Geometry
- Schoen, A.H. "Infinite Periodic Minimal Surfaces Without Self-Intersections." NASA TN D-5541 (1970)
- Hyde, S.T. et al. "The Language of Shape: The Role of Curvature in Condensed Matter." Elsevier (1997)
- Karcher, H. "The Triply Periodic Minimal Surfaces of Alan Schoen." Manuscripta Mathematica 64.3 (1989)
- Michielsen, K. & Stavenga, D.G. "Gyroid Cuticular Structures in Butterfly Wing Scales." J. Royal Society Interface 5 (2008)

### Philosophy & Critical Theory
- Deleuze, G. & Guattari, F. "A Thousand Plateaus: Capitalism and Schizophrenia." University of Minnesota Press (1987)
- Deleuze, G. "Difference and Repetition." Columbia University Press (1994)
- Massumi, B. "A User's Guide to Capitalism and Schizophrenia: Deviations from Deleuze and Guattari." MIT Press (1992)

### Morphogenesis & Developmental Biology
- Thompson, D'Arcy. "On Growth and Form." Cambridge University Press (1917)
- Turing, A. "The Chemical Basis of Morphogenesis." Phil. Trans. Royal Society B (1952)
- Wolpert, L. "Positional Information and the Spatial Pattern of Cellular Differentiation." J. Theoretical Biology (1969)
- Thom, René. "Structural Stability and Morphogenesis." Westview Press (1994)

### Thermodynamics & Self-Organization
- Prigogine, I. & Stengers, I. "Order Out of Chaos: Man's New Dialogue with Nature." Bantam (1984)
- Nicolis, G. & Prigogine, I. "Self-Organization in Nonequilibrium Systems." Wiley (1977)
- Kauffman, S. "The Origins of Order: Self-Organization and Selection in Evolution." Oxford (1993)
