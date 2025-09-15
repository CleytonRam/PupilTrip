extends ParallaxBackground

func _ready():
    for layer in get_children():
        if layer is ParallaxLayer:
            var sprite = layer.get_node("Sprite2D")
            if sprite and sprite.texture:
                # Configura mirroring automático baseado no tamanho da textura
                var texture_size = sprite.texture.get_size()
                layer.motion_mirroring = texture_size
                print("Mirroring configurado para: ", texture_size)