# Keep the counts, change the neighbours

Random_Definition made repeatability depend on a seed and a procedure. Random_Entropy takes another seeded sequence and asks what its measurement retains. The primary is `shannon_entropy_meter:90#stand:ledger#disclosure:ledger` at (5,6). All excerpts below come from `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd`.

## Read two records of the same sample

Find a pair among the 200 tiles on the desk. The first forty are marked there, spelled out on the upper panel, and shown enlarged on the front face. The enlarged excerpt stays in draw order even when SORT regroups the upper ribbon. It is an excerpt of the active sample, not another sample.

The opening sequence is drawn once from a local seeded generator:

```gdscript
for i in range(sequence_length):
    sequence.append(_rng.randi_range(0, num_symbols - 1))
```

The map uses ten symbols and 200 draws. The default seed is `hash("shannon_entropy")`, exposed in the source readout. These draws are independent of the previous hall's RGB generator. The continuity between rooms is the question of procedure, not a transfer of that room's colours into this meter.

## Sort before explaining the invariant

Press SORT and watch both the ribbon and the bars. The tiles move into symbol groups over 1.2 seconds. Their counts and entropy remain. SORT does not resample or overwrite the original sequence. It changes where the existing tile instances are drawn, using a stable order within each symbol group. Press again to restore their positions.

The sorted copy used by the readout is constructed as follows:

```gdscript
func sorted_copy() -> Array[int]:
    var out: Array[int] = []
    for sym in range(num_symbols):
        for i in range(_sequence.size()):
            if _sequence[i] == sym:
                out.append(sym)
    return out
```

The measurement visits one symbol at a time:

```gdscript
for s in sequence:
    counts[s] += 1
```

Every permutation of this sample gives the same counts. The entropy loop receives those counts, without the positions:

```gdscript
for c in counts:
    if c > 0:
        var p: float = float(c) / float(sequence_length)
        entropy -= p * (log(p) / log(2.0))
```

Each observed share p weights its own information value, −log₂(p). The result is an average in bits per symbol under these empirical shares, not the total information in a 200-symbol message. Zero-count terms contribute zero and are skipped before the logarithm. An all-one-symbol sample gives zero. Twenty copies of each of ten symbols give log₂(10), about 3.321928. The arrival sample gives approximately 3.255647 because its counts differ from twenty each.

SORT can make groups easier to find without changing this number. A repeating cycle of ten symbols can also have maximum marginal entropy. The loop does not condition a prediction on the previous symbol. It therefore cannot measure every kind of predictability, dependency, meaning or compressibility in the ordered sequence.

## Change the source, keeping the alphabet and N

CONTRAST selects a cached second sample with its own seed, the first seed plus one. Its source weights decrease by a factor of two:

```gdscript
for k in range(num_symbols):
    weights.append(pow(2.0, -float(k)))
```

A local generator draws against their cumulative sum. The normalized source probabilities are approximately 0.50049, 0.25024, 0.12512, and so on. They imply expected counts; they do not impose those counts on a finite sample. The captured sample has counts [109,46,20,17,6,2,0,0,0,0] and H ≈ 1.817600. CONTRAST again restores the original 200 draws. The current sorting choice is retained.

## Ask the display what its heights mean

The upper bars use a height relative to the largest count in the active sample:

```gdscript
var height: float = (float(counts[i]) / float(max_count)) * FREQ_BAR_HEIGHT if max_count > 0 else 0.0
height = max(0.002, height)
```

The largest bar is 0.10 m tall whether its count is 31 or 109. Four zero counts in the concentrated sample still get 0.002 m marks. These choices make the marks visible and fit each histogram into the panel. They prevent direct comparison of absolute counts by height across samples. The desk prints the counts so the reader can check the scaling.

## Disclose a model after observing its sample

DISCLOSE moves through ledger → works → origin → oracle → tally → ledger. Works reveals the formula. Origin names the generator and seed and adds pale expected-count bars from the active source: 20 each for the uniform law; approximately [100.1,50.0,25.0,12.5,6.3,3.1,1.6,0.8,0.4,0.2] for the concentrated law. The ghosts share the sample's vertical scale, are capped at its maximum display height, and have the same 2 mm minimum. Small positive expectations and zero observed counts may therefore have the same drawn height.

Oracle withholds the upper panel's supporting displays. It does not remove the desk's tiles, excerpt or readout. The source is still available elsewhere in the installation. Repeated disclosure changes rebuild the upper panel once while keeping the desk, sorting state and the selected built-in sample consistent.

The next hall, Random_Remove, makes selection spatial. Before a random choice removes a cell, another rule has already decided which cells are eligible.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.
