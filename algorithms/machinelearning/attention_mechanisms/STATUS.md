# Status: SYNC

The `AttentionMechanisms.gd` script and the `README.md` are aligned. The implementation is a functional, data-driven visualization of a self-attention mechanism, and the documentation reflects this.

**Source of Truth:** SYNC

**Completed Refinements:**
- Replaced placeholder `sin(time)` logic with a functional attention score calculation based on inverse distance.
- Introduced an interactive `query_index` to select the active Query token.
- The visualization (token emission, attention matrix) is now driven by the calculated scores.
- The `README.md` has been updated to describe the new, more accurate implementation.

**Next Steps:**
- Consider further enhancements, such as implementing different scoring functions (e.g., dot-product) or visualizing multi-head attention.
