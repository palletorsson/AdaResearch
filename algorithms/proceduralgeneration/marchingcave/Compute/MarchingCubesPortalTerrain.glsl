#[compute]
#version 460

// Combined terrain + multiple portal toruses in single marching cubes mesh

// #------ SIMPLEX NOISE ------#
vec3 mod289(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
	return mod289(((x*34.0)+10.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
{ 
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
	return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
								dot(p2,x2), dot(p3,x3) ) );
}

struct Triangle {
	vec4 a;
	vec4 b;
	vec4 c;
	vec4 norm;
};

const int cornerIndexAFromEdge[12] = {0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3};
const int cornerIndexBFromEdge[12] = {1, 2, 3, 0, 5, 6, 7, 4, 4, 5, 6, 7};

const int offsets[256] = {0, 0, 3, 6, 12, 15, 21, 27, 36, 39, 45, 51, 60, 66, 75, 84, 90, 93, 99, 105, 114, 120, 129, 138, 150, 156, 165, 174, 186, 195, 207, 219, 228, 231, 237, 243, 252, 258, 267, 276, 288, 294, 303, 312, 324, 333, 345, 357, 366, 372, 381, 390, 396, 405, 417, 429, 438, 447, 459, 471, 480, 492, 507, 522, 528, 531, 537, 543, 552, 558, 567, 576, 588, 594, 603, 612, 624, 633, 645, 657, 666, 672, 681, 690, 702, 711, 723, 735, 750, 759, 771, 783, 798, 810, 825, 840, 852, 858, 867, 876, 888, 897, 909, 915, 924, 933, 945, 957, 972, 984, 999, 1008, 1014, 1023, 1035, 1047, 1056, 1068, 1083, 1092, 1098, 1110, 1125, 1140, 1152, 1167, 1173, 1185, 1188, 1191, 1197, 1203, 1212, 1218, 1227, 1236, 1248, 1254, 1263, 1272, 1284, 1293, 1305, 1317, 1326, 1332, 1341, 1350, 1362, 1371, 1383, 1395, 1410, 1419, 1425, 1437, 1446, 1458, 1467, 1482, 1488, 1494, 1503, 1512, 1524, 1533, 1545, 1557, 1572, 1581, 1593, 1605, 1620, 1632, 1647, 1662, 1674, 1683, 1695, 1707, 1716, 1728, 1743, 1758, 1770, 1782, 1791, 1806, 1812, 1827, 1839, 1845, 1848, 1854, 1863, 1872, 1884, 1893, 1905, 1917, 1932, 1941, 1953, 1965, 1980, 1986, 1995, 2004, 2010, 2019, 2031, 2043, 2058, 2070, 2085, 2100, 2106, 2118, 2127, 2142, 2154, 2163, 2169, 2181, 2184, 2193, 2205, 2217, 2232, 2244, 2259, 2268, 2280, 2292, 2307, 2322, 2328, 2337, 2349, 2355, 2358, 2364, 2373, 2382, 2388, 2397, 2409, 2415, 2418, 2427, 2433, 2445, 2448, 2454, 2457, 2460};
const int lengths[256] = {0, 3, 3, 6, 3, 6, 6, 9, 3, 6, 6, 9, 6, 9, 9, 6, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 6, 9, 12, 12, 9, 9, 12, 12, 9, 12, 15, 15, 6, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 12, 15, 15, 12, 6, 9, 9, 12, 9, 12, 6, 9, 9, 12, 12, 15, 12, 15, 9, 6, 9, 12, 12, 9, 12, 15, 9, 6, 12, 15, 15, 12, 15, 6, 12, 3, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 12, 9, 12, 12, 15, 9, 6, 12, 9, 12, 9, 15, 6, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 12, 15, 15, 12, 9, 12, 12, 9, 12, 15, 15, 12, 12, 9, 15, 6, 15, 12, 6, 3, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 6, 9, 9, 6, 9, 12, 12, 15, 12, 15, 15, 6, 12, 9, 15, 12, 9, 6, 12, 3, 9, 12, 12, 15, 12, 15, 9, 12, 12, 15, 15, 6, 9, 12, 6, 3, 6, 9, 9, 6, 9, 12, 6, 3, 9, 6, 12, 3, 6, 3, 3, 0};

layout(set = 0, binding = 0, std430) restrict buffer TriangleBuffer
{
	Triangle data[];
}
triangleBuffer;

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
	// Portal params
	float numPortals;
	float portalSpacing;
	float portalRadius;
	float portalMinorRadius;
	float portalEmergenceHeight;
}
params;

layout(set = 0, binding = 2, std430) coherent buffer Counter
{
	uint counter;
};

layout(set = 0, binding = 3, std430) restrict buffer LutBuffer
{
	int data[];
}
lut;

