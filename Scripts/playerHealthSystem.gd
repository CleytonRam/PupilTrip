extends Node
class_name PlayerHealthComponent



@export var flashMaterial: ShaderMaterial
@export var damageAnimationName: String = "Damage"

# Configurações de saúde
@export var max_health: int = 100
@export var current_health: int = 100
@export var is_invincible: bool = false
@export var invincibility_time: float = 0.5

# Configurações do flash
@export var flash_duration: float = 0.3
@export var flash_color: Color = Color.RED

var flash_intensity: float = 0.0
var isFlashing: bool = false

var player: CharacterBody2D
var sprite: AnimatedSprite2D
var originalMaterial: Material
var healthSystem: HealthSystem  # Agora é uma variável interna

func _ready():
	player = get_parent()
	sprite = player.get_node("AnimatedSprite2D")
	
	# Cria o HealthSystem como nó filho
	create_health_system()
	
	if sprite:
		originalMaterial = sprite.material
	if flashMaterial:
		flashMaterial.set_shader_parameter("flash_color", flash_color)
	
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
	print("=== INICIANDO EFEITO DE DANO ===")
	print("Player tomou ", amount, " de dano. Vida: ", getHealth(), "/", getMaxHealth())
	
	# Toca animação de dano
	if sprite and sprite.sprite_frames.has_animation("Damage"):
		print("Tocando animação de dano")
		sprite.play("Damage")
	else:
		print("AVISO: Animação de dano não encontrada")
	
	# Efeito visual de flash
	if sprite and flashMaterial:
		print("Iniciando efeito de flash")
		start_flash_effect()
	else:
		print("AVISO: Sprite ou FlashMaterial não encontrado")
		print("Sprite: ", sprite)
		print("FlashMaterial: ", flashMaterial)
	
	# Efeito de tela tremer
	if get_tree().has_group("camera"):
		get_tree().call_group("camera", "add_trauma", 0.3)
		print("Chamando efeito de camera shake")
	else:
		print("AVISO: Grupo 'camera' não encontrado")
	
	# Aguarda um tempo antes de voltar às animações normais
	await get_tree().create_timer(0.5).timeout
	print("=== EFEITO DE DANO FINALIZADO ===")

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
	print("Iniciando flash effect...")
	if isFlashing:
		print("Flash já está ativo, ignorando")
		return
	if not sprite:
		print("ERRO: Sprite não encontrado")
		return
	if not flashMaterial:
		print("ERRO: FlashMaterial não atribuído")
		return
		
	print("Aplicando material de flash ao sprite")
	isFlashing = true
	sprite.material = flashMaterial
	
	var tween = create_tween()
	print("Criando tween para animação do flash")
	tween.parallel().tween_method(update_flash_intensity, 0.0, 1.0, 0.1)
	tween.tween_method(update_flash_intensity, 1.0, 0.0, 0.4)
	tween.tween_callback(end_flash_effect)

func update_flash_intensity(value: float):
	print("Atualizando intensidade do flash para: ", value)
	flash_intensity = value
	if flashMaterial:
		flashMaterial.set_shader_parameter("intensity", flash_intensity)
	else:
		print("ERRO: FlashMaterial é nulo durante a atualização")

func end_flash_effect():
	print("Finalizando efeito de flash")
	if sprite:
		sprite.material = null
	isFlashing = false

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
