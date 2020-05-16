#version 450
#extension GL_ARB_separate_shader_objects : enable
#include "common_descriptor_sets.glsl"



layout(location = 0) in vec3 vertex_color;

layout(location = 0) out vec4 output_color;


void main()
{
    output_color = vec4(vertex_color, 1.0);
}