// SDF for a torus at a specific position (VERTICAL/STANDING orientation)
float torusSDF(vec3 worldPos, vec3 torusCenter, float majorRadius, float minorRadius, float noiseVariation, float angle)
{
	// Transform to torus-local space
	vec3 localPos = worldPos - torusCenter;
	
	// Rotate to face outward from center
	float c = cos(-angle);
	float s = sin(-angle);
	vec3 rotated = vec3(
		localPos.x * c - localPos.z * s,
		localPos.y,
		localPos.x * s + localPos.z * c
	);
	
	// Calculate VERTICAL torus SDF (standing upright like a doorway)
	// Ring lies in XY plane (vertical), hole faces along Z axis (horizontal)
	float distFromZAxis = length(vec2(rotated.x, rotated.y));
	vec2 torusPoint = vec2(distFromZAxis - majorRadius, rotated.z);
	float torusDist = length(torusPoint) - minorRadius;
	
	// Add organic noise deformation
	vec3 noiseOffset = vec3(params.noiseOffsetX, params.noiseOffsetY, params.noiseOffsetZ);
	vec3 samplePos = (rotated + torusCenter + noiseOffset) * params.noiseScale / params.scale;
	
	float deformation = 0;
	float amplitude = 1.0;
	float frequency = 1.0;
	
	for (int i = 0; i < 3; i++)
	{
		float noise = snoise(samplePos * frequency + vec3(noiseVariation * 10.0));
		deformation += noise * amplitude;
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	
	// Add twist and bulges (around the ring)
	float ringAngle = atan(rotated.y, rotated.x);
	float twist = sin(ringAngle * 3.0 + rotated.z * 0.1) * 2.0;
	float bulge = sin(ringAngle * 5.0) * cos(rotated.z * 0.15) * 3.0;
	
	return torusDist + deformation * 6.0 + twist + bulge;
}

vec4 evaluate(vec3 coord)
{   
	float cellSize = 1.0 / params.numVoxelsPerAxis * params.scale;
	float cx = int(params.posX / cellSize + 0.5 * sign(params.posX)) * cellSize;
	float cy = int(params.posY / cellSize + 0.5 * sign(params.posY)) * cellSize;
	float cz = int(params.posZ / cellSize + 0.5 * sign(params.posZ)) * cellSize;
	vec3 centreSnapped = vec3(cx, cy, cz);

	vec3 posNorm = coord / vec3(params.numVoxelsPerAxis) - vec3(0.5);
	vec3 worldPos = posNorm * params.scale + centreSnapped;
	vec3 noiseOffset = vec3(params.noiseOffsetX, params.noiseOffsetY, params.noiseOffsetZ);
	vec3 samplePos = (worldPos + noiseOffset) * params.noiseScale / params.scale;

	// ===== TERRAIN DENSITY =====
	// Calculate surface variation (rolling hills)
	float surfaceNoise = 0;
	surfaceNoise += snoise(vec3(worldPos.x * 0.01, 0, worldPos.z * 0.01)) * 15.0;
	surfaceNoise += snoise(vec3(worldPos.x * 0.03, 0, worldPos.z * 0.03)) * 5.0;
	
	// Create flat terrain base (positive = solid, negative = air)
	float surfaceHeight = surfaceNoise;
	float terrainDensity = (surfaceHeight - worldPos.y) / 30.0;  // Inverted
	
	// ===== PORTAL TORUSES =====
	// Start with a very large distance (no portal nearby)
	float portalsDensity = 1000.0;
	
	// Calculate positions and SDFs for all portals
	int numPortals = int(params.numPortals);
	float angleStep = 6.28318530718 / float(numPortals); // TAU / numPortals
	
	for (int i = 0; i < numPortals; i++)
	{
		float angle = float(i) * angleStep;
		vec3 portalCenter = vec3(
			cos(angle) * params.portalSpacing,
			params.portalEmergenceHeight,
			sin(angle) * params.portalSpacing
		);
		
		float torusDist = torusSDF(
			worldPos, 
			portalCenter, 
			params.portalRadius, 
			params.portalMinorRadius,
			float(i), // Variation per portal
			angle     // Rotation to face center
		);
		
		// CSG Union: take minimum distance (closest portal)
		portalsDensity = min(portalsDensity, torusDist / 30.0);
	}
	
	// ===== COMBINE TERRAIN + PORTALS =====
	// CSG Union: terrain OR portals (take maximum = most solid)
	// Positive density = solid, negative = air
	// We want solid where EITHER terrain OR portals are solid
	float density = max(terrainDensity, -portalsDensity);  // Portal SDF needs negation

	return vec4(worldPos, density);
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

	// 8 corners of the current cube
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

	// Calculate cube configuration index
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

	// Create triangles for current cube configuration
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

		Triangle tri;
		tri.a = interpolateVerts(cubeCorners[a0], cubeCorners[b0], isoLevel);
		tri.b = interpolateVerts(cubeCorners[a1], cubeCorners[b1], isoLevel);
		tri.c = interpolateVerts(cubeCorners[a2], cubeCorners[b2], isoLevel);

		// Calculate normal
		vec3 ab = tri.b.xyz - tri.a.xyz;
		vec3 ac = tri.c.xyz - tri.a.xyz;
		vec3 normal = normalize(cross(ab, ac));
		tri.norm = vec4(normal, 0);

		uint index = atomicAdd(counter, 1);
		triangleBuffer.data[index] = tri;
	}
}

