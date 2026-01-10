**Dynamic Programming**
Memoization, Optimal Substructure, Overlapping Subproblems

**Dynamic programming solves complex problems by breaking them into overlapping subproblems.**

**Core idea:** **Remember solutions** to avoid recomputing them.

**Two approaches:** **Memoization** (top-down) or **Tabulation** (bottom-up).

---

## Concept

**Problem:** Recursive solutions often recompute same subproblems many times.

**Example - Fibonacci:**

```
func fib(n):
    if n <= 1:
        return n
    return fib(n-1) + fib(n-2)

# fib(5) calls:
#   fib(4) + fib(3)
#   fib(4) calls fib(3) + fib(2)
#   fib(3) called TWICE! (exponential explosion)
```

**Dynamic Programming:** **Store** fib(3) result first time, **reuse** it.

---

## Requirements

**Dynamic programming applies when:**

**1. Optimal substructure**
Optimal solution contains optimal solutions to subproblems.

**2. Overlapping subproblems**
Same subproblems solved multiple times.

---

## Memoization (Top-Down)

**Recursive + cache:**

**Code:**

```
var memo = {}

func fib_memo(n: int) -> int:
    if n <= 1:
        return n

    # Check if already computed
    if n in memo:
        return memo

    # Compute and store
    memo = fib_memo(n - 1) + fib_memo(n - 2)
    return memo

# fib_memo(100) is fast!
# Each fib(k) computed only once, then cached
# O(n) time instead of O(2^n)
```

**Memoization = recursion + memory.**

---

## Tabulation (Bottom-Up)

**Iterative + table:**

**Code:**

```
func fib_table(n: int) -> int:
    if n <= 1:
        return n

    var table = []
    table.resize(n + 1)

    # Base cases
    table[0] = 0
    table[1] = 1

    # Fill table bottom-up
    for i in range(2, n + 1):
        table = table[i - 1] + table[i - 2]

    return table

# No recursion, just iteration
# Still O(n) time, O(n) space
```

**Tabulation = iteration + table.**

---

## Classic Examples

**1. Longest Common Subsequence (LCS):**

func lcs(a: String, b: String) -> int:
    var m = a.length()
    var n = b.length()
    var dp = []

    # Initialize 2D table
    for i in range(m + 1):
        dp.append([])
        dp.resize(n + 1)
        for j in range(n + 1):
            dp = 0

    # Fill table
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if a[i - 1] == b[j - 1]:
                dp = dp[i - 1][j - 1] + 1
            else:
                dp = max(dp[i - 1], dp[j - 1])

    return dp

# lcs(