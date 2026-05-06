Branching corridors fork and rejoin, separated by void trenches. The same path appears twice — once as a recursive descent that splits and splits again, once as a flattened loop that remembers what it already computed.

A recursive tree builds the same subtree thousands of times. Memoization collapses that redundancy: compute once, look up forever after. Tail recursion goes further — it never builds the stack at all, converting depth into iteration. The insight is not about speed. It is that memory and structure are interchangeable.
