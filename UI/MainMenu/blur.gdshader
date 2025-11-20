shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;

void fragment() {
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    
    // Gaussian blur sampling
    for (float x = -blur_amount; x <= blur_amount; x += 1.0) {
        for (float y = -blur_amount; y <= blur_amount; y += 1.0) {
            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
            float weight = exp(-(x * x + y * y) / (2.0 * blur_amount));
            color += texture(TEXTURE, UV + offset) * weight;
            total_weight += weight;
        }
    }
    
    COLOR = color / total_weight;
}
