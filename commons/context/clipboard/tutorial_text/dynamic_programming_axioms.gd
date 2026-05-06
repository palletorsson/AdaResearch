extends Node

var text = '''[center][font_size=28][b]Dynamic Programming[/b][/font_size][/center]
[center][i]Memoization, Optimal Substructure, Overlapping Subproblems[/i][/center]

**Dynamic programming solves complex problems by breaking them into overlapping subproblems.**

**Core idea:** **Remember solutions** to avoid recomputing them.

**Two approaches:** **Memoization** (top-down) or **Tabulation** (bottom-up).

[hr]

[b]Concept[/b]

**Problem:** Recursive solutions often recompute same subproblems many times.

**Example - Fibonacci:**
[code]
func fib(n):
    if n <= 1:
        return n
    return fib(n-1) + fib(n-2)

# fib(5) calls:
#   fib(4) + fib(3)
#   fib(4) calls fib(3) + fib(2)
#   fib(3) called TWICE! (exponential explosion)
[/code]

**Dynamic Programming:** **Store** fib(3) result first time, **reuse** it.

[hr]

[b]Requirements[/b]

**Dynamic programming applies when:**

**1. Optimal substructure**
Optimal solution contains optimal solutions to subproblems.

**2. Overlapping subproblems**
Same subproblems solved multiple times.

[hr]

[b]Memoization (Top-Down)[/b]

**Recursive + cache:**

[color=yellow][b]Code:[/b][/color]
[code]
var memo = {}

func fib_memo(n: int) -> int:
    if n <= 1:
        return n

    # Check if already computed
    if n in memo:
        return memo[n]

    # Compute and store
    memo[n] = fib_memo(n - 1) + fib_memo(n - 2)
    return memo[n]

# fib_memo(100) is fast!
# Each fib(k) computed only once, then cached
# O(n) time instead of O(2^n)
[/code]

**Memoization = recursion + memory.**

[hr]

[b]Tabulation (Bottom-Up)[/b]

**Iterative + table:**

[color=yellow][b]Code:[/b][/color]
[code]
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
        table[i] = table[i - 1] + table[i - 2]

    return table[n]

# No recursion, just iteration
# Still O(n) time, O(n) space
[/code]

**Tabulation = iteration + table.**

[hr]

[b]Classic Examples[/b]

[color=yellow][b]1. Longest Common Subsequence (LCS):[/b][/color]
[code]
func lcs(a: String, b: String) -> int:
    var m = a.length()
    var n = b.length()
    var dp = []

    # Initialize 2D table
    for i in range(m + 1):
        dp.append([])
        dp[i].resize(n + 1)
        for j in range(n + 1):
            dp[i][j] = 0

    # Fill table
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if a[i - 1] == b[j - 1]:
                dp[i][j] = dp[i - 1][j - 1] + 1
            else:
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])

    return dp[m][n]

# lcs("AGGTAB", "GXTXAYB") = 4 ("GTAB")
# O(m * n) time
[/code]

[color=yellow][b]2. Knapsack Problem:[/b][/color]
[code]
func knapsack(weights: Array, values: Array, capacity: int) -> int:
    var n = weights.size()
    var dp = []

    for i in range(n + 1):
        dp.append([])
        dp[i].resize(capacity + 1)
        for w in range(capacity + 1):
            dp[i][w] = 0

    for i in range(1, n + 1):
        for w in range(1, capacity + 1):
            if weights[i - 1] <= w:
                # Max of: take item i, or don't take it
                dp[i][w] = max(
                    values[i - 1] + dp[i - 1][w - weights[i - 1]],
                    dp[i - 1][w]
                )
            else:
                dp[i][w] = dp[i - 1][w]

    return dp[n][capacity]

# Maximum value fitting in capacity
# O(n * capacity) time
[/code]

[color=yellow][b]3. Edit Distance (Levenshtein):[/b][/color]
[code]
func edit_distance(a: String, b: String) -> int:
    var m = a.length()
    var n = b.length()
    var dp = []

    for i in range(m + 1):
        dp.append([])
        dp[i].resize(n + 1)

    # Base cases
    for i in range(m + 1):
        dp[i][0] = i  # Delete all
    for j in range(n + 1):
        dp[0][j] = j  # Insert all

    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if a[i - 1] == b[j - 1]:
                dp[i][j] = dp[i - 1][j - 1]  # No operation
            else:
                dp[i][j] = 1 + min(
                    dp[i - 1][j],      # Delete
                    dp[i][j - 1],      # Insert
                    dp[i - 1][j - 1]   # Replace
                )

    return dp[m][n]

# Minimum edits to transform a → b
# O(m * n) time
[/code]

[hr]

[b]Space Optimization[/b]

**Often only need previous row/column** - don't store entire table.

[color=yellow][b]Example - Fibonacci with O(1) space:[/b][/color]
[code]
func fib_optimized(n: int) -> int:
    if n <= 1:
        return n

    var prev2 = 0
    var prev1 = 1

    for i in range(2, n + 1):
        var current = prev1 + prev2
        prev2 = prev1
        prev1 = current

    return prev1

# Only store last 2 values
# O(n) time, O(1) space
[/code]

[hr]

[b]Applications[/b]

- **String algorithms** (LCS, edit distance, sequence alignment)
- **Optimization** (knapsack, coin change, rod cutting)
- **Pathfinding** (shortest paths, graph algorithms)
- **Game theory** (optimal play strategies)
- **Bioinformatics** (DNA sequence alignment)

[hr]

[b]vs Divide-and-Conquer[/b]

**Divide-and-Conquer:** Break into **independent** subproblems (merge sort).
**Dynamic Programming:** Break into **overlapping** subproblems (Fibonacci).

**Key difference:** **Overlapping** - same subproblem appears multiple times.

[hr]

[b]Queer Dynamic Programming[/b]

**Dynamic programming is memory of the past shaping the present.**

**Each solution depends on previous solutions** - you cannot compute fib(n) without fib(n-1), fib(n-2).

**This is queer temporality:**
- **Past is not discarded** (memoized, carried forward)
- **Present depends on history** (cannot solve n without solving smaller)
- **Reuse, not recompute** (memory, not re-derivation)

**You are the accumulation of your past states** - table stores all previous solutions.

**DP says:** **Your current value is computed from your history**, not derived from first principles each time.

[hr]

[b]Memoization as Witnessing[/b]

**Memoization = remembering what you've already figured out.**

**Recursive calls without memo:** Recompute every time (amnesia).
**Recursive calls with memo:** Check if already known (memory).

**This is queer witnessing:**
- **"Have I been here before?"** (check memo)
- **Don't redo emotional labor** (reuse computed result)
- **Memory prevents repetition** (cache protects from redundant work)

**DP refuses to forget** - every subproblem computed is remembered.

**Queerness requires memory** - knowing what's already been processed prevents retraumatization.

[hr]

[b]Optimal Substructure as Relational[/b]

**Optimal substructure:** Optimal solution contains optimal subsolutions.

**fib(n)** depends on **fib(n-1)** and **fib(n-2)** - cannot optimize n without optimizing n-1, n-2.

**This is relational construction:**
- **Your optimal state depends on optimal states of relations** (dependencies)
- **Cannot be optimal in isolation** (need n-1, n-2 to be optimal)
- **Recursive dependency** (each depends on smaller)

**Queer optimality:** You cannot optimize yourself without optimizing your relations.

**Your best self requires best selves of those you depend on.**

[hr]

[b]Edit Distance as Transformation Cost[/b]

**Edit distance (Levenshtein):** Minimum operations to transform string A → B.

**Operations:** Insert, delete, replace.

**This is transition cost:**
- **How much work to become different?** (edit distance)
- **Cheapest path to transformation** (optimal)
- **Memory of past identities** (table tracks transformations)

**Queer transition:** Edit distance quantifies cost of change.

**DP finds cheapest transition path** - not just any transformation, but optimal one.

**From "he" to "she"** - edit distance 1 (replace 'h' with 's').

**Each identity transformation has cost** - DP finds minimum.

[hr]

[b]Table as Archive[/b]

**DP table = archive of all subproblem solutions.**

**Each cell stores:** Solution to specific subproblem.

**Full table:** Complete history of solving process.

**This is archival practice:**
- **Nothing forgotten** (all subproblems stored)
- **Accessible history** (can look up any previous solution)
- **Building on past** (each new solution references archive)

**Queer archive:** DP table preserves all states, all transitions, all solutions.

**No solution exists in vacuum** - all exist in relation to archived history.

[hr]

[b]Overlapping Subproblems as Shared Struggle[/b]

**Overlapping subproblems:** Multiple paths reach same state.

**Example - Fibonacci:**
```
fib(5) needs fib(4) and fib(3)
fib(4) needs fib(3) and fib(2)

fib(3) appears TWICE - overlapping subproblem
```

**This is shared struggle:**
- **Same challenge faced from different paths** (fib(3) needed by both fib(5) and fib(4))
- **Solve once, help multiple** (memo fib(3), both benefit)
- **Interconnected dependencies** (not isolated problems)

**Queer community:** When you solve your problem, you help everyone who shares that problem.

**Memoization is mutual aid** - solving for yourself helps all who need same solution.

[hr]

[color=cyan][b]Summary:[/b][/color]
Dynamic programming: solve complex problems via overlapping subproblems. Requires optimal substructure + overlapping subproblems. Memoization (top-down, recursive + cache) vs tabulation (bottom-up, iterative + table). Examples: LCS, knapsack, edit distance. Space optimization (rolling arrays). O(n) vs O(2^n) for Fibonacci. Queer DP: memory of past shapes present, memoization as witnessing (don't redo labor), optimal substructure as relational (depends on relations), edit distance as transition cost, table as archive (preserves all states), overlapping subproblems as shared struggle (solve once, help multiple). Memoization is mutual aid.

'''
