shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	// formula from "https://stackoverflow.com/a/596241"
    float avg = ((0.2126 * COLOR.r) + (0.7152 * COLOR.g) + (0.0722 * COLOR.b));
    COLOR.rgb = vec3(avg);
}