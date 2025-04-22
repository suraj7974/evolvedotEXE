shader_type canvas_item;

uniform float blur_amount : hint_range(0, 5) = 2.0;

void fragment() {
    vec4 color = vec4(0.0);
    
    // Simple Gaussian blur effect
    for (float i = -blur_amount; i <= blur_amount; i++) {
        for (float j = -blur_amount; j <= blur_amount; j++) {
            color += texture(TEXTURE, UV + vec2(i, j) * TEXTURE_PIXEL_SIZE);
        }
    }
    
    // Normalize
    color /= pow(2.0 * blur_amount + 1.0, 2.0);
    
    // Add slight dimming effect
    color.rgb *= 0.85;
    
    COLOR = color;
}