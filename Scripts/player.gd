extends CharacterBody2D

@export var speed: float = 200.0
@export var jumpForce: float = -400.0
@export var gravity: float = 1000.0
@export var test_mode: bool = true

@onready var animatedSprite = $AnimatedSprite2D

# Estados do jogador
enum PlayerState { NORMAL, DASHING, USING_ABILITY, TAKING_DAMAGE }
var current_state: PlayerState = PlayerState.NORMAL

# Sistema de habilidades desbloqueadas (permanentes)
var unlockedAbilities: Dictionary = {
	"coke_dash": false,
	"beck_smoke": false, 
	"meth_jump": false,
	"mushroom_vision": false
}

var baseSpeed: float = 200.0
var baseJumpForce: float = -400.0

# Variáveis de controle de habilidades
var canDoubleJump: bool = false
var hasDoubleJumped: bool = false
var wasOnFloor: bool = false
var isJumping: bool = false
var double_jump_available: bool = false  # Nova variável para controle mais preciso

# Variáveis do dash
@export var dashSpeed: float = 600.0
@export var dashDuration: float = 0.2
@export var dashCooldown: float = 1.0

var isDashing: bool = false
var dashDirection: Vector2 = Vector2.ZERO
var dashTimer: float = 0.0
var dashCooldownTimer: float = 0.0
var canDash: bool = true

# Variáveis da visão de cogumelo
var mushroomVisionActive: bool = false
var visionCooldown: float = 0.0
var visionDuration: float = 5.0
var visionCooldownTime: float = 10.0

# Nova variável para controlar animação de dano
var is_taking_damage: bool = false
var damage_animation_finished: bool = true

func _ready():
	animatedSprite.play("Idle")
	baseSpeed = speed
	baseJumpForce = jumpForce
	add_to_group("player")
	
	# Garante que o PlayerHealthComponent existe
	setup_health_component()
	
	print("Vida inicial: ", get_health(), "/", get_max_health())

func setup_health_component():
	# Verifica se o PlayerHealthComponent já existe
	if not has_node("PlayerHealthComponent"):
		print("Criando PlayerHealthComponent automaticamente...")
		
		# Cria um novo nó PlayerHealthComponent
		var health_component = Node.new()
		health_component.name = "PlayerHealthComponent"
		health_component.set_script(load("res://Scripts/playerHealthSystem.gd"))
		add_child(health_component)
		
		# Configura as propriedades exportadas
		health_component.max_health = 100
		health_component.current_health = 100
		
		# Conecta o sinal de dano
		if health_component.has_method("get_health_system"):
			var health_system = health_component.get_health_system()
			if health_system and health_system.has_signal("damageTaken"):
				health_system.damageTaken.connect(_on_player_damage_taken)
		
		print("PlayerHealthComponent criado com sucesso!")
	else:
		print("PlayerHealthComponent encontrado!")
		# Conecta o sinal de dano se já existir
		var health_component = $PlayerHealthComponent
		if health_component.has_method("get_health_system"):
			var health_system = health_component.get_health_system()
			if health_system and health_system.has_signal("damageTaken"):
				health_system.damageTaken.connect(_on_player_damage_taken)

func _physics_process(delta):
	# Atualizar cooldowns
	if visionCooldown > 0:
		visionCooldown -= delta
	
	if dashCooldownTimer > 0:
		dashCooldownTimer -= delta
	else:
		canDash = true  
	 # Verificar se acabou de sair do chão (para habilitar pulo duplo)
	if wasOnFloor and not is_on_floor():
		double_jump_available = unlockedAbilities["meth_jump"]
	
	wasOnFloor = is_on_floor()
	# Máquina de estados principal
	match current_state:
		PlayerState.DASHING:
			handle_dash_state(delta)
		PlayerState.TAKING_DAMAGE:
			handle_damage_state(delta)
		PlayerState.USING_ABILITY:
			# Estado para habilidades que requerem controle especial
			pass
		_: # NORMAL
			handle_normal_state(delta)

