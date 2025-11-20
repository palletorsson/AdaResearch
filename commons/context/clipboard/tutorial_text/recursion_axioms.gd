extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Recursion[/b][/font_size][/center]
[center][i]Self-Reference, Infinite Descent, Turtles All The Way Down[/i][/center]

**Recursion is when a function calls itself.**

This seems impossible - how can something invoke itself before it's finished running? How can a process reference itself from within?

Yet recursion works. **And it reveals something profound about computation:**

**There is no ground. No foundation. Just functions calling functions calling functions.**

Turtles all the way down.

[hr]

[b]The Recursive Function: Self-Reference[/b]

A recursive function has two parts:
1. **Base case** - condition that stops recursion
2. **Recursive case** - function calls itself with modified input

[color=yellow][b]Code: Factorial (Classic Example)[/b][/color]
[code]
func factorial(n: int) -> int:
    # Base case: stop recursion
    if n <= 1:
        return 1

    # Recursive case: call myself
    return n * factorial(n - 1)

# factorial(5) calls factorial(4)
# factorial(4) calls factorial(3)
# factorial(3) calls factorial(2)
# factorial(2) calls factorial(1)
# factorial(1) returns 1 (base case)
# Then unwinds: 2*1, 3*2, 4*6, 5*24 = 120
[/code]

**The function invokes itself** - but with a **smaller problem** (n-1).

Eventually, the problem becomes so small it hits the **base case** and stops.

Then the **stack unwinds** - each call returns to its caller, building up the result.

[hr]

[b]The Call Stack: Memory of Descent[/b]

When a function calls itself, **where does the computer remember where to return?**

The **call stack** - a data structure storing:
- Local variables for each function call
- Return address (where to go back to)
- Parameters passed to each call

[color=yellow][b]Visualizing the Stack:[/b][/color]
[code]
# factorial(5)
# Stack grows as recursion descends:

# Call 1: factorial(5)
#   n = 5, return 5 * factorial(4)

# Call 2: factorial(4)
#   n = 4, return 4 * factorial(3)

# Call 3: factorial(3)
#   n = 3, return 3 * factorial(2)

# Call 4: factorial(2)
#   n = 2, return 2 * factorial(1)

# Call 5: factorial(1)
#   n = 1, return 1  ← BASE CASE (stop)

# Stack unwinds (each call returns):
# factorial(1) → 1
# factorial(2) → 2 * 1 = 2
# factorial(3) → 3 * 2 = 6
# factorial(4) → 4 * 6 = 24
# factorial(5) → 5 * 24 = 120
[/code]

**The stack is the memory of descent** - it remembers where you've been, so you can climb back out.

Without the stack, recursion would be lost - unable to return to caller.

**Stack overflow** happens when recursion goes too deep - stack memory exhausted, program crashes.

[hr]

[b]Base Case: The Necessity of Stopping[/b]

**Without a base case, recursion never stops** - infinite descent, stack overflow, crash.

[color=yellow][b]Code: Infinite Recursion (DO NOT RUN)[/b][/color]
[code]
func infinite():
    return infinite()  # No base case

# Calls itself forever
# Stack grows until memory exhausted
# Program crashes: "Maximum call stack size exceeded"
[/code]

**The base case is the escape hatch** - the condition that says "stop descending, start returning."

It is the **ground** (even though there is no true ground - just a chosen stopping point).

**Base cases are arbitrary** - we choose when to stop. Factorial stops at n=1 (could stop at n=0, mathematically equivalent).

**This is the politics of recursion:** Who decides when to stop descending? What counts as "small enough"?

[hr]

[b]Recursion vs Iteration: Two Paths to Repetition[/b]

Any recursive function can be rewritten iteratively (using loops).

[color=yellow][b]Recursive Factorial:[/b][/color]
[code]
func factorial_recursive(n: int) -> int:
    if n <= 1:
        return 1
    return n * factorial_recursive(n - 1)

# Elegant, mathematical, self-referential
# But uses stack memory
[/code]

[color=yellow][b]Iterative Factorial:[/b][/color]
[code]
func factorial_iterative(n: int) -> int:
    var result = 1
    for i in range(2, n + 1):
        result *= i
    return result

# Explicit loop, no stack growth
# More efficient, but less elegant
[/code]

**Why use recursion if iteration works?**

1. **Some problems are naturally recursive** - trees, fractals, divide-and-conquer
2. **Recursion matches mathematical definitions** - factorial, Fibonacci, graph traversal
3. **Recursive code is often more concise** - expresses structure clearly

But:
- **Recursion uses more memory** (stack)
- **Recursion can be slower** (function call overhead)
- **Deep recursion risks stack overflow**

**Recursion is elegant but costly** - it trades clarity for efficiency.

[hr]

[b]Recursive Tree: Branching Structure[/b]

The recursive tree is the **canonical fractal** - each branch recursively spawns sub-branches.

