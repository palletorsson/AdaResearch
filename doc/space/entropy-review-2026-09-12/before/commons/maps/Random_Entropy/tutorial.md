# Tutorial — Random_Entropy

## Claim
Entropy measures surprise, not mess. Sort a sequence of two hundred draws into blocks and the gauge reads the same number; change the shares between the symbols and it falls. Every excerpt below is from `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd`, the room's gauge.

## Idea
Shannon's move: do not ask what a message means, ask how unexpected each symbol is. If every draw is the same symbol, the single-symbol entropy is zero; this measurement leaves other questions about the sequence open. If ten symbols are equally likely, their entropy is log₂(10) = 3.32 bits per symbol; a fixed binary label for one of ten symbols still needs four bits. The gauge draws a sample, tallies it, and applies the formula to the tallies.

## Code
Draw the sample from a seeded local generator, so the same two hundred symbols arrive every time the gauge is built:

```gdscript
	for i in range(sequence_length):
		sequence.append(_rng.randi_range(0, num_symbols - 1))
```

Tally it — one count per symbol, nothing about position:

```gdscript
	for s in sequence:
		counts[s] += 1
```

Turn the tallies into bits, skipping symbols that never occurred (a zero share has no logarithm):

```gdscript
	for c in counts:
		if c > 0:
			var p: float = float(c) / float(sequence_length)
			entropy -= p * (log(p) / log(2.0))
```

Know the ceiling, which depends only on the alphabet:

```gdscript
	var max_h: float = log(num_symbols) / log(2.0)
```

The same loop, over any counts, is what the desk's readout uses for the sorted copy:

```gdscript
static func entropy_of(counts: Array, n: int) -> float:
```

## Try
1. Read the tiles and the bars before the number. The bars are the tallies; the tiles are the order.
2. Press SORT. The tiles regroup into ten blocks; the bars and H stay. The readout counts how many tiles moved and prints the sorted copy's H beside the reading.
3. Press CONTRAST. Same ten symbols, same two hundred draws, a concentrated source: the number falls to about two bits and the first bar towers.
4. Press DISCLOSE until the formula and then the source appear on the panel. The reading stays while the upper panel reveals its account; the desk keeps its tiles and readout. At the source rung the pale bars behind the live ones are the named source's expected counts — a flat line for the even source, a staircase for the concentrated one — and the plate prints them.
5. Ask what the number did not notice: the order, any pattern between neighbours, whether the row meant anything.

## Where it goes
The next room, Random_Remove, makes the eligible set spatial: a rule decides what can be chosen before anything is removed at random.
