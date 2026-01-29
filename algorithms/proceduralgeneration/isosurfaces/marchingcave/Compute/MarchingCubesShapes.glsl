#[compute]
#version 460

// #------ SIMPLEX NOISE ------#
// (Standard noise implementation)
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x*34.0)+10.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) { 
	const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
	const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

	vec3 i  = floor(v + dot(v, C.yyy) );
	vec3 x0 =   v - i + dot(i, C.xxx) ;

	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min( g.xyz, l.zxy );
	vec3 i2 = max( g.xyz, l.zxy );

	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy;
	vec3 x3 = x0 - D.yyy;

	i = mod289(i); 
	vec4 p = permute( permute( permute( 
			i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
			+ i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
			+ i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

	float n_ = 0.142857142857;
	vec3  ns = n_ * D.wyz - D.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_ );

	vec4 x = x_ *ns.x + ns.yyyy;
	vec4 y = y_ *ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4( x.xy, y.xy );
	vec4 b1 = vec4( x.zw, y.zw );

	vec4 s0 = floor(b0)*2.0 + 1.0;
	vec4 s1 = floor(b1)*2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
	vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

	vec3 p0 = vec3(a0.xy,h.x);
	vec3 p1 = vec3(a0.zw,h.y);
	vec3 p2 = vec3(a1.xy,h.z);
	vec3 p3 = vec3(a1.zw,h.w);

	vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
	m = m * m;
	return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3) ) );
}

// Structs
struct Triangle {
	vec4 a;
	vec4 b;
	vec4 c;
	vec4 norm;
};

// Marching Cubes Tables
const int cornerIndexAFromEdge[12] = {0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3};
const int cornerIndexBFromEdge[12] = {1, 2, 3, 0, 5, 6, 7, 4, 4, 5, 6, 7};
const int offsets[256] = {0, 0, 3, 6, 12, 15, 21, 27, 36, 39, 45, 51, 60, 66, 75, 84, 90, 93, 99, 105, 114, 120, 129, 138, 150, 156, 165, 174, 186, 195, 207, 219, 228, 231, 237, 243, 252, 258, 267, 276, 288, 294, 303, 312, 324, 333, 345, 357, 366, 372, 381, 390, 396, 405, 417, 429, 438, 447, 459, 471, 480, 492, 507, 522, 528, 531, 537, 543, 552, 558, 567, 576, 588, 594, 603, 612, 624, 633, 645, 657, 666, 672, 681, 690, 702, 711, 723, 735, 750, 759, 771, 783, 798, 810, 825, 840, 852, 858, 867, 876, 888, 897, 909, 915, 924, 933, 945, 957, 972, 984, 999, 1008, 1014, 1023, 1035, 1047, 1056, 1068, 1083, 1092, 1098, 1110, 1125, 1140, 1152, 1167, 1173, 1185, 1188, 1191, 1197, 1203, 1212, 1218, 1227, 1236, 1248, 1254, 1263, 1272, 1284, 1293, 1305, 1317, 1326, 1332, 1341, 1350, 1362, 1371, 1383, 1395, 1410, 1419, 1425, 1437, 1446, 1458, 1467, 1482, 1488, 1494, 1503, 1512, 1524, 1533, 1545, 1557, 1572, 1581, 1593, 1605, 1620, 1632, 1647, 1662, 1674, 1683, 1695, 1707, 1716, 1728, 1743, 1758, 1770, 1782, 1791, 1806, 1812, 1827, 1839, 1845, 1848, 1854, 1863, 1872, 1884, 1893, 1905, 1917, 1932, 1941, 1953, 1965, 1980, 1986, 1995, 2004, 2010, 2019, 2031, 2043, 2058, 2070, 2085, 2100, 2106, 2118, 2127, 2142, 2154, 2163, 2169, 2181, 2184, 2193, 2205, 2217, 2232, 2244, 2259, 2268, 2280, 2292, 2307, 2322, 2328, 2337, 2349, 2355, 2358, 2364, 2373, 2382, 2388, 2397, 2409, 2415, 2418, 2427, 2433, 2445, 2448, 2454, 2457, 2460};
const int lengths[256] = {0, 3, 3, 6, 3, 6, 6, 9, 3, 6, 6, 9, 6, 9, 9, 6, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 6, 9, 12, 12, 9, 9, 12, 12, 9, 12, 15, 15, 6, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 12, 15, 15, 12, 6, 9, 9, 12, 9, 12, 6, 9, 9, 12, 12, 15, 12, 15, 9, 6, 9, 12, 12, 9, 12, 15, 9, 6, 12, 15, 15, 12, 15, 6, 12, 3, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 12, 9, 12, 12, 15, 9, 6, 12, 9, 12, 9, 15, 6, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 12, 15, 15, 12, 9, 12, 12, 9, 12, 15, 15, 12, 12, 9, 15, 6, 15, 12, 6, 3, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 6, 9, 9, 6, 9, 12, 12, 15, 12, 15, 15, 6, 12, 9, 15, 12, 9, 6, 12, 3, 9, 12, 12, 15, 12, 15, 9, 12, 12, 15, 15, 6, 9, 12, 6, 3, 6, 9, 9, 6, 9, 12, 6, 3, 9, 6, 12, 3, 6, 3, 3, 0};

