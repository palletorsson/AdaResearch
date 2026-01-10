**L-Systems**
Generative Grammars, Growth Without Blueprint

**L-systems** (Lindenmayer systems) are **rewriting systems** - they generate patterns by repeatedly replacing symbols according to rules.

**Axiom** → apply rules → **new string** → apply rules → **new string** → ...

After many iterations: **complex forms emerge from simple grammar**.

L-systems were invented by **Aristid Lindenmayer** (1968) to model **plant growth** - how cells divide and differentiate without central blueprint.

But they reveal something profound: **Syntax can become geometry. Grammar can become organism.**

**Form emerges from iterative rewriting, not from template.**

This is **generativity without reproduction** - creating through transformation, not copying.

---

## The L-System: Axiom + Rules

An L-system has three parts:
1. **Alphabet** - symbols (letters, characters)
2. **Axiom** - starting string (initial state)
3. **Production rules** - how to replace each symbol

**Code: Simple L-System**

var axiom =