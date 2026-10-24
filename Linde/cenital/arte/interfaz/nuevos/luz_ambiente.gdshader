shader_type canvas_item;
// Propuesta E06: aplicar exclusivamente al mundo; HUD en CanvasLayer aparte.
uniform float noche : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tinte_nocturno : source_color = vec4(0.55, 0.62, 0.82, 1.0);
void fragment() {
    vec4 base = COLOR;   // en Godot 4 COLOR ya incluye TEXTURE*modulate; multiplicar otra vez elevaba al cuadrado el color (mundo oscuro)
    COLOR = vec4(base.rgb * mix(vec3(1.0), tinte_nocturno.rgb, noche), base.a);
}
