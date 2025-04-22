shader_type canvas_item;

uniform float blur_amount : hint_range(0, 20) = 0.0;

void fragment() {
	vec4 color = vec4(0.0);
	float weight_total = 0.0;
	
	// Gaussian blur approximation
	for(float x = -blur_amount; x <= blur_amount; x += 1.0) {
		for(float y = -blur_amount; y <= blur_amount; y += 1.0) {
			vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
			// Gaussian weight
			float weight = exp(-(x*x + y*y) / (2.0 * blur_amount * blur_amount));
			color += texture(TEXTURE, UV + offset) * weight;
			weight_total += weight;
		}
	}
	
	// Normalize
	if (weight_total > 0.0) {
		color /= weight_total;
	}
	
	// Add slight darkening for better contrast with the popup
	color.rgb *= 0.9;
	
	COLOR = color;
}