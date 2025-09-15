extends CharacterBody2D

# Configurações do inimigo
@export var speed: float = 40.0
@export var damage: int = 10
@export var health: int = 30
@export var attackRange: float = 20.0
@export var patrolRange: float = 100.0

# Variáveis de estado
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var currentState: State = State.PATROL
var direction: int = 1
var target = null
var startPosition: Vector2

# Referências
@onready var animatedSprite = $AnimatedSprite2D
@onready var attackArea = $AttackArea
@onready var wallDetection = $WallDetection
@onready var edgeDetection = $EdgeDetection

func _ready():
    startPosition = global_position
    attackArea.body_entered.connect(_on_attack_area_body_entered)
    attackArea.body_exited.connect(_on_attack_area_body_exited)

func _physics_process(delta):
    if currentState == State.DEAD:
        return
    
    match currentState:
        State.IDLE:
            idle_state(delta)
        State.PATROL:
            patrol_state(delta)
        State.CHASE:
            chase_state(delta)
        State.ATTACK:
            attack_state(delta)
        State.HURT:
            hurt_state(delta)
    
    move_and_slide()

func idle_state(delta):
    velocity.x = 0
    animatedSprite.play("idle")
    
    # Transição para patrol após um tempo
    if randf() < 0.01:  # 1% de chance a cada frame
        currentState = State.PATROL
        direction = 1 if randf() > 0.5 else -1

func patrol_state(delta):
    animatedSprite.play("walk")
    velocity.x = direction * speed
    
    # Verifica se chegou ao limite do patrol
    if abs(global_position.x - startPosition.x) > patrolRange:
        direction *= -1
        startPosition = global_position
    
    # Verifica obstáculos
    if wallDetection.is_colliding() or not edgeDetection.is_colliding():
        direction *= -1
    
    # Procura por jogador
    var player = get_tree().get_first_node_in_group("player")
    if player and global_position.distance_to(player.global_position) < 150:
        target = player
        currentState = State.CHASE

func chase_state(delta):
    if not target:
        currentState = State.PATROL
        return
    
    animatedSprite.play("walk")
    
    # Move-se em direção ao jogador
    var to_target = target.global_position - global_position
    direction = 1 if to_target.x > 0 else -1
    velocity.x = direction * speed * 1.2  # Mais rápido ao perseguir
    
    # Verifica se está perto o suficiente para atacar
    if abs(to_target.x) < attackRange:
        currentState = State.ATTACK
    
    # Se o jogador ficou muito longe, volta a patrulhar
    if to_target.length() > 200:
        target = null
        currentState = State.PATROL

func attack_state(delta):
    velocity.x = 0
    animatedSprite.play("attack")
    
    # Espera a animação de ataque terminar
    await animatedSprite.animation_finished
    
    # Causa dano se o jogador ainda estiver na área
    if target and attackArea.has_overlapping_bodies():
        var health_component = target.get_node("HealthComponent")
        if health_component:
            health_component.take_damage(damage)
    
    # Volta a perseguir
    currentState = State.CHASE

func hurt_state(delta):
    velocity.x = 0
    animatedSprite.play("hurt")
    
    # Espera a animação de dano terminar
    await animatedSprite.animation_finished
    
    # Volta ao estado anterior
    currentState = State.CHASE if target else State.PATROL

func take_damage(amount: int):
    if currentState == State.DEAD:
        return
    
    health -= amount
    
    # Efeito visual de dano
    modulate = Color.RED
    await get_tree().create_timer(0.1).timeout
    modulate = Color.WHITE
    
    if health <= 0:
        die()
    else:
        currentState = State.HURT

func die():
    currentState = State.DEAD
    velocity.x = 0
    animatedSprite.play("death")
    
    # Desativa colisões
    $CollisionShape2D.set_deferred("disabled", true)
    attackArea.monitoring = false
    
    # Espera a animação de morte terminar
    await animatedSprite.animation_finished
    
    # Remove o inimigo
    queue_free()

func _on_attack_area_body_entered(body):
    if body.is_in_group("player"):
        target = body
        if currentState != State.ATTACK and currentState != State.HURT:
            currentState = State.ATTACK

func _on_attack_area_body_exited(body):
    if body == target:
        target = null
        currentState = State.PATROL