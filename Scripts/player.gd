extends CharacterBody2D

@export var speed: float = 200.0
@export var jumpForce: float = -400.0
@export var gravity: float = 1000.0

@onready var animatedSprite = $AnimatedSprite2D

# Estados do jogador
enum PlayerState { NORMAL, DASHING, USING_ABILITY }
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

func _ready():
    animatedSprite.play("Idle")
    baseSpeed = speed
    baseJumpForce = jumpForce
    add_to_group("player")

func _physics_process(delta):
    # Atualizar cooldowns
    if visionCooldown > 0:
        visionCooldown -= delta
    
    if dashCooldownTimer > 0:
        dashCooldownTimer -= delta
    else:
        canDash = true  
    
    # Máquina de estados principal
    match current_state:
        PlayerState.DASHING:
            handle_dash_state(delta)
        PlayerState.USING_ABILITY:
            # Estado para habilidades que requerem controle especial
            pass
        _: # NORMAL
            handle_normal_state(delta)

func handle_normal_state(delta):
    # Física normal
    wasOnFloor = is_on_floor()
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        hasDoubleJumped = false
        isJumping = false
    
    # Input de pulo
    if Input.is_action_just_pressed("jump"):
        if is_on_floor():
            velocity.y = jumpForce
            isJumping = true
        elif unlockedAbilities["meth_jump"] and not hasDoubleJumped:
            velocity.y = jumpForce * 0.8
            hasDoubleJumped = true
    
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
    
    move_and_slide()
    update_animation(direction)

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
    # Se estiver dashando, não muda a animação
    if current_state == PlayerState.DASHING:
        return
    
    var animation = ""
    
    if not is_on_floor():
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

func unlockAbility(abilityType: String):
    if abilityType in unlockedAbilities:
        unlockedAbilities[abilityType] = true
        print("Habilidade desbloqueada: ", abilityType)
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

func createSmokeEffect():
    if unlockedAbilities["beck_smoke"]:
        print("Efeito de fumaça criado")

func createUnlockEffect(abilityType: String):
    print("Efeito de desbloqueio para: ", abilityType)

func take_damage(amount: int) -> bool:
    if has_node("PlayerHealthComponent"):
        return $PlayerHealthComponent.takeDamage(amount)
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