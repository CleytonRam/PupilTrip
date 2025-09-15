extends Node
class_name PlayerHealthComponent

@export var healthSystem: HealthSystem
@export var flashMaterial: ShaderMaterial
@export var damageAnimationName: String = "Damage"  # Nome da sua animação de dano

var sprite: AnimatedSprite2D
var originalMaterial: Material
var isFlashing: bool = false

func _ready():
    # Encontra o AnimatedSprite2D do player automaticamente
    sprite = get_parent().get_node("AnimatedSprite2D")
    if sprite:
        originalMaterial = sprite.material
    
    # Conecta os sinais
    if healthSystem:
        healthSystem.damage_taken.connect(onDamageTaken)
        healthSystem.health_depleted.connect(onHealthDepleted)
        healthSystem.health_restored.connect(onHealthRestored)

func onDamageTaken(amount: int):
    # Toca animação de dano com alta prioridade (10)
    get_parent().play_animation_with_priority("Damage", 10)
    
    # Espera a animação terminar
    await get_tree().create_timer(0.5).timeout  # Ajuste o tempo conforme sua animação
    
    # Reseta a prioridade depois da animação de dano
    get_parent().animation_priority = 0
    get_parent().is_animation_locked = false
    
    # Resto do código de efeitos visuais...
    if sprite and flashMaterial:
        start_flash_effect()
    
    get_tree().call_group("camera", "add_trauma", 0.3)
    
    # Efeito visual de flash
    if sprite and flashMaterial:
        start_flash_effect()
    
    # Efeitos de tela tremer ou outros feedbacks
    get_tree().call_group("camera", "add_trauma", 0.3)

func onHealthDepleted():
    print("Player morreu!")
    # Toca animação de morte se existir
    if sprite and sprite.sprite_frames.has_animation("Death"):
        sprite.play("Death")
        await sprite.animation_finished
    
    # Aqui você pode chamar a lógica de morte do player
    get_parent().queue_free()

func onHealthRestored(amount: int):
    print("Health restored: ", amount)
    # Efeitos visuais de cura (opcional)
    if sprite and sprite.sprite_frames.has_animation("Heal"):
        sprite.play("Heal")
        await sprite.animation_finished
        # Volta para animação idle depois de curar
        if sprite:
            sprite.play("Idle")

func start_flash_effect():
    if isFlashing:
        return
        
    isFlashing = true
    sprite.material = flashMaterial
    
    # Cria um timer para voltar ao material original
    var timer = Timer.new()
    timer.wait_time = 0.1
    timer.one_shot = true
    timer.timeout.connect(endFlashEffect)
    add_child(timer)
    timer.start()

func endFlashEffect():
    if sprite:
        sprite.material = originalMaterial
    isFlashing = false

# Métodos para interface com o HealthSystem
func takeDamage(amount: int) -> bool:
    if healthSystem:
        return healthSystem.takeDamage(amount)
    return false

func restoreHealth(amount: int) -> bool:
    if healthSystem:
        return healthSystem.restoreHealth(amount)
    return false

func getHealth() -> int:
    if healthSystem:
        return healthSystem.currentHealth
    return 0

func getMaxHealth() -> int:
    if healthSystem:
        return healthSystem.maxHealth
    return 0