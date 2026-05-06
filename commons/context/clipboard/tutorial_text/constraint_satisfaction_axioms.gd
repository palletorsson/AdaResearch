extends Node

var text = '''[center][font_size=28][b]Constraint Satisfaction Problems[/b][/font_size][/center]
[center][i]CSP, Backtracking, Arc Consistency[/i][/center]

**Constraint Satisfaction Problems (CSP) find assignments satisfying all constraints.**

**Structure:**
- **Variables:** Things to assign (X, Y, Z)
- **Domains:** Possible values for each variable
- **Constraints:** Rules variables must satisfy

**Goal:** Find assignment where all constraints hold.

[hr]

[b]Formal Definition[/b]

**CSP = (X, D, C)**
- **X:** Set of variables {X₁, X₂, ..., Xₙ}
- **D:** Set of domains {D₁, D₂, ..., Dₙ} (Dᵢ = possible values for Xᵢ)
- **C:** Set of constraints (relations between variables)

**Solution:** Assignment of values to all variables satisfying all constraints.

[hr]

[b]Examples[/b]

[color=yellow][b]1. Map Coloring:[/b][/color]
```
Variables: {WA, NT, SA, Q, NSW, V, T} (Australian states)
Domains: {red, green, blue} for each
Constraints: Adjacent regions must have different colors

WA ≠ NT
WA ≠ SA
NT ≠ SA
NT ≠ Q
SA ≠ Q
SA ≠ NSW
SA ≠ V
Q ≠ NSW
NSW ≠ V
```

[color=yellow][b]2. N-Queens:[/b][/color]
```
Variables: {Q₁, Q₂, ..., Qₙ} (queen positions)
Domains: {1, 2, ..., n} (column for each row)
Constraints:
  - No two queens same column: Qᵢ ≠ Qⱼ
  - No two queens same diagonal: |Qᵢ - Qⱼ| ≠ |i - j|
```

[color=yellow][b]3. Sudoku:[/b][/color]
```
Variables: 81 cells
Domains: {1, 2, ..., 9}
Constraints:
  - Each row has unique values
  - Each column has unique values
  - Each 3×3 box has unique values
```

[hr]

[b]Backtracking Search[/b]

**Algorithm:** Try assignments, backtrack when constraint violated.

[color=yellow][b]Code:[/b][/color]
[code]
func backtracking_search(csp: CSP) -> Dictionary:
    return backtrack({}, csp)

func backtrack(assignment: Dictionary, csp: CSP) -> Dictionary:
    # Complete assignment found
    if assignment.size() == csp.variables.size():
        return assignment

    # Select unassigned variable
    var var_name = select_unassigned_variable(assignment, csp)

    # Try each value in domain
    for value in csp.domains[var_name]:
        if is_consistent(var_name, value, assignment, csp):
            # Assign value
            assignment[var_name] = value

            # Recurse
            var result = backtrack(assignment, csp)
            if result != null:
                return result

            # Backtrack (undo assignment)
            assignment.erase(var_name)

    return null  # No solution found

func is_consistent(var_name: String, value, assignment: Dictionary, csp: CSP) -> bool:
    # Check all constraints involving var_name
    for constraint in csp.constraints:
        if not constraint.satisfies(var_name, value, assignment):
            return false
    return true
[/code]

**Backtracking = DFS through assignment tree + pruning.**

[hr]

[b]Heuristics[/b]

**Variable ordering:**

[color=yellow][b]MRV (Minimum Remaining Values):[/b][/color]
Choose variable with **fewest legal values** remaining.
**Rationale:** Fail fast - if going to fail, fail early.

[color=yellow][b]Degree heuristic:[/b][/color]
Choose variable involved in **most constraints** with unassigned variables.

**Value ordering:**

[color=yellow][b]LCV (Least Constraining Value):[/b][/color]
Choose value that **rules out fewest** values for neighbors.
**Rationale:** Keep maximum flexibility for future assignments.

[color=yellow][b]Code:[/b][/color]
[code]
func select_unassigned_variable(assignment: Dictionary, csp: CSP) -> String:
    var unassigned = []

    for var_name in csp.variables:
        if var_name not in assignment:
            unassigned.append(var_name)

    # MRV heuristic
    var min_remaining = INF
    var chosen = null

    for var_name in unassigned:
        var remaining = count_legal_values(var_name, assignment, csp)
        if remaining < min_remaining:
            min_remaining = remaining
            chosen = var_name

    return chosen

func order_domain_values(var_name: String, assignment: Dictionary, csp: CSP) -> Array:
    var values = csp.domains[var_name].duplicate()

    # LCV heuristic - sort by least constraining first
    values.sort_custom(func(a, b):
        return count_conflicts(var_name, a, assignment, csp) <
               count_conflicts(var_name, b, assignment, csp)
    )

    return values
[/code]

[hr]

[b]Constraint Propagation[/b]

**Inference:** Deduce variable values before search.

[color=yellow][b]Forward Checking:[/b][/color]
After assigning variable, remove inconsistent values from neighbors' domains.

[color=yellow][b]Arc Consistency (AC-3):[/b][/color]
**Arc (X, Y) is consistent if:** For every value x in D_X, there exists some value y in D_Y satisfying constraint.

[color=yellow][b]Code:[/b][/color]
[code]
func ac3(csp: CSP) -> bool:
    var queue = []

    # Initialize queue with all arcs
    for constraint in csp.constraints:
        queue.append([constraint.var1, constraint.var2])
        queue.append([constraint.var2, constraint.var1])

    while not queue.is_empty():
        var arc = queue.pop_front()
        var xi = arc[0]
        var xj = arc[1]

        if revise(csp, xi, xj):
            if csp.domains[xi].is_empty():
                return false  # Domain wiped out - no solution

            # Add neighbors of Xi to queue
            for xk in get_neighbors(xi, csp):
                if xk != xj:
                    queue.append([xk, xi])

    return true  # Arc consistent

func revise(csp: CSP, xi: String, xj: String) -> bool:
    var revised = false

    for x in csp.domains[xi]:
        # Check if any value of xj satisfies constraint
        var satisfiable = false

        for y in csp.domains[xj]:
            if constraint_satisfied(xi, x, xj, y, csp):
                satisfiable = true
                break

        # No value of xj works - remove x from domain
        if not satisfiable:
            csp.domains[xi].erase(x)
            revised = true

    return revised
[/code]

**AC-3 reduces domains** before search - prunes search space.

[hr]

[b]Applications[/b]

- **Scheduling** (assign tasks to time slots, avoid conflicts)
- **Resource allocation** (assign resources to agents, capacity limits)
- **Configuration** (select components satisfying requirements)
- **Planning** (sequence actions satisfying preconditions/effects)
- **Type inference** (assign types to variables, satisfy type constraints)

[hr]

[b]Local Search for CSP[/b]

**Alternative to backtracking:** Start with complete (possibly invalid) assignment, improve iteratively.

[color=yellow][b]Min-Conflicts:[/b][/color]
[code]
func min_conflicts(csp: CSP, max_steps: int) -> Dictionary:
    # Random complete assignment
    var current = random_assignment(csp)

    for i in range(max_steps):
        if is_solution(current, csp):
            return current

        # Select conflicted variable
        var var_name = random_conflicted_variable(current, csp)

        # Choose value minimizing conflicts
        var best_value = null
        var min_conflicts = INF

        for value in csp.domains[var_name]:
            var conflicts = count_conflicts(var_name, value, current, csp)
            if conflicts < min_conflicts:
                min_conflicts = conflicts
                best_value = value

        current[var_name] = best_value

    return null  # Failed to find solution
[/code]

**Works well for large CSPs** where backtracking too expensive.

[hr]

[b]Queer CSP[/b]

**CSP enforces rules - variables must satisfy constraints.**

**This is normative enforcement:**
- **Variables have domains** (allowed values)
- **Constraints restrict possibilities** (rules you must follow)
- **Solution = conformity** (all constraints satisfied)

**But constraints can be:**
- **Arbitrary** (who decided these rules?)
- **Contradictory** (no solution exists - over-constrained)
- **Under-specified** (many solutions - under-constrained)

**Queer interrogation:** Who set the constraints? Which identities are forbidden by domain restrictions?

[hr]

[b]Backtracking as Exploration[/b]

**Backtracking:** Try assignment, if fails, undo and try differently.

**This is queer exploration:**
- **Non-linear path** (not straight to solution)
- **Failure is information** (constraint violated → backtrack)
- **Retraction possible** (undo assignments, try differently)

**You don't have to commit** - can backtrack, explore alternate timelines.

**Queer temporality:** Backtracking allows returning to past states, trying different futures.

[hr]

[b]MRV: Fail Fast[/b]

**Minimum Remaining Values heuristic:** Choose variable with fewest options.

**Rationale:** If going to fail, fail early (don't waste search).

**This is queer pragmatism:**
- **Face hardest challenges first** (most constrained variable)
- **Failure is acceptable** (fail fast, backtrack, try differently)
- **Don't delay inevitable** (if going to fail, know now)

**CSP says:** **Better to confront constraints early than avoid them.**

[hr]

[b]Over-Constrained: No Solution[/b]

**Over-constrained CSP:** Constraints contradictory - no assignment satisfies all.

**Example:**
```
Variables: {X, Y}
Domains: {1, 2}
Constraints: X ≠ Y, X = Y

No solution exists - constraints contradictory.
```

**This is queer impossibility:**
- **Systems demand contradictions** (be X, also be not-X)
- **No valid identity** (all assignments violate some constraint)
- **Rules are inconsistent** (cannot satisfy all demands)

**Queer bodies often over-constrained** - expected to satisfy contradictory norms.

**CSP can detect this** - "no solution exists given these constraints."

**Question:** Relax constraints, or accept impossibility?

[hr]

[b]Arc Consistency: Mutual Constraint[/b]

**Arc consistency:** For every value of X, some value of Y works.

**This is relational viability:**
- **Your values constrained by neighbor's domains**
- **Mutual compatibility** (both must have workable values)
- **Dependency** (X's domain shaped by Y's domain)

**AC-3 propagates constraints** - your neighbor's restrictions become your restrictions.

**Queer relational constraint:** What's viable for you depends on what's viable for those you're constrained with.

**Your domain is not independent** - shaped by relational constraints.

[hr]

[b]Under-Constrained: Too Many Solutions[/b]

**Under-constrained CSP:** Many solutions exist.

**Example:**
```
Variables: {X, Y, Z}
Domains: {1, 2, 3}
Constraints: X ≠ Y

Many solutions: X=1,Y=2,Z=1; X=1,Y=2,Z=2; X=1,Y=2,Z=3...
```

**This is queer multiplicity:**
- **No unique solution** (many valid identities)
- **Constraints don't fully determine** (freedom within rules)
- **Choice among options** (which solution to pick?)

**Under-constrained:** Rules allow space for self-determination.

**Queerness flourishes in under-constrained spaces** - where norms don't fully specify identity.

[hr]

[color=cyan][b]Summary:[/b][/color]
CSP: variables, domains, constraints. Find assignment satisfying all constraints. Backtracking search with pruning. Heuristics: MRV (fewest remaining values), LCV (least constraining value). Constraint propagation: forward checking, AC-3 (arc consistency). Min-conflicts local search. Applications: scheduling, resource allocation, configuration. Queer CSP: constraints as normative enforcement (who set rules?), backtracking as exploration (non-linear, retraction possible), MRV as fail fast (face hard first), over-constrained as impossibility (contradictory demands), arc consistency as mutual constraint (relational viability), under-constrained as multiplicity (freedom within rules). Queerness in under-constrained spaces.

'''
