/datum/caste_datum/neomorph
	caste_type = XENO_CASTE_NEOMORPH
	tier = 2
	melee_damage_lower = XENO_DAMAGE_TIER_3
	melee_damage_upper = XENO_DAMAGE_TIER_4
	melee_vehicle_damage = XENO_DAMAGE_TIER_3
	max_health = XENO_HEALTH_TIER_9
	plasma_gain = XENO_PLASMA_GAIN_TIER_8
	plasma_max = XENO_PLASMA_TIER_10
	xeno_explosion_resistance = XENO_EXPLOSIVE_ARMOR_TIER_1
	armor_deflection = XENO_ARMOR_TIER_1
	evasion = XENO_EVASION_HIGH
	speed = XENO_SPEED_HELLHOUND //Faster than drones, slower than lurkers.

	caste_desc = "A warrior of the hive."
	evolves_to = list(XENO_CASTE_QUEEN, XENO_CASTE_BURROWER, XENO_CASTE_CARRIER, XENO_CASTE_HIVELORD) //Add more here separated by commas
	deevolves_to = list("Drone")

	tackle_min = 2
	tackle_max = 4

	minimap_icon = "predalien"

/mob/living/carbon/xenomorph/neomorph
	caste_type = XENO_CASTE_NEOMORPH
	name = XENO_CASTE_NEOMORPH
	desc = "An alien warrior."
	icon = 'icons/mob/xenos/neomorph.dmi'
	icon_size = 48
	icon_state = "Neomorph Walking"
	plasma_types = list(PLASMA_PURPLE)
	tier = 2
	pixel_x = -12
	old_x = -12

	gib_chance = 50
	claw_type = CLAW_TYPE_SHARP
	pull_multiplier = 0.2 /// Pretty much no pull delay, for those quick drags.

	acid_blood_damage = 35 /// Strong acid blood. Should be a define in the future.
	acid_blood_spatter = TRUE /// Testing variable, means that their blood can melt objects in the environment. Primarily barricades.

	icon_xeno = 'icons/mob/xenos/neomorph.dmi'
	icon_xenonid = 'icons/mob/xenonids/drone.dmi'

	target_unconscious = FALSE

/*
 * ==========================================================================|
 * 							BASE DEFINES AND PROCS
 * --------------------------------------------------------------------------|
 * ==========================================================================|
*/


/mob/living/carbon/xenomorph/neomorph/Initialize()
	base_actions = list(
		/datum/action/xeno_action/onclick/xeno_resting,
		/datum/action/xeno_action/onclick/regurgitate,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/activable/tail_stab/tail_seize/neomorph,
		/datum/action/xeno_action/activable/warrior_punch/neomorph,
		/datum/action/xeno_action/onclick/tacmap,
	)
	inherent_verbs = list(
		/mob/living/carbon/xenomorph/proc/vent_crawl,
	)

	if(istype(ai_movement_handler, /datum/xeno_ai_movement/linger))


	. = ..()

/mob/living/carbon/xenomorph/neomorph/init_movement_handler()
	return new /datum/xeno_ai_movement/linger(src)

/datum/action/xeno_action/activable/tail_stab/tail_seize/neomorph
	default_ai_action = TRUE
	ai_prob_chance = 70
	xeno_cooldown = 8 SECONDS
	charge_time = FALSE
	use_white_tail = TRUE

/datum/action/xeno_action/activable/tail_stab/tail_seize/neomorph/process_ai(mob/living/carbon/xenomorph/parent, delta_time)
	/// Short-circuit. Will return the last thing checked or FALSE if it fails at any step.
	/// We do not need to check for distance here as the tailstab itself will do that; that distance being 2.
	return DT_PROB(ai_prob_chance, delta_time) && use_ability_async(parent.current_target) && (get_dist(parent, parent.current_target) <= 7) && (get_dist(parent, parent.current_target) > 3) && !check_for_obstacles_projectile(parent, parent.current_target, GLOB.ammo_list[/datum/ammo/xeno/oppressor_tail])

/proc/check_for_obstacles_projectile(mob/firer, mob/target, obj/projectile/P)
	var/list/turf/path = get_line(firer, target, include_start_atom = FALSE)
	if(!length(path) || get_dist(firer, target) > P.ammo.max_range)
		return TRUE

	var/blocked = FALSE
	for(var/turf/T in path)
		if(T.density && T.opacity)
			blocked = TRUE
			break

		for(var/obj/O in T)
			if(O.get_projectile_hit_boolean(P) && O.opacity)
				blocked = TRUE
				break

	return blocked

/datum/action/xeno_action/activable/warrior_punch/neomorph
	default_ai_action = TRUE
	ai_prob_chance = 100

/datum/action/xeno_action/activable/warrior_punch/neomorph/use_ability()
	var/mob/living/carbon/xenomorph/stabbing_xeno = owner
	if(istype(stabbing_xeno.ai_movement_handler, /datum/xeno_ai_movement/linger))
		var/datum/xeno_ai_movement/linger/movement = stabbing_xeno.ai_movement_handler
		COOLDOWN_START(movement, reengage_cooldown, movement.reengage_interval)
	. = ..()

/datum/action/xeno_action/activable/warrior_punch/neomorph/process_ai(mob/living/carbon/xenomorph/parent, delta_time)
	/// Short-circuit. Will return the last thing checked or FALSE if it fails at any step.
	return DT_PROB(ai_prob_chance, delta_time) && use_ability_async(parent.current_target)
