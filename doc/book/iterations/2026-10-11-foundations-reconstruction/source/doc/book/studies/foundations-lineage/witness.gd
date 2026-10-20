extends RefCounted
const CAPACITY := 8
var terms: Array[int] = []

func append_bit(bit: int) -> bool:
    if bit not in [0,1] or terms.size()>=CAPACITY: return false
    terms.append(bit)
    return true

func first_one() -> int:
    return terms.find(1)

func inspect_prefix() -> Dictionary:
    var index := first_one()
    return {"finite_contains_one":index>=0, "witness_index":index,
        "future_claim":"WITNESSED" if index>=0 else "NO WITNESS YET"}

func diagonal(rows: Array) -> Dictionary:
    if rows.is_empty(): return {"valid":false, "bits":[]}
    for row in rows:
        if not row is Array or row.size()!=rows.size(): return {"valid":false, "bits":[]}
        for bit in row:
            if not bit is int or bit not in [0,1]: return {"valid":false, "bits":[]}
    var bits: Array[int] = []
    for i in rows.size(): bits.append(1-int(rows[i][i]))
    return {"valid":true, "bits":bits}
