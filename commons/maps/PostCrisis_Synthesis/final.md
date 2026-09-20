# One choice you can answer for

Can you name one person a useful design choice could leave out?

<!-- @accountability_ledger -->

Read one complete pair on the ledger before it scrolls away. Choose a concrete case, such as a short name field and someone whose name exceeds it. Say what the designer probably gained, what the person encounters, and one change that could reduce the difficulty.

The exhibit cycles through prewritten examples of choices and exclusions. Six lines remain visible at once, and an amber mark accompanies a new entry. Its form resembles an accumulating record, but these entries are examples: it is not recording your visit, saving your discussion or certifying that any problem has been repaired.

The source makes the operation inspectable:

```gdscript
_entries.push_front(line)
while _entries.size() > visible_lines:
    _entries.pop_back()
_count += 1
```

A line enters at the front; another leaves when the buffer is full. The counter survives that loss. We met a running count near the point at the beginning of the museum. Here counting and remembering separate in four lines of code. The machine can announce progress while the evidence of an earlier problem has already disappeared.

An accountable record would connect a decision with evidence about its effect and someone able to revisit it. Naming an excluded case is a beginning. It becomes useful when it leads to an action, an observation after the action, and a decision about what to change next.

Return mentally to one room you have just walked. Perhaps a slider was difficult to reach, a number concealed several different conditions, or a label promised a computation the exhibit could not yet perform. Choose one case small enough to inspect. State the intended experience, the present obstacle and the smallest improvement that would let you test the difference.

Now ask where else the same relation occurs. A readable control, a preserved alternative or a visible source can be a reusable principle. Reusing it still requires checking the new room: the same height may not suit every body, and the same explanatory sequence may not suit every concept. Generalisation is a claim to test through another encounter.

The ledger does not absolve a choice by displaying its cost. Some exclusions call for repair, some for another route, and some for changing the category that made the case disappear. The response should stay attached to the person’s actual difficulty rather than becoming a decorative admission of imperfection.

<!-- @ -->

Go back to a chosen room with one question, one proposed change and one observable consequence. The museum’s next version begins with that specific return.
