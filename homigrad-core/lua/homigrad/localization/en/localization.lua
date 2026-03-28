-- "addons\\homigrad-core\\lua\\homigrad\\localization\\en\\localization.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hg.Localizations = hg.Localizations or {}

hg.Localizations.en = {}

table.Empty(hg.Localizations.en)

local l = {}

// Текст Смерти
l.Dead = "DEAD"
l.dead_blood = "You died from blood loss."
l.dead_pain = "You died in unbearable pain."
l.dead_painlosing = "You fell asleep."
l.dead_adrenaline = "You died of an overdose."
l.dead_kys = "You killed yourself." //rule 1488: no funny images with text kys!!!!
l.dead_hungry = "You starved to death."
l.dead_neck = "Your neck was broken."
l.dead_necksnap = "Your neck was snapped."
l.dead_world = "Bid farewell, cruel world!"
l.dead_head = "Boom, headshot."
l.dead_headExplode = "Your head has exploded."
l.dead_fullgib = "You got ripped apart."
l.dead_blast = "You've got exploded."
l.dead_water = "You're drowned."
l.dead_poison = "You died from the poison."
l.dead_burn = "You burnt to death."
l.dead_unknown = "I don't even know how did you died."

l["kill_ValveBiped.Bip01_Head1"] = "head"
l["kill_ValveBiped.Bip01_Spine"] = "back"
l["kill_ValveBiped.Bip01_Spine1"] = "back"
l["kill_ValveBiped.Bip01_Spine2"] = "back"
l["kill_ValveBiped.Bip01_Spine4"] = "back"
l["kill_ValveBiped.Bip01_Pelvis"] = "pelvis"

l["kill_ValveBiped.Bip01_R_Hand"] = "right hand"
l["kill_ValveBiped.Bip01_R_Forearm"] = "right hand"
l["kill_ValveBiped.Bip01_R_UpperArm"] = "right forearm"

l["kill_ValveBiped.Bip01_R_Foot"] = "right foot"
l["kill_ValveBiped.Bip01_R_Thigh"] = "right thigh"
l["kill_ValveBiped.Bip01_R_Calf"] = "right shin"

l["kill_ValveBiped.Bip01_R_Shoulder"] = "right shoulder"
l["kill_ValveBiped.Bip01_R_Elbow"] = "right elbow"
    
l["kill_ValveBiped.Bip01_L_Hand"] = "left hand"
l["kill_ValveBiped.Bip01_L_Forearm"] = "left arm"
l["kill_ValveBiped.Bip01_L_UpperArm"] = "left forearm"

l["kill_ValveBiped.Bip01_L_Foot"] = "left foot"
l["kill_ValveBiped.Bip01_L_Thigh"] = "left thigh"
l["kill_ValveBiped.Bip01_L_Calf"] = "left shin"

l["kill_ValveBiped.Bip01_L_Shoulder"] = "left shoulder"
l["kill_ValveBiped.Bip01_L_Elbow"] = "left elbow"

l["in"] = "in"
l.kill_by_wep = "with"

l.died_by = "You got killed by"
l.died = "You got killed"
l.died_killed = "You got killed by"
l.died_by_npc = "Killed by NPC"
l.died_by_object = "Killed by object"

// Оружие
l.gun_revolver = "%s Rounds Chambered"
l.gun_revolvermags = "%s Bullets left"

l.gun_shotgun = "%s"
l.gun_shotgunmags = "%s Shells left"

l.gun_default = "%s"
l.gun_defaultmags = "%s Mags Left"

l.gun_empty = "Empty"
l.gun_nearempty = "Nearly Empty"
l.gun_halfempty = "Half Empty"
l.gun_nearfull = "Nearly Full"
l.gun_r_pump = "Press R to pump."
l.gun_full = "Full" 

l.cuff = "Cuff %s"
l.cuffed = "%s Is already cuffed."

// Спект
l.SpectALT = "Disable / Enable display of nicknames on ALT"
l.SpectHP = "Health: %s"
l.SpectCur = "Spectators: %s"
l.SpectMode = "Spectating Mode: %s"

