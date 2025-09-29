extends Area2D

# Enum para tipos de coletáveis (agora em uma string simples)
@export var abilityType: String = "none"  # Valores: "coke_dash", "beck_smoke", "meth_jump", "mushroom_vision"

func _ready():
	setupAppearance()
	body_entered.connect(_on_body_entered)

func setupAppearance():
	var sprite = $Sprite2D
	match abilityType:
		"coke_dash":
			# Carrega a imagem específica e ajusta a escala
			sprite.texture = load("res://Assets/PowerUps/Sprite-0001.png")  
			sprite.scale = Vector2(0.8, 0.8)  
			sprite.modulate = Color(1, 0.7, 0.9)  # Rosa
		"beck_smoke":
			sprite.modulate = Color(0.8, 0.8, 0.8)  # Cinza
		"meth_jump":
			# Carrega a imagem específica e ajusta a escala
			sprite.texture = load("res://Assets/PowerUps/Sprite-0002.png")  
			sprite.scale = Vector2(0.8, 0.8)  
			sprite.modulate = Color(0.8, 0.9, 1)  # Azul claro
		"mushroom_vision":
			sprite.modulate = Color(1, 0.5, 1)  # Roxo
		_:
			sprite.modulate = Color(1, 1, 1)  # Branco padrão

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Desativa a colisão imediatamente
		$CollisionShape2D.set_deferred("disabled", true)
		
		# Chama o método para desbloquear a habilidade
		if body.has_method("unlockAbility"):
			body.unlockAbility(abilityType)
		
		# Faz o item desaparecer com efeito
		disappear()

func disappear():
	# Efeito de desaparecimento
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property($Sprite2D, "modulate:a", 0, 0.2)
	tween.tween_callback(queue_free)