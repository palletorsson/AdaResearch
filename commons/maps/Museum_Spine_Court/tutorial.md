# Tutorial — Museum_Spine_Court

## Claim
Placement is a grammar, and museums are its grammar books. Five rules place any collection: axial anchor, flanking pair, greeter, perimeter rhythm, open center.

## Idea
Read the great courts (Cour Marly, the Met's Dendur wing, the NHM nave) and the same structure repeats: the walk enters HIGH and descends INTO the collection (terraces = the curated axis); one monumental piece anchors the far end of the axis so every sightline resolves; pairs flank thresholds; small pieces keep a steady beat along the walls; the middle stays walkable. Light comes from above so the objects, not the windows, own the shadows.

## Code
```text
grammar MUSEUM_COURT:
  terraces   := heights descending toward the court   # enter high, descend in
  anchor     := largest piece @ far end of main axis  # every sightline ends here
  flank(T)   := pair of pieces @ threshold T          # stair heads, doors
  rhythm     := small pieces @ regular bays, walls    # arcade beat
  center     := KEEP OPEN (floor may be art)          # the middle is for the walker
  light      := from above                            # collection casts the shadows
```

## Try
1. Stop on the entry terrace before descending. Count what you can already see — the grammar is designed to be legible from here.
2. Walk the axis without stopping. Notice the anchor grows the whole way; that is the sightline doing its work.
3. Now walk the perimeter instead. The rhythm pieces come at an even beat — arcade bays as a metronome.
4. Stand in the open center on the mosaic and turn around once. Every piece faces you. That is the grammar's real output: from the center, the collection is a single sentence.
