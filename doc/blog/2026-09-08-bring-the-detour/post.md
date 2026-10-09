---
title: "Bring the detour"
subtitle: "The first ten rooms of Ada Research: learning the construction, following what escapes it, and choosing where to go next."
date: "2026-09-08"
author: "Palle + Codex"
tags: ["artistic-research", "primitives", "book", "discovery", "queer-method", "work-in-progress"]
sequence: "primitives"
---

You arrive late. A counter in the first room is already running.

There is nothing to catch up with by reading faster. Before we reached this number, the engine had already drawn frames, updated objects, received inputs. We could stop here and investigate the code behind any of those operations. We could spend the visit there.

Instead, we begin with a point.

This is the situation Ada Research begins from: a world already underway, differences on our hands, and time to follow only some of them. The museum and its book offer a path through that abundance. We are working towards a teacher being able to lead a group along it, and a student walking alone being able to discover the same principles without being handed every answer first.

We have reached a useful pause after the ten halls of Primitives. Their thread runs from a point through connections, traces, grids, faces, bodies, deformation, approximation and limits, to the question of what would make a construction complete. Before going into Transformation, this is a record of what has begun to hold together, and what still needs work.

![A gold triangular portal frames a succession of purple polygonal rings, with a small selection instrument beside the opening.](/blog-images/2026-09-08-bring-the-detour/portals.png)

*Near the end of Primitives, a sequence of twenty torus meshes offers increasing resolution. Its order can be reversed. This and the other engine screenshots below are isolated development captures, not photographs of a completed museum walkthrough.*

## The code we leave running

The first counter gives us a small piece of code to think with:

```gdscript
func _process(delta):
    _count += 1
```

This teaching example counts calls since its own counter began. The room's displayed engine frame count reaches further back, to the engine's start. Neither number is elapsed time. Already, saying “the counter” has hidden a choice about which beginning we mean.

For now, we choose to learn what adding one on each call does. Tracking, rendering and the machinery that makes the digits readable continue around that choice. They remain available for another investigation. The rabbit is ahead of us again.

Nearby, the invisible point stays invisible. Its position can be read in source, and the arrangement directs our attention towards it, but it will never reward our patience by appearing. Giving something a coordinate and giving it a visible body are separate acts. We begin to learn how much has to be added before a point becomes something we can meet.

That is the oscillation we are trying to write: an encounter opens a question; a first principle and a few lines of code make something specific understandable; that understanding lets another question appear.

## Bring the detour

In the next hall, joining two points brings down a DO NOT CROSS barrier. The consequence was authored: a connection event calls an explosion. Geometry alone did not require the way to open.

Afterwards, the two endpoints give us another question. Walk directly between them, then take a detour. What would a segment connecting the ends preserve of those two journeys?

Trace begins with the invitation: *bring the detour*.

Take the drawing dot and move it through the air. A line follows. Pause with the dot in your hand. The game keeps processing, but a stationary pause adds no new position to this recorder. Its list grows when the sampling rules admit another point.

![A cyan example trace above a tilted black instrument. The display reports 18 retained points and lists the last ten world positions.](/blog-images/2026-09-08-bring-the-detour/trace.png)

*The recorder's count comes from its retained list. This development example contains eighteen positions; its table shows rows nine to eighteen. An earlier position can belong to the line while remaining outside the display's current window.*

```gdscript
var point_count = _trail_points.size()
```

There is a satisfying directness to that line. Count what was kept. The question of what was kept can occupy the rest of the hall.

A movement threshold, a recording grid and the intervals between calls each participate. The straight segments join accepted positions across moments the recorder did not measure. Zooming in does not retrieve those moments. A finer record would still be a record, with its own choices and costs.

The coarse recorder also offers something. Move within one rounding region and hold its stored address steady. Cross the edge repeatedly and give the change a rhythm. A rule that cannot preserve a small loop may help you make a repeatable corner. We want the reader to discover such uses, including ones we have not prepared.

## The gesture gets another life

Release a drawing dot in Trace and its retained positions can travel into Grid. The next hall recentres and enlarges the record. Pink shows the transformed source shape; green rounds the enlarged positions again.