func handle_normal_state(delta):
	# Física normal
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		hasDoubleJumped = false
		isJumping = false
		double_jump_available = unlockedAbilities["meth_jump"]  # Reset no chão
	
	# Input de pulo - SISTEMA ATUALIZADO
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# Pulo normal
			velocity.y = jumpForce
			isJumping = true
			double_jump_available = unlockedAbilities["meth_jump"]
			print("Pulo normal executado")
		elif double_jump_available and not hasDoubleJumped && isJumping:
			# Pulo duplo
			perform_double_jump()
	
	# Movimento horizontal
	var direction = Input.get_axis("moveLeft", "moveRight")
	velocity.x = direction * speed

	# Input de dash
	if unlockedAbilities["coke_dash"] and Input.is_action_just_pressed("sprint") and not isDashing and canDash:
		current_state = PlayerState.DASHING
		performDash()
		return
	
	# Input de visão de cogumelo
	if unlockedAbilities["mushroom_vision"] and Input.is_action_just_pressed("vision") and visionCooldown <= 0:
		toggleMushroomVision()
	
	if test_mode and Input.is_action_just_pressed("test_damage"):
		take_damage(10)
		print("Dano de teste aplicado! Vida: ", get_health(), "/", get_max_health())
	
	move_and_slide()
	
	# Só atualiza animação se não estiver em animação de dano
	if damage_animation_finished and current_state == PlayerState.NORMAL:
		update_animation(direction)


func handle_damage_state(delta):
	# Durante o dano, o player não pode se mover
	velocity.x = 0
	velocity.y += gravity * delta
	
	move_and_slide()
	
	# Não atualiza animação normal durante o dano

func handle_dash_state(delta):
	velocity = dashDirection * dashSpeed
	dashTimer -= delta
	
	if dashTimer <= 0:
		current_state = PlayerState.NORMAL
		isDashing = false
		dashCooldownTimer = dashCooldown
		canDash = false
	
	move_and_slide()

func update_animation(direction):
	"""Atualiza as animações considerando o pulo duplo"""
	var animation = ""
	
	# Prioridade para animação de pulo duplo
	if hasDoubleJumped and not is_on_floor():
		if animatedSprite.sprite_frames.has_animation("DoubleJump"):
			animation = "DoubleJump"
		else:
			animation = "Jump"
	elif not is_on_floor():
		animation = "Jump"
	elif direction != 0:
		animation = "Run"
	else:
		animation = "Idle"
	
	# Só muda se for diferente da atual
	if animatedSprite.animation != animation:
		animatedSprite.play(animation)
	
	# Virar o sprite conforme a direção
	if direction > 0:
		animatedSprite.flip_h = false
	elif direction < 0:
		animatedSprite.flip_h = true

# Nova função para lidar com o dano recebido
func _on_player_damage_taken(amount: int):
	print("Recebendo sinal de dano: ", amount)
	
	# Marca que a animação de dano está acontecendo
	damage_animation_finished = false
	
	# Muda para estado de dano
	current_state = PlayerState.TAKING_DAMAGE
	is_taking_damage = true
	
	# Toca a animação de dano
	if animatedSprite.sprite_frames.has_animation("Damage") && is_taking_damage:
		animatedSprite.play("Damage")
		print("Tocando animação de dano")
		
		# Conecta o sinal para saber quando a animação termina
		if not animatedSprite.animation_finished.is_connected(_on_damage_animation_finished):
			animatedSprite.animation_finished.connect(_on_damage_animation_finished)

	await get_tree().create_timer(0.5).timeout
	_on_damage_animation_finished()

func _on_damage_animation_finished():
	print("Animação de dano terminou")
	
	# Desconecta o sinal para evitar múltiplas chamadas
	if animatedSprite.animation_finished.is_connected(_on_damage_animation_finished):
		animatedSprite.animation_finished.disconnect(_on_damage_animation_finished)
	
	# Volta ao estado normal
	current_state = PlayerState.NORMAL
	is_taking_damage = false
	damage_animation_finished = true
	
	print("Voltando ao estado normal após dano")

