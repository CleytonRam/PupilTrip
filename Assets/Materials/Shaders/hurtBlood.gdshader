shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float blood_effect : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    
    // Efeito de flash simples
    vec3 flash_effect = mix(original_color.rgb, flash_color.rgb, intensity);
    
    // Efeito de sangue/ferimento (escurece as cores exceto o vermelho)
    vec3 blood_effect_color = mix(flash_effect, vec3(flash_effect.r * 1.2, flash_effect.g * 0.7, flash_effect.b * 0.7), blood_effect);
    
    COLOR = vec4(mix(flash_effect, blood_effect_color, blood_effect), original_color.a);
}