![Pink and green traces cross a ruled grid, while a cased readout stands to its side.](/blog-images/2026-09-08-bring-the-detour/grid.png)

*The Grid artifact with an example trace. In the running museum, a released dot or stick supplies the shared record. The whiteboard keeps a painted image and does not send its strokes through this route.*

The display makes its vertices with this operation:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

Subtract a centre. Multiply a displacement. The source list remains available while the same gesture acquires another size.

A bend that barely moved a wrist can now suggest a detour for a body. We can propose using it as a score: follow this curve with your feet, decide where to pause, let someone else interpret it. This is an invitation in the book, not an automatic movement task the game judges.

Here the connection between visualization and thinking becomes a method we can work with. Change the implementation, inspect what changes in the image, try the consequence with a body, revise the question. The visual argument has operations we can return to and disagree about.

## Which shape does the method want?

In the triangle hall, closing three edges leaves the centre empty until we ask for a fill. A boundary and a visible face have to be constructed separately.

Then the drawing tool accepts a more awkward outline: an L. It fills a closed loop by connecting the first point to successive pairs around the boundary. This is a triangle fan. Try the same six corners twice, starting from A and then from B.

![Two diagrams of the same L-shaped boundary. The fan starting at A stays inside. Starting at B sends triangles into the missing upper-right notch.](/blog-images/2026-09-08-bring-the-detour/triangle-fan.svg)

*Diagram of the book's experiment, using its six coordinates. Both runs submit four fan triangles. The black boundary is unchanged; the coloured triangles show the effect of choosing a different first point.*

Changing the start has changed the fill. Some triangles from B enter the notch we intended to leave empty. The count is still four.

We can trace the cause precisely. That precision gives us choices: choose a suitable starting point, change the outline, or use another triangulation method. The tool's convenient shape need not become the shape everyone must want.

This is one place where a queer method takes a concrete form for this project. We can learn a rule closely enough to recognise what it accommodates, what it mishandles, and where an unfamiliar use becomes possible. The remainder deserves attention; what to do with it remains a question.

## A book and a room learning together

The work has moved in both directions. Sometimes prose described an encounter the room could no longer support. Sometimes a working artifact offered something the prose had not noticed. Restoring a lost platform, exposing a retained count or changing which artifacts carry the main lesson can alter what we are able to write.

We are bringing four accounts into conversation: the reachable space, the tutorial's arrangement of primary and supporting artifacts, the critical questions, and the book's prose. A primary artifact is an encounter the book asks the reader to follow. Other artifacts can remain available for a longer visit. A developed room need not be emptied to make its first path legible.

Across the later halls, that path becomes a question about purpose. In Cube, replaying construction can preserve a deformation while restoring resets it. In Ignorance, a mesh count invites us to decide what a shape needs to do. In Portals, the resolution ladder can run back towards facets. Melencolia gathers the tools and asks what would make their use complete.

The writing still sometimes explains a discrepancy too quickly. Point One offers more beginnings than a first visit can comfortably hold. The repeated instruments risk making every encounter feel like reading a panel. And we are currently more practised at exposing omissions than at discovering surprising forms of cooperation with a rule.

These are the questions we are carrying forward. The next halls will use a tighter rhythm: one clear encounter to begin with, enough code to understand what happened, and room for the reader's next experiment. The fuller material can surround that passage. We will return to the opening with more experience of where it leads.

Transformation is waiting with a question already present in the enlarged trace: **when something moves, turns or changes scale, what do we agree to call the same thing?**

Bring the detour.

---

Explore the current encounters: [Point One](/necklace/thread?map=Point_One&role=primary), [Trace](/necklace/thread?map=Point_Trace&role=primary), [Grid](/necklace/thread?map=Point_Line_Grid&role=primary), [Triangle](/necklace/thread?map=Point_Triangle_Context&role=primary), [Portals](/necklace/thread?map=Primitives_Portals&role=primary), [Melencolia](/necklace/thread?map=Primitives_Melencolia&role=primary). Follow the ongoing alignment of rooms and text on [Museum Progress](/museum-progress?sequence=primitives).
