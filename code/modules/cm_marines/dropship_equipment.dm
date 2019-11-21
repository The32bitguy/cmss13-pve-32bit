
#define DROPSHIP_WEAPON "dropship_weapon"
#define DROPSHIP_CREW_WEAPON "dropship_crew_weapon"
#define DROPSHIP_ELECTRONICS "dropship_electronics"
#define DROPSHIP_FUEL_EQP "dropship_fuel_equipment"
#define DROPSHIP_COMPUTER "dropship_computer"

//the bases onto which you attach dropship equipments.

/obj/effect/attach_point
	name = "equipment attach point"
	desc = "A place where heavy equipment can be installed with a powerloader."
	unacidable = TRUE
	anchored = TRUE
	var/gimbal = GIMBAL_CENTER//which way it is gimballed
	icon = 'icons/obj/structures/props/almayer_props.dmi'
	icon_state = "equip_base"
	var/base_category //what kind of equipment this base accepts.
	var/ship_tag //used to associate the base to a dropship.
	var/obj/structure/dropship_equipment/installed_equipment

/obj/effect/attach_point/Dispose()
	if(installed_equipment)
		qdel(installed_equipment)
		installed_equipment = null
	. = ..()

/obj/effect/attach_point/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/powerloader_clamp))
		var/obj/item/powerloader_clamp/PC = I
		install_equipment(PC, user)
		return TRUE
	. = ..()

/obj/effect/attach_point/proc/install_equipment(var/obj/item/powerloader_clamp/PC, var/mob/living/user)
	if(!istype(PC.loaded, /obj/structure/dropship_equipment))
		return
	var/obj/structure/dropship_equipment/SE = PC.loaded
	if(!(base_category in SE.equip_categories) )
		to_chat(user, SPAN_WARNING("[SE] doesn't fit on [src]."))
		return TRUE
	if(installed_equipment)
		return TRUE
	playsound(loc, 'sound/machines/hydraulics_1.ogg', 40, 1)
	var/point_loc = loc
	if(!do_after(user, 70, INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		return TRUE
	if(loc != point_loc)//dropship flew away
		return TRUE
	if(installed_equipment || PC.loaded != SE)
		return TRUE
	to_chat(user, SPAN_NOTICE("You install [SE] on [src]."))
	SE.forceMove(loc)
	PC.loaded = null
	playsound(loc, 'sound/machines/hydraulics_2.ogg', 40, 1)
	PC.update_icon()
	installed_equipment = SE
	SE.ship_base = src

	for(var/datum/shuttle/ferry/marine/S in shuttle_controller.process_shuttles)
		if(S.shuttle_tag == ship_tag)
			SE.linked_shuttle = S
			S.equipments += SE
			break

	SE.update_equipment()


/obj/effect/attach_point/weapon
	name = "weapon system attach point"
	icon_state = "equip_base_front"
	base_category = DROPSHIP_WEAPON

/obj/effect/attach_point/weapon/dropship1
	ship_tag = "USS Almayer Dropship 1"

/obj/effect/attach_point/weapon/dropship2
	ship_tag = "USS Almayer Dropship 2"


/obj/effect/attach_point/crew_weapon
	name = "crew compartment attach point"
	base_category = DROPSHIP_CREW_WEAPON

/obj/effect/attach_point/crew_weapon/dropship1
	ship_tag = "USS Almayer Dropship 1"

/obj/effect/attach_point/crew_weapon/dropship2
	ship_tag = "USS Almayer Dropship 2"

/obj/effect/attach_point/electronics
	name = "electronic system attach point"
	base_category = DROPSHIP_ELECTRONICS
	icon_state = "equip_base_front"

/obj/effect/attach_point/electronics/dropship1
	ship_tag = "USS Almayer Dropship 1"

/obj/effect/attach_point/electronics/dropship2
	ship_tag = "USS Almayer Dropship 2"


/obj/effect/attach_point/fuel
	name = "engine system attach point"
	icon = 'icons/obj/structures/props/almayer_props64.dmi'
	icon_state = "fuel_base"
	base_category = DROPSHIP_FUEL_EQP

/obj/effect/attach_point/fuel/dropship1
	ship_tag = "USS Almayer Dropship 1"

/obj/effect/attach_point/fuel/dropship2
	ship_tag = "USS Almayer Dropship 2"


/obj/effect/attach_point/computer
	base_category = DROPSHIP_COMPUTER

/obj/effect/attach_point/computer/dropship1
	ship_tag = "USS Almayer Dropship 1"

/obj/effect/attach_point/computer/dropship2
	ship_tag = "USS Almayer Dropship 2"



//////////////////////////////////////////////////////////////////////////////////////////////////////////////::

//Actual dropship equipments

/obj/structure/dropship_equipment
	density = TRUE
	anchored = TRUE
	icon = 'icons/obj/structures/props/almayer_props.dmi'
	climbable = TRUE
	layer = ABOVE_OBJ_LAYER //so they always appear above attach points when installed
	var/list/equip_categories //on what kind of base this can be installed.
	var/obj/effect/attach_point/ship_base //the ship base the equipment is currently installed on.
	var/uses_ammo = FALSE //whether it uses ammo
	var/obj/structure/ship_ammo/ammo_equipped //the ammo currently equipped.
	var/is_weapon = FALSE //whether the equipment is a weapon usable for dropship bombardment.
	var/obj/structure/machinery/computer/dropship_weapons/linked_console //the weapons console of the dropship we're installed on.
	var/is_interactable = FALSE //whether they get a button when shown on the shuttle console's equipment list.
	var/datum/shuttle/ferry/marine/linked_shuttle
	var/screen_mode = 0 //used by the dropship console code when this equipment is selected
	var/point_cost = 0 //how many points it costs to build this with the fabricator, set to 0 if unbuildable.

/obj/structure/dropship_equipment/Dispose()
	if(ammo_equipped)
		qdel(ammo_equipped)
		ammo_equipped = null
	if(linked_shuttle)
		linked_shuttle.equipments -= src
		linked_shuttle = null
	if(ship_base)
		ship_base.installed_equipment = null
		ship_base = null
	if(linked_console)
		if(linked_console.selected_equipment && linked_console.selected_equipment == src)
			linked_console.selected_equipment = null
		linked_console = null
	. = ..()

/obj/structure/dropship_equipment/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/powerloader_clamp))
		var/obj/item/powerloader_clamp/PC = I
		if(PC.loaded)
			load_ammo(PC, user)

		else if(uses_ammo && ammo_equipped)
			unload_ammo(PC, user)

		else
			grab_equipment(PC, user)
		return TRUE


