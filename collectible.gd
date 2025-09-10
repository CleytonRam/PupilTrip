extends Area2D

@export var powerType: Enums.PowerType = Enums.PowerType.NONE
@export var duration: float = 10.0




func _ready():
     setupAppearence()

func setupAppearence():
    var sprite = $Sprite2D
    match powerType:
        Enums.powerType.COKE_DASH:
            sprite.modulate = Color(1, 0.7, 0.9)
        Enums.powerType.BECK_SMOKE:
            sprite.modulate = Color(0.8, 0.8, 0.8)
        Enums.powerType.LSJUMP:
            sprite.modulate = Color(0.5, 1, 0.5)
        Enums.powerType.EXTRAZY:
            sprite.modulate = Color(1, 0.5, 0.5)



func _on_area_entered(body):
    if body.is_in_group("player"):
       body.collect_power(powerType, duration)
       queue_free()
