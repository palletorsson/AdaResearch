A transformation is a difference between a thing and its copy, and there are exactly three kinds.

This is the smallest room in the chapter, and it comes first because everything after it uses these three differences to get you somewhere. Here nothing moves and nothing is crossed. One yellow block stands alone, and then the same block stands twice, four times over, and each time the copy differs from the original in one way only. You walk the difference. That is the lesson, and it is the whole of it.

```gdscript
func difference(a: Transform3D, b: Transform3D) -> Transform3D:
    return a.affine_inverse() * b
```

Take the copy's transform and divide out the original's, and what is left is the transformation: a translation if only the origin differs, a rotation if only the basis has turned, a scale if only the basis has stretched. The room lays the answer out in space so you can read it without the division.

## One cube, then the difference

<!-- @mario_cube -->

A yellow block with an orange wire, one metre on a side, alone on the floor near the door. That is the cube. It is the unit the whole museum is built from, and in this room it is also the thing being copied. Walk into it and a rainbow of seven bands stands up over it; every block in the room does that once, and the first one you reach does it first.

Two blocks, four metres apart on the same row. Nothing about the second is different from the first except where it is. That difference is translation, and it is the only one of the three you could describe without looking at the block at all: a vector, four along x, nothing else.

Two blocks again, and the second is turned forty-five degrees about the upright. It stands in the same place and it is the same size, and its corners point where the first block's faces do. That difference is rotation, and it is the first one that needs the block to have a shape: you cannot turn a point.

Two blocks, and the second is one and a half times the size. Same place, same facing, more of it. That difference is scale, and it is the one you cannot see from inside: were you scaled with it, nothing would have happened.

The last pair does all three at once. The copy is moved along the row and lifted a metre, turned forty-five degrees, and grown by half. One block, one copy, three differences, and the point of the chapter in a single object: those three are added one at a time to read, and applied all at once to do. The next hall gives each of them a hole to cross.

<!-- @clipboard -->

A card at half size beside the exit. Walk within a metre and a half and its page fades up: the axioms of transformation, which say what the room just showed you in the language of a four-by-four matrix. Sixteen numbers, and every move a thing can make.

<!-- @ -->

## Before the holes

Every later room in this chapter is a floor with holes in it, and every hole is the trace of one of these three differences, used as a way through. This room is the differences at rest. Learn to see them here, between a block and its copy, and you will see them in the floor.

Next: three cubes, three pits, and the same three differences put to work.
