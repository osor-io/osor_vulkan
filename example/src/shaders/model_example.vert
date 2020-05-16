#version 450
#extension GL_ARB_separate_shader_objects : enable
#include "common_descriptor_sets.glsl"


layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec3 in_vertex_color;



layout(location = 0) out vec3 out_vertex_color;


mat4 rotation_matrix(vec3 axis,float angle) {
    vec3 n = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    return mat4(c+(1.-c)*n.x*n.x    ,  (1.-c)*n.x*n.y-s*n.z ,  (1.-c)*n.x*n.z+s*n.y  , 0.0,
                (1.-c)*n.x*n.y+s*n.z,  c+(1.-c)*n.y*n.y     ,  (1.-c)*n.y*n.z-s*n.x  , 0.0,
                (1.-c)*n.x*n.z-s*n.y,  (1.-c)*n.y*n.z+s*n.x ,  c+(1.-c)*n.z*n.z      , 0.0,
                0.0                 ,  0.0                  ,  0.0                   , 1.0);
}

void main()
{
    float rotation_value = 1.0 - clamp(length((vec2(mouse.xy)/resolution.xy) * 2.0 - 1.0), 0, 1);
    float rotation_scale = 1.0 + rotation_value;

    mat4 extra_rotation = rotation_matrix(vec3(0,-3.0,0.7), 3.3 * sin(time) * rotation_scale);
    extra_rotation *= rotation_matrix(vec3(2,0.3,0.1), 0.3 * sin(0.5 + time*2) * rotation_scale);
    extra_rotation *= rotation_matrix(vec3(0.1,0.3,2), 4.6 * sin(0.7 + time*3) * rotation_scale);

    vec4 model_position = vec4(vertex_position, 1.0);
    mat4 world_from_model_rotated = world_from_model * extra_rotation;
    vec4 world_position = world_from_model_rotated * model_position;
    vec4 view_position = view_from_world * world_position;
    gl_Position = projection_from_view * view_position;
    out_vertex_color = mix(in_vertex_color, vec3(1.0,1.0,0.0), rotation_value);
}