/obj/structure/dropship_equipment/proc/load_ammo(var/obj/item/powerloader_clamp/PC, var/mob/living/user)
	if(!ship_base || !uses_ammo || ammo_equipped || !istype(PC.loaded, /obj/structure/ship_ammo))
		return
	var/obj/structure/ship_ammo/SA = PC.loaded
	if(SA.equipment_type != type)
		to_chat(user, SPAN_WARNING("[SA] doesn't fit in [src]."))
		return
	playsound(src, 'sound/machines/hydraulics_1.ogg', 40, 1)
	var/point_loc = ship_base.loc
	if(!do_after(user, 30, INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		return
	if(!ship_base || ship_base.loc != point_loc)
		return
	if(!ammo_equipped && PC.loaded == SA && PC.linked_powerloader && PC.linked_powerloader.buckled_mob == user)
		SA.forceMove(src)
		PC.loaded = null
		playsound(src, 'sound/machines/hydraulics_2.ogg', 40, 1)
		PC.update_icon()
		to_chat(user, SPAN_NOTICE("You load [SA] into [src]."))
		ammo_equipped = SA
		update_equipment()

/obj/structure/dropship_equipment/proc/unload_ammo(var/obj/item/powerloader_clamp/PC, var/mob/living/user)
	playsound(src, 'sound/machines/hydraulics_2.ogg', 40, 1)
	var/point_loc = ship_base ? ship_base.loc : null
	if(!do_after(user, 30, INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		return
	if(point_loc && ship_base != point_loc) //dropship flew away
		return
	if(!ammo_equipped || !PC.linked_powerloader || PC.linked_powerloader.buckled_mob != user)
		return
	playsound(src, 'sound/machines/hydraulics_1.ogg', 40, 1)
	if(!ammo_equipped.ammo_count)
		ammo_equipped.loc = null
		to_chat(user, SPAN_NOTICE("You discard the empty [ammo_equipped.name] in [src]."))
		qdel(ammo_equipped)
	else
		ammo_equipped.forceMove(PC.linked_powerloader)
		PC.loaded = ammo_equipped
		PC.update_icon()
		to_chat(user, SPAN_NOTICE("You remove [ammo_equipped] from [src] and load it into [PC]."))
	ammo_equipped = null
	update_icon()

/obj/structure/dropship_equipment/proc/grab_equipment(var/obj/item/powerloader_clamp/PC, var/mob/living/user)
	playsound(loc, 'sound/machines/hydraulics_2.ogg', 40, 1)
	var/duration_time = 10
	var/point_loc
	if(ship_base)
		duration_time = 70 //uninstalling equipment takes more time
		point_loc = ship_base.loc
	if(!do_after(user, duration_time, INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		return
	if(point_loc && ship_base != point_loc) //dropship flew away
		return
	if(!PC.linked_powerloader || PC.loaded || PC.linked_powerloader.buckled_mob != user)
		return
	forceMove(PC.linked_powerloader)
	PC.loaded = src
	playsound(src, 'sound/machines/hydraulics_1.ogg', 40, 1)
	PC.update_icon()
	to_chat(user, SPAN_NOTICE("You've [ship_base ? "uninstalled" : "grabbed"] [PC.loaded] with [PC]."))
	if(ship_base)
		ship_base.installed_equipment = null
		ship_base = null
		if(linked_shuttle)
			linked_shuttle.equipments -= src
			linked_shuttle = null
			if(linked_console && linked_console.selected_equipment == src)
				linked_console.selected_equipment = null
	update_equipment()





/obj/structure/dropship_equipment/update_icon()
	return

/obj/structure/dropship_equipment/proc/update_equipment()
	return

//things to do when the shuttle this equipment is attached to is about to launch.
/obj/structure/dropship_equipment/proc/on_launch()
	return

//things to do when the shuttle this equipment is attached to land.
/obj/structure/dropship_equipment/proc/on_arrival()
	return

/obj/structure/dropship_equipment/proc/equipment_interact(mob/user)
	if(is_interactable)
		if(linked_console.selected_equipment) return
		linked_console.selected_equipment = src
		to_chat(user, SPAN_NOTICE("You select [src]."))



//////////////////////////////////// turret holders //////////////////////////////////////

/obj/structure/dropship_equipment/sentry_holder
	equip_categories = list(DROPSHIP_WEAPON, DROPSHIP_CREW_WEAPON)
	name = "sentry deployment system"
	desc = "A box that deploys a sentry turret. Fits on both the external weapon and crew compartment attach points of dropships. You need a powerloader to lift it."
	density = 0
	health = null
	icon_state = "sentry_system"
	is_interactable = TRUE
	point_cost = 500
	var/deployment_cooldown
	var/obj/structure/machinery/marine_turret/premade/dropship/deployed_turret

/obj/structure/dropship_equipment/sentry_holder/initialize()
	if(!deployed_turret)
		deployed_turret = new(src)
		deployed_turret.deployment_system = src
	..()

/obj/structure/dropship_equipment/sentry_holder/New()
	if(!deployed_turret)
		deployed_turret = new(src)
		deployed_turret.deployment_system = src
	..()

/obj/structure/dropship_equipment/sentry_holder/examine(mob/user)
	..()
	if(!deployed_turret)
		to_chat(user, "Its turret is missing.")

/obj/structure/dropship_equipment/sentry_holder/on_launch()
	if(ship_base && ship_base.base_category == DROPSHIP_WEAPON) //only external sentires are automatically undeployed
		undeploy_sentry()

/obj/structure/dropship_equipment/sentry_holder/equipment_interact(mob/user)
	if(deployed_turret)
		if(deployment_cooldown > world.time)
			to_chat(user, SPAN_WARNING("[src] is busy."))
			return //prevents spamming deployment/undeployment
		if(deployed_turret.loc == src) //not deployed
			if(z == LOW_ORBIT_Z_LEVEL && ship_base.base_category == DROPSHIP_WEAPON)
				to_chat(user, SPAN_WARNING("[src] can't deploy mid-flight."))
			else
				to_chat(user, SPAN_NOTICE("You deploy [src]."))
				deploy_sentry()
		else
			to_chat(user, SPAN_NOTICE("You retract [src]."))
			undeploy_sentry()
	else
		to_chat(user, SPAN_WARNING("[src] is unresponsive."))

/obj/structure/dropship_equipment/sentry_holder/update_equipment()
	if(ship_base)
		dir = ship_base.dir
		icon_state = "sentry_system_installed"
		if(deployed_turret)
			deployed_turret.dir = dir
			if(linked_shuttle && deployed_turret.camera)
				if(linked_shuttle.shuttle_tag == "[MAIN_SHIP_NAME] Dropship 1")
					deployed_turret.camera.network.Add("dropship1") //accessible via the dropship camera console
				else
					deployed_turret.camera.network.Add("dropship2")
			if(ship_base.base_category == DROPSHIP_WEAPON)
				switch(dir)
					if(SOUTH)
						deployed_turret.pixel_x = 0
						deployed_turret.pixel_y = 8
					if(NORTH)
						deployed_turret.pixel_x = 0
						deployed_turret.pixel_y = -8
					if(EAST)
						deployed_turret.pixel_x = -8
						deployed_turret.pixel_y = 0
					if(WEST)
						deployed_turret.pixel_x = 8
						deployed_turret.pixel_y = 0
			else
				deployed_turret.pixel_x = 0
				deployed_turret.pixel_y = 0
	else
		dir = initial(dir)
		if(deployed_turret)
			if(deployed_turret.camera)
				if(deployed_turret.camera.network.Find("dropship1"))
					deployed_turret.camera.network.Remove("dropship1")
				else if(deployed_turret.camera.network.Find("dropship2"))
					deployed_turret.camera.network.Remove("dropship2")
			icon_state = "sentry_system"
			deployed_turret.pixel_y = 0
			deployed_turret.pixel_x = 0
			deployed_turret.loc = src
			deployed_turret.dir = dir
			deployed_turret.on = 0
		else
			icon_state = "sentry_system_destroyed"

/obj/structure/dropship_equipment/sentry_holder/proc/deploy_sentry()
	if(deployed_turret)
		playsound(loc, 'sound/machines/hydraulics_1.ogg', 40, 1)
		deployment_cooldown = world.time + 50
		deployed_turret.on = 1
		if(ship_base.base_category == DROPSHIP_WEAPON)
			deployed_turret.loc = get_step(src, dir)
		else
			deployed_turret.loc = src.loc
		icon_state = "sentry_system_deployed"

		for(var/mob/M in deployed_turret.loc)
			if(deployed_turret.loc == src.loc)
				step( M, deployed_turret.dir )
			else
				step( M, get_dir(src,deployed_turret) )

/obj/structure/dropship_equipment/sentry_holder/proc/undeploy_sentry()
	if(deployed_turret)
		playsound(loc, 'sound/machines/hydraulics_2.ogg', 40, 1)
		deployment_cooldown = world.time + 50
		deployed_turret.loc = src
		deployed_turret.on = 0
		icon_state = "sentry_system_installed"





/obj/structure/dropship_equipment/mg_holder
	name = "machine gun deployment system"
	desc = "A box that deploys a crew-served scoped M56D heavy machine gun. Fits on both the external weapon and crew compartment attach points of dropships. You need a powerloader to lift it."
	density = 0
	equip_categories = list(DROPSHIP_WEAPON, DROPSHIP_CREW_WEAPON)
	icon_state = "mg_system"
	point_cost = 300
	var/deployment_cooldown
	var/obj/structure/machinery/m56d_hmg/mg_turret/dropship/deployed_mg

/obj/structure/dropship_equipment/mg_holder/initialize()
	if(!deployed_mg)
		deployed_mg = new(src)
		deployed_mg.deployment_system = src
	..()

/obj/structure/dropship_equipment/mg_holder/New()
	if(!deployed_mg)
		deployed_mg = new(src)
		deployed_mg.deployment_system = src
	..()

/obj/structure/dropship_equipment/mg_holder/examine(mob/user)
	..()
	if(!deployed_mg)
		to_chat(user, "Its machine gun is missing.")

/obj/structure/dropship_equipment/mg_holder/on_launch()
	if(ship_base && ship_base.base_category == DROPSHIP_WEAPON) //only external mgs are automatically undeployed
		undeploy_mg()

/obj/structure/dropship_equipment/mg_holder/attack_hand(user as mob)
	if(ship_base)
		if(deployed_mg)
			if(deployment_cooldown > world.time)
				to_chat(user, SPAN_WARNING("[src] is not ready."))
				return //prevents spamming deployment/undeployment
			if(deployed_mg.loc == src) //not deployed
				if(z == LOW_ORBIT_Z_LEVEL && ship_base.base_category == DROPSHIP_WEAPON)
					to_chat(user, SPAN_WARNING("[src] can't be deployed mid-flight."))
				else
					to_chat(user, SPAN_NOTICE("You pull out [deployed_mg]."))
					deploy_mg(user)
			else
				to_chat(user, SPAN_NOTICE("You stow [deployed_mg]."))
				undeploy_mg()
		else
			to_chat(user, SPAN_WARNING("[src] is empty."))
		return

	..()

/obj/structure/dropship_equipment/mg_holder/update_equipment()
	if(ship_base)
		dir = ship_base.dir
		icon_state = "mg_system_installed"
		if(deployed_mg)
			deployed_mg.dir = dir
			if(ship_base.base_category == DROPSHIP_WEAPON)
				switch(dir)
					if(NORTH)
						if(	istype(get_step(src, WEST), /turf/open) )
							deployed_mg.pixel_x = 5
						else if ( istype(get_step(src, EAST), /turf/open) )
							deployed_mg.pixel_x = -5
					if(EAST)
						deployed_mg.pixel_y = 9
					if(WEST)
						deployed_mg.pixel_y = 9
			else
				deployed_mg.pixel_x = 0
				deployed_mg.pixel_y = 0
	else
		dir = initial(dir)
		if(deployed_mg)
			icon_state = "mg_system"
			deployed_mg.pixel_y = 0
			deployed_mg.pixel_x = 0
			deployed_mg.loc = src
			deployed_mg.dir = dir
		else
			icon_state = "mg_system_destroyed"

/obj/structure/dropship_equipment/mg_holder/proc/deploy_mg(mob/user)
	if(deployed_mg)
		playsound(loc, 'sound/machines/hydraulics_1.ogg', 40, 1)
		deployment_cooldown = world.time + 20
		if(ship_base.base_category == DROPSHIP_WEAPON)
			switch(dir)
				if(NORTH)
					if( istype(get_step(src, WEST), /turf/open) )
						deployed_mg.loc = get_step(src, WEST)
					else if ( istype(get_step(src, EAST), /turf/open) )
						deployed_mg.loc = get_step(src, EAST)
					else
						deployed_mg.loc = get_step(src, NORTH)
				if(EAST)
					deployed_mg.loc = get_step(src, SOUTH)
				if(WEST)
					deployed_mg.loc = get_step(src, SOUTH)
		else
			deployed_mg.loc = src.loc
		icon_state = "mg_system_deployed"

		for(var/mob/M in deployed_mg.loc)
			if(M == user || deployed_mg.loc == src.loc)
				step( M, turn(deployed_mg.dir,180) )
			else
				step( M, get_dir(src,deployed_mg) )

/obj/structure/dropship_equipment/mg_holder/proc/undeploy_mg()
	if(deployed_mg)
		if(deployed_mg.operator)
			deployed_mg.operator.unset_interaction()
		playsound(loc, 'sound/machines/hydraulics_2.ogg', 40, 1)
		deployment_cooldown = world.time + 10
		deployed_mg.loc = src
		icon_state = "mg_system_installed"


////////////////////////////////// FUEL EQUIPMENT /////////////////////////////////

/obj/structure/dropship_equipment/fuel
	icon = 'icons/obj/structures/props/almayer_props64.dmi'
	equip_categories = list(DROPSHIP_FUEL_EQP)


/obj/structure/dropship_equipment/fuel/update_equipment()
	if(ship_base)
		pixel_x = ship_base.pixel_x
		pixel_y = ship_base.pixel_y
		icon_state = "[initial(icon_state)]_installed"
	else
		pixel_x = initial(pixel_x)
		pixel_y = initial(pixel_y)
		bound_width = initial(bound_width)
		bound_height = initial(bound_height)
		icon_state = initial(icon_state)


/obj/structure/dropship_equipment/fuel/fuel_enhancer
	name = "fuel enhancer"
	desc = "A fuel enhancement system for dropships. It improves the thrust produced by the fuel combustion for faster travels. Fits inside the engine attach points. You need a powerloader to lift it."
	icon_state = "fuel_enhancer"
	point_cost = 800

/obj/structure/dropship_equipment/fuel/cooling_system
	name = "cooling system"
	desc = "A cooling system for dropships. It produces additional cooling reducing delays between launch. Fits inside the engine attach points. You need a powerloader to lift it."
	icon_state = "cooling_system"
	point_cost = 800


///////////////////////////////////// ELECTRONICS /////////////////////////////////////////

/obj/structure/dropship_equipment/electronics
	equip_categories = list(DROPSHIP_ELECTRONICS)

/obj/structure/dropship_equipment/electronics/chaff_launcher
	name = "chaff launcher"
	icon_state = "chaff_launcher"
	point_cost = 0


#define LIGHTING_MAX_LUMINOSITY_SHIPLIGHTS 12

/obj/structure/dropship_equipment/electronics/spotlights
	name = "spotlight"
	icon_state = "spotlights"
	desc = "A set of highpowered spotlights to illuminate large areas. Fits on electronics attach points of dropships. Moving this will require a powerloader."
	is_interactable = TRUE
	point_cost = 300
	var/spotlights_cooldown
	var/brightness = 11

/obj/structure/dropship_equipment/electronics/spotlights/get_light_range()
	return min(luminosity, LIGHTING_MAX_LUMINOSITY_SHIPLIGHTS)

/obj/structure/dropship_equipment/electronics/spotlights/equipment_interact(mob/user)
	if(spotlights_cooldown > world.time)
		to_chat(user, SPAN_WARNING("[src] is busy."))
		return //prevents spamming deployment/undeployment
	if(luminosity != brightness)
		SetLuminosity(brightness)
		icon_state = "spotlights_on"
		to_chat(user, SPAN_NOTICE("You turn on [src]."))
	else
		SetLuminosity(0)
		icon_state = "spotlights_off"
		to_chat(user, SPAN_NOTICE("You turn off [src]."))
	spotlights_cooldown = world.time + 50

/obj/structure/dropship_equipment/electronics/spotlights/update_equipment()
	..()
	if(ship_base)
		if(luminosity != brightness)
			icon_state = "spotlights_off"
		else
			icon_state = "spotlights_on"
	else
		icon_state = "spotlights"
		if(luminosity)
			SetLuminosity(0)

/obj/structure/dropship_equipment/electronics/spotlights/on_launch()
	SetLuminosity(0)

/obj/structure/dropship_equipment/electronics/spotlights/on_arrival()
	SetLuminosity(brightness)

#undef LIGHTING_MAX_LUMINOSITY_SHIPLIGHTS



/obj/structure/dropship_equipment/electronics/flare_launcher
	name = "flare launcher"
	icon_state = "flare_launcher"
	point_cost = 0

/obj/structure/dropship_equipment/electronics/targeting_system
	name = "targeting system"
	icon_state = "targeting_system"
	desc = "A targeting system for dropships. It improves firing accuracy on laser targets. Fits on electronics attach points. You need a powerloader to lift this."
	point_cost = 800

/obj/structure/dropship_equipment/electronics/targeting_system/update_equipment()
	if(ship_base)
		icon_state = "[initial(icon_state)]_installed"
	else
		icon_state = initial(icon_state)

/obj/structure/dropship_equipment/electronics/landing_zone_detector
	name = "\improper LZ detector"
	desc = "An electronic device linked to the dropship's camera system that lets you observe your landing zone mid-flight."
	icon_state = "lz_detector"
	point_cost = 400
	var/obj/structure/machinery/computer/security/dropship/linked_cam_console

/obj/structure/dropship_equipment/electronics/landing_zone_detector/update_equipment()
	if(ship_base)
		if(!linked_cam_console)
			for(var/obj/structure/machinery/computer/security/dropship/D in range(5, loc))
				linked_cam_console = D
				break
		icon_state = "[initial(icon_state)]_installed"
	else
		linked_cam_console = null
		icon_state = initial(icon_state)


/obj/structure/dropship_equipment/electronics/landing_zone_detector/Dispose()
	linked_cam_console = null
	. = ..()

/obj/structure/dropship_equipment/electronics/landing_zone_detector/on_launch()
	linked_cam_console.network.Add("landing zones") //only accessible while in the air.

/obj/structure/dropship_equipment/electronics/landing_zone_detector/on_arrival()
	linked_cam_console.network.Remove("landing zones")


/////////////////////////////////// COMPUTERS //////////////////////////////////////

//unfinished and unused
/obj/structure/dropship_equipment/adv_comp
	equip_categories = list(DROPSHIP_COMPUTER)
	point_cost = 0

/obj/structure/dropship_equipment/adv_comp/update_equipment()
	if(ship_base)
		icon_state = "[initial(icon_state)]_installed"
	else
		icon_state = initial(icon_state)


/obj/structure/dropship_equipment/adv_comp/docking
	name = "docking computer"
	icon_state = "docking_comp"
	point_cost = 0


////////////////////////////////////// WEAPONS ///////////////////////////////////////

/obj/structure/dropship_equipment/weapon
	name = "abstract weapon"
	icon = 'icons/obj/structures/props/almayer_props64.dmi'
	equip_categories = list(DROPSHIP_WEAPON)
	bound_width = 32
	bound_height = 64
	uses_ammo = TRUE
	is_weapon = TRUE
	screen_mode = 1
	is_interactable = TRUE
	var/last_fired //used for weapon cooldown after use.
	var/firing_sound
	var/firing_delay = 20 //delay between firing. 2 seconds by default
	var/fire_mission_only = TRUE //whether the weapon can only be fire in fly-by mode (sic).

/obj/structure/dropship_equipment/weapon/update_equipment()
	if(ship_base)
		dir = ship_base.dir
		bound_width = 32
		bound_height = 32
	else
		dir = initial(dir)
		bound_width = initial(bound_width)
		bound_height = initial(bound_height)
	update_icon()

/obj/structure/dropship_equipment/weapon/equipment_interact(mob/user)
	if(is_interactable)
		if(linked_console.selected_equipment == src)
			linked_console.selected_equipment = null
		else
			linked_console.selected_equipment = src

/obj/structure/dropship_equipment/weapon/examine(mob/user)
	..()
	if(ammo_equipped)
		ammo_equipped.show_loaded_desc(user)
	else
		to_chat(user, "It's empty.")



/obj/structure/dropship_equipment/weapon/proc/deplete_ammo()
	if(ammo_equipped)
		ammo_equipped.ammo_count = max(ammo_equipped.ammo_count-ammo_equipped.ammo_used_per_firing, 0)
	update_icon()

/obj/structure/dropship_equipment/weapon/proc/open_fire(obj/selected_target, var/mob/user = usr)
	set waitfor = 0
	var/turf/target_turf = get_turf(selected_target)
	if(firing_sound)
		playsound(loc, firing_sound, 70, 1)
	var/obj/structure/ship_ammo/SA = ammo_equipped //necessary because we nullify ammo_equipped when firing big rockets
	var/ammo_max_inaccuracy = SA.max_inaccuracy
	var/ammo_accuracy_range = SA.accuracy_range
	var/ammo_travelling_time = SA.travelling_time //how long the rockets/bullets take to reach the ground target.
	var/ammo_warn_sound = SA.warning_sound
	deplete_ammo()
	last_fired = world.time
	if(linked_shuttle)
		for(var/obj/structure/dropship_equipment/electronics/targeting_system/TS in linked_shuttle.equipments)
			ammo_accuracy_range = max(ammo_accuracy_range-2, 0) //targeting system increase accuracy and reduce travelling time.
			ammo_max_inaccuracy = max(ammo_max_inaccuracy -3, 1)
			ammo_travelling_time = max(ammo_travelling_time - 20, 10)
			break

	if(ammo_travelling_time)
		var/total_seconds = max(round(ammo_travelling_time/10),1)
		for(var/i = 0 to total_seconds)
			sleep(10)
			if(!selected_target || !selected_target.loc)//if laser disappeared before we reached the target,
				ammo_accuracy_range = min(ammo_accuracy_range + 1, ammo_max_inaccuracy) //accuracy decreases

	var/list/possible_turfs = list()
	for(var/turf/TU in range(ammo_accuracy_range, target_turf))
		possible_turfs += TU
	var/turf/impact = pick(possible_turfs)
	if(ammo_warn_sound)
		playsound(impact, ammo_warn_sound, 70, 1)
	new /obj/effect/overlay/temp/blinking_laser (impact)
	sleep(10)
	SA.source_mob = user
	SA.detonate_on(impact)

/obj/structure/dropship_equipment/weapon/proc/open_fire_firemission(obj/selected_target, var/mob/user = usr)
	set waitfor = 0
	var/turf/target_turf = get_turf(selected_target)
	if(firing_sound)
		playsound(loc, firing_sound, 70, 1)
		playsound(target_turf, firing_sound, 70, 1)
	var/obj/structure/ship_ammo/SA = ammo_equipped //necessary because we nullify ammo_equipped when firing big rockets
	var/ammo_accuracy_range = SA.accuracy_range
	// no warning sound and no travel time
	deplete_ammo()
	last_fired = world.time
	if(linked_shuttle)
		for(var/obj/structure/dropship_equipment/electronics/targeting_system/TS in linked_shuttle.equipments)
			ammo_accuracy_range = max(ammo_accuracy_range-2, 0) //targeting system increase accuracy and reduce travelling time.
			break

	ammo_accuracy_range /= 2 //buff for basically pointblanking the ground

	var/list/possible_turfs = list()
	for(var/turf/TU in range(ammo_accuracy_range, target_turf))
		possible_turfs += TU
	var/turf/impact = pick(possible_turfs)
	sleep(3)
	SA.source_mob = user
	SA.detonate_on(impact)

/obj/structure/dropship_equipment/weapon/heavygun
	name = "\improper GAU-21 30mm cannon"
	desc = "A dismounted GAU-21 'Rattler' 30mm rotary cannon. It seems to be missing its feed links and has exposed connection wires. Capable of firing 5200 rounds a minute, feared by many for its power. Earned the nickname 'Rattler' from the vibrations it would cause on dropships in its inital production run."
	icon_state = "30mm_cannon"
	firing_sound = 'sound/effects/cannon30.ogg'
	point_cost = 400
	fire_mission_only = FALSE

/obj/structure/dropship_equipment/weapon/heavygun/update_icon()
	if(ammo_equipped)
		icon_state = "30mm_cannon_loaded[ammo_equipped.ammo_count?"1":"0"]"
	else
		if(ship_base) icon_state = "30mm_cannon_installed"
		else icon_state = "30mm_cannon"


/obj/structure/dropship_equipment/weapon/rocket_pod
	name = "rocket pod"
	icon_state = "rocket_pod"
	desc = "A rocket pod weapon system capable of launching a single laser-guided rocket. Moving this will require some sort of lifter."
	firing_sound = 'sound/weapons/gun_flare_explode.ogg'
	firing_delay = 5
	point_cost = 600

/obj/structure/dropship_equipment/weapon/rocket_pod/deplete_ammo()
	ammo_equipped = null //nothing left to empty after firing
	update_icon()

/obj/structure/dropship_equipment/weapon/rocket_pod/update_icon()
	if(ammo_equipped && ammo_equipped.ammo_count)
		icon_state = "rocket_pod_loaded[ammo_equipped.ammo_id]"
	else
		if(ship_base) icon_state = "rocket_pod_installed"
		else icon_state = "rocket_pod"


/obj/structure/dropship_equipment/weapon/minirocket_pod
	name = "minirocket pod"
	icon_state = "minirocket_pod"
	desc = "A mini rocket pod capable of launching six laser-guided mini rockets. Moving this will require some sort of lifter."
	icon = 'icons/obj/structures/props/almayer_props64.dmi'
	firing_sound = 'sound/weapons/gun_flare_explode.ogg'
	firing_delay = 10 //1 seconds
	point_cost = 600

/obj/structure/dropship_equipment/weapon/minirocket_pod/update_icon()
	if(ammo_equipped && ammo_equipped.ammo_count)
		icon_state = "minirocket_pod_loaded"
	else
		if(ship_base) icon_state = "minirocket_pod_installed"
		else icon_state = "minirocket_pod"

/obj/structure/dropship_equipment/weapon/minirocket_pod/deplete_ammo()
	..()
	if(ammo_equipped && !ammo_equipped.ammo_count) //fired last minirocket
		ammo_equipped = null

/obj/structure/dropship_equipment/weapon/laser_beam_gun
	name = "laser beam gun"
	icon_state = "laser_beam"
	desc = "State of the art technology recently acquired by the USCM, it fires a battery-fed pulsed laser beam at near lightspeed setting on fire everything it touches. Moving this will require some sort of lifter."
	icon = 'icons/obj/structures/props/almayer_props64.dmi'
	firing_sound = 'sound/effects/phasein.ogg'
	firing_delay = 50 //5 seconds
	point_cost = 500
	fire_mission_only = FALSE

/obj/structure/dropship_equipment/weapon/laser_beam_gun/update_icon()
	if(ammo_equipped && ammo_equipped.ammo_count)
		icon_state = "laser_beam_loaded"
	else
		if(ship_base) icon_state = "laser_beam_installed"
		else icon_state = "laser_beam"


/*TBD
/obj/structure/dropship_equipment/weapon/launch_bay
	name = "launch bay"
	icon_state = "launch_bay"
	desc = "A launch bay to drop special ordnance. Fits inside the dropship's crew weapon emplacement. Moving this will require some sort of lifter."
	icon = 'icons/obj/structures/props/almayer_props.dmi'
	firing_sound = 'sound/weapons/gun_flare_explode.ogg'
	firing_delay = 10 //1 seconds
	equip_categories = list(DROPSHIP_CREW_WEAPON) //fits inside the central spot of the dropship
	point_cost = 0

	update_icon()
		if(ammo_equipped && ammo_equipped.ammo_count)
			icon_state = "launch_bay_loaded"
		else
			if(ship_base) icon_state = "launch_bay"
			else icon_state = "launch_bay"
*/



//////////////// OTHER EQUIPMENT /////////////////



/obj/structure/dropship_equipment/medevac_system
	name = "medevac system"
	desc = "A winch system to lift injured marines on medical stretchers onto the dropship. Acquire lift target through the dropship equipment console."
	equip_categories = list(DROPSHIP_CREW_WEAPON)
	icon_state = "medevac_system"
	point_cost = 500
	is_interactable = TRUE
	var/obj/structure/bed/medevac_stretcher/linked_stretcher
	var/medevac_cooldown
	var/busy_winch

/obj/structure/dropship_equipment/medevac_system/Dispose()
	if(linked_stretcher)
		linked_stretcher.linked_medevac = null
		linked_stretcher = null
	. = ..()

/obj/structure/dropship_equipment/medevac_system/update_equipment()
	if(ship_base)
		icon_state = "medevac_system_deployed"
	else
		if(linked_stretcher)
			linked_stretcher.linked_medevac = null
			linked_stretcher = null
		icon_state = "medevac_system"


/obj/structure/dropship_equipment/medevac_system/equipment_interact(mob/user)
	if(!linked_shuttle)
		return

	if(linked_shuttle.moving_status != SHUTTLE_INTRANSIT)
		to_chat(user, SPAN_WARNING("[src] can only be used while in flight."))
		return

	if(!linked_shuttle.transit_gun_mission)
		to_chat(user, SPAN_WARNING("[src] requires a flyby flight to be used."))
		return

	if(busy_winch)
		to_chat(user, SPAN_WARNING(" The winch is already in motion."))
		return

	if(world.time < medevac_cooldown)
		to_chat(user, SPAN_WARNING("[src] was just used, you need to wait a bit before using it again."))
		return

	var/list/possible_stretchers = list()
	for(var/obj/structure/bed/medevac_stretcher/MS in activated_medevac_stretchers)
		var/area/AR = get_area(MS)
		var/evaccee_name
		var/evaccee_triagecard_color
		if(MS.buckled_mob)
			evaccee_name = MS.buckled_mob.real_name
			if (ishuman(MS.buckled_mob))
				var/mob/living/carbon/human/H = MS.buckled_mob
				evaccee_triagecard_color = H.holo_card_color
		else if(MS.buckled_bodybag)
			for(var/atom/movable/AM in MS.buckled_bodybag)
				if(isliving(AM))
					var/mob/living/L = AM
					evaccee_name = "[MS.buckled_bodybag.name]: [L.real_name]"
					if (ishuman(L))
						var/mob/living/carbon/human/H = L
						evaccee_triagecard_color = H.holo_card_color
					break
			if(!evaccee_name)
				evaccee_name = "Empty [MS.buckled_bodybag.name]"
		else
			evaccee_name = "Empty"

		if (evaccee_triagecard_color && evaccee_triagecard_color == "none")
			evaccee_triagecard_color = null

		possible_stretchers["[evaccee_name] [evaccee_triagecard_color ? "\[" + uppertext(evaccee_triagecard_color) + "\]" : ""] ([AR.name])"] = MS

	if(!possible_stretchers.len)
		to_chat(user, SPAN_WARNING("No active medevac stretcher detected."))
		return

	var/stretcher_choice = input("Which emitting stretcher would you like to link with?", "Available stretchers") as null|anything in possible_stretchers
	if(!stretcher_choice)
		return

	var/obj/structure/bed/medevac_stretcher/selected_stretcher = possible_stretchers[stretcher_choice]
	if(!selected_stretcher)
		return

	if(!ship_base) //system was uninstalled midway
		return

	if(!selected_stretcher.stretcher_activated)//stretcher beacon was deactivated midway
		return

	if(selected_stretcher.z != 1) //in case the stretcher was on a groundside dropship that flew away during our input()
		return

	if(!selected_stretcher.buckled_mob && !selected_stretcher.buckled_bodybag)
		to_chat(user, SPAN_WARNING("This medevac stretcher is empty."))
		return

	if(selected_stretcher.linked_medevac && selected_stretcher.linked_medevac != src)
		to_chat(user, SPAN_WARNING("There's another dropship hovering over that medevac stretcher."))
		return

	if(!linked_shuttle)
		return

	if(linked_shuttle.moving_status != SHUTTLE_INTRANSIT)
		to_chat(user, SPAN_WARNING("[src] can only be used while in flight."))
		return

	if(!linked_shuttle.transit_gun_mission)
		to_chat(user, SPAN_WARNING("[src] requires a flyby flight to be used."))
		return

	if(busy_winch)
		to_chat(user, SPAN_WARNING(" The winch is already in motion."))
		return

	if(world.time < medevac_cooldown)
		to_chat(user, SPAN_WARNING("[src] was just used, you need to wait a bit before using it again."))
		return

	if(selected_stretcher == linked_stretcher) //already linked to us, unlink it
		to_chat(user, SPAN_NOTICE(" You move your dropship away from that stretcher's beacon."))
		linked_stretcher.visible_message(SPAN_NOTICE("[linked_stretcher] detects a dropship is no longer overhead."))
		linked_stretcher.linked_medevac = null
		linked_stretcher = null
		return

	to_chat(user, SPAN_NOTICE(" You move your dropship above the selected stretcher's beacon."))

	if(linked_stretcher)
		linked_stretcher.linked_medevac = null
		linked_stretcher.visible_message(SPAN_NOTICE("[linked_stretcher] detects a dropship is no longer overhead."))

	linked_stretcher = selected_stretcher
	linked_stretcher.linked_medevac = src
	linked_stretcher.visible_message(SPAN_NOTICE("[linked_stretcher] detects a dropship overhead."))




//on arrival we break any link
/obj/structure/dropship_equipment/medevac_system/on_arrival()
	if(linked_stretcher)
		linked_stretcher.linked_medevac = null
		linked_stretcher = null


/obj/structure/dropship_equipment/medevac_system/attack_hand(mob/user)
	if(!ishuman(user))
		return
	if(!ship_base) //not installed
		return
	if(!skillcheck(user, SKILL_PILOT, SKILL_PILOT_TRAINED))
		to_chat(user, SPAN_WARNING(" You don't know how to use [src]."))
		return

	if(!linked_shuttle)
		return

	if(linked_shuttle.moving_status != SHUTTLE_INTRANSIT)
		to_chat(user, SPAN_WARNING("[src] can only be used while in flight."))
		return

	if(!linked_shuttle.transit_gun_mission)
		to_chat(user, SPAN_WARNING("[src] requires a flyby flight to be used."))
		return

	if(busy_winch)
		to_chat(user, SPAN_WARNING(" The winch is already in motion."))
		return

	if(!linked_stretcher)
		to_chat(user, SPAN_WARNING("There seems to be no medevac stretcher connected to [src]."))
		return

	if(linked_stretcher.z != 1)
		linked_stretcher.linked_medevac = null
		linked_stretcher = null
		to_chat(user, SPAN_WARNING(" There seems to be no medevac stretcher connected to [src]."))
		return

	if(world.time < medevac_cooldown)
		to_chat(user, SPAN_WARNING("[src] was just used, you need to wait a bit before using it again."))
		return

	activate_winch(user)


/obj/structure/dropship_equipment/medevac_system/proc/activate_winch(mob/user)
	set waitfor = 0
	var/old_stretcher = linked_stretcher
	busy_winch = TRUE
	playsound(loc, 'sound/machines/medevac_extend.ogg', 40, 1)
	flick("medevac_system_active", src)
	user.visible_message(SPAN_NOTICE("[user] activates [src]'s winch."), \
						SPAN_NOTICE("You activate [src]'s winch."))
	sleep(30)

	busy_winch = FALSE
	var/fail
	if(!linked_stretcher || linked_stretcher != old_stretcher || linked_stretcher.z != 1)
		fail = TRUE

	else if(!ship_base) //uninstalled midway
		fail = TRUE

	else if(!linked_shuttle || linked_shuttle.moving_status != SHUTTLE_INTRANSIT || !linked_shuttle.transit_gun_mission)
		fail = TRUE

	if(fail)
		if(linked_stretcher)
			linked_stretcher.linked_medevac = null
			linked_stretcher = null
		to_chat(user, SPAN_WARNING("The winch finishes lifting but there seems to be no medevac stretchers connected to [src]."))
		return

	var/atom/movable/lifted_object
	if(linked_stretcher.buckled_mob)
		lifted_object = linked_stretcher.buckled_mob
	else if(linked_stretcher.buckled_bodybag)
		lifted_object = linked_stretcher.buckled_bodybag

	if(lifted_object)
		var/turf/T = get_turf(lifted_object)
		T.ceiling_debris_check(2)
		lifted_object.forceMove(loc)
	else
		to_chat(user, SPAN_WARNING("The winch finishes lifting the medevac stretcher but it's empty!"))
		linked_stretcher.linked_medevac = null
		linked_stretcher = null
		return

	flick("winched_stretcher", linked_stretcher)
	linked_stretcher.visible_message(SPAN_NOTICE("A winch hook falls from the sky and starts lifting [linked_stretcher] up."))

	medevac_cooldown = world.time + 600
	linked_stretcher.linked_medevac = null
	linked_stretcher = null

// Fulton extraction system

/obj/structure/dropship_equipment/fulton_system
	name = "fulton recovery system"
	desc = "A winch system to collect any fulton recovery balloons in high altitude. Make sure you turn it on!"
	equip_categories = list(DROPSHIP_CREW_WEAPON)
	icon_state = "fulton_system"
	point_cost = 500
	is_interactable = TRUE
	var/fulton_cooldown
	var/busy_winch

/obj/structure/dropship_equipment/fulton_system/update_equipment()
	if(ship_base)
		icon_state = "fulton_system_deployed"
	else
		icon_state = "fulton_system"


/obj/structure/dropship_equipment/fulton_system/equipment_interact(mob/user)
	if(!linked_shuttle)
		return

	if(linked_shuttle.moving_status != SHUTTLE_INTRANSIT)
		to_chat(user, SPAN_WARNING("[src] can only be used while in flight."))
		return

	if(busy_winch)
		to_chat(user, SPAN_WARNING(" The winch is already in motion."))
		return

	if(world.time < fulton_cooldown)
		to_chat(user, SPAN_WARNING("[src] was just used, you need to wait a bit before using it again."))
		return

	var/list/possible_fultons = list()
	for(var/obj/item/stack/fulton/F in deployed_fultons)
		var/recovery_object
		if(F.attached_atom)
			recovery_object = F.attached_atom.name
		else
			recovery_object = "Empty"
		possible_fultons["[recovery_object]"] = F

	if(!possible_fultons.len)
		to_chat(user, SPAN_WARNING("No active balloons detected."))
		return

	var/fulton_choice = input("Which balloon would you like to link with?", "Available balloons") as null|anything in possible_fultons
	if(!fulton_choice)
		return

	var/obj/item/stack/fulton/F = possible_fultons[fulton_choice]
	if(!fulton_choice)
		return

	if(!ship_base) //system was uninstalled midway
		return

	if(F.z == 1) //in case the fulton popped during our input()
		return

	if(!F.attached_atom)
		to_chat(user, SPAN_WARNING("This balloon stretcher is empty."))
		return

	if(!linked_shuttle)
		return

	if(linked_shuttle.moving_status != SHUTTLE_INTRANSIT)
		to_chat(user, SPAN_WARNING("[src] can only be used while in flight."))
		return

	if(busy_winch)
		to_chat(user, SPAN_WARNING(" The winch is already in motion."))
		return

	if(world.time < fulton_cooldown)
		to_chat(user, SPAN_WARNING("[src] was just used, you need to wait a bit before using it again."))
		return

	to_chat(user, SPAN_NOTICE(" You move your dropship above the selected balloon's beacon."))

	activate_winch(user, F)

/obj/structure/dropship_equipment/fulton_system/proc/activate_winch(mob/user, var/obj/item/stack/fulton/linked_fulton)
	set waitfor = 0
	busy_winch = TRUE
	playsound(loc, 'sound/machines/medevac_extend.ogg', 40, 1)
	flick("fulton_system_active", src)
	user.visible_message(SPAN_NOTICE("[user] activates [src]'s winch."), \
						SPAN_NOTICE("You activate [src]'s winch."))
	sleep(30)

	busy_winch = FALSE
	var/fail
	if(!linked_fulton || linked_fulton.z == 1)
		fail = TRUE

	else if(!ship_base) //uninstalled midway
		fail = TRUE

	else if(!linked_shuttle || linked_shuttle.moving_status != SHUTTLE_INTRANSIT)
		fail = TRUE

	if(fail)
		to_chat(user, SPAN_WARNING("The winch finishes lifting but there seems to be no balloon connected to [src]."))
		return

	if(linked_fulton.attached_atom)
		linked_fulton.return_fulton(get_turf(src))
	else
		to_chat(user, SPAN_WARNING("The winch finishes lifting the medevac stretcher but it's empty!"))
		return

	fulton_cooldown = world.time + 50