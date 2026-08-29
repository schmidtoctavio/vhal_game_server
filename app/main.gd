extends Node


# =========================================================
# REFERENCIAS
# =========================================================

@onready var game_server: GameServer = (
	$GameServer
)

@onready var backend_ticket_validator: BackendTicketValidator = (
	$BackendTicketValidator
)

@onready var backend_vault_repository: BackendVaultRepository = (
	$BackendVaultRepository
)

@onready var backend_character_inventory_repository: BackendCharacterInventoryRepository = (
	$BackendCharacterInventoryRepository
)

@onready var backend_character_equipment_repository: BackendCharacterEquipmentRepository = (
	$BackendCharacterEquipmentRepository
)

@onready var backend_item_transfer_repository: BackendItemTransferRepository = (
	$BackendItemTransferRepository
)

@onready var character_item_state_coordinator: CharacterItemStateCoordinator = (
	$CharacterItemStateCoordinator
)

@onready var equipment_coordinator: EquipmentCoordinator = (
	$EquipmentCoordinator
)

@onready var inventory_coordinator: InventoryCoordinator = (
	$InventoryCoordinator
)

@onready var vault_coordinator: VaultCoordinator = (
	$VaultCoordinator
)

@onready var item_container_transfer_coordinator: ItemContainerTransferCoordinator = (
	$ItemContainerTransferCoordinator
)

@onready var npc_service_coordinator: NpcServiceCoordinator = (
	$NpcServiceCoordinator
)

@onready var movement_coordinator: MovementCoordinator = (
	$MovementCoordinator
)

@onready var skill_cast_coordinator: SkillCastCoordinator = (
	$SkillCastCoordinator
)

@onready var basic_attack_coordinator: BasicAttackCoordinator = (
	$BasicAttackCoordinator
)

@onready var world_presence_coordinator: WorldPresenceCoordinator = (
	$WorldPresenceCoordinator
)

@onready var authentication_coordinator: AuthenticationCoordinator = (
	$AuthenticationCoordinator
)

@onready var world_session_registry: WorldSessionRegistry = (
	$WorldSessionRegistry
)

@onready var world_navigation_registry: WorldNavigationRegistry = (
	$WorldNavigationRegistry
)

@onready var world_movement_system: WorldMovementSystem = (
	$WorldMovementSystem
)

@onready var world_npc_registry: WorldNpcRegistry = (
	$WorldNpcRegistry
)

@onready var world_mob_registry: WorldMobRegistry = (
	$WorldMobRegistry
)

@onready var world_drop_coordinator: WorldDropCoordinator = (
	$WorldDropCoordinator
)


@onready var world_drop_registry: WorldDropRegistry = (
	$WorldDropRegistry
)

@onready var world_drop_pickup_coordinator: WorldDropPickupCoordinator = (
	$WorldDropPickupCoordinator
)

@onready var backend_character_progression_repository: BackendCharacterProgressionRepository = (
	$BackendCharacterProgressionRepository
)


@onready var character_progression_coordinator: CharacterProgressionCoordinator = (
	$CharacterProgressionCoordinator
)

@onready var backend_character_runtime_state_repository: BackendCharacterRuntimeStateRepository = (
	$BackendCharacterRuntimeStateRepository
)

@onready var character_runtime_state_coordinator: CharacterRuntimeStateCoordinator = (
	$CharacterRuntimeStateCoordinator
)

@onready var backend_character_skill_learning_repository: BackendCharacterSkillLearningRepository = (
	$BackendCharacterSkillLearningRepository
)

@onready var skill_learning_coordinator: SkillLearningCoordinator = (
	$SkillLearningCoordinator
)

@onready var primary_stat_allocation_coordinator: PrimaryStatAllocationCoordinator = (
	$PrimaryStatAllocationCoordinator
)

@onready var backend_character_stats_repository: BackendCharacterStatsRepository = (
	$BackendCharacterStatsRepository
)

# =========================================================
# START
# =========================================================

