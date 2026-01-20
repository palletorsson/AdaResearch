extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Affordance Catalog[/b][/font_size][/center]
[center][i]What Primitives Can Do[/i][/center]

In bricolage, parts are not defined by what they **are** but by what they **afford**.

This catalog maps each primitive to its affordances—the actions, roles, and structural possibilities it enables.

[hr]

[b]Point Affordances[/b]

The point is dimensionless location—pure position.

[color=yellow][b]Structural[/b][/color]
- **anchor**: fixed position in space, attachment site
- **vertex**: corner of polygon/polyhedron
- **joint**: connection point between members
- **origin**: reference for coordinate system

[color=yellow][b]Relational[/b][/color]
- **node**: entity in a graph/network
- **sample**: single measurement location
- **seed**: starting point for growth
- **attractor**: center of gravitational/magnetic influence

[color=yellow][b]Spatial[/b][/color]
- **marker**: indicates position without volume
- **trace**: records path as sequence of positions
- **distribution**: collection of points forms cloud/scatter

[i]The point affords position without extent.[/i]

[hr]

[b]Line Affordances[/b]

The line is 1D extension—connection between points.

[color=yellow][b]Structural[/b][/color]
- **edge**: boundary of polygon face
- **strut**: tension/compression member
- **beam**: load-bearing span
- **axis**: rotation reference

[color=yellow][b]Relational[/b][/color]
- **connection**: links two nodes
- **bond**: relationship between parts
- **path**: traversable route
- **vector**: direction with magnitude

[color=yellow][b]Spatial[/b][/color]
- **boundary**: separates regions
- **ray**: extends infinitely in one direction
- **trace**: visible path through space
- **guide**: alignment reference

[i]The line affords connection and direction.[/i]

[hr]

[b]Triangle Affordances[/b]

The triangle is the minimal polygon—inherently stable.

[color=yellow][b]Structural[/b][/color]
- **face**: surface element of polyhedron
- **brace**: rigid connection (triangulation)
- **truss_element**: load distribution unit
- **gusset**: reinforcement at joint

[color=yellow][b]Relational[/b][/color]
- **minimal_surface**: smallest polygon
- **stable_unit**: cannot deform without breaking
- **tessellation_seed**: tiles plane without gaps

[color=yellow][b]Spatial[/b][/color]
- **roof_pitch**: angled overhead surface
- **ramp**: inclined access plane
- **wedge**: splitting/separating form

[color=cyan][b]Key Property:[/b][/color]
Triangles are **inherently rigid**. A square can deform into a rhombus; a triangle cannot deform without changing edge lengths. This is why triangulation stabilizes structures.

[i]The triangle affords stability through rigidity.[/i]

[hr]

[b]Plane/Quad Affordances[/b]

The plane is 2D surface—extension without volume.

[color=yellow][b]Structural[/b][/color]
- **platform**: horizontal support surface
- **wall**: vertical barrier/division
- **roof**: overhead shelter
- **floor**: ground-level walking surface

[color=yellow][b]Functional[/b][/color]
- **seat**: body support surface
- **table_top**: work/eating surface
- **shelf**: storage platform
- **panel**: enclosure element

[color=yellow][b]Spatial[/b][/color]
- **divider**: separates spaces
- **membrane**: tension surface
- **reflector**: bounces light/sound
- **screen**: visual barrier

[color=yellow][b]Relational[/b][/color]
- **face**: exterior surface of volume
- **slice**: cross-section through solid
- **layer**: stratum in accumulation

[i]The plane affords surface and division.[/i]

[hr]

[b]Cube Affordances[/b]

The cube is modular volume—space that can be occupied.

[color=yellow][b]Structural[/b][/color]
- **module**: repeatable building unit
- **voxel**: volume element in 3D grid
- **block**: stackable mass
- **foundation**: base unit for building

[color=yellow][b]Functional[/b][/color]
- **container**: enclosed storage space
- **room**: habitable volume
- **cell**: discrete spatial unit
- **box**: transport/packaging form

[color=yellow][b]Spatial[/b][/color]
- **volume**: measured 3D extent
- **corner**: 90° intersection of three planes
- **frame**: bounding box of other objects

[color=yellow][b]Relational[/b][/color]
- **grid_unit**: element in regular 3D array
- **neighbor**: adjacent cell in lattice
- **tessellation**: fills space without gaps

[i]The cube affords modular volume and stacking.[/i]

[hr]

[b]Sphere Affordances[/b]

The sphere is omnidirectional volume—equal in all directions.

[color=yellow][b]Structural[/b][/color]
- **node**: connection hub (ball joint)
- **bearing**: rotation surface
- **dome**: overhead enclosure (hemisphere)
- **pressure_vessel**: uniform stress distribution

[color=yellow][b]Functional[/b][/color]
- **joint**: articulation point in skeleton
- **ball**: rolling/throwing object
- **head**: terminal element
- **hub**: central connection point