// Уровни

l.level_wins = "%s wins."
l.levels_endin = "Round ends in: %s"

l.swat_arrived = "SWAT Arrived."
l.swat_arrivein = "SWAT will arrive in: %s"

l.round_to_end_dr = "Round ended"
l.round_will_end_in_dr = "Round will end in: %s"

l.police_arrived = "Police Arrived."
l.police_arrivein = "Police will arrive in: %s"

l.ng_arrived = "National Guard Arrived."
l.ng_arrivein = "National Guard will arrive in: %s"

l.you_are = "You are %s"
l.lvl_loadingmode = "Loading mode %s"

l.hunter_victim = "Victim"
l.hunter_victim_desc = "You need to survive. \n Escape when the SWAT arrives."

l.hunter_swat = "SWAT"
l.hunter_swat_desc = "You need to neutralize hunter. \n Help survivors escape."

l.hunter_hunter = "Hunter"
l.hunter_hunter_desc = "Your task is to kill everyone before SWAT arrives."

l.dr_runner = "Runner"
l.dr_runner_desc = "You need to complete the map and eliminate \"Killer\""

l.dr_killer = "Killer" //"Saw51" //чеча инцидент оу ее
l.dr_killer_desc = "Your task is to kill everyone on this map using traps."
l.dr_youwilldiein = "You will die in: %s"

l.jb_prisoner = "Inmate"
l.jb_prisoner_desc = "You need to kill warden | escape prison."

l.jb_warden = "Warden"
l.jb_warden_desc = "You need to complete your shift as warden. \n Dont let prisoners escape | kill you."

l.tdm_red = "Red"
l.tdm_red_desc = "Kill opposite team"

l.tdm_blue = "Blue"
l.tdm_blue_desc = "Kill opposite team"

l.riot_red = "Rioters"
l.riot_red_desc = "Keep your rights! Destroy all those who would slow you down!"

l.riot_blue = "Police"
l.riot_blue_desc = "Neutralize rioters, try not to kill them"

l.hmcd_bystander = "Innocent"
l.hmcd_bystander_desc = "You are an innocent, rely only on yourself, but stick around with crowds to make traitor's job harder."

l.hmcd_gunman = "Gunman"
l.hmcd_gunman_desc = "You are an innocent, rely only on yourself, but stick around with crowds to make traitor's job harder."

l.hmcd_traitor = "Traitor"
l.hmcd_traitor_desc = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here."

l.hmcd_gfz = "Gun-Free Zone"
l.hmcd_soe = "State Of Emergency"
l.hmcd_standard = "Standard"
l.hmcd_ww = "Wild West"

l.hmcd_traitor_soe = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here." 
l.hmcd_traitor_gfz = "You're geared up with knife hidden in your pockets. Murder everyone here."
l.hmcd_traitor_standard = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here."
l.hmcd_traitor_ww = "This town ain't that big for all of us."

l.hmcd_gunman_soe = "You are an innocent with a hunting weapon. Find and neutralize the traitor before it's too late." 
l.hmcd_gunman_gfz = "You are a bystander of a murder scene, although it didn't happen to you, you better be cautious."
l.hmcd_gunman_standard = "You are a bystander with a concealed firearm. You've tasked yourself to help police find the criminal faster."
l.hmcd_gunman_ww = "You're the sheriff of this town. You gotta find and kill the lawless bastard."

l.hmcd_bystander_soe = "You are an innocent, rely only on yourself, but stick around with crowds to make traitor's job harder."
l.hmcd_bystander_gfz = "You are a bystander of a murder scene, although it didn't happen to you, you better be cautious."
l.hmcd_bystander_standard = "You are a bystander of a murder scene, although it didn't happen to you, you better be cautious."
l.hmcd_bystander_ww = "We gotta get justice served over here, there's a lawless prick murdering men."
l.hmcd_police = "Police"
l.hmcd_police_desc = "You arrived as police. Find the traitor and arrest or eliminate them."

l.hl2dm_cmb_name = "UNIT %s"
l.hl2dm_cmb = "Combine"
l.hl2dm_cmb_desc = "Eliminate any resistance."

