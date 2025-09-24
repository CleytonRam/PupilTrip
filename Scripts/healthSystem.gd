
extends Node
class_name HealthSystem

signal healthChanged(currentHealth, maxHealth)
signal healthDepleted()
signal damageTaken(amount)
signal healthRestored(amount)

@export var maxHealth: int = 100
@export var currentHealth: int = 100
@export var isInvincible: bool = false
@export var invincibilityTime: float = 0.5

var invincibilityTimer: float = 0.0

func _ready():
    currentHealth = maxHealth

func _process(delta):
    if invincibilityTimer > 0:
        invincibilityTimer -= delta

func takeDamage(amount: int) -> bool:
    if isInvincible or invincibilityTimer > 0:
        return false
    currentHealth -= amount
    currentHealth = max(0, currentHealth)

    damageTaken.emit(amount)
    healthChanged.emit(currentHealth, maxHealth)

    if currentHealth <= 0:
        healthDepleted.emit()
        return true
    
    invincibilityTimer = invincibilityTime
    return false

func restoreHealth(amount: int) -> bool:
    if currentHealth >= maxHealth:
        return false
        
    currentHealth += amount
    currentHealth = min(currentHealth, maxHealth)
    
    healthRestored.emit(amount)
    healthChanged.emit(currentHealth, maxHealth)
    return true