extends CharacterBody2D
##
## EnemyBasic.gd
## - Persigue al jugador
## - Recibe daño desde proyectiles
## - Daño de contacto (opcional con cooldown)
##

@export var speed: float = 90.0
@export var max_hp: int = 20
@export var contact_damage: int = 10
@export var knockback_resistance: float = 0.0  # 0..1

var hp: int

var player: Node2D
var can_hit := true  # para no pegar 100 veces por segundo

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")

	# Si tenés un Timer llamado HitCD:
	if has_node("HitCD"):
		var t := $HitCD as Timer
		t.timeout.connect(func(): can_hit = true)

func _physics_process(_dt: float) -> void:
	if player and is_instance_valid(player):
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()

func damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		_die()

func _die() -> void:
	# (Opcional) instanciar una gema de XP acá
	queue_free()

# --- CONTACTO: si el Enemy toca al Player ---
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and can_hit:
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
		can_hit = false  # espera el cooldown del Timer (si existe)

# ---- HURTBOX - RECIBE DAÑO ---------
func take_damage(dmg: int, knockback: float = 0.0, from_pos: Vector2 = Vector2.ZERO) -> void:
	hp -= dmg
		# Knockback simple (opcional)
	if from_pos != Vector2.ZERO and knockback > 0.0:
		var dir := (global_position - from_pos).normalized()
		velocity += dir * knockback * (1.0 - clamp(knockback_resistance, 0.0, 1.0))
	if hp <= 0:
		queue_free()

func _on_hurtbox_hurt(amount: int) -> void:
	take_damage(amount)