func _ready() -> void:
	if game_server == null:
		push_error(
			"ServerMain | No existe GameServer."
		)

		get_tree().quit(
			1
		)

		return


	if backend_ticket_validator == null:
		push_error(
			"ServerMain | No existe BackendTicketValidator."
		)

		get_tree().quit(
			2
		)

		return


	if not backend_ticket_validator.is_configured():
		push_error(
			"ServerMain | BackendTicketValidator no configurado."
		)

		get_tree().quit(
			3
		)

		return


	if backend_vault_repository == null:
		push_error(
			"ServerMain | No existe BackendVaultRepository."
		)


		get_tree().quit(
			8
		)


		return


	if not backend_vault_repository.is_configured():
		push_error(
			"ServerMain | BackendVaultRepository no configurado."
		)


		get_tree().quit(
			8
		)


		return


	if backend_character_inventory_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendCharacterInventoryRepository."
			)
		)


		get_tree().quit(
			9
		)


		return


	if not backend_character_inventory_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendCharacterInventoryRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			9
		)


		return

	if backend_character_progression_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendCharacterProgressionRepository."
			)
		)


		get_tree().quit(
			32
		)


		return


	if not backend_character_progression_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendCharacterProgressionRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			32
		)


		return

	if backend_character_stats_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendCharacterStatsRepository."
			)
		)


		get_tree().quit(
			41
		)


		return


	if not backend_character_stats_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendCharacterStatsRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			41
		)


		return

	if backend_character_runtime_state_repository == null:
		push_error(
			"ServerMain | No existe BackendCharacterRuntimeStateRepository."
		)

		get_tree().quit(
			34
		)

		return


	if not backend_character_runtime_state_repository.is_configured():
		push_error(
			"ServerMain | BackendCharacterRuntimeStateRepository no configurado."
		)

		get_tree().quit(
			34
		)

		return

	if backend_character_skill_learning_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendCharacterSkillLearningRepository."
			)
		)


		get_tree().quit(
			37
		)


		return


	if not backend_character_skill_learning_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendCharacterSkillLearningRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			37
		)


		return

	if skill_learning_coordinator == null:
		push_error(
			"ServerMain | No existe SkillLearningCoordinator."
		)


		get_tree().quit(
			38
		)


		return


	if not skill_learning_coordinator.setup(
		game_server,
		world_session_registry,
		npc_service_coordinator,
		backend_character_skill_learning_repository,
		character_item_state_coordinator
	):
		push_error(
			"ServerMain | No se pudo inicializar SkillLearningCoordinator."
		)


		get_tree().quit(
			38
		)


		return


	if backend_character_equipment_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendCharacterEquipmentRepository."
			)
		)

		get_tree().quit(
			11
		)


		return


	if not backend_character_equipment_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendCharacterEquipmentRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			11
		)


		return


	var equipment_contract_error := (
		ServerEquipmentRules.validate_contract()
	)


	if not equipment_contract_error.is_empty():
		push_error(
			(
				"ServerMain | Equipment Domain Contract inválido: "
				+
				equipment_contract_error
			)
		)


		get_tree().quit(
			12
		)


		return


	var equipment_snapshot_contract_error := (
		ServerEquipmentSnapshotValidator.validate_contract()
	)


	if not equipment_snapshot_contract_error.is_empty():
		push_error(
			(
				"ServerMain | Equipment Snapshot Contract inválido: "
				+
				equipment_snapshot_contract_error
			)
		)


		get_tree().quit(
			13
		)


		return


	var equipment_transfer_contract_error := (
		ServerEquipmentTransferValidator.validate_contract()
	)


	if not equipment_transfer_contract_error.is_empty():
		push_error(
			(
				"ServerMain | Equipment Transfer Contract inválido: "
				+
				equipment_transfer_contract_error
			)
		)


		get_tree().quit(
			14
		)


		return

	var class_stats_catalog_contract_error := (
		ServerClassStatsCatalog.validate_contract()
	)


	if not class_stats_catalog_contract_error.is_empty():
		push_error(
			(
				"ServerMain | "
				+
				"Class Stats Catalog Contract inválido: "
				+
				class_stats_catalog_contract_error
			)
		)


		get_tree().quit(
			39
		)


		return

	var skill_catalog_contract_error := (
		ServerSkillCatalog.validate_contract()
	)


	if not skill_catalog_contract_error.is_empty():
		push_error(
			(
				"ServerMain | Skill Catalog Contract inválido: "
				+
				skill_catalog_contract_error
			)
		)


		get_tree().quit(
			24
		)


		return

	var skill_learning_catalog_contract_error := (
		ServerSkillLearningCatalog.validate_contract()
	)


	if not skill_learning_catalog_contract_error.is_empty():
		push_error(
			(
				"ServerMain | "
				+
				"Skill Learning Catalog Contract inválido: "
				+
				skill_learning_catalog_contract_error
			)
		)


		get_tree().quit(
			36
		)


		return

	var mob_drop_catalog_contract_error := (
		ServerMobDropCatalog.validate_contract()
	)


	if not mob_drop_catalog_contract_error.is_empty():
		push_error(
			(
				"ServerMain | Mob Drop Catalog inválido: "
				+
				mob_drop_catalog_contract_error
			)
		)


		get_tree().quit(
			28
		)


		return


	print(
		"ServerMain | Mob Drop Catalog Contract validado."
	)

	print(
		"ServerMain | Class Stats Catalog Contract validado."
	)

	print(
		"ServerMain | Skill Catalog Contract validado."
	)

	print(
		"ServerMain | Skill Learning Catalog Contract validado."
	)

	print(
		"ServerMain | Equipment Domain Contract validado."
	)


	print(
		"ServerMain | Equipment Snapshot Contract validado."
	)


	print(
		"ServerMain | Equipment Transfer Contract validado."
	)


	if backend_item_transfer_repository == null:
		push_error(
			(
				"ServerMain | No existe "
				+
				"BackendItemTransferRepository."
			)
		)


		get_tree().quit(
			10
		)


		return


	if not backend_item_transfer_repository.is_configured():
		push_error(
			(
				"ServerMain | "
				+
				"BackendItemTransferRepository "
				+
				"no configurado."
			)
		)


		get_tree().quit(
			10
		)


		return


	if world_session_registry == null:
		push_error(
			"ServerMain | No existe WorldSessionRegistry."
		)

		get_tree().quit(
			4
		)

		return

	if character_runtime_state_coordinator == null:
		push_error(
			"ServerMain | No existe CharacterRuntimeStateCoordinator."
		)

		get_tree().quit(
			35
		)

		return


	if not character_runtime_state_coordinator.setup(
		world_session_registry,
		backend_character_runtime_state_repository
	):
		push_error(
			"ServerMain | No se pudo inicializar CharacterRuntimeStateCoordinator."
		)

		get_tree().quit(
			35
		)

		return

	if skill_cast_coordinator == null:
		push_error(
			"ServerMain | No existe SkillCastCoordinator."
		)


		get_tree().quit(
			25
		)


		return


	if not skill_cast_coordinator.setup(
		game_server,
		world_session_registry,
		world_mob_registry
	):
		push_error(
			"ServerMain | No se pudo inicializar SkillCastCoordinator."
		)


		get_tree().quit(
			25
		)


		return

	if primary_stat_allocation_coordinator == null:
		push_error(
			"ServerMain | No existe PrimaryStatAllocationCoordinator."
		)


		get_tree().quit(
			40
		)


		return


	if not primary_stat_allocation_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_stats_repository
	):
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"PrimaryStatAllocationCoordinator."
			)
		)


		get_tree().quit(
			40
		)


		return

	if basic_attack_coordinator == null:
		push_error(
			"ServerMain | No existe BasicAttackCoordinator."
		)


		get_tree().quit(
			27
		)


		return


	if not basic_attack_coordinator.setup(
		game_server,
		world_session_registry,
		world_mob_registry
	):
		push_error(
			"ServerMain | No se pudo inicializar BasicAttackCoordinator."
		)


		get_tree().quit(
			27
		)


		return


	if character_item_state_coordinator == null:
		push_error(
			"ServerMain | No existe CharacterItemStateCoordinator."
		)


		get_tree().quit(
			15
		)


		return


	if not character_item_state_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_inventory_repository,
		backend_character_equipment_repository
	):
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"CharacterItemStateCoordinator."
			)
		)


		get_tree().quit(
			15
		)


		return


	if equipment_coordinator == null:
		push_error(
			"ServerMain | No existe EquipmentCoordinator."
		)


		get_tree().quit(
			16
		)


		return


	if not equipment_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_equipment_repository,
		character_item_state_coordinator
	):
		push_error(
			"ServerMain | No se pudo inicializar EquipmentCoordinator."
		)


		get_tree().quit(
			16
		)


		return


	if inventory_coordinator == null:
		push_error(
			"ServerMain | No existe InventoryCoordinator."
		)


		get_tree().quit(
			17
		)


		return


	if not inventory_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_inventory_repository
	):
		push_error(
			"ServerMain | No se pudo inicializar InventoryCoordinator."
		)


		get_tree().quit(
			17
		)


		return


	if vault_coordinator == null:
		push_error(
			"ServerMain | No existe VaultCoordinator."
		)


		get_tree().quit(
			18
		)


		return


	if not vault_coordinator.setup(
		game_server,
		world_session_registry,
		backend_vault_repository
	):
		push_error(
			"ServerMain | No se pudo inicializar VaultCoordinator."
		)


		get_tree().quit(
			18
		)


		return


	if world_navigation_registry == null:
		push_error(
			"ServerMain | No existe WorldNavigationRegistry."
		)

		get_tree().quit(
			5
		)

		return


	if item_container_transfer_coordinator == null:
		push_error(
			"ServerMain | No existe ItemContainerTransferCoordinator."
		)


		get_tree().quit(
			19
		)


		return


	if not item_container_transfer_coordinator.setup(
		game_server,
		world_session_registry,
		backend_character_inventory_repository,
		backend_item_transfer_repository,
		vault_coordinator
	):
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"ItemContainerTransferCoordinator."
			)
		)


		get_tree().quit(
			19
		)


		return


	var navigation_result: Error = (
		await world_navigation_registry.initialize()
	)


	if navigation_result != OK:
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"la navegación. Error: %d"
			)
			%
			navigation_result
		)

		get_tree().quit(
			5
		)

		return


	if world_movement_system == null:
		push_error(
			"ServerMain | No existe WorldMovementSystem."
		)

		get_tree().quit(
			6
		)

		return


	if not world_movement_system.setup(
		world_session_registry
	):
		push_error(
			"ServerMain | No se pudo inicializar WorldMovementSystem."
		)

		get_tree().quit(
			6
		)

		return


	if world_npc_registry == null:
		push_error(
			"ServerMain | No existe WorldNpcRegistry."
		)

		get_tree().quit(
			7
		)

		return


	var npc_registry_result := (
		world_npc_registry.initialize()
	)


	if npc_registry_result != OK:
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"WorldNpcRegistry. Error: %d"
			)
			%
			npc_registry_result
		)

		get_tree().quit(
			7
		)

		return

	# =====================================================
	# MOBS
	# =====================================================

	if world_mob_registry == null:
		push_error(
			"ServerMain | No existe WorldMobRegistry."
		)


		get_tree().quit(
			26
		)


		return


	var mob_registry_result := (
		world_mob_registry.initialize()
	)


	if mob_registry_result != OK:
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"WorldMobRegistry. Error: %d"
			)
			%
			mob_registry_result
		)


		get_tree().quit(
			26
		)


		return

	# =====================================================
	# CHARACTER PROGRESSION
	# =====================================================

	if character_progression_coordinator == null:
		push_error(
			"ServerMain | No existe CharacterProgressionCoordinator."
		)


		get_tree().quit(
			33
		)


		return


	if not character_progression_coordinator.setup(
		game_server,
		world_session_registry,
		world_mob_registry,
		backend_character_progression_repository
	):
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"CharacterProgressionCoordinator."
			)
		)


		get_tree().quit(
			33
		)


		return

	# =====================================================
	# WORLD DROPS
	# =====================================================

	if world_drop_registry == null:
		push_error(
			"ServerMain | No existe WorldDropRegistry."
		)


		get_tree().quit(
			29
		)


		return


	var world_drop_registry_result := (
		world_drop_registry.initialize()
	)


	if world_drop_registry_result != OK:
		push_error(
			(
				"ServerMain | No se pudo inicializar "
				+
				"WorldDropRegistry. Error: %d"
			)
			%
			world_drop_registry_result
		)


		get_tree().quit(
			29
		)


		return

	if world_drop_coordinator == null:
		push_error(
			"ServerMain | No existe WorldDropCoordinator."
		)


		get_tree().quit(
			30
		)


		return


	if not world_drop_coordinator.setup(
		world_mob_registry,
		world_drop_registry
	):
		push_error(
			"ServerMain | No se pudo inicializar WorldDropCoordinator."
		)


		get_tree().quit(
			30
		)


		return

	if world_drop_pickup_coordinator == null:
		push_error(
			"ServerMain | No existe WorldDropPickupCoordinator."
		)

		get_tree().quit(
			31
		)

		return


	if not world_drop_pickup_coordinator.setup(
		game_server,
		world_session_registry,
		world_drop_registry,
		backend_character_inventory_repository
	):
		push_error(
			"ServerMain | No se pudo inicializar WorldDropPickupCoordinator."
		)

		get_tree().quit(
			31
		)

		return

	if npc_service_coordinator == null:
		push_error(
			"ServerMain | No existe NpcServiceCoordinator."
		)


		get_tree().quit(
			20
		)


		return


	if not npc_service_coordinator.setup(
		game_server,
		world_session_registry,
		world_npc_registry,
		vault_coordinator
	):
		push_error(
			"ServerMain | No se pudo inicializar NpcServiceCoordinator."
		)


		get_tree().quit(
			20
		)


		return


	if not vault_coordinator.npc_service_invalidation_requested.is_connected(
		npc_service_coordinator.invalidate_active_service
	):
		vault_coordinator.npc_service_invalidation_requested.connect(
			npc_service_coordinator.invalidate_active_service
		)


	if not item_container_transfer_coordinator.npc_service_invalidation_requested.is_connected(
		npc_service_coordinator.invalidate_active_service
	):
		item_container_transfer_coordinator.npc_service_invalidation_requested.connect(
			npc_service_coordinator.invalidate_active_service
		)


	if movement_coordinator == null:
		push_error(
			"ServerMain | No existe MovementCoordinator."
		)


		get_tree().quit(
			21
		)


		return


	if not movement_coordinator.setup(
		game_server,
		world_session_registry,
		world_navigation_registry,
		world_movement_system,
		npc_service_coordinator
	):
		push_error(
			"ServerMain | No se pudo inicializar MovementCoordinator."
		)


		get_tree().quit(
			21
		)


		return


	if world_presence_coordinator == null:
		push_error(
			"ServerMain | No existe WorldPresenceCoordinator."
		)


		get_tree().quit(
			22
		)


		return


	if not world_presence_coordinator.setup(
		game_server,
		world_session_registry,
		world_mob_registry,
		world_drop_registry
	):
		push_error(
			"ServerMain | No se pudo inicializar WorldPresenceCoordinator."
		)


		get_tree().quit(
			22
		)


		return


	if authentication_coordinator == null:
		push_error(
			"ServerMain | No existe AuthenticationCoordinator."
		)


		get_tree().quit(
			23
		)


		return


	if not authentication_coordinator.setup(
		game_server,
		backend_ticket_validator,
		world_session_registry,
		world_presence_coordinator,
		character_item_state_coordinator,
		character_runtime_state_coordinator
	):
		push_error(
			"ServerMain | No se pudo inicializar AuthenticationCoordinator."
		)


		get_tree().quit(
			23
		)


		return


	var result := (
		game_server.start()
	)


	if result != OK:
		push_error(
			"ServerMain | No se pudo iniciar el servidor."
		)

		get_tree().quit(
			result
		)

		return


	print(
		"ServerMain | VHAL Game Server iniciado."
	)
