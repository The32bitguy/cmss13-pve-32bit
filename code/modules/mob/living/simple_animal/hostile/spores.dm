/mob/living/simple_animal/hostile/spores
	name = "dancing spores"
	desc = "???"
	icon = 'icons/mob/neomorph_spores.dmi'
	icon_state = "spores"
	icon_living = "spores"
	icon_dead = "carp_dead"
	icon_gib = "carp_gib"
	speak_chance = 0
	turns_per_move = 5
	meat_type = null
	response_help = "pets the"
	response_disarm = "gently pushes aside the"
	response_harm = "hits the"
	speed = 4
	maxHealth = 25
	health = 25

	harm_intent_damage = 0
	melee_damage_lower = 0
	melee_damage_upper = 0
	attacktext = "bites"
	attack_sound = 'sound/surgery/organ2.ogg'

	//Space carp aren't affected by atmos.
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0

	break_stuff_probability = 15

	faction = "carp"
	var/light_exposure_tally = 0

/mob/living/simple_animal/hostile/carp/Process_Spacemove(check_drift = 0)
	return 1 //No drifting in space for space carp! //original comments do not steal

/*
/mob/living/simple_animal/hostile/spores/evaluate_target(mob/living/target)
	if(target.faction == src.faction && !attack_same)
		return FALSE
	else if(target in friends)
		return FALSE
	else
		for(var/obj/M in oview(7,target))

		return target
*/

/mob/living/simple_animal/hostile/spores/Move()
	var/turf/check_for_lights = get_turf(src)
	var/delay_for_being_in_light = FALSE
	if(check_for_lights.luminosity || (check_for_lights.dynamic_lumcount >= 1))
		light_exposure_tally++
	else
		light_exposure_tally--
	light_exposure_tally = clamp(light_exposure_tally, 0, 5)
	if(prob(light_exposure_tally*10))
		Stun(0.1)
	. = ..()
	for(var/obj/item/device/flashlight/flare/lit_flare in orange(1,src))
		if(lit_flare.light_range > 1)
			if(target_mob)
				step(get_step_away(src, target_mob, 99))
			else
				Stun(2)

/mob/living/simple_animal/hostile/spores/FindTarget()
	. = ..()
	if(.)
		manual_emote("nashes at [.]")

/mob/living/simple_animal/hostile/spores/AttackingTarget()
	. =..()
	var/mob/living/L = .
	if(istype(L))
		if(prob(15))
			L.apply_effect(3, WEAKEN)
			L.visible_message(SPAN_DANGER("\the [src] knocks down \the [L]!"))