func unlockAbility(abilityType: String):
	if abilityType in unlockedAbilities:
		unlockedAbilities[abilityType] = true
		print("Habilidade desbloqueada: ", abilityType)
		
		# Feedback específico para meth_jump
		if abilityType == "meth_jump":
			print("Pulo duplo desbloqueado! Pressione JUMP no ar para usar.")
		
		createUnlockEffect(abilityType)

func performDash():
	if unlockedAbilities["coke_dash"] and canDash:
		var inputDirection = Vector2(
			Input.get_axis("moveLeft", "moveRight"),
			0
		)
		
		if inputDirection != Vector2.ZERO:
			dashDirection = inputDirection.normalized()
		else:
			dashDirection = Vector2.RIGHT if not animatedSprite.flip_h else Vector2.LEFT
		
		isDashing = true
		dashTimer = dashDuration
		
		# Toca a animação de dash
		animatedSprite.play("Dash")
		createDashEffect()
		
		print("Dash realizado! Recarga: ", dashCooldown, " segundos")
func perform_double_jump():
	"""Executa o pulo duplo com todos os efeitos"""
	velocity.y = jumpForce * 1.2  
	hasDoubleJumped = true
	double_jump_available = false
	isJumping = true
	
	# Tocar animação do pulo duplo
	if animatedSprite.sprite_frames.has_animation("DoubleJump"):
		animatedSprite.play("DoubleJump")
		print("Animação de pulo duplo executada")
	else:
		print("AVISO: Animação DoubleJump não encontrada!")
		animatedSprite.play("Jump")  # Fallback para animação de pulo normal
	
	# Efeito visual do pulo duplo
	create_double_jump_effect()
	print("Pulo duplo executado! Velocidade: ", velocity.y)

func toggleMushroomVision():
	mushroomVisionActive = not mushroomVisionActive
	
	if mushroomVisionActive:
		visionCooldown = visionDuration
		enableMushroomVision()
		get_tree().create_timer(visionDuration).timeout.connect(disableMushroomVision)
	else:
		disableMushroomVision()

func enableMushroomVision():
	print("Visão de cogumelo ativada!")

func disableMushroomVision():
	mushroomVisionActive = false
	visionCooldown = visionCooldownTime
	print("Visão de cogumelo desativada. Recarregando...")

func createDashEffect():
	print("Efeito de dash criado")

func create_double_jump_effect():
	"""Cria efeitos visuais para o pulo duplo"""
	# Efeito de partículas (pode ser implementado depois)
	print("Efeito de pulo duplo criado")
	
	# Pequeno efeito de escala no sprite
	var tween = create_tween()
	tween.tween_property(animatedSprite, "scale", Vector2(1.1, 0.9), 0.1)
	tween.tween_property(animatedSprite, "scale", Vector2(1.0, 1.0), 0.1)

func createSmokeEffect():
	if unlockedAbilities["beck_smoke"]:
		print("Efeito de fumaça criado")

func createUnlockEffect(abilityType: String):
	print("Efeito de desbloqueio para: ", abilityType)

func take_damage(amount: int) -> bool:
	if has_node("PlayerHealthComponent"):
		return $PlayerHealthComponent.takeDamage(amount)
	else:
		print("ERRO: PlayerHealthComponent não encontrado ao tentar causar dano!")
		return false

func heal(amount: int) -> bool:
	if has_node("PlayerHealthComponent"):
		return $PlayerHealthComponent.restoreHealth(amount)
	return false

func get_health() -> int:
	if has_node("PlayerHealthComponent"):
		return $PlayerHealthComponent.getHealth()
	return 0

func get_max_health() -> int:
	if has_node("PlayerHealthComponent"):
		return $PlayerHealthComponent.getMaxHealth()
	return 0