l.hl2dm_rebel = "Rebel"
l.hl2dm_rebel_desc = "Eliminate every Combine unit!"

l.criresp_suspect = "Suspect"
l.criresp_suspect_desc = "This is my fucking house, bitches, I can do what I want."

l.criresp_swat = "SWAT Operator"
l.criresp_swat_desc = "Negotiations failed, eliminate the threat. 10-4"

l.gw_blue = "Groove Member"
l.gw_red = "Bloodz Member"
l.gw_blue_desc = "Kill all bloodz mazafakas"
l.gw_red_desc = "Kill all groove mazafakas"

l.zs_surv = "Human"
l.zs_surv_desc = "Survive."

l.zs_zombie = "Zombie"
l.zs_zombie_desc = "KILL EVERYONE"
l.zs_wavein = "Next wave in: %s"
l.zs_waveendin = "Wave will end in: %s"
l.zs_peopleleft = "Humans left: %s"
l.zs_buymenu_open = "Press F2 to open buymenu"

l.coop_endsin = "Map will change in: %s"
l.coop_rebel = "Rebels"
l.coop_gondon = "Gordon Freeman"
l.coop_gondon_desc = "Lead the resistance to win!"
l.coop_cmb = "Combine"

l.coop_rebel_desc = "Follow the freeman!"
l.coop_cmb_desc = "what the fuck?"

l.event_maker = "Eventmaster"
l.event_player = "Player"

// Скорборд

l.sc_players = "Players"
l.sc_invento = "Inventory"
l.sc_teams = "Teams"
l.sc_settings = "Settings"

l.sc_copysteam = "Copy STEAMID"
l.sc_openprofile = "Open profile"
l.sc_copysteam64 = "Copy STEAMID64"
l.sc_copynick = "Copy Nick"

l.sc_unable_prof = "Unable to open profile."
l.sc_unable_steamid = "Unable to copy STEAMID."
l.sc_success_copy = "Succesfully copied STEAMID (%s)"
l.sc_success_copy64 = "Succesfully copied STEAMID64 (%s)"
l.sc_success_nick = "Succesfully copied nick (%s)"
l.sc_jb_ranks = "JB Ranks"
l.sc_event_menu = "Event Menu"
l.sc_curround = "Current Round: %s"
l.sc_nextround = "Next Round: %s"
l.sc_team = "Team"
l.sc_ug = "Usergroup"
l.sc_status = "Status"
l.sc_tps = "Server Tickrate: %s"
l.sc_mutedead = "Mute dead"
l.sc_muteall = "Mute all"

//Радиалка
l.hg_posture = "Change Posture"
l.hg_resetposture = "Reset Posture"
l.hg_suicide = "Commit suicide."
l.hg_unload = "Unload"
l.hg_attachments = "Attachments"
l.hg_drop = "Drop"

//Аттачменты
l.att_menu_title = "Attachments"
l.att_sights = "Sights"
l.att_suppressors = "Suppressors"
l.att_grips = "Grips"
l.att_no_weapon = "No weapon in hands"
l.att_no_modifications = "No modifications available for this weapon"
l.att_category_unavailable = "This category is not available for this weapon"
l.att_remove_all = "Remove All"

// Остальное
l.inv_drop = "Drop"
l.inv_roll = "Roll drum"
l.pulse_normal = "Normal pulse."
l.pulse_high = "High pulse."
l.pulse_low = "Low pulse."
l.pulse_lowest = "You can't feel a pulse"
l.pulse_no = "You can't feel a pulse"
l.youre_hungry = "You're hungry."
l.need_2_players = "We need 2 players to start."

l.use_door = "Door"
l.ent_small_crate = "Small Container"
l.ent_medium_crate = "Medium Container"
l.ent_large_crate = "Large Container"
l.ent_melee_crate = "Melee Container"
l.ent_weapon_crate = "Weapon Container"
l.ent_grenade_crate = "Grenade Container"
l.ent_explosives_crate = "Explosives Container"
l.ent_medkit_crate = "Medicines Container"
l.use_ezammo = "Ammo Crate"

