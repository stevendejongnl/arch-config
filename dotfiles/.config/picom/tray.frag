#version 330

in vec2 texcoord;
uniform sampler2D tex;

// Tray icons: drop the brand colours and show each icon in the bar's secondary ink.
// The bar background (#17181a) is darker than every icon pixel, so a luma ramp keeps it dark.
vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    float k = clamp((l - 0.09) / 0.55, 0.0, 1.0);
    vec3 bg = vec3(0.090, 0.094, 0.102);
    vec3 ink = vec3(0.659, 0.663, 0.678);
    return default_post_processing(vec4(mix(bg, ink, k), c.a));
}
