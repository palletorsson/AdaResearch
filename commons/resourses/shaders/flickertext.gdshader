shader_type spatial;


uniform vec2 u_resolution = vec2(1.0, 1.0);


// Function to generate a random number based on 1D input
float random(float x) {
    return fract(sin(x) * 43758.5453);
}

// Function to generate a random number based on 2D input
float myrandom(vec2 p) {
    return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x))));
}

// Function to determine if a bit in a binary representation of a number is set
float bin(vec2 ipos, float n) {
    float remain = mod(n, 33554432.0);
    for (int i = 0; i < 25; i++) {
        if (floor(float(i)/3.0) == ipos.y && mod(float(i), 3.0) == ipos.x) {
            return step(1.0, mod(remain, 2.0));
        }
        remain = ceil(remain / 2.0);
    }
    return 0.0;
}

// Function to draw character segments based on numeric value
float char(vec2 st, float n) {
    st.x = st.x * 2.0 - 0.5;
    st.y = st.y * 1.2 - 0.1;

    vec2 grid = vec2(3.0, 5.0);
    vec2 ipos = floor(st * grid);
    vec2 fpos = fract(st * grid);

    n = floor(mod(n, 10.0));
    float digit = 0.0;
    if (n < 1.0) digit = 31600.0;
    else if (n < 2.0) digit = 9363.0;
    else if (n < 3.0) digit = 31184.0;
    else if (n < 4.0) digit = 31208.0;
    else if (n < 5.0) digit = 23525.0;
    else if (n < 6.0) digit = 29672.0;
    else if (n < 7.0) digit = 29680.0;
    else if (n < 8.0) digit = 31013.0;
    else if (n < 9.0) digit = 31728.0;
    else if (n < 10.0) digit = 31717.0;

    float pct = bin(ipos, digit);
    return step(0.5, 1.0 - pct);
}

void fragment() {
    vec2 st = UV;
    st.x *= u_resolution.x / u_resolution.y;

    float rows = 24.0;
    vec2 ipos = floor(st * rows);
    vec2 fpos = fract(st * rows);

    // Applying time based motion to position
    ipos += vec2(0.0, floor(TIME * 0.3 * myrandom(ipos + vec2(1.0))));

    float pct = myrandom(ipos);
    vec3 color = vec3(char(fpos, 100.0 * pct));

    // Colorizing the output based on the character segment generated
    ALBEDO = vec3(color);
}