l.use_time_bomb = "Time Bomb"
l.use_fragnade = "Frag Nade"
l.use_firenade = "Incendiary Nade"
l.use_sticknade = "Stick Nade"
l.use_dynam = "Dynamite"
l.use_smokenade = "Smoke Nade"
l.use_signalnade = "Signal Nade"
l.use_gasnade = "Poison Gas Nade"
l.use_teargasnade = "Tear Gas Nade"
l.use_detpack = "Detonation Pack"
l.use_buket = "Grenade Satchel Charge"
l.use_tnt = "Satchel Charge"
l.use_button = "Button"

l.alive = "Alive"
l.unalive = "Dead"
l.unknown = "Unknown"
l.spectating = "Spectating"
l.spectator = "Spectator"

l.cant_kick = "You cant kick because your leg is broken."
l.leg_hurt = "Your leg hurts."
l.uncon = "UNCONSCIOUS"

l.heal = "Heal %s"
l.wep_delay = "Delay: %s"
l.wep_dmg = "Damage: %s"
l.wep_force = "Force: %s"

l.item_notexist = "Item is not exist."

l.hasnt_pulse = "He has no pulse."
l.otrub_but_he_live = "He's unconscious, but he's still alive."
l.has_pulse = "He has pulse."

l.r_close = "Press R to close."

//Локализация названий

l.weapon_bandage = "Bandage"
l.weapon_medkit_hg = "Medkit"
l.weapon_painkillers_hg = "Painkillers"
l.weapon_adrenaline = "Adrenaline"

l.weapon_beton = "Eatable armature"
l.weapon_burger = "Burger"
l.weapon_water_bottle = "Water Bottle"
l.weapon_canned_burger = "Canned Burger"
l.weapon_milk = "Milk"
l.weapon_chips = "Pringles"
l.weapon_energy_drink = "Monster Energy"

l.weapon_ied = "Improved Explosive Device"
l.ied_plant = "Plant IED"
l.ied_metalprop = "in metallic prop"
l.weapon_hands = "Hands"

l.weapon_radio = "Radio"

l.weapon_handcuffs = "Cuffs"

l.weapon_pbat = "Police Tonfa"
l.weapon_sog = "SOG SEAL 2000"
l.weapon_crowbar_hg = "Crowbwar"
l.weapon_fubar = "Fubar"
l.weapon_hammer = "Hammer"
l.weapon_hatchet = "Hatchet"
l.weapon_axe = "Wooden Axe"
l.weapon_shovel = "Shovel"
l.weapon_melee = "Combat Knife"
l.weapon_pipe = "Pipe"
l.weapon_kitknife = "Kitchen Knife"
l.weapon_wrenchdedsex = "Wrench"
l.weapon_batmetal = "Metal Bat"  
l.weapon_machete = "Machete"
l.weapon_slegdehammer = "Sledgehammer"