layout(set = 0, binding = 0, std430) restrict buffer TriangleBuffer { Triangle data[]; } triangleBuffer;

layout(set = 0, binding = 1, std430) restrict buffer ParamsBuffer
{
	float time;
	float noiseScale;
	float isoLevel;
	float numVoxelsPerAxis;
	float scale;
	float posX;
	float posY;
	float posZ;
	float noiseOffsetX;
	float noiseOffsetY;
	float noiseOffsetZ;
	float shapeId; // Appended shape ID
} params;

layout(set = 0, binding = 2, std430) coherent buffer Counter { uint counter; };
layout(set = 0, binding = 3, std430) restrict buffer LutBuffer { int data[]; } lut;

// --- SDF Primitives ---
float sdSphere(vec3 p, float s) {
	return length(p) - s;
}

float sdBox(vec3 p, vec3 b) {
	vec3 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdBoxRound(vec3 p, vec3 b, float r) {
	vec3 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float sdCappedCylinder(vec3 p, float h, float r) {
	vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
	vec3 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

float sdTorus(vec3 p, vec2 t) {
	vec2 q = vec2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
}

// --- SDF Operations ---
float opUnion(float d1, float d2) { return min(d1, d2); }
float opSmoothUnion(float d1, float d2, float k) {
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
	return mix(d2, d1, h) - k * h * (1.0 - h);
}
float opSubtraction(float d1, float d2) { return max(-d1, d2); }
float opIntersection(float d1, float d2) { return max(d1, d2); }

// --- Specific Shape Functions ---

// --- Specific Shape Functions ---

float chairSDF(vec3 p) {
	// Centered roughly at 0
	float seat = sdBoxRound(p - vec3(0, 0, 0), vec3(15, 2, 15), 1.0);
	float back = sdBoxRound(p - vec3(0, 15, -13), vec3(15, 12, 2), 1.0);
	float leg1 = sdBox(p - vec3(12, -10, 12), vec3(2, 8, 2));
	float leg2 = sdBox(p - vec3(-12, -10, 12), vec3(2, 8, 2));
	float leg3 = sdBox(p - vec3(12, -10, -12), vec3(2, 8, 2));
	float leg4 = sdBox(p - vec3(-12, -10, -12), vec3(2, 8, 2));
	
	float res = opUnion(seat, back);
	res = opUnion(res, leg1);
	res = opUnion(res, leg2);
	res = opUnion(res, leg3);
	res = opUnion(res, leg4);
	return res;
}

float houseSDF(vec3 p) {
    // Centered roughly at 0
	float base = sdBox(p, vec3(20, 15, 20));
	
    vec3 roofP = p - vec3(0, 15, 0); 
    float roof = max(abs(roofP.x), abs(roofP.z)) + roofP.y - 20.0;
    roof = max(roof, -roofP.y); 
    
	float chimney = sdBox(p - vec3(12, 20, 5), vec3(3, 8, 3));
	
	float house = opUnion(base, roof);
	house = opUnion(house, chimney);
	
	float door = sdBox(p - vec3(0, -15, 20), vec3(5, 10, 5));
	house = opSubtraction(door, house);
	
	return house;
}

float bottleSDF(vec3 p) {
    p.y += 10.0; // Shift down
	float body = sdCappedCylinder(p, 15.0, 8.0);
	float neck = sdCappedCylinder(p - vec3(0, 20, 0), 8.0, 2.5);
	return opSmoothUnion(body, neck, 2.0);
}

float computerSDF(vec3 p) {
    // Monitor
	float screen = sdBoxRound(p - vec3(0, 10, 0), vec3(16, 10, 0.4), 0.5);
	float backBump = sdBoxRound(p - vec3(0, 10, -2), vec3(10, 6, 2), 1.0);
	
	// Stand
	float standV = sdBox(p - vec3(0, 0, -2), vec3(3, 6, 1));
	float standBase = sdBox(p - vec3(0, -6, 0), vec3(8, 0.2, 6));
	
	float mon = opUnion(screen, backBump);
	mon = opUnion(mon, standV);
	mon = opUnion(mon, standBase);
	return mon;
}

float cupSDF(vec3 p) {
	float cylinderOutside = sdCappedCylinder(p, 8.0, 6.0);
	float cylinderInside = sdCappedCylinder(p - vec3(0, 2, 0), 8.0, 5.0);
	
    vec3 q = p - vec3(6.0, 0.0, 0.0);
    float handle = sdTorus(q.zyx, vec2(3.5, 0.8));
    
	float cup = opSubtraction(cylinderInside, cylinderOutside);
	return opUnion(cup, handle);
}

float humanSDF(vec3 p) {
    // Centered at 0
	float head = sdSphere(p - vec3(0, 11, 0), 6.0);
	float torso = sdCapsule(p, vec3(0, -15, 0), vec3(0, 3, 0), 8.0);
	
	// Arms
	float armL = sdCapsule(p, vec3(9, 1, 0), vec3(20, -10, 5), 2.5);
	float armR = sdCapsule(p, vec3(-9, 1, 0), vec3(-20, -10, 5), 2.5);
	
	// Legs
	float legL = sdCapsule(p, vec3(3, -15, 0), vec3(5, -40, 0), 3.0);
	float legR = sdCapsule(p, vec3(-3, -15, 0), vec3(-5, -40, 0), 3.0);
	
	float body = opSmoothUnion(head, torso, 2.0);
	body = opSmoothUnion(body, armL, 1.0);
	body = opSmoothUnion(body, armR, 1.0);
	body = opSmoothUnion(body, legL, 1.0);
	body = opSmoothUnion(body, legR, 1.0);
	
	return body;
}

// --- Lab Items SDFs ---

float microscopeSDF(vec3 p) {
	// Base
	float base = sdBoxRound(p - vec3(0, -10, -5), vec3(8, 2, 10), 0.5);
	// Arm curving up
	float armVertical = sdBoxRound(p - vec3(0, 0, -12), vec3(3, 10, 3), 0.5);
	float armTop = sdBoxRound(p - vec3(0, 8, -6), vec3(3, 3, 8), 0.5);
	// Eyepiece/Tube
	float tube = sdCappedCylinder(p - vec3(0, 5, 0), 8.0, 2.5);
	float eyepiece = sdCappedCylinder(p - vec3(0, 14, 0), 2.0, 3.0);
	// Stage
	float stage = sdBox(p - vec3(0, -2, 0), vec3(6, 0.5, 6));
	
	float res = opUnion(base, armVertical);
	res = opUnion(res, armTop);
	res = opUnion(res, tube);
	res = opUnion(res, eyepiece);
	res = opUnion(res, stage);
	return res;
}

float flaskSDF(vec3 p) {
	// Erlenmeyer-ish shape
	// Cone body
	vec3 q = p;
	q.y += 10.0;
	float cone = sdCappedCylinder(q, 8.0, 8.0 * (1.0 - clamp(q.y/15.0, 0.0, 1.0)) + 3.0); // Rough approximation
	float sphereBody = sdSphere(p - vec3(0, -10, 0), 10.0); // Florence flask style is easier with sphere
	float neck = sdCappedCylinder(p - vec3(0, 5, 0), 10.0, 3.0);
	float rim = sdTorus(p - vec3(0, 15, 0), vec2(3.0, 0.8));
	
	float res = opSmoothUnion(sphereBody, neck, 3.0);
	res = opUnion(res, rim);
	return res;
}

float dnaSDF(vec3 p) {
	// Double Helix
	// Twist space
	float twist = p.y * 0.15;
	float c = cos(twist);
	float s = sin(twist);
	mat2  m = mat2(c, -s, s, c);
	vec3  q = vec3(m * p.xz, p.y);
	
	// Two strands
	vec3 q1 = q - vec3(6, 0, 0); // Offset in twisted x
	vec3 q2 = q - vec3(-6, 0, 0);
	
	float strand1 = length(q1.xz) - 1.5; // Vertical cylinder in twisted space
	float strand2 = length(q2.xz) - 1.5;
	
	// Rungs (horizontal connectors)
	// Repeating every X units
	float rungY = mod(p.y, 6.0) - 3.0; // Repetition
	float rungDist = sdBox(vec3(q.x, rungY, q.z), vec3(6, 1.0, 1.0));
	
	float strands = opUnion(strand1, strand2);
	// Limit height
	float heightLimit = sdBox(p, vec3(20, 25, 20));
	
	return opIntersection(opUnion(strands, rungDist), heightLimit);
}

float atomSDF(vec3 p) {
	// Nucleus
	float nucleus = sdSphere(p, 4.0);
	
	// Electrons / Orbitals
	// Ring 1: Flat
	float ring1 = sdTorus(p, vec2(14.0, 0.5));
	
	// Ring 2: Rotated 60 deg X
	float c = cos(1.047); // 60 deg
	float s = sin(1.047);
	vec3 p2 = p;
	p2.yz = mat2(c, -s, s, c) * p2.yz;
	float ring2 = sdTorus(p2, vec2(14.0, 0.5));
	
	// Ring 3: Rotated -60 deg X
	vec3 p3 = p;
	p3.yz = mat2(c, s, -s, c) * p3.yz;
	float ring3 = sdTorus(p3, vec2(14.0, 0.5));
	
	// Electrons (spheres on rings)
	// Animate them? Need time. For now static.
	float e1 = sdSphere(p - vec3(14,0,0), 1.5);
	float e2 = sdSphere(p2 - vec3(14,0,0), 1.5);
	float e3 = sdSphere(p3 - vec3(14,0,0), 1.5);

	float res = opUnion(nucleus, ring1);
	res = opUnion(res, ring2);
	res = opUnion(res, ring3);
	res = opUnion(res, e1);
	res = opUnion(res, e2);
	res = opUnion(res, e3);
	return res;
}

float sculptureSDF(vec3 p) {
	// A non-closed torus with 20 bulges flowing the radius
	
	// 1. Get Angle
	float angle = atan(p.z, p.x);
	
	// 2. Create 20 bulges modulated by angle
	// 20 repetitions around the circle
	float bulgeSignal = cos(angle * 20.0);
	
	// 3. Modulate thickness/radius
	// Base major radius 12.0
	// Base minor radius 2.0, varying +/- 1.0
	float variation = 1.0 * bulgeSignal;
	
	vec2 t = vec2(length(p.xz) - 12.0, p.y);
	float rawTorus = length(t) - (2.5 + variation);
	
	// 4. Make it non-closed (Gap at the back, angle ~ PI)
	// We subtract a wedge or box at the back (where x is negative and z is near 0)
	// Let's cut where angle is > 3.0 or < -3.0 (small slice at -x axis)
	
	float gap = sdBox(p - vec3(-15, 0, 0), vec3(5, 5, 5));
	
	return opSubtraction(gap, rawTorus);
}

// --- Combined Evaluate Function ---
vec4 evaluate(vec3 coord)
{   
	float cellSize = 1.0 / params.numVoxelsPerAxis * params.scale;
	float cx = int(params.posX / cellSize + 0.5 * sign(params.posX)) * cellSize;
	float cy = int(params.posY / cellSize + 0.5 * sign(params.posY)) * cellSize;
	float cz = int(params.posZ / cellSize + 0.5 * sign(params.posZ)) * cellSize;
	vec3 centreSnapped = vec3(cx, cy, cz);

	vec3 posNorm = coord / vec3(params.numVoxelsPerAxis) - vec3(0.5);
	vec3 worldPos = posNorm * params.scale + centreSnapped;

	// SDF Evaluation
	float dist = 100.0;
	int id = int(params.shapeId);
	
	if (id == 0) dist = humanSDF(worldPos);
	else if (id == 1) dist = chairSDF(worldPos);
	else if (id == 2) dist = houseSDF(worldPos);
	else if (id == 3) dist = bottleSDF(worldPos);
	else if (id == 4) dist = cupSDF(worldPos);
	else if (id == 5) dist = computerSDF(worldPos);
	else if (id == 6) dist = microscopeSDF(worldPos);
	else if (id == 7) dist = flaskSDF(worldPos);
	else if (id == 8) dist = dnaSDF(worldPos);
	else if (id == 9) dist = atomSDF(worldPos);
	else if (id == 10) dist = sculptureSDF(worldPos);
	else dist = humanSDF(worldPos); // Default

	return vec4(worldPos, dist);
}

vec4 interpolateVerts(vec4 v1, vec4 v2, float isoLevel)
{
	float t = (isoLevel - v1.w) / (v2.w - v1.w);
	return v1 + t * (v2 - v1);
}

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
void main()
{
	vec3 id = gl_GlobalInvocationID;
	
	// Optimization: Skip if far from center (optional, but good for performance)
	// For now, keep it simple.

	vec4 cubeCorners[8] = {
		evaluate(vec3(id.x + 0, id.y + 0, id.z + 0)),
		evaluate(vec3(id.x + 1, id.y + 0, id.z + 0)),
		evaluate(vec3(id.x + 1, id.y + 0, id.z + 1)),
		evaluate(vec3(id.x + 0, id.y + 0, id.z + 1)),
		evaluate(vec3(id.x + 0, id.y + 1, id.z + 0)),
		evaluate(vec3(id.x + 1, id.y + 1, id.z + 0)),
		evaluate(vec3(id.x + 1, id.y + 1, id.z + 1)),
		evaluate(vec3(id.x + 0, id.y + 1, id.z + 1))
	};

	uint cubeIndex = 0;
	float isoLevel = params.isoLevel;
	if (cubeCorners[0].w < isoLevel) cubeIndex |= 1;
	if (cubeCorners[1].w < isoLevel) cubeIndex |= 2;
	if (cubeCorners[2].w < isoLevel) cubeIndex |= 4;
	if (cubeCorners[3].w < isoLevel) cubeIndex |= 8;
	if (cubeCorners[4].w < isoLevel) cubeIndex |= 16;
	if (cubeCorners[5].w < isoLevel) cubeIndex |= 32;
	if (cubeCorners[6].w < isoLevel) cubeIndex |= 64;
	if (cubeCorners[7].w < isoLevel) cubeIndex |= 128;

	int numIndices = lengths[cubeIndex];
	int offset = offsets[cubeIndex];
	
	for (int i = 0; i < numIndices; i += 3) {
		int v0 = lut.data[offset + i];
		int v1 = lut.data[offset + 1 + i];
		int v2 = lut.data[offset + 2 + i];

		int a0 = cornerIndexAFromEdge[v0];
		int b0 = cornerIndexBFromEdge[v0];
		int a1 = cornerIndexAFromEdge[v1];
		int b1 = cornerIndexBFromEdge[v1];
		int a2 = cornerIndexAFromEdge[v2];
		int b2 = cornerIndexBFromEdge[v2];
		
		Triangle currTri;
		currTri.a = interpolateVerts(cubeCorners[a0], cubeCorners[b0], isoLevel);
		currTri.b = interpolateVerts(cubeCorners[a1], cubeCorners[b1], isoLevel);
		currTri.c = interpolateVerts(cubeCorners[a2], cubeCorners[b2], isoLevel);

		vec3 ab = currTri.b.xyz - currTri.a.xyz;
		vec3 ac = currTri.c.xyz - currTri.a.xyz;
		currTri.norm = -vec4(normalize(cross(ab,ac)), 0); // Negative to face out if SDF is dist

		uint index = atomicAdd(counter, 1u);
		triangleBuffer.data[index] = currTri;
	}
}