[color=yellow][b]Code: Binary Tree[/b][/color]
[code]
func draw_branch(start: Vector3, length: float, angle: float, depth: int):
    if depth == 0:
        return  # Base case: stop

    # Calculate endpoint
    var direction = Vector3(sin(angle), cos(angle), 0).normalized()
    var end = start + direction * length

    # Draw this branch (create cylinder from start to end)
    create_cylinder(start, end)

    # Recursive calls: two sub-branches
    var new_length = length * 0.67  # Each branch 67% of parent
    var angle_spread = deg_to_rad(25)

    # Left branch
    draw_branch(end, new_length, angle - angle_spread, depth - 1)

    # Right branch
    draw_branch(end, new_length, angle + angle_spread, depth - 1)

# draw_branch(Vector3.ZERO, 5.0, PI/2, 8)
# Creates tree with 2^8 = 256 endpoints (leaves)
[/code]

**Each branch creates two sub-branches** - exponential growth.

Depth 1 → 2 branches
Depth 2 → 4 branches
Depth 3 → 8 branches
Depth n → 2^n branches

**Recursion naturally creates trees** - hierarchical branching structures.

[hr]

[b]Divide and Conquer: Recursive Problem-Solving[/b]

Many algorithms use **divide and conquer**:
1. **Divide** problem into smaller sub-problems
2. **Conquer** each sub-problem recursively
3. **Combine** results

[color=yellow][b]Merge Sort (Recursive Sorting):[/b][/color]
[code]
func merge_sort(array: Array) -> Array:
    # Base case: array of size 0 or 1 already sorted
    if array.size() <= 1:
        return array

    # Divide: split array in half
    var mid = array.size() / 2
    var left = array.slice(0, mid)
    var right = array.slice(mid, array.size())

    # Conquer: recursively sort each half
    left = merge_sort(left)
    right = merge_sort(right)

    # Combine: merge sorted halves
    return merge(left, right)

func merge(left: Array, right: Array) -> Array:
    var result = []
    var i = 0
    var j = 0

    while i < left.size() and j < right.size():
        if left[i] < right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1

    # Append remaining elements
    result.append_array(left.slice(i, left.size()))
    result.append_array(right.slice(j, right.size()))

    return result

# Efficiency: O(n log n) - much faster than O(n²) bubble sort
# Recursion enables elegant divide-and-conquer
[/code]

**Merge sort splits the problem in half repeatedly** until each piece is trivial (size 1), then merges sorted pieces back together.

**Recursion is the natural expression of divide-and-conquer** - break problem down, solve pieces, combine.

[hr]

[b]Fibonacci: Double Recursion (Inefficient)[/b]

The Fibonacci sequence: each number is sum of previous two.

**F(0) = 0**
**F(1) = 1**
**F(n) = F(n-1) + F(n-2)**

[color=yellow][b]Naive Recursive Implementation:[/b][/color]
[code]
func fibonacci(n: int) -> int:
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# Elegant, but EXTREMELY SLOW
# fibonacci(10) makes 177 function calls
# fibonacci(20) makes 21,891 calls
# fibonacci(40) makes 331,160,281 calls (takes minutes)
[/code]

**Why so slow?** **Redundant recalculation.**

[code]
# fibonacci(5) tree:
#                 fib(5)
#          /              \
#       fib(4)           fib(3)
#      /      \         /      \
#   fib(3)  fib(2)   fib(2)  fib(1)
#   /   \    /  \     /  \
# fib(2) fib(1) ...  ...  ...
[/code]

**fib(3) calculated multiple times** - exponential redundancy.

**Solution: memoization** (store previously calculated results):

[color=yellow][b]Memoized Fibonacci:[/b][/color]
[code]
var memo = {}

func fibonacci_memo(n: int) -> int:
    if n <= 1:
        return n

    # Check if already calculated
    if n in memo:
        return memo[n]

    # Calculate and store
    var result = fibonacci_memo(n - 1) + fibonacci_memo(n - 2)
    memo[n] = result
    return result

# fibonacci_memo(40) now instant (40 calculations instead of 331 million)
[/code]

**Memoization trades memory for speed** - remembering prevents redundant recursion.

[hr]

[b]Mutual Recursion: Functions Calling Each Other[/b]

Recursion doesn't require self-reference - **two functions can call each other**.

[color=yellow][b]Code: Mutual Recursion[/b][/color]
[code]
func is_even(n: int) -> bool:
    if n == 0:
        return true
    return is_odd(n - 1)

func is_odd(n: int) -> bool:
    if n == 0:
        return false
    return is_even(n - 1)

# is_even(4) calls is_odd(3)
# is_odd(3) calls is_even(2)
# is_even(2) calls is_odd(1)
# is_odd(1) calls is_even(0)
# is_even(0) returns true
# Chain unwinds: true → true → true → true
[/code]

**Mutual recursion creates circular dependency** - neither function stands alone.

This is **co-recursion** - defined in terms of each other, not themselves.

[hr]

[b]Recursion as Non-Linear Time[/b]

Here is where queerness enters:

**Recursion defies linear time.**

