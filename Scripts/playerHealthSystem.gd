extends Node
class_name PlayerHealthComponent

@export var healthSystem: HealthSystem
@export var flashMaterial: ShaderMaterial
@export var damageAnimationName: String = "Damage"

var player: CharacterBody2D
var sprite: AnimatedSprite2D
var originalMaterial: Material
var isFlashing: bool = false

func _ready():
    player = get_parent()
    sprite = player.get_node("AnimatedSprite2D")
    
    if sprite:
        originalMaterial = sprite.material
    
    if healthSystem:
        healthSystem.damage_taken.connect(onDamageTaken)
        healthSystem.health_depleted.connect(onHealthDepleted)
        healthSystem.health_restored.connect(onHealthRestored)

func onDamageTaken(amount: int):
    # Toca animação de dano
    if sprite and sprite.sprite_frames.has_animation("Damage"):
        sprite.play("Damage")
    
    # Efeito visual de flash
    if sprite and flashMaterial:
        start_flash_effect()
    
    # Efeito de tela tremer
    get_tree().call_group("camera", "add_trauma", 0.3)
    
    # Aguarda um tempo antes de voltar às animações normais
    await get_tree().create_timer(0.5).timeout

func onHealthDepleted():
    print("Player morreu!")
    
    # Toca animação de morte se existir
    if sprite and sprite.sprite_frames.has_animation("Death"):
        sprite.play("Death")
        await sprite.animation_finished
    
    # Desativa o jogador
    player.set_physics_process(false)
    
    # Aqui você pode adicionar lógica adicional de game over
    # Por exemplo: get_tree().reload_current_scene() após um delay

func onHealthRestored(amount: int):
    print("Health restored: ", amount)
    
    # Efeitos visuais de cura (opcional)
    if sprite and sprite.sprite_frames.has_animation("Heal"):
        sprite.play("Heal")
        await sprite.animation_finished

func start_flash_effect():
    if isFlashing:
        return
        
    isFlashing = true
    sprite.material = flashMaterial
    
    await get_tree().create_timer(0.1).timeout
    
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