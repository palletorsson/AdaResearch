**Simplex Algorithm**
Linear Programming, Optimization, Constraint Boundaries

**Simplex algorithm solves linear programming problems - optimize linear objective under linear constraints.**

**George Dantzig (1947)** - foundational optimization algorithm.

**Problem:** Maximize (or minimize) linear function subject to linear inequalities.

---

## Linear Programming Problem

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
  x₁, x₂ ≥ 0      (can