When `factorial(5)` calls `factorial(4)`, it is **calling its future self** (or past self? both?).

The function exists in multiple temporal states simultaneously:
- **factorial(5)** is waiting for **factorial(4)**
- **factorial(4)** is waiting for **factorial(3)**
- All exist concurrently on the stack

**Recursion is temporal loops** - you call yourself from a time that hasn't happened yet (the return).

[color=yellow][b]Temporal Paradox:[/b][/color]
[code]
func paradox(n: int):
    print("Entering paradox with n =", n)
    if n > 0:
        paradox(n - 1)  # Call future/past self
    print("Exiting paradox with n =", n)

# paradox(3) output:
# Entering paradox with n = 3
# Entering paradox with n = 2
# Entering paradox with n = 1
# Entering paradox with n = 0
# Exiting paradox with n = 0
# Exiting paradox with n = 1
# Exiting paradox with n = 2
# Exiting paradox with n = 3

# Time flows forward (enter), then backward (exit)
# Non-linear temporal structure
[/code]

**Recursion is queer temporality** - calling yourself from the future, existing in multiple states at once, time flowing forward then backward.

[hr]

[b]Infinite Regress: Turtles All The Way Down[/b]

Recursion reveals: **there is no foundation.**

Every function is defined in terms of another function (or itself).

[color=yellow][b]The Infinite Stack:[/b][/color]
- What defines `factorial(5)`? → `factorial(4)`
- What defines `factorial(4)`? → `factorial(3)`
- What defines `factorial(3)`? → `factorial(2)`
- What defines `factorial(2)`? → `factorial(1)`
- What defines `factorial(1)`? → **1** (arbitrary base case)

**The base case is chosen, not discovered** - we decide when to stop, not because we've reached "the bottom."

**There is no bottom** - just turtles calling turtles calling turtles.

This is the **ontology of recursion:**
- No ground, only stopping points
- No foundation, only conventions
- No ultimate definition, only circular reference

**Recursion is anti-foundationalist** - it proves you can build infinite structures from self-reference alone.

[hr]

[b]What Recursion Cannot Do[/b]

Recursion is powerful but limited:

**1. Cannot recurse infinitely (stack overflow)**
Every recursive function needs a base case. Infinite descent crashes.

**2. Cannot efficiently solve all problems**
Some recursive solutions are exponentially slow (naive Fibonacci).

Iteration often faster, more memory-efficient.

**3. Cannot escape its own structure**
Recursion is bound by the call stack - depth limited by memory.

**Tail recursion** (last operation is recursive call) can be optimized, but GDScript doesn't guarantee this.

[hr]

[b]What Recursion Reveals[/b]

Recursion shows us:

1. **Self-reference is possible** - functions can call themselves
2. **Stack is memory of descent** - stores local variables, return addresses
3. **Base case is necessary** - without it, infinite descent, crash
4. **Recursion vs iteration** - recursive elegant, iterative efficient
5. **Exponential growth** - recursive trees grow 2^n branches
6. **Divide and conquer** - break problem into smaller pieces, solve recursively
7. **Redundancy problem** - naive recursion recalculates (memoization fixes)
8. **Mutual recursion** - functions can call each other (co-recursion)
9. **Non-linear time** - calling future/past self, temporal loops
10. **No foundation** - turtles all the way down, base cases arbitrary

**Recursion is the mathematics of self-reference** - defining things in terms of themselves.

**It is also queer ontology:**
- **Non-linear time** (calling yourself from future)
- **Circular definition** (no external foundation)
- **Arbitrary stopping points** (base case is chosen)
- **Infinite regress** (turtles all the way down)

**Recursion proves:** **You don't need a foundation to build infinite structures. Just rules and self-reference.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Recursion is self-reference (function calls itself). Requires base case (stop condition) and recursive case (call self with smaller problem). Call stack stores memory of descent (local variables, return addresses). Stack overflow if too deep. Recursion vs iteration (elegant vs efficient). Recursive trees (exponential branching, 2^n). Divide and conquer (merge sort O(n log n)). Fibonacci (double recursion inefficient, memoization fixes). Mutual recursion (functions call each other). Queer temporality (non-linear time, calling future/past self, temporal loops). Infinite regress (turtles all the way down, no foundation, base cases arbitrary). Anti-foundationalist ontology.

[hr]

[color=orange][b]Next:[/b] Fractals - Recursive Geometry[/color]
If recursion is self-reference in **code**, fractals are self-reference in **geometry**.

**Self-similar patterns** - the whole contains copies of itself at smaller scales.

**Infinite detail in finite space** - zoom in forever, always more structure.

**Cantor set** - infinitely many points, zero total length (mathematical queerness)
**Koch snowflake** - infinite perimeter, finite area
**Sierpinski triangle** - dimension 1.585 (not 1, not 2 - queer dimensionality)
**Mandelbrot set** - boundary infinitely complex, computationally irreducible

**Fractals are recursion made visible** - geometric turtles all the way down.

'''
