extends RefCounted
# n represents the finite ordinal {0,...,n-1}. This is not a universal set.
func members(n: int) -> Array[int]:
    var result: Array[int] = []
    for x in range(maxi(0, n)):
        if not range(x).has(x): result.append(x)
    return result

func test(assumed: bool, restricted: bool, n: int = 4) -> Dictionary:
    if n < 0 or n > 6: return {"valid":false}
    var selected := members(n)
    # Every ordinal below n survives. The result equals ordinal n, outside n.
    var in_domain := range(n).has(n) if restricted else true
    var required := in_domain and not assumed
    return {"valid":true, "assumed":assumed, "required":required,
        "agrees":assumed==required, "members":selected,
        "domain_contains_result":in_domain, "restricted":restricted}
