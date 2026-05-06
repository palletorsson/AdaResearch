**Skip Lists**
Probabilistic Data Structures, Layered Lists, Fast Search

**Skip lists are probabilistic data structures providing O(log n) search/insert/delete.**

**Alternative to balanced trees** (AVL, Red-Black) with simpler implementation.

**Core idea:** Layered linked lists with **express lanes** for fast traversal.

---

## Concept

**Linked list:** O(n) search (must traverse sequentially).

**Skip list:** Multiple layers - upper layers **skip** over elements.

**Structure:**
- **Bottom layer:** All elements (complete sorted linked list)
- **Higher layers:** Subset of elements (sparse