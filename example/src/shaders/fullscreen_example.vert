#version 450
#extension GL_ARB_separate_shader_objects : enable
#include "common_descriptor_sets.glsl"

vec2 fullscreen_positions[3] = vec2[]
(
    vec2(-1.0, -1.0),
    vec2(-1.0,  3.0),
    vec2( 3.0, -1.0)
);

void main()
{
    gl_Position = vec4(fullscreen_positions[gl_VertexIndex], 0.0, 1.0);
}