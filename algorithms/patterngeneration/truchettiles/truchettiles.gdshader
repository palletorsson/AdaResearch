shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec2 tiles = vec2(8.0, 8.0);                 // number of cells (x,y)
uniform vec4 color_a : source_color = vec4(0.0,0.0,0.0,1.0); // black
uniform vec4 color_b : source_color = vec4(1.0,1.0,1.0,1.0); // white
uniform float edge_soft : hint_range(0.0, 0.05) = 0.0;       // set >0 for tiny anti-alias

void fragment(){
    // tile index + local coords in cell
    vec2 t  = UV * tiles;
    vec2 i  = floor(t);      // cell id
    vec2 f  = fract(t);      // 0..1 inside cell

    // chessboard parity of the cell
    float parity = mod(i.x + i.y, 2.0);

    // two diagonals: y > x  vs  y > 1-x
    float d0 = f.y - f.x;        // rising diagonal
    float d1 = f.y - (1.0 - f.x); // falling diagonal

    // crisp or slightly softened edge
    float m0 = edge_soft > 0.0 ? smoothstep(0.0, edge_soft, d0) : step(0.0, d0);
    float m1 = edge_soft > 0.0 ? smoothstep(0.0, edge_soft, d1) : step(0.0, d1);

    // alternate diagonals per cell
    float mask = mix(m0, m1, parity);

    ALBEDO = mix(color_a.rgb, color_b.rgb, mask);
    ALPHA  = mix(color_a.a,  color_b.a,  mask);
}
