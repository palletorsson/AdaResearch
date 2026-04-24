# Random Definition

Randomness is irreducibility. Build the crank machine that separates pseudo-random from true random.

Declare the PRNG.

```gdscript
class_name PRNGCrank
extends Node

@export var seed: int = 42
var state: int = 0

func _ready() -> void:
    state = seed
```

A PRNG keeps state. The seed is the only hidden input. Same seed, same sequence.

Step the state.

```gdscript
func next() -> int:
    state = (state * 1103515245 + 12345) & 0x7fffffff
    return state
```

A linear congruential step. The numbers look random but are fully determined by the previous state.

Produce a uniform float.

```gdscript
func uniform() -> float:
    return float(next()) / float(0x7fffffff)
```

Dividing by the maximum yields a value in [0, 1). The function is reproducible across runs with the same seed.

Expose a crank handle.

```gdscript
func _on_crank_turned(turns: float) -> void:
    for i in int(turns):
        var v := uniform()
        history.append(v)
        readout_label.text = "%.4f" % v
```

Each quarter turn emits one sample. The readout updates. The learner watches the sequence appear.

Compare to a TRNG source.

```gdscript
func true_random_sample() -> float:
    var t := Time.get_ticks_usec()
    var hardware: int = (t ^ (t >> 13)) & 0xfffff
    return float(hardware) / float(0xfffff)
```

Hardware entropy from the clock is not cryptographic, but it is not reproducible. The same program on the same seed yields different values every run.

Log the seed and sample.

```gdscript
func log_sample(v: float, kind: String) -> void:
    log_entries.append({"kind": kind, "value": v, "seed": seed})
```

Entries tag which source produced the value. The log becomes evidence for the distinction.

Plot the histogram.

```gdscript
func update_histogram(values: Array) -> void:
    var bins := PackedInt32Array()
    bins.resize(10)
    for v in values:
        bins[int(clamp(v * 10.0, 0, 9))] += 1
    histogram.update(bins)
```

Ten bins show the distribution. Uniform means equal heights, roughly. Deviations shrink as the sample grows.

You have named the vocabulary. The next map, Random Remove, turns randomness into subtraction.
<<</MAP>>>

Seed from player input.

```gdscript
func _on_seed_keyboard_entry(text: String) -> void:
    if text.is_valid_int():
        seed = int(text)
        state = seed
```

The learner can type a seed. Any reproducible run becomes shareable.

Compare PRNG and TRNG side by side.

```gdscript
func compare_sources(count: int) -> void:
    for i in count:
        log_sample(uniform(), "prng")
        log_sample(true_random_sample(), "trng")
```

Pairs of samples accumulate under each label. The histograms diverge subtly over time.

Expose a bit view.

```gdscript
func bit_view(v: float) -> String:
    var bits: int = int(v * 0xffffff)
    return String.num_int64(bits, 2).pad_zeros(24)
```

Each float becomes a binary string. The view exposes the underlying entropy source in its rawest form.
