extends RefCounted
## Decimal natural numbers retain the reference's BigInt behaviour beyond int64.
static func clean(value: String) -> String:
	var s := ""
	for c in value:
		if c>="0" and c<="9":s+=c
	while s.length()>1 and s[0]=="0":s = s.substr(1)
	return s if not s.is_empty() else "0"
static func odd(s: String) -> bool:return int(s[-1])%2==1
static func divide(s: String,by: int) -> Dictionary:
	var result := "";var carry := 0
	for c in s:
		var n := carry*10+int(c);result+=str(n/by);carry = n%by
	return {"quotient":clean(result),"remainder":carry}
static func multiply(s: String,by: int) -> String:
	var result := "";var carry := 0
	for i in range(s.length()-1,-1,-1):
		var n := int(s[i])*by+carry;result = str(n%10)+result;carry = n/10
	while carry>0:result = str(carry%10)+result;carry = carry/10
	return clean(result)
static func add(s: String,by: int) -> String:
	var result := "";var carry := by
	for i in range(s.length()-1,-1,-1):
		var n := int(s[i])+carry
		if n<0:result = str(posmod(n,10))+result;carry = -1
		else:result = str(n%10)+result;carry = n/10
	if carry<0:return "0"
	return clean((str(carry) if carry>0 else "")+result)
static func next(s: String,a := 3,b := 1) -> String:return add(multiply(s,a),b) if odd(s) else divide(s,2).quotient
static func logarithm(s: String) -> float:
	var count := mini(s.length(),14);return log(maxf(1,float(s.substr(0,count))))/log(2.0)+(s.length()-count)*log(10.0)/log(2.0)
static func trajectory(s: String,a := 3,b := 1,limit := 6000) -> Array[String]:
	var values: Array[String] = [clean(s)];var seen := {}
	while values[-1]!="1" and values.size()<limit and not seen.has(values[-1]):seen[values[-1]] = true;values.append(next(values[-1],a,b))
	return values
static func digits(s: String,base := 6) -> Array:
	var result: Array = [];var current := clean(s)
	while current!="0":
		var d := divide(current,base);result.append(d.remainder);current = d.quotient
	return result if not result.is_empty() else [0]
