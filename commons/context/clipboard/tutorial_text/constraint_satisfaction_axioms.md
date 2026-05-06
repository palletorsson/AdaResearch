**Constraint Satisfaction Problems**
CSP, Backtracking, Arc Consistency

**Constraint Satisfaction Problems (CSP) find assignments satisfying all constraints.**

**Structure:**
- **Variables:** Things to assign (X, Y, Z)
- **Domains:** Possible values for each variable
- **Constraints:** Rules variables must satisfy

**Goal:** Find assignment where all constraints hold.

---

## Formal Definition

**CSP = (X, D, C)**
- **X:** Set of variables {X₁, X₂, ..., Xₙ}
- **D:** Set of domains {D₁, D₂, ..., Dₙ} (Dᵢ = possible values for Xᵢ)
- **C:** Set of constraints (relations between variables)

**Solution:** Assignment of values to all variables satisfying all constraints.

---

## Examples

**1. Map Coloring:**
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

**2. N-Queens:**
```
Variables: {Q₁, Q₂, ..., Qₙ} (queen positions)
Domains: {1, 2, ..., n} (column for each row)
Constraints:
  - No two queens same column: Qᵢ ≠ Qⱼ
  - No two queens same diagonal: |Qᵢ - Qⱼ| ≠ |i - j|
```

**3. Sudoku:**
```
Variables: 81 cells
Domains: {1, 2, ..., 9}
Constraints:
  - Each row has unique values
  - Each column has unique values
  - Each 3×3 box has unique values
```

---

## Backtracking Search

**Algorithm:** Try assignments, backtrack when constraint violated.

**Code:**

```
func backtracking_search(csp: CSP) -> Dictionary:
    return backtrack({}, csp)

func backtrack(assignment: Dictionary, csp: CSP) -> Dictionary:
    # Complete assignment found
    if assignment.size() == csp.variables.size():
        return assignment

    # Select unassigned variable
    var var_name = select_unassigned_variable(assignment, csp)

    # Try each value in domain
    for value in csp.domains:
        if is_consistent(var_name, value, assignment, csp):
            # Assign value
            assignment = value

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
```

**Backtracking = DFS through assignment tree + pruning.**

---

## Heuristics

**Variable ordering:**

**MRV (Minimum Remaining Values):**
Choose variable with **fewest legal values** remaining.
**Rationale:** Fail fast - if going to fail, fail early.

**Degree heuristic:**
Choose variable involved in **most constraints** with unassigned variables.

**Value ordering:**

**LCV (Least Constraining Value):**
Choose value that **rules out fewest** values for neighbors.
**Rationale:** Keep maximum flexibility for future assignments.

**Code:**

```
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
    var values = csp.domains.duplicate()

    # LCV heuristic - sort by least constraining first
    values.sort_custom(func(a, b):
        return count_conflicts(var_name, a, assignment, csp) <
               count_conflicts(var_name, b, assignment, csp)
    )

    return values
```

---

## Constraint Propagation

**Inference:** Deduce variable values before search.

**Forward Checking:**
After assigning variable, remove inconsistent values from neighbors