// Settings
l.setting_fov = "FOV (Field of View)"
l.setting_fov_desc = "Decreases or increases the player's field of view"
l.setting_notify = "Notification Display"
l.setting_notify_desc = "Enables system notifications display in the top left corner"
l.setting_cshs_camera = "Cat's Homicide Server Camera"
l.setting_cshs_camera_desc = "Enables ragdoll camera similar to Cat's homicide server"
l.setting_casual = "Hand Grab Icons"
l.setting_casual_desc = "Enables/disables icon display when grabbing with hands."
l.setting_multicore = "Multi-core Rendering"
l.setting_multicore_desc = "Enables usage of multiple CPU cores, FPS may increase significantly."
l.setting_pixels = "Pixel Textures"
l.setting_pixels_desc = "Makes textures more pixelated."
l.setting_ssao = "SSAO (aka Gomigrad-Shaders)"
l.setting_ssao_desc = "Adds realistic soft shadows in corners, joints, recesses, and object contact points."
l.setting_3dskybox = "3D Skybox"
l.setting_3dskybox_desc = "Enables/disables 3D skybox rendering, may help with performance on weak PCs."
l.setting_ragdoll = "Ragdoll (fake)"
l.setting_ragdoll_desc = "Fall into ragdoll mode (rag doll)."
l.setting_suicide = "Suicide"
l.setting_suicide_desc = "Shoot yourself in the head with a weapon."
l.setting_kick = "Kick"
l.setting_kick_desc = "Kick with your foot."
l.setting_header = "SETTINGS"
l.setting_tab_general = "General"
l.setting_tab_graphics = "Graphics"
l.setting_tab_keyboard = "Keyboard"
l.setting_tab_skins = "Skins"
l.setting_tab_account = "Account"
l.setting_section_settings = "SETTINGS"
l.setting_section_personalization = "PERSONALIZATION"
l.setting_voice_bg = "Voice Chat Background"
l.setting_voice_bg_select = "Select a background to display in voice chat"
l.setting_voice_bg_choose = "Select Background"
l.setting_voice_bg_reset = "Reset Background"
l.setting_key_none = "NONE"
l.setting_skins_title = "Server Skins"
l.setting_skins_desc = "Skins will be applied next round."
l.setting_skins_set = "Set"
l.setting_skins_unset = "Unset"
l.setting_skins_selected = "Selected"
l.setting_skins_empty = "No skins available."
l.setting_skins_applied_next = "Skin will be applied next round."
l.setting_tab_bg_title = "TAB Background"
l.setting_tab_bg_desc = "Enter an image URL"
l.setting_row_bg_title = "Scoreboard Row Background"
l.setting_row_bg_desc = "Enter an image URL"
l.setting_apply = "OK"
l.setting_reset = "Reset"

l.mvp_soundkit = "Music kit: %s"
l.soundkit_Default = "Default"
l.soundkit_HighNoon = "Feed Me - High Noon"
l.soundkit_DashStar = "Knock2 - Dashstar*"
l.soundkit_ChipzelYellowMagic = "Chipzel - Yellow Magic"

// Hints
l.setting_hint_notify = "Enables/disables notification on the main screen at top left, default is off."
l.setting_hint_multicore = "Enables multi-core rendering\n(Enabled by default)"
l.setting_hint_pixels = "Enables pixelated textures\n(Disabled by default)"

// ретеве
l.rtv_header = "VOTE FOR NEXT MAP"
l.rtv_header_timer = "VOTE FOR NEXT MAP - %s"
l.rtv_hint = "SELECT A MAP TO VOTE"
l.rtv_votes = "vote(s)"
l.rtv_time_up = "Time is up!"
l.rtv_random = "RANDOM"
l.rtv_randomly = "RANDOMLY"
l.rtv_extend = "EXTEND"
l.rtv_continue = "CONTINUE"


l.sc_jb_ranks_title = "Police ranks"
l.sc_jb_ranks_manage_hint = "Right click a player to change rank"
l.sc_jb_ranks_view_hint = "Police ranks overview"
l.sc_jb_ranks_search = "Enter player name..."
l.sc_jb_rank_remove = "Remove rank"
l.sc_jb_only = "This tab is available only in JailBreak"

l.sc_event_access_only = "Available for doperator+ only"
l.sc_event_field_title = "Title"
l.sc_event_field_description = "Description"
l.sc_event_field_roles = "Roles"
l.sc_event_field_rules = "Rules"
l.sc_event_field_banner = "Banner / image"
l.sc_event_placeholder_title = "Event title"
l.sc_event_placeholder_description = "Event description"
l.sc_event_placeholder_roles = "Event roles"
l.sc_event_placeholder_rules = "Leave empty to use default rules"
l.sc_event_placeholder_banner = "Banner URL"
l.sc_event_send = "Send event"
l.sc_event_loading_preview = "Loading preview..."
l.sc_event_preview_title_fallback = "Event title"
l.sc_event_preview_description_fallback = "Event description"
l.sc_event_preview_host = "Host"
l.sc_event_preview_rules = "Rules"
l.sc_event_preview_rules_custom = "custom"
l.sc_event_preview_rules_default = "default"
l.sc_event_preview_roles = "Roles"
l.sc_event_preview_roles_empty = "Not specified"

hg.Localizations.en = l
