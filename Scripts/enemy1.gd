extends CharacterBody2D

var health: int = 50
var max_health: int = 50

func _ready():
	add_to_group("pausable")
	
	# Configura para o inimigo ser pausável
	process_mode = Node.PROCESS_MODE_PAUSABLE

# Função para receber dano
func take_damage(damage_amount: int):
	health -= damage_amount
	print("Inimigo atingido! Vida restante: ", health)
	
	# Efeito visual de dano (opcional)
	create_damage_effect()
	
	# Verifica se o inimigo morreu
	if health <= 0:
		die()

func create_damage_effect():
	# Aqui você pode adicionar efeitos como:
	# - Piscar o sprite
	# - Tocar som de dano
	# - Aplicar knockback
	$Sprite2D.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color.WHITE

func die():
	print("Inimigo derrotado!")
	queue_free()  # Remove o inimigo da cena
