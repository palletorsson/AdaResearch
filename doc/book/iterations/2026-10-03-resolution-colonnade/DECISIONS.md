# Rings of Ash — resolution colonnade

3 October 2026. Requested spatial companion to the Primitives/Portals studies.

## Arrangement

Twenty-five totems occupy a 20 by 28 metre courtyard. The revised gallery uses five nine-section profiles: Vessel, Reed, Bell, Spindle and Cairn. Height is independent of radial width. Mesh heights range from 2.65 to 5.95 metres; the 0.22 metre plinths bring overall heights to 2.87–6.17 metres. Five profile families circulate through the rows, with an authored staggered skyline. Width factors retain clearance within the 1.86 metre plinths. All bodies remain below the lowest overhead beam. Column centres are 3.4 metres apart across the room and 4 metres apart along it. The entrance and central aisle are aligned at X = 1.7 so the visitor can see and walk between columns.

Across: 4, 6, 8, 12 and 16 radial segments. Ahead: the same five counts of height subdivisions per curved section. Labels state the profile, mesh height, sides and profile divisions. Since form and height now also vary, adjacent bodies do not isolate the effect of resolution alone. Set `varied_forms = false` before the gallery enters the tree to recover the original Vessel-only, equal-height comparison. These are an authored lathe's two sampling counts, not a claim that the CylinderMesh rings property alone changes the silhouette of a straight cylinder. Straight collars use one height interval. Each recipe has five curved sections with a linear taper and a sinusoidal bulge or hollow, separated by four straight collars. Sharing this topology keeps the sampling counts comparable while the silhouettes differ. Both counts independently change the actual mesh and triangle count. Flat normals preserve the resulting facets.

## Atmosphere

Pompeii-inspired red plaster, pale stone, charcoal floor, bronze rims and a luminous rose disc. The project already has Pompeii facade presets; their colour family informed this new composition. It is an imagined gallery, not a historical reconstruction. The roof remains open between side strips and high beams. Desktop Forward+ uses modest volumetric haze and SSAO; other rendering paths retain the cheaper ordinary haze. The rose disc is an emissive material, not a portal.

## Deliverables and scope

The source artifact is in commons/artifacts/resolution_colonnade/. A separate resolution_colonnade.json registry file exposes the reusable totem and the full gallery. The totem is a placeable artifact; the gallery's room footprint is declared and it is excluded from automatic map placement. No current spine hall or manuscript was overwritten.

The updated student starter includes resolution_colonnade.tscn with desktop/XR rigs and the source-identical gallery scripts. F6 enters this gallery; F5 retains the project's existing Day Zero scene. It is an optional spatial companion, not a new prerequisite tutorial. Existing desktop controls and XR movement are reused. R or B/Y returns to the entrance; falling outside the floor also returns there.

## Validation

45 native checks passed in an isolated Godot 4.6 starter. Twenty-five parameter pairs, populated finite mesh data, five distinct profiles at fixed test height and resolution, prescribed mesh heights, contact with the plinths, lateral and overhead clearance, the restored uniform comparison, independent triangle-count growth, supporting floor, an unobstructed central aisle, actual column collision, a full desktop walk and return/recovery were checked. The columns have 27,140 triangles together, excluding architecture and plinths. This is not a measured frame-rate guarantee.

An initial winding error was corrected so Godot's clockwise front faces agree with outward lighting normals and collision. The final native error log is empty. Five screenshots were captured and inspected inside the running room. The revised close-up targets follow the new heights. Physical headset comfort, headset performance and standalone Quest deployment remain untested.
