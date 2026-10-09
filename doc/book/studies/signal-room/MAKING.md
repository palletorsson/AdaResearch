# Keep the values. Change their neighbours.

You already have a running scene, an indexed array and a seeded random-number generator. This study uses them together. The supplied viewer takes care of putting the picture around a body.

Begin with **Repeat**. The white band to your left meets a black band to your right. Follow one of them across the floor and up the wall. The bend belongs to the room; the array continues through it.

Each address holds either zero or one. The index still comes from a row and a column:

```gdscript
var index := row * COLUMNS + column
values[index] = (int(row / 2) + int(column / 8)) % 2
```

There are 16 columns and 256 rows. Integer division groups two rows at a time and splits the columns into two banks of eight; the remainder `% 2` alternates black and white. Change `row / 2` to `row / 4` in `artifacts/score.gd`. Run again. The bands become twice as deep, while the addresses and the total of each value stay the same.

Now choose **Shuffle rows**. The thicknesses no longer repeat regularly. Every original row still exists, including its two complementary halves. What changed was the order in which whole rows were placed.

Choose **Shuffle cells**. The halves break apart. Each individual value can change address. There are still 2,048 of each. Shuffling a collection is a different operation from drawing a fresh zero or one independently at every address: here, an extra white cell somewhere must be balanced by a black cell elsewhere.

In the supplied shuffle, a list of source indices is permuted first. Each destination then reads one source. The cell case reduces to:

```gdscript
result[index] = ordered[order[index]]
```

`order` contains every source index exactly once. That is the promise a permutation keeps. Open the short Fisher–Yates loop that constructs it when the relationship between source and destination is clear. It draws each swap from the remaining unplaced indices, including the current one. It uses a local generator, so another artifact cannot consume its next draw.

Keep the mode fixed, note a seed, change it, then enter the old seed again. The picture returns in this Godot version. A seed works with a procedure and its implementation; it is not a portable picture file or a promise that every future engine version will emit the same stream.

The small monitor reads 16 values from the same displayed array. Slide its first row through the record. Its columns straddle the two original banks, making the relation between local choice and large pattern visible. **Step one row** changes the displayed offset, not the stored record; after 256 steps it returns.

## Make something of your own

Keep the dimensions and values fixed for the first experiment. Change how they can move. What happens if only the left bank is shuffled? What happens if groups of four rows travel together? Record the seed, the group size and the mode beside one screenshot. Your result should make it possible for someone else to reconstruct the decision, not merely admire the pattern.

The large room is borrowed apparatus at this stage. Materials, texture uploads, triangle UVs, camera code and collision construction can wait. What you should be able to carry away is smaller: **an address, a value, and a decision about which relations a rearrangement is allowed to break.**
