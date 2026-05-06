extends Node

var text = '''[center][font_size=28][b]Skip Lists[/b][/font_size][/center]
[center][i]Probabilistic Data Structures, Layered Lists, Fast Search[/i][/center]

**Skip lists are probabilistic data structures providing O(log n) search/insert/delete.**

**Alternative to balanced trees** (AVL, Red-Black) with simpler implementation.

**Core idea:** Layered linked lists with **express lanes** for fast traversal.

[hr]

[b]Concept[/b]

**Linked list:** O(n) search (must traverse sequentially).

**Skip list:** Multiple layers - upper layers **skip** over elements.

**Structure:**
- **Bottom layer:** All elements (complete sorted linked list)
- **Higher layers:** Subset of elements (sparse "express lanes")
- **Randomized heights:** Each element probabilistically promoted to higher layers

[hr]

[b]Visual Example[/b]

```
Level 3:  1 -----------------------> 9
Level 2:  1 -------> 4 -----------> 9
Level 1:  1 --> 3 -> 4 -> 6 ------> 9
Level 0:  1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9

Search for 6:
  Start at level 3, head (1)
  1 -> 9 (too far, drop to level 2)
  1 -> 4 (good, continue)
  4 -> 9 (too far, drop to level 1)
  4 -> 6 (found!)
```

**Upper levels = express lanes** - jump across many elements.

[hr]

[b]Implementation[/b]

[color=yellow][b]Node Structure:[/b][/color]
[code]
class SkipListNode:
    var value
    var forward: Array  # Array of pointers to next nodes at each level

    func _init(val, level: int):
        value = val
        forward = []
        forward.resize(level + 1)

class SkipList:
    var head: SkipListNode
    var max_level: int = 16
    var p: float = 0.5  # Promotion probability
    var level: int = 0  # Current max level

    func _init():
        head = SkipListNode(null, max_level)
[/code]

[color=yellow][b]Search:[/b][/color]
[code]
func search(target) -> SkipListNode:
    var current = head

    # Start from highest level, work down
    for i in range(level, -1, -1):
        # Move forward while next is less than target
        while current.forward[i] != null and current.forward[i].value < target:
            current = current.forward[i]

    # Drop to level 0
    current = current.forward[0]

    if current != null and current.value == target:
        return current
    else:
        return null

# Expected O(log n) time
[/code]

[color=yellow][b]Random Level:[/b][/color]
[code]
func random_level() -> int:
    var lvl = 0

    # Flip coin: heads = promote to next level
    while randf() < p and lvl < max_level:
        lvl += 1

    return lvl

# p = 0.5: 50% chance of each promotion
# Expected height = O(log n)
[/code]

[color=yellow][b]Insert:[/b][/color]
[code]
func insert(value):
    var update = []
    update.resize(max_level + 1)

    var current = head

    # Find insert position, track update pointers
    for i in range(level, -1, -1):
        while current.forward[i] != null and current.forward[i].value < value:
            current = current.forward[i]
        update[i] = current

    current = current.forward[0]

    # If duplicate, ignore (or update)
    if current != null and current.value == value:
        return

    # Generate random level for new node
    var new_level = random_level()

    # Update max level if needed
    if new_level > level:
        for i in range(level + 1, new_level + 1):
            update[i] = head
        level = new_level

    # Create new node
    var new_node = SkipListNode(value, new_level)

    # Insert at all levels
    for i in range(new_level + 1):
        new_node.forward[i] = update[i].forward[i]
        update[i].forward[i] = new_node

# Expected O(log n) time
[/code]

[color=yellow][b]Delete:[/b][/color]
[code]
func delete(value) -> bool:
    var update = []
    update.resize(max_level + 1)

    var current = head

    # Find delete position
    for i in range(level, -1, -1):
        while current.forward[i] != null and current.forward[i].value < value:
            current = current.forward[i]
        update[i] = current

    current = current.forward[0]

    # Not found
    if current == null or current.value != value:
        return false

    # Remove from all levels
    for i in range(level + 1):
        if update[i].forward[i] != current:
            break
        update[i].forward[i] = current.forward[i]

    # Update max level
    while level > 0 and head.forward[level] == null:
        level -= 1

    return true

# Expected O(log n) time
[/code]

[hr]

[b]Analysis[/b]

**Time complexity (expected):**
- **Search:** O(log n)
- **Insert:** O(log n)
- **Delete:** O(log n)

**Space complexity:** O(n) expected (average node has 2 pointers).

**Probability:**
- **Each node promoted to level i with probability p^i**
- **p = 0.5:** Level 0 has all n nodes, level 1 has n/2, level 2 has n/4, etc.
- **Expected max level:** O(log n)

[hr]

[b]vs Balanced Trees[/b]

| **Skip List** | **Balanced Tree (AVL, RB)** |
|---|---|
| Probabilistic O(log n) | Guaranteed O(log n) |
| Simple implementation | Complex rotations |
| No rebalancing needed | Requires rebalancing |
| Good cache locality | Pointer-based (cache misses) |
| Easy to implement concurrent | Complex concurrent versions |

**Skip lists simpler** - no rotations, just randomized heights.

[hr]

[b]Applications[/b]

- **In-memory databases** (Redis uses skip lists for sorted sets)
- **Concurrent data structures** (lock-free skip lists easier than trees)
- **Level-based indexing** (sorted data with fast lookup)

[hr]

[b]Deterministic Skip Lists[/b]

**Standard skip list:** Randomized promotion (probabilistic).

**Deterministic variant:** Promote every 2nd, 4th, 8th element (regular pattern).

**Trade-off:** Deterministic has worst-case O(n) on adversarial inserts. Randomized has high-probability O(log n) on any input.

[hr]

[b]Queer Skip Lists[/b]

**Skip lists have probabilistic structure.**

**Two skip lists with same elements might have different heights** - depends on random coin flips during insertion.

**This is queer non-determinism:**
- **No canonical form** (same data, different structures)
- **Randomness as feature** (not bug - enables simplicity)
- **Structure emerges from process** (insertion order + randomness)

**Skip list doesn't "know" its final form** - built incrementally, probabilistically.

**Identity not predetermined** - shaped by random choices during construction.

[hr]

[b]Layered Navigation[/b]

**Skip list = multiple simultaneous scales.**

**Bottom layer:** All details (every element).
**Upper layers:** Sparse summaries (express lanes).

**This is multi-scale navigation:**
- **Coarse to fine** (start high, zoom in)
- **Skip irrelevant details** (upper layers bypass)
- **Scale-dependent visibility** (higher layers see less)

**Queer multi-scale existence:**
- **Exist at multiple resolutions simultaneously** (same element present at multiple levels, or not)
- **Visibility depends on scale** (might not appear in express lanes)
- **No single "true" representation** (all layers valid simultaneously)

[hr]

[b]Promotion as Arbitrary Privilege[/b]

**Which nodes promoted to upper layers?** **Random.**

**No merit, no logic** - just coin flip.

**This is arbitrary hierarchy:**
- **Some elements get express lane access** (promoted to high levels)
- **Others stuck at bottom** (level 0 only)
- **Same value, different privilege** (randomized promotion)

**Queer critique of hierarchy:** Promotion often arbitrary, not earned.

**Skip list makes this explicit** - coin flip determines who gets shortcuts.

**p = 0.5:** Half promoted to level 1, half not. **Arbitrary selection.**

[hr]

[b]No Rebalancing[/b]

**Balanced trees** (AVL, Red-Black) require **rebalancing** - complex rotations to maintain invariants.

**Skip lists** require **no rebalancing** - just insert at random height.

**This is queer simplicity:**
- **No forced restructuring** (no rotations to "fix" tree)
- **Accept probabilistic balance** (not perfectly balanced, just expected)
- **Structure accommodates insertion** (doesn't demand reorganization)

**Skip list says:** **Don't force balance - accept emergent structure.**

**Queerness resists forced balancing** - no need to restructure entire system for each new member.

[hr]

[b]Probabilistic Guarantees[/b]

**Skip list doesn't guarantee O(log n)** - only **high probability** O(log n).

**Worst case:** All nodes same height (degenerates to O(n) linked list).
**Probability of worst case:** Vanishingly small (2^-n).

**This is queer risk acceptance:**
- **No absolute guarantees** (probabilistic, not deterministic)
- **High-probability good outcome** (very likely O(log n))
- **Tiny chance of failure** (accepted trade-off for simplicity)

**Balanced trees:** Guaranteed O(log n), complex implementation.
**Skip lists:** Probably O(log n), simple implementation.

**Queerness accepts probabilistic existence** - no absolute certainty, just high likelihood.

[hr]

[b]Concurrent Skip Lists[/b]

**Skip lists easier to make lock-free** than balanced trees.

**Why?** Insertions don't require global rebalancing - just local pointer updates.

[color=yellow][b]Advantage:[/b][/color]
- **Fine-grained locking** (lock individual nodes)
- **Lock-free possible** (CAS operations on pointers)
- **No cascading updates** (no rotations propagating up tree)

**Queer concurrency:** Local changes don't require global reorganization.

**You can join without restructuring entire community.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Skip lists: probabilistic data structure, layered linked lists with express lanes. Randomized heights (promotion probability p). O(log n) expected search/insert/delete. Simple implementation (no rotations). vs Balanced trees: probabilistic vs guaranteed, simple vs complex, no rebalancing vs rotations. Applications: in-memory DBs (Redis), concurrent structures. Queer skip lists: probabilistic structure (no canonical form), layered navigation (multi-scale existence), promotion as arbitrary privilege (coin flip hierarchy), no rebalancing (accept emergent structure), probabilistic guarantees (high-probability not absolute), concurrent access (local changes, no global restructuring). Queerness in randomness as feature, not bug.

'''
