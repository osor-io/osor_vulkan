#version 450
#extension GL_ARB_separate_shader_objects : enable
#include "common_descriptor_sets.glsl"
#define PI (3.141592653589)
#define NOISE_OCTAVES (10)


layout(location = 0) out vec4 output_color;


float hash(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.13);
    p3 += dot(p3, p3.yzx + 3.333);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 x)
{
    vec2 i = floor(x);
    vec2 f = fract(x);
	float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 x)
{
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
	for (int i = 0; i < NOISE_OCTAVES; ++i) {
		v += a * noise(x);
		x = rot * x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

vec2 rotate(vec2 dir, float angle)
{
    dir.x = cos(angle) * dir.x + -sin(angle) * dir.y;
    dir.y = sin(angle) * dir.x + cos(angle) * dir.y;
    return dir;
}


float ease_in_3(float x)
{
    return (x*x*x);
}

float remap (float value, float min_in, float max_in, float min_out, float max_out)
{
    return min_out + ((value - min_in) / (max_in - min_in)) * (max_out - min_out);
}

void main()
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 ndcuv = uv * 2.0 - 1.0;
    ndcuv.x *= float(resolution.x)/resolution.y;
    vec2 mouse_uv = vec2(mouse.xy)/resolution.xy;
    vec2 mouse_ndcuv = mouse_uv * 2.0 - 1.0;
    mouse_ndcuv.x *= float(resolution.x)/resolution.y;
    float distance_to_mouse = length(mouse_ndcuv - ndcuv);

    float angle_a = PI/2.0;
    float angle_b = PI/2.5;
    float angle_c = PI/0.5;
    vec2 dir_a = normalize(vec2(cos(angle_a), sin(angle_a)));
    vec2 dir_b = normalize(vec2(cos(angle_b), sin(angle_b)));
    vec2 dir_c = normalize(vec2(cos(angle_c), sin(angle_c)));
    
    ndcuv = rotate(ndcuv, length(ndcuv.xy));
    float dist_to_seam = abs(ndcuv.y);

    vec2 dir = normalize(ndcuv.xy);
    float dist = length(ndcuv.xy);
    vec2 sample_coordinates;
    sample_coordinates.x = (atan(dir.y, dir.x));
    sample_coordinates.y = dist;

    vec2 fbm_sample_a = sample_coordinates + (time*0.5)*dir_a;
    vec2 fbm_sample_b = sample_coordinates + (time*0.7)*dir_b;
    vec2 fbm_sample_c = sample_coordinates + (time*0.2)*dir_c;

    float angle = dist*0.2;
    fbm_sample_a = rotate(fbm_sample_a, angle);
    fbm_sample_b = rotate(fbm_sample_b, angle);
    fbm_sample_c = rotate(fbm_sample_c, angle);

    vec3 col = vec3(1,1,1);
    col.x = fbm(fbm_sample_a);
	col.y = fbm(fbm_sample_b);
	col.z = fbm(fbm_sample_c);

    float mouse_factor = 0.2 * ease_in_3(1.0 - clamp(remap(distance_to_mouse, 0, 2, 0, 1), 0, 1));
    float baw = clamp(col.x * col.y * col.z * 1.0, 0.0, 1.0);
    baw = mix(0.0, baw, smoothstep(0.0, 0.05, dist_to_seam));
    output_color = vec4(baw, baw-mouse_factor, baw-mouse_factor, 1.0);
}