[color=yellow][b]Spatial[/b][/color]
- **enclosure**: surrounds point equally
- **distribution**: represents omnidirectional spread
- **influence_zone**: radial field of effect

[color=yellow][b]Relational[/b][/color]
- **atom**: fundamental unit in molecule
- **center**: origin of radial structure
- **pivot**: rotation center

[color=cyan][b]Key Property:[/b][/color]
The sphere has no preferred direction. It affords **isotropy**—same behavior regardless of orientation.

[i]The sphere affords connection without direction.[/i]

[hr]

[b]Cylinder Affordances[/b]

The cylinder is directional volume—axis defines orientation.

[color=yellow][b]Structural[/b][/color]
- **column**: vertical load support
- **beam**: horizontal load span
- **strut**: diagonal bracing member
- **leg**: furniture support

[color=yellow][b]Functional[/b][/color]
- **axle**: rotation axis
- **shaft**: transmission of rotation
- **pipe**: fluid conduit
- **handle**: grip element

[color=yellow][b]Spatial[/b][/color]
- **extrusion**: 2D shape extended linearly
- **tunnel**: passage through volume
- **core**: central structural element

[color=yellow][b]Relational[/b][/color]
- **connector**: bridges between nodes
- **member**: element in truss/frame
- **segment**: portion of longer element

[color=cyan][b]Key Property:[/b][/color]
The cylinder has one preferred axis. It affords **directionality**—behavior differs along vs perpendicular to axis.

[i]The cylinder affords directional support and connection.[/i]

[hr]

[b]Torus Affordances[/b]

The torus is cyclic volume—continuous path around center.

[color=yellow][b]Structural[/b][/color]
- **ring**: closed loop structure
- **hoop**: circular frame
- **collar**: surrounding band
- **washer**: distributed load surface

[color=yellow][b]Functional[/b][/color]
- **handle**: grip that encloses
- **wheel**: rotation about center
- **portal**: passage through ring
- **seal**: continuous boundary

[color=yellow][b]Spatial[/b][/color]
- **orbit**: circular path around center
- **encirclement**: surrounds without enclosing
- **topology**: genus-1 surface (one hole)

[i]The torus affords cyclic enclosure without sealing.[/i]

[hr]

[b]Cone Affordances[/b]

The cone is transitional volume—from point to circle.

[color=yellow][b]Structural[/b][/color]
- **point_load**: force concentration at apex
- **funnel**: guides toward point
- **tent**: shelter from apex
- **spire**: vertical termination

[color=yellow][b]Functional[/b][/color]
- **nozzle**: flow direction/concentration
- **horn**: acoustic amplification
- **drill**: penetration form
- **stake**: ground anchor

[color=yellow][b]Spatial[/b][/color]
- **gradient**: continuous size change
- **projection**: radiates from point
- **taper**: narrowing toward end

[i]The cone affords transition between point and surface.[/i]

[hr]

[b]Affordance Combinations[/b]

Structures emerge when affordances combine:

[color=yellow][b]Chair[/b][/color]
[code]
plane.affordance("seat")      # Sitting surface
plane.affordance("back")      # Lean support
cylinder.affordance("leg") × 4  # Vertical support
→ Chair emerges from combined affordances
[/code]

[color=yellow][b]Table[/b][/color]
[code]
plane.affordance("table_top")   # Work surface
cylinder.affordance("leg") × 4  # Vertical support
→ Table: platform elevated for standing use
[/code]

[color=yellow][b]Geodesic Dome[/b][/color]
[code]
triangle.affordance("stable_unit") × many
sphere.affordance("distribution")
cylinder.affordance("strut") × many
→ Dome: triangulated sphere from struts and nodes
[/code]

[color=yellow][b]Skeleton[/b][/color]
[code]
sphere.affordance("joint") × many
cylinder.affordance("connector") × many
→ Articulated structure: nodes connected by members
[/code]

[hr]

[b]Reading Affordances from Context[/b]

The same primitive has different affordances in different contexts:

[code]
# Cylinder in chair context
cylinder → leg (vertical support)

# Cylinder in wheel context
cylinder → axle (rotation axis)

# Cylinder in plumbing context
cylinder → pipe (fluid conduit)

# Cylinder in fence context
cylinder → post (boundary marker)
[/code]

Context activates different affordances.
The bricoleur reads affordance from situation, not from label.

[i]Parts are what they do, not what they're called.[/i]

[hr]

[color=cyan][b]Summary:[/b][/color]
Each primitive affords multiple structural, functional, spatial, and relational possibilities. Point: anchor, vertex, node. Line: edge, strut, path. Triangle: face, brace, stable unit. Plane: platform, wall, shelf. Cube: module, voxel, container. Sphere: joint, node, hub. Cylinder: column, beam, axle. The bricoleur combines affordances to discover structures. Context determines which affordances activate.

'''
