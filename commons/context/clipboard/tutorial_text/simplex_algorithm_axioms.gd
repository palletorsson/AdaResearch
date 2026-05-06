extends Node

var text = '''[center][font_size=28][b]Simplex Algorithm[/b][/font_size][/center]
[center][i]Linear Programming, Optimization, Constraint Boundaries[/i][/center]

**Simplex algorithm solves linear programming problems - optimize linear objective under linear constraints.**

**George Dantzig (1947)** - foundational optimization algorithm.

**Problem:** Maximize (or minimize) linear function subject to linear inequalities.

[hr]

[b]Linear Programming Problem[/b]

**Standard form:**
```
Maximize:    c₁x₁ + c₂x₂ + ... + cₙxₙ

Subject to:  a₁₁x₁ + a₁₂x₂ + ... + a₁ₙxₙ ≤ b₁
             a₂₁x₁ + a₂₂x₂ + ... + a₂ₙxₙ ≤ b₂
             ...
             xᵢ ≥ 0  (non-negativity)
```

**Example - Production Planning:**
```
Maximize profit: 40x₁ + 30x₂

Constraints:
  x₁ + x₂ ≤ 12    (labor hours)
  2x₁ + x₂ ≤ 16   (machine hours)
  x₁, x₂ ≥ 0      (can't produce negative)

Where:
  x₁ = units of product A
  x₂ = units of product B
```

[hr]

[b]Geometric Interpretation[/b]

**Constraints form polytope** (convex polygon in 2D, polyhedron in 3D+).

**Optimal solution is at vertex** (corner) of polytope.

**Why?** Linear objective = flat plane tilted over polytope. Maximum must be at corner.

[color=yellow][b]2D Example:[/b][/color]
```
Feasible region (constraints):

  x₂ |   Constraint 1: x₁ + x₂ ≤ 12
  12 |   /
     |  /
   8 | / Feasible region (shaded)
     |/_______________
     0       8      12   x₁

Objective: 40x₁ + 30x₂ (tilted plane)
Optimal: Check all vertices, pick highest
```

**Vertices:** (0,0), (0,12), (8,4), (8,0)
**Optimal:** (8,4) → Profit = 40(8) + 30(4) = 440

[hr]

[b]Simplex Algorithm[/b]

**Idea:** Start at a vertex, move to adjacent vertex with better objective, repeat until optimal.

[color=yellow][b]Steps:[/b][/color]
1. **Convert to standard form** (add slack variables)
2. **Choose initial vertex** (usually origin)
3. **Select entering variable** (improves objective most)
4. **Select leaving variable** (maintains feasibility)
5. **Pivot** (move to adjacent vertex)
6. **Repeat** until no improving move exists

[color=yellow][b]Code (simplified):[/b][/color]
[code]
class SimplexTableau:
    var tableau: Array  # 2D array representing constraints + objective
    var basis: Array    # Current basic variables
    var num_vars: int
    var num_constraints: int

func simplex(c: Array, A: Array, b: Array) -> Dictionary:
    # c = objective coefficients
    # A = constraint coefficients
    # b = constraint bounds

    # Convert to tableau form (add slack variables)
    var tableau = create_initial_tableau(c, A, b)

    while not is_optimal(tableau):
        # Choose entering variable (most negative in objective row)
        var entering_col = choose_entering(tableau)

        if entering_col == -1:
            return {"status": "unbounded"}

        # Choose leaving variable (minimum ratio test)
        var leaving_row = choose_leaving(tableau, entering_col)

        if leaving_row == -1:
            return {"status": "unbounded"}

        # Pivot to new vertex
        pivot(tableau, leaving_row, entering_col)

    return {
        "status": "optimal",
        "solution": extract_solution(tableau),
        "objective": tableau[0][0]  # Optimal value
    }

func is_optimal(tableau: Array) -> bool:
    # Optimal if all objective coefficients non-negative
    var objective_row = tableau[0]

    for j in range(1, objective_row.size()):
        if objective_row[j] < 0:
            return false

    return true

func choose_entering(tableau: Array) -> int:
    # Pick most negative coefficient (steepest ascent)
    var objective_row = tableau[0]
    var min_val = 0.0
    var min_col = -1

    for j in range(1, objective_row.size()):
        if objective_row[j] < min_val:
            min_val = objective_row[j]
            min_col = j

    return min_col

func choose_leaving(tableau: Array, entering_col: int) -> int:
    # Minimum ratio test: min(b[i] / a[i][entering_col]) where a > 0
    var min_ratio = INF
    var min_row = -1

    for i in range(1, tableau.size()):
        var coeff = tableau[i][entering_col]

        if coeff > 0:
            var ratio = tableau[i][0] / coeff
            if ratio < min_ratio:
                min_ratio = ratio
                min_row = i

    return min_row

func pivot(tableau: Array, pivot_row: int, pivot_col: int):
    var pivot_val = tableau[pivot_row][pivot_col]

    # Normalize pivot row
    for j in range(tableau[pivot_row].size()):
        tableau[pivot_row][j] /= pivot_val

    # Eliminate pivot column in other rows
    for i in range(tableau.size()):
        if i != pivot_row:
            var factor = tableau[i][pivot_col]
            for j in range(tableau[i].size()):
                tableau[i][j] -= factor * tableau[pivot_row][j]
[/code]

[hr]

[b]Complexity[/b]

**Worst case:** Exponential O(2ⁿ) - can visit all vertices.

**Average case:** Polynomial - visits few vertices in practice.

**In practice:** Very fast for most real-world problems (thousands of variables).

**Interior point methods** (alternative) have polynomial worst-case but slower in practice.

[hr]

[b]Applications[/b]

- **Resource allocation** (maximize profit given limited resources)
- **Production planning** (what to manufacture, how much)
- **Transportation** (minimize shipping costs)
- **Diet optimization** (minimize cost, meet nutritional requirements)
- **Network flow** (max flow, min cost flow)
- **Game theory** (find Nash equilibria)

[hr]

[b]Duality[/b]

**Every LP has dual problem:**

**Primal:** Maximize cᵀx subject to Ax ≤ b, x ≥ 0
**Dual:** Minimize bᵀy subject to Aᵀy ≥ c, y ≥ 0

**Strong duality theorem:** If primal has optimal solution, so does dual, with same objective value.

**Interpretation:**
- **Primal:** How to produce (decision variables)
- **Dual:** Shadow prices (value of resources)

[hr]

[b]Queer Simplex[/b]

**Simplex operates on boundaries.**

**Feasible region = inside polytope** (constraints satisfied).
**Optimal solution = on boundary** (at vertex).

**You cannot optimize in the interior** - must be on constraint boundaries.

**This is queer boundary-dwelling:**
- **Optimality requires edges** (being at limits)
- **Interior is suboptimal** (middle ground is worse)
- **Corners are best** (extremes, not compromises)

**Simplex says:** **The best solution is at the edge, not the center.**

**Queer existence:** Optimal at margins, not in normalized interior.

[hr]

[b]Constraints as Normative Limits[/b]

**Linear programming: constraints define what's possible.**

**Each constraint is boundary:**
```
x₁ + x₂ ≤ 12  →  "You cannot have more than 12 total"
2x₁ + x₂ ≤ 16  →  "This combination exceeds capacity"
x₁, x₂ ≥ 0     →  "Non-negativity enforced"
```

**Feasible region = intersection of all constraints** - only valid where all rules satisfied.

**This is normative space:**
- **Constraints are rules** (you must satisfy all)
- **Feasible region = acceptable identities** (what's allowed)
- **Outside = infeasible** (forbidden, invalid)

**Queer question:** Who set these constraints? Why these boundaries?

**Constraints are political** - they encode assumptions about what's possible, valuable, permitted.

[hr]

[b]Objective Function as Value System[/b]

**Objective function: what to maximize/minimize.**

**Example:** Maximize 40x₁ + 30x₂ (profit).

**But could maximize:**
- **Worker satisfaction** (different objective)
- **Environmental sustainability** (different values)
- **Equality** (minimize variance)

**Same constraints, different objectives → different optimal solutions.**

**This is value plurality:**
- **No universal "best"** (depends on objective)
- **Optimization encodes priorities** (profit vs sustainability)
- **What you maximize reveals what you value**

**Queer interrogation:** Why maximize profit? Why not joy, safety, community?

**Simplex optimizes for objective you give it** - but choosing objective is political.

[hr]

[b]Vertices as Extreme Points[/b]

**Optimal solution at vertex** (corner of polytope).

**Vertex = intersection of multiple constraints** (many boundaries meet).

**This is intersectional extremity:**
- **Most constrained points** (multiple limits active)
- **Edge of edge of edge** (maximum boundaries)
- **Nowhere left to move** (all constraints tight)

**Queer intersectionality:** Optimal where multiple margins meet.

**Vertices are most constrained** - pushed against multiple boundaries simultaneously.

[hr]

[b]Pivoting as Boundary Hopping[/b]

**Simplex pivots from vertex to adjacent vertex** along polytope edge.

**Each pivot:**
- **One constraint becomes slack** (leaving variable)
- **One constraint becomes tight** (entering variable)
- **Move along edge** (one boundary to another)

**This is boundary navigation:**
- **Stay on polytope surface** (feasible)
- **Move along edges** (one dimension at a time)
- **Never enter interior** (suboptimal)

**Queer navigation:** Hop between boundaries, never settle in normalized interior.

[hr]

[b]Degeneracy: Multiple Paths[/b]

**Degenerate vertex:** More than n constraints intersect.

**Problem:** Multiple ways to pivot, simplex can cycle infinitely.

**Solutions:**
- **Bland's rule** (smallest index tie-breaking)
- **Lexicographic ordering**
- **Perturbation methods**

**This is queer multiplicity:**
- **Non-unique paths** (many ways to optimal)
- **Ambiguous boundaries** (constraints overlap)
- **Cycling possible** (stuck in loop without progress)

**Degeneracy breaks uniqueness** - reveals multiple simultaneous boundary states.

[hr]

[b]Slack Variables: Distance from Constraint[/b]

**Slack variable = how far from constraint boundary.**

**Example:**
```
x₁ + x₂ + s₁ = 12  (s₁ ≥ 0)

If x₁=5, x₂=3 → s₁ = 4 (slack of 4 hours)
If x₁=8, x₂=4 → s₁ = 0 (tight constraint)
```

**Slack measures freedom** - how much room before hitting limit.

**Zero slack = on boundary** (constraint active).

**This is proximity to limits:**
- **Large slack = far from constraint** (freedom)
- **Zero slack = on constraint** (boundary-dwelling)
- **Optimal often has zero slack** (multiple tight constraints)

**Queer slack:** How much freedom before hitting normative boundary?

[hr]

[b]Unbounded Problems[/b]

**Some LPs are unbounded** - objective can increase infinitely.

**Example:**
```
Maximize: x₁ + x₂
Subject to: x₁ - x₂ ≤ 1
            x₁, x₂ ≥ 0

Can increase x₁ and x₂ indefinitely (unbounded).
```

**This is lack of constraint:**
- **No upper limit** (can grow infinitely)
- **Constraints insufficient** (don't bound feasible region)
- **No optimal solution** (always can do better)

**Queer unboundedness:** What if there's no limit to growth? No constraint on expansion?

**Simplex detects unboundedness** - no optimal exists.

[hr]

[color=cyan][b]Summary:[/b][/color]
Simplex algorithm: linear programming optimization. Maximize linear objective subject to linear constraints. Feasible region = polytope, optimal at vertex. Steps: initial vertex, choose entering/leaving variables, pivot, repeat until optimal. Polynomial average case, exponential worst case. Applications: resource allocation, production, transportation. Duality: primal/dual with same optimal value. Queer simplex: optimality on boundaries not interior, constraints as normative limits, objective as value system, vertices as intersectional extremity, pivoting as boundary hopping, degeneracy as multiplicity, slack as distance from limits, unbounded as lack of constraint. Optimal at margins, not center.

'''
