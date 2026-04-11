A chain of rooms, each connected to the next by a single narrow passage. No shortcuts. No way to jump from the first room to the fifth without passing through two, three, four. The passage is the pointer. The room is the node.

A linked list is memory scattered across a heap, stitched together by addresses. Each node holds its data and a reference to the next. Insertion is cheap — splice a new node in by rewriting two pointers. Random access is expensive — you must walk the chain from the head, counting steps. The room enforces this. You cannot skip ahead. You navigate by traversal, not by index.

Arrays know where everything is. Linked lists know only what comes next. That constraint is not a limitation — it is a different relationship to sequence, one where connection matters more than position.
