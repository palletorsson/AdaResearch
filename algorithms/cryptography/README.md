# Cryptography

Secrets, keys, and mathematical locks.

## QFEP Connection

Cryptography is **controlled entropy** — encryption adds apparent randomness (E) that can only be reversed with the key (F). RSA's security relies on the asymmetry between multiplication (easy) and factoring (hard). Information hiding is queer: the message is there and not-there simultaneously.

## Contents

| Folder | Description |
|--------|-------------|
| `rsa/` | RSA public-key encryption visualization |

## RSA Algorithm

```
1. Choose two primes: p, q
2. Compute n = p × q
3. Compute φ(n) = (p-1)(q-1)
4. Choose e: 1 < e < φ(n), gcd(e, φ(n)) = 1
5. Compute d: d × e ≡ 1 (mod φ(n))

Public key:  (n, e)
Private key: (n, d)

Encrypt: c = m^e mod n
Decrypt: m = c^d mod n
```

The magic: computing d requires knowing φ(n), which requires factoring n.
Factoring large numbers is computationally hard.

## Files

- 1 GDScript file
- 1 scene file
