shader_type canvas_item;
// Stylizes the low-resolution camera preview so it matches the pixel-art look:
// posterized colours, scanlines and a slight red tint in the shadows.

uniform float levels : hint_range(2.0, 32.0) = 7.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float scanline_count = 90.0;
uniform vec3 shadow_tint : source_color = vec3(0.35, 0.05, 0.08);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 color = floor(source.rgb * levels + 0.5) / levels;
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, color + shadow_tint * 0.35, 1.0 - luma);
	float scanline = 0.5 + 0.5 * sin(UV.y * scanline_count * 6.2831853);
	color *= 1.0 - scanline_strength * scanline;
	COLOR = vec4(color, source.a) * COLOR;
}
