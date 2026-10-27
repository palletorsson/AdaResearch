extends RefCounted
## Twenty rules from an address (x, z) to one of n states, in five families: lines, number,
## distance (from the centre cell), walks, chance. The same rules, by the same names, drive the
## palette floor and the tiling studies of the spatial lab (ada_encyclopedia/src/lib/colour-study.ts
## RULES). Two implementations of one rule drift, so tools/address_rules_crosscheck.py computes
## both on the same grids and fails on any cell where they disagree.
## Here the hall's tiling fields use them: the state a rule gives an address sets a tile's turn,
## mirror or inversion (tiling_pattern.gd rule_image).

const NAMES: PackedStringArray = ["sum", "difference", "columns", "rows", "knight", "linear",
	"product", "squares", "gcd", "pascal", "xor", "and",
	"rings", "diamonds", "frames", "sectors", "spiral", "primes", "collatz", "scatter"]

const M32 := 0xFFFFFFFF

static var _pascal: Dictionary = {}


## The state (0 .. n-1) the rule gives address (x, z) on an N x N field; a and b feed `linear`.
static func state(rule: String, x: int, z: int, n: int, size: int, a: int = 1, b: int = 3) -> int:
	var c: int = (size - 1) / 2
	match rule:
		"sum": return (x + z) % n
		"difference": return posmod(x - z, n)
		"columns": return x % n
		"rows": return z % n
		"knight": return (x + 2 * z) % n
		"linear": return posmod(a * x + b * z, n)
		"product": return (x * z) % n
		"squares": return (x * x + z * z) % n
		"gcd": return (_gcd(x + 1, z + 1) - 1) % n
		"pascal": return _pascal_mod(x, z, n)
		"xor": return (x ^ z) % n
		"and":
			var shared: int = x & z
			if shared == 0:
				return 0
			var bits: int = 0
			while shared:
				bits += shared & 1
				shared >>= 1
			return 1 + (bits - 1) % (n - 1) if n > 1 else 0
		"rings":
			# 64-bit floats, as JavaScript's hypot (Vector2 would be 32-bit)
			var half: float = float(size - 1) / 2.0
			var dx: float = float(x) - half
			var dz: float = float(z) - half
			return int(round(sqrt(dx * dx + dz * dz))) % n
		"diamonds": return (absi(x - c) + absi(z - c)) % n
		"frames": return maxi(absi(x - c), absi(z - c)) % n
		"sectors":
			return mini(n - 1, int(floor((atan2(float(z - c), float(x - c)) + PI) / TAU * n)))
		"spiral": return (_ulam(x - c, z - c) - 1) % n
		"primes": return 0 if _is_prime(_ulam(x - c, z - c)) else 1 % n
		"collatz": return _collatz(x * size + z + 1) % n
		"scatter": return _mixed_hash(x, z) % n
	push_warning("address_rules: unknown rule '%s'" % rule)
	return 0


static func _gcd(p: int, q: int) -> int:
	while q != 0:
		var t: int = p % q
		p = q
		q = t
	return p


static func _is_prime(v: int) -> bool:
	if v < 2:
		return false
	var d: int = 2
	while d * d <= v:
		if v % d == 0:
			return false
		d += 1
	return true


static func _collatz(v: int) -> int:
	var k: int = 0
	while v != 1 and k < 999:
		v = 3 * v + 1 if v % 2 else v / 2
		k += 1
	return k


## The Ulam spiral's number at (x, y): 1 at the centre, out to the right, then counter-clockwise.
static func _ulam(x: int, y: int) -> int:
	var k: int = maxi(absi(x), absi(y))
	var m: int = (2 * k + 1) * (2 * k + 1)
	if k == 0:
		return 1
	if y == -k:
		return m - (k - x)
	if x == -k:
		return m - 2 * k - (y + k)
	if y == k:
		return m - 4 * k - (k + x)
	return m - 6 * k - (k - y)


## C(x + z, x) mod n from a table, never from big numbers.
static func _pascal_mod(x: int, z: int, n: int) -> int:
	if not _pascal.has(n):
		var t: Array = []
		for i in 32:
			var row: Array = []   # plain Arrays: a packed array nested in an Array is a value
			row.resize(32)
			row.fill(1)
			t.append(row)
		for i in range(1, 32):
			for j in range(1, 32):
				t[i][j] = (t[i - 1][j] + t[i][j - 1]) % n
		_pascal[n] = t
	return int(_pascal[n][x][z]) % n


## JavaScript's Math.imul: the low 32 bits of a product, as a signed 32-bit int. Split into
## 16-bit halves so no 64-bit product can overflow.
static func _imul(p: int, q: int) -> int:
	var u: int = p & M32
	var w: int = q & M32
	var lo: int = (u & 0xFFFF) * w
	var hi: int = (((u >> 16) & 0xFFFF) * w) & 0xFFFF
	return _i32((lo + (hi << 16)) & M32)


static func _i32(v: int) -> int:
	v &= M32
	return v - 0x100000000 if v >= 0x80000000 else v


## The scatter rule's mixed hash, step for step as colour-study.ts writes it.
static func _mixed_hash(x: int, z: int) -> int:
	var h: int = _i32(_imul(x, 374761393) + _imul(z, 668265263))
	h = _imul(h ^ ((h & M32) >> 13), 1274126177)
	h = _i32(h ^ ((h & M32) >> 16))
	return h & M32
