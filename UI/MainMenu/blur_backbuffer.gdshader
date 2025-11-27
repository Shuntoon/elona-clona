shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 50.0) = 3.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    
    // Gaussian blur sampling from back buffer
    for (float x = -blur_amount; x <= blur_amount; x += 1.0) {
        for (float y = -blur_amount; y <= blur_amount; y += 1.0) {
            vec2 offset = vec2(x, y) * SCREEN_PIXEL_SIZE;
            float weight = exp(-(x * x + y * y) / (2.0 * blur_amount));
            color += texture(screen_texture, SCREEN_UV + offset) * weight;
            total_weight += weight;
        }
    }
    
    COLOR = color / total_weight;
    COLOR.a = 1.0; // Full opacity
}
