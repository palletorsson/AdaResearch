# Primitives_Polythedra — enclosure and passage

This is room 6 of the current ten-room primitives sequence, between Point_Triangle_Context and Point_Animatedcube. It connects an open corner and a closed surface with the uses of those forms around a moving body.

The map is 13 by 28 cells. Entry is `sp` at (7, 0); the exit `t` is at (4, 27). Coordinates below are (column, row), not world positions. The existing floor heights and museum placement rules still determine actual height.

## The first passage

| Encounter | Grid positions | Question |
| --- | --- | --- |
| Open corner: `grab_trihedron` | (9, 5) | Which face is missing, and does its collision model also leave it out? |
| Closed surface: `grab_tetrahedron` | (6, 7) | What does another face enclose? |
| Prism variants: `prism_block` | (5, 1), (2, 5), (3, 5) | What changes visually while the collision surface stays the same? |
| Utility wedges: `wp` | (1, 3), (1, 12), (2, 12), (3, 12) | Where can forward movement become ascent? |
| Twelve concrete sections | ring along columns 4–8, rows 10–14 | Where does the physical boundary redirect movement? |
| STOP and four arrows | (3, 9), (6, 9), (2, 11), (3, 15), (7, 15) | What is requested, and what is mechanically enforced? |

The book visits the corner and tetrahedron before returning to the prism examples near the entrance. This is an authored comparison route, not a claim that the current floor automatically presents everything in that order.

## Work to return to

The five-handle pyramid and cube remain near the held solids. The diamond stack, thirty-rock spawner and scanner extend the lesson into repeated forms, gaps and sections. The scanner currently animates a cyan plane with a collider; its separate cross-section display is not activated by its own ready/process path. The legacy path-game nodes and catalyst objects remain available for a later gameplay review. The gallery request marker is a proposal, not a built gallery.

[The tutorial](tutorial.md) includes return-visit questions for these works. [The technical reference](technical.md) retains face counts, angular defect, regular solids and volume calculations. [The inventory](artifacts.md) records all 34 current placements, including repeated objects.

The former 7×9 layout and snap-tetrahedron puzzle described in earlier drafts are historical. The puzzle is absent from this room. Earlier drafts are preserved in the dated iteration archive.

## Review still needed

Inspect plinth reach, sign legibility, the backtrack to the prisms, the preserved central opening and the joins at each utility wedge in the actual museum. Component physics checks do not establish these full-room conditions. No layout or runtime behavior is changed by this editorial pass.
