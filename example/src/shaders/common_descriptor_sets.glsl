


layout(set = 0, binding = 0) uniform per_frame_data
{
    ivec2 resolution;
    float time;
    float delta_time;

    ivec2 mouse;
    int something;
    int something_else;
};


layout(set = 1, binding = 0) uniform per_view_data
{
    mat4 view_from_world;
    mat4 projection_from_view;
};


layout(set = 2, binding = 0) uniform per_object_data
{
    mat4 world_from_model;
};
