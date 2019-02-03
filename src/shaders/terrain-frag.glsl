#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

// uniform vec4 u_Color_1;
// uniform vec4 u_Color_2;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;
in float fs_height;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    vec3 dark_purple = vec3(48.0, 1.0, 71.0) / 255.0;
    vec3 bright_gold = vec3(252.0, 211.0, 5.0) / 255.0;

    vec3 Col = vec3(mix(dark_purple, bright_gold, pow(fs_height, 3.0)));
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    out_Col = vec4(mix(Col, vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
}
