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
