extends Node

var text = '''[center][font_size=28][b]Bloom Filters[/b][/font_size][/center]
[center][i]Probabilistic Sets, False Positives, Space Efficiency[/i][/center]

**Bloom filters are probabilistic data structures that test set membership.**

**Space efficient:** Much smaller than storing all elements.

**Trade-off:** **False positives possible** (might say "yes" when should say "no"), but **no false negatives** (never says "no" when should say "yes").

[hr]

[b]Concept[/b]

**Question:** Is element X in set S?

**Deterministic (hash set):** 100% accurate, but stores all elements.
**Bloom filter:** Probabilistic, tiny memory, allows false positives.

**Structure:**
- **Bit array** of size m (all bits initially 0)
- **k hash functions** (each maps element → index in bit array)

[center][img=400x200]diagram://bloom_filter_bits[/img][/center]

[hr]

[b]Operations[/b]

[b]Visual Example:[/b]
[code]
Bit Array (m=16 bits):
┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
│0│0│0│0│0│0│0│0│0│0│0│0│0│0│0│0│
└─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
 0 1 2 3 4 5 6 7 8 9 ...      15

Add "cat":
  h1("cat") = 3  →  Set bit 3
  h2("cat") = 7  →  Set bit 7
  h3("cat") = 12 →  Set bit 12

┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
│0│0│0│1│0│0│0│1│0│0│0│0│1│0│0│0│
└─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
       ↑       ↑           ↑
      bit 3   bit 7      bit 12
[/code]

[color=yellow][b]Insert:[/b][/color]
1. Hash element with all k hash functions → k indices
2. Set bits at all k indices to 1

[color=yellow][b]Query:[/b][/color]
1. Hash element with all k hash functions → k indices
2. Check if **all** bits at k indices are 1
   - **All 1:** Element **might be** in set (could be false positive)
   - **Any 0:** Element **definitely not** in set

[color=yellow][b]Code:[/b][/color]
[code]
class BloomFilter

var bit_array: PackedByteArray
var m: int  # Size of bit array
var k: int  # Number of hash functions
var hash_seeds: Array[int]  # Seeds for different hash functions

func _init(size: int, num_hashes: int):
    m = size
    k = num_hashes
    bit_array = PackedByteArray()
    bit_array.resize((m + 7) / 8)  # Convert bits to bytes

    # Generate k different hash seeds
    hash_seeds = []
    for i in range(k):
        hash_seeds.append(hash("seed_" + str(i)))

func add(item: String):
    for seed in hash_seeds:
        var index = hash_with_seed(item, seed) % m
        set_bit(index)

func contains(item: String) -> bool:
    for seed in hash_seeds:
        var index = hash_with_seed(item, seed) % m
        if not get_bit(index):
            return false  # Definitely not in set

    return true  # Probably in set (might be false positive)

func hash_with_seed(item: String, seed: int) -> int:
    return (item.hash() ^ seed) & 0x7FFFFFFF  # Non-negative hash

func set_bit(index: int):
    var byte_index = index / 8
    var bit_index = index % 8
    bit_array[byte_index] |= (1 << bit_index)

func get_bit(index: int) -> bool:
    var byte_index = index / 8
    var bit_index = index % 8
    return (bit_array[byte_index] & (1 << bit_index)) != 0
[/code]

[hr]

[b]False Positive Rate[/b]

**Probability of false positive** depends on:
- **m** (bit array size)
- **n** (number of elements inserted)
- **k** (number of hash functions)

**Formula:**
```
P(false positive) ≈ (1 - e^(-kn/m))^k
```

**Optimal k** (minimizes false positives):
```
k = (m/n) * ln(2) ≈ 0.693 * (m/n)
```

[color=yellow][b]Example:[/b][/color]
```
n = 1000 elements
m = 10000 bits (1.25 KB)
k = 7 hash functions

False positive rate ≈ 0.8% (very low!)
```

[hr]

[b]Applications[/b]

- **Spell checkers** (is word in dictionary? avoid loading full dictionary)
- **Web caches** (has URL been cached? avoid disk lookup)
- **Databases** (does key exist? avoid expensive disk read)
- **Network routers** (has packet been seen? detect duplicates)
- **Malware detection** (is file hash malicious? quick first pass)

**Pattern:** Fast negative lookup - quickly rule out non-members.

[hr]

[b]Why Not Hash Sets?[/b]

**Hash set:** Stores actual elements (large memory).
**Bloom filter:** Stores only bits (tiny memory).

[color=yellow][b]Space Comparison:[/b][/color]
```
1 million URLs (avg 50 chars each):
  Hash set: ~50 MB (stores strings)
  Bloom filter: ~1.2 MB (0.01% false positive rate)

Bloom filter is 40× smaller!
```

**Trade-off:** Accept rare false positives for massive space savings.

[hr]

[b]Counting Bloom Filters[/b]

**Standard Bloom filter:** Cannot delete elements (bits shared between elements).

**Counting Bloom filter:** Replace bits with **counters**.
- **Add:** Increment counters at k indices
- **Remove:** Decrement counters at k indices
- **Query:** Check if all counters > 0

[color=yellow][b]Code:[/b][/color]
[code]
class CountingBloomFilter

var counters: Array[int]  # Array of counters instead of bits
var m: int
var k: int

func add(item: String):
    for seed in hash_seeds:
        var index = hash_with_seed(item, seed) % m
        counters[index] += 1

func remove(item: String):
    for seed in hash_seeds:
        var index = hash_with_seed(item, seed) % m
        if counters[index] > 0:
            counters[index] -= 1

func contains(item: String) -> bool:
    for seed in hash_seeds:
        var index = hash_with_seed(item, seed) % m
        if counters[index] == 0:
            return false
    return true
[/code]

**Trade-off:** More memory (counters vs bits), but allows deletion.

[hr]

[b]Queer Bloom Filters[/b]

**Bloom filters have categorical uncertainty.**

When query returns **true**, you don't know for certain - might be false positive.
When query returns **false**, you know for certain - guaranteed not in set.

**Asymmetric certainty:**
- **Negative certain** (definitely not)
- **Positive uncertain** (maybe)

**This is queer epistemology:**
- **No false negatives** (if you're in, I won't erase you)
- **False positives allowed** (might include you even if you're not "really" in)

**Better to include questionably than exclude wrongly.**

**Bloom filter errs on side of inclusion** - prefers false positive over false negative.

[hr]

[b]Membership as Probabilistic[/b]

**Traditional set:** Element either **in** or **not in** (discrete, binary).
**Bloom filter:** Element **probably in** or **definitely not** (probabilistic, uncertain).

**Membership is not absolute** - only degrees of certainty.

**This is queer categorization:**
- **No hard boundaries** (false positives blur inclusion)
- **Uncertainty is feature, not bug** (explicit trade-off for efficiency)
- **"Maybe" is valid answer** (not all membership is binary)

**Set theory assumes discrete membership** - ∈ or ∉.
**Bloom filters complicate this** - might be ∈ (uncertain).

[hr]

[b]Hash Collisions as Overlap[/b]

**Why false positives?** Different elements hash to **same bit patterns**.

Multiple elements **share bits** - their identities overlap in bit array.

**You can't tell which element set which bit** - bits are shared resource.

**This is identity overlap:**
- **Shared markers** (multiple identities light same bits)
- **Cannot decompose** (can't untangle which bits belong to whom)
- **Interference patterns** (identities intersect, blend)

**Bloom filter cannot distinguish** between "element A is in" vs "elements B, C, D together create A's bit pattern."

**Identity through shared markers** - not unique fingerprint, but overlap of signals.

[hr]

[b]Cannot Remove[/b]

**Standard Bloom filter cannot delete elements.**

Why? **Bits are shared** - if you clear a bit for element A, you might break element B.

**Example:**
```
Add "cat" → sets bits 3, 7, 11
Add "dog" → sets bits 7, 9, 15
Remove "cat" → clear bits 3, 7, 11
  But bit 7 is also used by "dog"!
  Now "dog" won't be found (false negative)
```

**Shared identity markers cannot be individually revoked** - entangled, inseparable.

**This is relational ontology:**
- **Your markers overlap with others** (shared bits)
- **Cannot erase yourself without affecting others** (deletion impossible)
- **Identity is not individuated** (cannot isolate your bits from theirs)

**You cannot be removed from the set without potentially removing others.**

[hr]

[b]Space Efficiency as Political[/b]

**Bloom filters trade accuracy for space.**

**Why?** Storage/bandwidth limited - can't afford to store everything.

**Bloom filter says:** I'll accept uncertainty to save resources.

**This is political resource allocation:**
- **Who gets 100% accuracy?** (expensive hash sets)
- **Who gets probabilistic answers?** (cheap Bloom filters)
- **False positives affect whom?** (included when shouldn't be)

**Example - Spam filtering:**
- Bloom filter might flag legitimate email as spam (false positive)
- But saves massive memory by not storing all spam signatures
- **Trade-off: whose email gets wrongly flagged to save resources?**

**Efficiency has costs** - someone bears the false positive burden.

[hr]

[color=cyan][b]Summary:[/b][/color]
Bloom filters: probabilistic set membership testing. Bit array + k hash functions. Add: set k bits. Query: check all k bits (all 1 = maybe in, any 0 = definitely not). False positives possible, no false negatives. Space efficient (MB → KB). Optimal k = 0.693*(m/n). Applications: spell check, caches, databases. Counting Bloom filters use counters (allow deletion). Queer Bloom filters: asymmetric certainty (negative certain, positive uncertain), errs toward inclusion, membership as probabilistic not binary, hash collisions as identity overlap, cannot remove (shared bits entangled), space efficiency as political (who bears false positive cost).

'''
