extends CharacterBody2D

@export var speed: float = 200.0
@export var jumpForce: float = -400.0
@export var gravity: float = 1000.0

@onready var animatedSprite = $AnimatedSprite2D

# Sistema de prioridade de animações
var animationPriority: int = 0
var currentAnimation: String = ""
var isAnimationLocked: bool = false

# Sistema de habilidades desbloqueadas (permanentes)
var unlockedAbilities: Dictionary = {
    "coke_dash": false,
    "beck_smoke": false, 
    "meth_jump": false,     # Mudamos LSD para Metanfetamina para o pulo
    "mushroom_vision": false  # Nova habilidade de visão com cogumelos
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
@export var dashCooldown: float = 1.0  # Tempo de recarga em segundos

var isDashing: bool = false
var dashDirection: Vector2 = Vector2.ZERO
var dashTimer: float = 0.0
var dashCooldownTimer: float = 0.0
var canDash: bool = true  # Controla se o dash pode ser usado

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
    
    if isDashing:
        velocity = dashDirection * dashSpeed
        dashTimer -= delta
        if dashTimer <= 0:
            isDashing = false
            dashCooldownTimer = dashCooldown
            canDash = false
        move_and_slide()
        return
        
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
            animatedSprite.play("Jump")
        elif unlockedAbilities["meth_jump"] and not hasDoubleJumped:
            velocity.y = jumpForce * 0.8
            hasDoubleJumped = true
    
    # Movimento horizontal
    var direction = Input.get_axis("moveLeft", "moveRight")
    velocity.x = direction * speed

    # Input de dash
    if unlockedAbilities["coke_dash"] and Input.is_action_just_pressed("sprint") and not isDashing:
        performDash()
    
    # Input de visão de cogumelo
    if unlockedAbilities["mushroom_vision"] and Input.is_action_just_pressed("vision") and visionCooldown <= 0:
        toggleMushroomVision()
    
    move_and_slide()
    updateAnimation(direction)

func unlockAbility(abilityType: String):
    if abilityType in unlockedAbilities:
        unlockedAbilities[abilityType] = true
        print("Habilidade desbloqueada: ", abilityType)
        
        # Ativar efeitos visuais de desbloqueio
        createUnlockEffect(abilityType)

func performDash():
    if unlockedAbilities["coke_dash"] and canDash and not isDashing:
        var inputDirection = Vector2(
            Input.get_axis("moveLeft", "moveRight"),
            0  # Dash apenas horizontal por padrão
        )
        
        if inputDirection != Vector2.ZERO:
            dashDirection = inputDirection.normalized()
        else:
            # Dash na direção que o personagem está virado
            dashDirection = Vector2.RIGHT if not animatedSprite.flip_h else Vector2.LEFT
        
        isDashing = true
        dashTimer = dashDuration
        
        # Toca a animação de dash
        playAnimationWithPriority("Dash", 5)
        
        # Cria efeito visual
        createDashEffect()
        
        print("Dash realizado! Recarga: ", dashCooldown, " segundos")


func toggleMushroomVision():
    mushroomVisionActive = not mushroomVisionActive
    
    if mushroomVisionActive:
        visionCooldown = visionDuration
        # Ativar efeitos visuais da visão
        enableMushroomVision()
        # Iniciar timer para desativar automaticamente
        get_tree().create_timer(visionDuration).timeout.connect(disableMushroomVision)
    else:
        disableMushroomVision()

func enableMushroomVision():
    # Aqui você implementaria a lógica para revelar elementos escondidos
    print("Visão de cogumelo ativada!")
    # Exemplo: mudar camadas de colisão, mostrar plataformas invisíveis, etc.

func disableMushroomVision():
    mushroomVisionActive = false
    visionCooldown = visionCooldownTime
    print("Visão de cogumelo desativada. Recarregando...")
    # Reverter mudanças feitas pela visão

func createDashEffect():
    # Implementar efeito visual do dash
    print("Efeito de dash criado")

func createSmokeEffect():
    if unlockedAbilities["beck_smoke"]:
        # Implementar efeito de fumaça que pode interagir com inimigos/ambiente
        print("Efeito de fumaça criado")

func createUnlockEffect(abilityType: String):
    # Efeito visual quando desbloqueia uma habilidade
    print("Efeito de desbloqueio para: ", abilityType)

func playAnimationWithPriority(animationName: String, priority: int = 0) -> bool:
    # Se já está tocando uma animação de maior prioridade, ignora
    if priority < animationPriority and isAnimationLocked:
        return false
    
    # Se a animação não existe, ignora
    if not animatedSprite.sprite_frames.has_animation(animationName):
        print("Animação não encontrada: ", animationName)
        return false
    
    # Se é a mesma animação atual, não precisa trocar
    if animationName == currentAnimation:
        return true
    
    # Troca para a nova animação
    currentAnimation = animationName
    animationPriority = priority
    animatedSprite.play(animationName)
    
    return true
func reset_animation_priority():
    animationPriority = 0
    isAnimationLocked = false
func updateAnimation(direction):
    # Não atualiza animação se estiver em animação de alta prioridade
    if animationPriority > 1:  # Prioridades > 1 bloqueiam animações normais
        return
    
    var animationToPlay = ""
    if not is_on_floor():
        animationToPlay = "Jump"
    elif direction != 0:
        animationToPlay = "Run"
    else:
        animationToPlay = "Idle"
    
    if animatedSprite.animation != animationToPlay:
        # Usa prioridade baixa (1) para animações normais
        playAnimationWithPriority(animationToPlay, 1)
    
    if direction > 0:
        animatedSprite.flip_h = false
    elif direction < 0:
        animatedSprite.flip_h = true