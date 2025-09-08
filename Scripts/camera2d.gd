extends Camera2D

@export var target: Node2D
@export var smoothSpeed: float = 5.0

func _process(delta):
    if target:
        global_position = global_position.lerp(target.global_position, smoothSpeed * delta)
