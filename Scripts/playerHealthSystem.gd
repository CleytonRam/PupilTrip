extends Node
class_name PlayerHealthComponent

# Configurações de saúde
@export var max_health: int = 100
@export var current_health: int = 100
@export var is_invincible: bool = false
@export var invincibility_time: float = 0.5

# Configurações do flash
@export var flash_duration: float = 0.3
@export var flash_color: Color = Color.RED
@export var flashMaterial: ShaderMaterial

var flash_intensity: float = 0.0
var isFlashing: bool = false

var player: CharacterBody2D
var sprite: AnimatedSprite2D
var originalMaterial: Material
var healthSystem: HealthSystem
var original_modulate: Color

func _ready():
	player = get_parent()
	sprite = player.get_node("AnimatedSprite2D")
	
	# Cria o HealthSystem como nó filho
	create_health_system()
	
	if sprite:
		originalMaterial = sprite.material
		original_modulate = sprite.modulate
		print("Sprite encontrado: ", sprite.name)
	else:
		print("ERRO: Sprite não encontrado!")
	
	print("Sistema de saúde inicializado: ", getHealth(), "/", getMaxHealth())

func create_health_system():
	# Remove qualquer HealthSystem existente
	for child in get_children():
		if child is HealthSystem:
			remove_child(child)
			child.queue_free()
	
	# Cria um novo HealthSystem como nó filho
	healthSystem = HealthSystem.new()
	healthSystem.name = "HealthSystem"
	add_child(healthSystem)
	
	# Configura as propriedades
	healthSystem.maxHealth = max_health
	healthSystem.currentHealth = current_health
	healthSystem.isInvincible = is_invincible
	healthSystem.invincibilityTime = invincibility_time
	
	# Conecta os sinais
	healthSystem.damageTaken.connect(onDamageTaken)
	healthSystem.healthDepleted.connect(onHealthDepleted)
	healthSystem.healthRestored.connect(onHealthRestored)
	
	print("HealthSystem criado como nó filho")

func onDamageTaken(amount: int):
	print("PlayerHealthComponent: Dano recebido: ", amount)
	
	# Apenas lida com os efeitos visuais, a animação será controlada pelo player.gd
	start_flash_effect()
	
	# Efeito de tela tremer
	# if get_tree().has_group("camera"):
	# 	get_tree().call_group("camera", "add_trauma", 0.3)

func onHealthDepleted():
	print("Player morreu!")
	
	# Toca animação de morte se existir
	if sprite and sprite.sprite_frames.has_animation("Death"):
		sprite.play("Death")
		await sprite.animation_finished
	
	# Desativa o jogador
	player.set_physics_process(false)

func onHealthRestored(amount: int):
	print("Health restored: ", amount, ". Vida: ", getHealth(), "/", getMaxHealth())
	
	# Efeitos visuais de cura (opcional)
	if sprite and sprite.sprite_frames.has_animation("Heal"):
		sprite.play("Heal")
		await sprite.animation_finished

func start_flash_effect():
	if isFlashing or not sprite:
		return
		
	isFlashing = true
	print("Iniciando efeito de flash...")
	
	# Método simples com modulação de cor
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	
	# Pisca para a cor do flash e volta
	tween.tween_property(sprite, "modulate", flash_color, 0.1)
	tween.tween_property(sprite, "modulate", original_modulate, 0.4)
	tween.tween_callback(end_flash_effect)
	
	print("Efeito de flash iniciado com sucesso!")

func end_flash_effect():
	if sprite:
		sprite.modulate = original_modulate
	isFlashing = false
	print("Efeito de flash finalizado")

# Método para obter o HealthSystem (para conexão de sinais)
func get_health_system() -> HealthSystem:
	return healthSystem

# Métodos para interface com o HealthSystem
func takeDamage(amount: int) -> bool:
	if healthSystem and is_instance_valid(healthSystem):
		return healthSystem.takeDamage(amount)
	else:
		print("ERRO: HealthSystem não é válido!")
		return false

func restoreHealth(amount: int) -> bool:
	if healthSystem and is_instance_valid(healthSystem):
		return healthSystem.restoreHealth(amount)
	else:
		print("ERRO: HealthSystem não é válido!")
		return false

func getHealth() -> int:
	if healthSystem and is_instance_valid(healthSystem):
		return healthSystem.currentHealth
	else:
		print("ERRO: HealthSystem não é válido!")
		return 0

func getMaxHealth() -> int:
	if healthSystem and is_instance_valid(healthSystem):
		return healthSystem.maxHealth
	else:
		print("ERRO: HealthSystem não é válido!")
		return 0