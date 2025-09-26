shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 10.0) = 5.0;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);

    // Efeito pulsante baseado no tempo
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    float final_intensity = intensity * pulse;

    vec3 blended_color = mix(original_color.rgb, flash_color.rgb, final_intensity);

    COLOR = vec4(blended_color, original_color.a);
}