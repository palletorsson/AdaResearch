# Architecture — records, footprints, boundaries

Growth supplied position/direction and a stack. Grammars and Curves separated the sentence from its interpretation. Architecture uses the existing dungeon interpreter and adds an explicit construction stage. Competition next investigates conditions on further growth.

## Follow the actual program

`commons/artifacts/lsystem_dungeon/lsystem_dungeon.gd` is the registered source. Its four GRAMMARS entries remain unchanged: warren, spiral, branch and meander. Ordinary placements retain warren at depth 3, fitted to display_size 0.7. Both ordinary and lesson paths use `produce_string` and `_interpret_turtle`; `plan_records` returns their sentence, segments and room positions without changing the miniature's settings.

The lesson selects branch at one rewrite: `F[+RF][-RF]F`. There are twelve symbols, four F movements and two R records. Initial position is zero and direction is +X on the XZ plane. The first F reaches (1,0,0). Both bracketed groups restore that junction; their Rs each mark it before the next movement. The two room records therefore share one address. The final endpoints are (2,0,0), (1,0,1) and (1,0,-1).

These are excerpts of the actual source:

```gdscript
var new_pos = pos + dir * step
segments.append([pos, new_pos])
pos = new_pos
```

```gdscript
rooms.append(pos)
```

`+` maps direction to (-z,0,x); `-` maps it to (z,0,-x). Brackets push/pop position and direction. Context-free rewriting alone does not guarantee an acyclic spatial graph: paths may revisit positions. This particular one-rewrite cross has a junction and four edges.

## Construction in metres

`commons/artifacts/architecture_lesson/architecture_lesson.gd` maps a raw point to `(p.z,-p.x)*4` in its local horizontal plane. All four segments are four metres long. There is no display fitting in this study.

Each segment receives an axis-aligned rectangle with square end caps. Clear widths are 0.4, 1.4 and 2.2 m. Optional rooms receive a 2.8 m square at each unique room address. On a fixed 0.2 m construction grid, footprints become occupied cells; dictionary union keeps shared cells once. The room is exactly 14×14 cells. Greedy rectangles merge floor cells to reduce geometry/collider count. This discretization is another policy, not a property of L-systems.

For every occupied cell, inspect its four adjacent cells:

```gdscript
if occupied.has(cell + direction): continue
```

Only exposed edges become walls. Collinear edges merge into runs; two explicit exceptions leave the main stem's ends open. Side ends remain closed. Wall thickness extends outward from the footprint, preserving the stated inner clear width. Walls rise 1.7 m above the 0.08 m slab and combine a low opaque base with translucent glass. Floor and wall colliders match those dimensions. The decorative centreline and brass margin have no collision.

PLAN displays a footprint and the unchanged centrelines without adding collision. BUILD supplies slabs and walls. WIDTH and ROOMS change the construction while retaining the records. RESET returns to PLAN, width 1.4 and rooms off. RULE changes only the small transparent readout. A fixed occupation check covers player groups em_walker, player_body and player; rebuilding refuses while a visitor is inside, with no deferred automatic change after exit.

The museum's continuous floor supports every state. The separate DesktopPlayer test body uses a capsule with radius 0.3 m and height 1.8 m. It can traverse the wide corridor and turn at its junction; the 0.4 m entrance stops it. This is a body-specific access test, not proof of accessibility for every avatar or headset movement system.

## Retained collection and limits

The original miniature remains on a rear plinth. It independently fits its records, renders slabs and side walls per segment and gives room markers larger tiles. Its walls do not implement the lesson's union/junction/door construction, and its meshes have no player collision. Dense miniatures are not certified navigable plans.

CityGenerator uses `X → F[+X]F[-X][^X][&X]` and `F → FF`, with 90-degree turns and pitch/yaw through Turtle3D. It creates a rotating 3D branch structure; the source does not extract city blocks or zone building plots. Dragon Room retains its fitted finite folded floor curve. The remaining seed, mesh grammar and catalyst works retain their original algorithms.

All nine artifact tokens remain. The original 13×12 structure is embedded at (3,23) in a 19×39 hall; raised cells and the other placements retain their relative arrangement, and the obsolete teleporter hole is filled. All roles and sequence order remain. More elaborate grammars, arbitrary corridor angles, moving walls with consent and deeper secondary encounters remain for a later pass. Headset reach, comfort and Quest timing remain pending.
