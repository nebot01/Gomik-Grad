-- "addons\\homigrad-core\\lua\\homigrad\\localization\\ru\\localization.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hg.Localizations = hg.Localizations or {}

hg.Localizations.ru = {}

table.Empty(hg.Localizations.ru)

local l = {}

// Текст Смерти
l.Dead = "МЁРТВ"
l.dead_blood = "Ты умер от потери крови."
l.dead_pain = "Ты умер от невыносимой боли."
l.dead_painlosing = "Ты упал спать."
l.dead_adrenaline = "Ты умер от передоза."
l.dead_kys = "Ты самоубился." //rule 1488: no funny images with text kys!!!!
l.dead_hungry = "Ты помер с голоду."
l.dead_neck = "Твоя шея была сломана."
l.dead_necksnap = "Твоя шея была свёрнута."
l.dead_world = "%s прощается с жестоким миром!"
l.dead_head = "Бум, в голову."
l.dead_headExplode = "Твоя голова была взорвана."
l.dead_fullgib = "Тебя разорвало."
l.dead_blast = "Ты взорвался."
l.dead_water = "Ты утонул."
l.dead_poison = "Ты умер от отравления."
l.dead_burn = "Ты сгорел заживо."
l.dead_unknown = "Я даже не знаю как ты умер то."

l["kill_ValveBiped.Bip01_Head1"] = "голову"
l["kill_ValveBiped.Bip01_Spine"] = "спину"
l["kill_ValveBiped.Bip01_Spine1"] = "спину"
l["kill_ValveBiped.Bip01_Spine2"] = "спину"
l["kill_ValveBiped.Bip01_Spine4"] = "спину"
l["kill_ValveBiped.Bip01_Pelvis"] = "таз"

l["kill_ValveBiped.Bip01_R_Hand"] = "правую руку"
l["kill_ValveBiped.Bip01_R_Forearm"] = "правую руку"
l["kill_ValveBiped.Bip01_R_UpperArm"] = "правый локоть"

l["kill_ValveBiped.Bip01_R_Foot"] = "правую ногу"
l["kill_ValveBiped.Bip01_R_Thigh"] = "правую ногу"
l["kill_ValveBiped.Bip01_R_Calf"] = "правую ногу"

l["kill_ValveBiped.Bip01_R_Shoulder"] = "правое плечо"
l["kill_ValveBiped.Bip01_R_Elbow"] = "правый локоть"

l["kill_ValveBiped.Bip01_L_Hand"] = "левую руку"
l["kill_ValveBiped.Bip01_L_Forearm"] = "левую руку"
l["kill_ValveBiped.Bip01_L_UpperArm"] = "левый локоть"

l["kill_ValveBiped.Bip01_L_Foot"] = "левую ногу"
l["kill_ValveBiped.Bip01_L_Thigh"] = "левую ногу"
l["kill_ValveBiped.Bip01_L_Calf"] = "левую ногу"

l["kill_ValveBiped.Bip01_L_Shoulder"] = "левое плечо"
l["kill_ValveBiped.Bip01_L_Elbow"] = "левый локоть"

l["in"] = "в"
l.kill_by_wep = "с помощью"

l.died_by = "Тебя убил"
l.died = "Тебя убило"
l.died_killed = "Тебя убил"
l.died_by_npc = "Убил НИП"
l.died_by_object = "Убил предмет"

// Оружие
l.gun_revolver = "%s Пуль заряжено"
l.gun_revolvermags = "%s Пуль в запасе"

l.gun_shotgun = "%s"
l.gun_shotgunmags = "%s Патрон осталось"

l.gun_default = "%s"
l.gun_defaultmags = "%s Магазинов осталось"

l.gun_empty = "Пусто"
l.gun_nearempty = "Почти Пусто"
l.gun_halfempty = "На половину пуст"
l.gun_nearfull = "Почти полон"
l.gun_r_pump = "Нажми R чтобы передёрнуть затвор."
l.gun_full = "Полон" 

l.cuff = "Связать %s"
l.cuffed = "%s Уже связан."

// Спект
l.SpectALT = "Выключить / Включить отображение никнеймов на ALT"
l.SpectHP = "Здоровье: %s"
l.SpectCur = "Наблюдателей: %s"
l.SpectMode = "Режим наблюдателя: %s"

// Уровни

l.level_wins = "%s выиграли."  
l.levels_endin = "Раунд закончится через: %s"

l.swat_arrived = "Прибыл Спецназ."  
l.swat_arrivein = "Спецназ прибудет через: %s"  

l.police_arrived = "Прибыла полиция."  
l.police_arrivein = "Полиция прибудет через: %s"  

l.ng_arrived = "Прибыла Национальная гвардия."  
l.ng_arrivein = "Национальная гвардия прибудет через: %s"  

l.you_are = "Вы – %s"  
l.lvl_loadingmode = "Загружаем режим %s"

l.hunter_victim = "Жертвы"  
l.hunter_victim_desc = "Вы должны выжить. \n Спасайтесь, когда прибудет спецназ."  

l.hunter_swat = "Спецназовцы"  
l.hunter_swat_desc = "Вы должны нейтрализовать Охотника. \n Помогите выжившим сбежать."  

l.hunter_hunter = "Охотники"  
l.hunter_hunter_desc = "Ваша задача – убить всех до прибытия спецназа."

l.hunter_hunter = "Hunter"
l.hunter_hunter_desc = "Ваша задача убить всех до приезда "

l.dr_runner = "Бегуны"
l.dr_runner_desc = "Вам нужно завершить карту и убить \"Убийцу\""

l.dr_killer = "Убийцы"
l.dr_killer_desc = "Ваша задача убить всех используя ловушки на карте"
l.dr_youwilldiein = "Ты умрешь через: %s"

l.jb_prisoner = "Заключенные"
l.jb_prisoner_desc = "Вам нужно убить надзирателя | сбежать из тюрьмы."

l.jb_warden = "Надзиратели"
l.jb_warden_desc = "Ваша задача закончить вашу смену. \n Не дайте заключенный сбежать | убить вас."

l.tdm_red = "Красные"  
l.tdm_red_desc = "Уничтожьте противоположную команду"  

l.tdm_blue = "Синие"  
l.tdm_blue_desc = "Уничтожьте противоположную команду"  

l.riot_red = "Бунтующие"  
l.riot_red_desc = "Отстаивайте свои права! Уничтожьте всех, кто встанет у вас на пути!"  

l.riot_blue = "Полиция"  
l.riot_blue_desc = "Нейтрализуйте бунтовщиков, старайтесь не убивать их"  

l.hmcd_bystander = "Невиновные"  
l.hmcd_bystander_desc = "Вы невиновны, полагайтесь только на себя, но держитесь в толпе, чтобы усложнить задачу предателю."  

l.hmcd_gunman = "Вооружённый"  
l.hmcd_gunman_desc = "Вы невиновны, полагайтесь только на себя, но держитесь в толпе, чтобы усложнить задачу предателю."  

l.hmcd_traitor = "Предатели"  
l.hmcd_traitor_desc = "У вас есть снаряжение, яды, взрывчатка и оружие, спрятанное в карманах. Убейте всех здесь."  

l.hmcd_gfz = "Зона без оружия"  
l.hmcd_soe = "Чрезвычайное положение"  
l.hmcd_standard = "Стандартный режим"  
l.hmcd_ww = "Дикий Запад"  

l.hmcd_traitor_soe = "У вас есть снаряжение, яды, взрывчатка и оружие, спрятанное в карманах. Убейте всех здесь."  
l.hmcd_traitor_gfz = "У вас есть нож, спрятанный в кармане. Убейте всех здесь."  
l.hmcd_traitor_standard = "У вас есть снаряжение, яды, взрывчатка и оружие, спрятанное в карманах. Убейте всех здесь."
l.hmcd_traitor_ww = "Этот город не настолько большой для всех нас"  

l.hmcd_gunman_soe = "Вы невиновны, но у вас есть охотничье оружие. Найдите и нейтрализуйте предателя, пока не стало слишком поздно."  
l.hmcd_gunman_gfz = "Вы свидетель убийства, хотя вас это не коснулось, лучше быть осторожным."  
l.hmcd_gunman_standard = "Вы свидетель с табельным оружием. Вы решили помочь полиции быстрее найти преступника."  
l.hmcd_gunman_ww = "Вы - шериф этого города. Вы должны найти и убить беззаконного ублюдка."

l.hmcd_bystander_soe = "Вы невиновны, полагайтесь только на себя, но держитесь в толпе, чтобы усложнить задачу предателю."  
l.hmcd_bystander_gfz = "Вы свидетель убийства, хотя вас это не коснулось, лучше быть осторожным."  
l.hmcd_bystander_standard = "Вы свидетель убийства, хотя вас это не коснулось, лучше быть осторожным."
l.hmcd_bystander_ww = "Мы должны восстановить справедливость, ведь здесь беззаконный урод убивает людей"
l.hmcd_police = "Полиция"
l.hmcd_police_desc = "Вы прибыли как полиция. Найдите предателя и задержите или ликвидируйте его."

l.hl2dm_cmb_name = "UNIT %s"
l.hl2dm_cmb = "Комбайны"
l.hl2dm_cmb_desc = "Уничтожьте любое сопротивление."

l.hl2dm_rebel = "Повстанцы"
l.hl2dm_rebel_desc = "Уничтожьте всех комбайнов!"

l.criresp_suspect = "Подозреваемые"
l.criresp_suspect_desc = "Это мой ёбанный дом, суки, я могу делать все, что захочу."

l.criresp_swat = "Оперативники SWAT"
l.criresp_swat_desc = "Переговоры не удались, устранить угрозу. 10-4"

l.gw_blue = "Участники банды Groove"
l.gw_red = "Участники банды Bloodz"
l.gw_blue_desc = "Убей всех уёбков из bloodz"
l.gw_red_desc = "Убей всех уёбков из groove"

l.zs_surv = "Люди"
l.zs_surv_desc = "Выживи."

l.zs_zombie = "Зомби"
l.zs_zombie_desc = "УБЕЙ ВСЕХ"
l.zs_wavein = "Следующая волна через: %s"
l.zs_waveendin = "Волна закончиться через: %s"
l.zs_peopleleft = "Осталось людей: %s"
l.zs_buymenu_open = "Press F2 to open buymenu"

l.coop_endsin = "Карта сменится через: %s"
l.coop_rebel = "Повстанцы"
l.coop_gondon = "Гордон Фримен"
l.coop_gondon_desc = "Управляйте сопротивлением чтобы победить!"
l.coop_cmb = "Альянс"

l.coop_rebel_desc = "За фрименом!"
l.coop_cmb_desc = "Чего блять? Ты че ахуел за комбайнов заходить?"

l.event_maker = "Ивент-мейкер"
l.event_player = "Игрок"

// Скорборд

l.sc_players = "Игроки"
l.sc_invento = "Инвентарь"
l.sc_teams = "Команды"
l.sc_settings = "Настройки"

l.sc_copysteam = "Скопировать STEAMID"
l.sc_openprofile = "Открыть профиль"
l.sc_copysteam64 = "Скопировать STEAMID64"
l.sc_copynick = "Скопировать ник"

l.sc_unable_prof = "Невозможно открыть профиль."
l.sc_unable_steamid = "Невозможно скопировать STEAMID."
l.sc_success_copy = "Успешно скопирован STEAMID (%s)"
l.sc_success_copy64 = "Успешно скопирован STEAMID64 (%s)"
l.sc_success_nick = "Успешно скопирован ник (%s)"

l.sc_jb_ranks = "Ранги JB"
l.sc_event_menu = "Ивент-меню"
l.sc_curround = "Текущий Раунд: %s"
l.sc_nextround = "Следующий Раунд: %s"
l.sc_team = "Команда"
l.sc_ug = "Юзергруп"
l.sc_status = "Статус"
l.sc_tps = "Тикрейт Сервера: %s"
l.sc_mutedead = "Замутить мёртвых"
l.sc_muteall = "Замутить всех"

//Радиалка
l.hg_posture = "Сменить Позу"
l.hg_resetposture = "Сбросить Позу"
l.hg_suicide = "Совершить суицид."
l.hg_unload = "Разрядить"
l.hg_attachments = "Аттачменты"
l.hg_drop = "Выкинуть"

//Аттачменты
l.att_menu_title = "Аттачменты"
l.att_sights = "Прицелы"
l.att_suppressors = "Глушители"
l.att_grips = "Рукоятки"
l.att_no_weapon = "Нет оружия в руках"
l.att_no_modifications = "Для этого оружия нет доступных модификаций"
l.att_category_unavailable = "Этот раздел недоступен для данного оружия"
l.att_remove_all = "Убрать всё"

// Остальное
l.inv_drop = "Выкинуть"
l.inv_roll = "Прокрутить барабан."
l.pulse_normal = "Нормальный пульс."
l.pulse_high = "Высокий пульс."
l.pulse_low = "Низкий пульс."
l.pulse_lowest = "Невозможно нащупать пульс."
l.pulse_no = "No pulse."
l.youre_hungry = "Ты голоден."
l.need_2_players = "Необходимо 2 игрока чтобы начать."

l.use_door = "Дверь"
l.ent_small_crate = "Малый ящик"
l.ent_medium_crate = "Средний ящик"
l.ent_large_crate = "Большой ящик"
l.ent_melee_crate = "Ящик с холодным оружием"
l.ent_weapon_crate = "Оружейный ящик"
l.ent_grenade_crate = "Ящик с гранатами"
l.ent_explosives_crate = "Ящик со взрывчаткой"
l.ent_medkit_crate = "Медицинский ящик"
l.use_ezammo = "Ящик с патронами"

l.use_time_bomb = "Бомба с таймером"
l.use_fragnade = "Ручная Граната"
l.use_firenade = "Зажигательная Граната"
l.use_sticknade = "Ручная граната с рукояткой"
l.use_dynam = "Динамит"
l.use_smokenade = "Дымовая граната"
l.use_signalnade = "Сигнальная шашка"
l.use_gasnade = "Газовая граната"
l.use_teargasnade = "Слезоточивая граната"
l.use_detpack = "Взрывной заряд"
l.use_buket = "Букет"
l.use_tnt = "Сатчель"
l.use_button = "Кнопка"

l.alive = "Живой"
l.unalive = "Мёртв"
l.unknown = "Неизвестно"
l.spectating = "Наблюдает"
l.spectator = "Наблюдатель"

l.cant_kick = "Ты не можешь пинать потому что твоя нога сломана."
l.leg_hurt = "Твоя нога болит."
l.uncon = "БЕЗ СОЗНАНИЯ"

l.heal = "Подлечить %s"
l.wep_delay = "Задержка: %s"
l.wep_dmg = "Урон: %s"
l.wep_force = "Сила: %s"

l.item_notexist = "Предмет не существует."

l.hasnt_pulse = "У него нет пульса."
l.otrub_but_he_live = "Он лежит в отключке, но он всё ещё жив."
l.has_pulse = "У него есть пульс."

l.r_close = "Нажми R чтобы закрыть."

//Локализация говна
l.ied_plant = "Заложить IED"
l.ied_metalprop = "в металлический проп"

l.weapon_bandage = "Бинт"
l.weapon_medkit_hg = "Аптечка"
l.weapon_painkillers_hg = "Болеутоляющие"
l.weapon_adrenaline = "Адреналин"

l.weapon_beton = "Съедобная арматура"
l.weapon_burger = "Бургер"
l.weapon_water_bottle = "Бутылка воды"
l.weapon_canned_burger = "Консервированный бургер"
l.weapon_milk = "Молоко"
l.weapon_chips = "Pringles"
l.weapon_energy_drink = "Monster Energy"

l.weapon_ied = "Взрывчатка"
l.ied_plant = "Заложить взрывчатку"
l.ied_metalprop = "в металлический проп"
l.weapon_hands = "Руки"

l.weapon_radio = "Рация"

l.weapon_handcuffs = "Стяжки"

l.weapon_pbat = "Полицейская Дубина"
l.weapon_sog = "SOG SEAL 2000"
l.weapon_crowbar_hg = "Монтировка"
l.weapon_fubar = "Фубар"
l.weapon_hammer = "Молоток"
l.weapon_hatchet = "Топорик"
l.weapon_axe = "Топор"
l.weapon_shovel = "Лопата"
l.weapon_melee = "Боевой Нож"
l.weapon_pipe = "Труба"
l.weapon_kitknife = "Кухонный Нож"
l.weapon_wrenchdedsex = "Гаечный ключ"
l.weapon_batmetal = "Металлическая Бита"  
l.weapon_machete = "Мачете"
l.weapon_slegdehammer = "Кувалда"

    // Настройки
    l.setting_fov = "FOV (Поле зрения)"
    l.setting_fov_desc = "Уменьшает, увеличивает поле зрения у игрока"
    l.setting_notify = "Отображание уведомления"
    l.setting_notify_desc = "Включает показ системные уведомления в левом верхнем углу"
    l.setting_cshs_camera = "Камера из Cat`s Homicide Server"
    l.setting_cshs_camera_desc = "Включает камеру в регдолле похожую на Cat`s homicide server"
    l.setting_casual = "Иконки при хватании руками"
    l.setting_casual_desc = "Включает/выключает отображение иконок при хватании руками."
    l.setting_multicore = "Многоядерный рендеринг"
    l.setting_multicore_desc = "Включает использование нескольких ядер процессора, FPS может заметно вырасти."
    l.setting_pixels = "Пиксельные текстуры"
    l.setting_pixels_desc = "Делает более пикселизированные текстуры."
    l.setting_ssao = "SSAO (aka Gomigrad-Shaders)"
    l.setting_ssao_desc = "Добавляет реалистичные мягкие тени в углах, стыках, впадинах и местах соприкосновения объектов."
    l.setting_3dskybox = "3D Skybox"
    l.setting_3dskybox_desc = "Включает/выключает отрисовку 3D скайбокса, может помочь с производительностью на слабых ПК."
    l.setting_ragdoll = "Регдолл (fake)"
    l.setting_ragdoll_desc = "Упасть в режим регдолла (тряпичной куклы)."
    l.setting_suicide = "Суицид"
    l.setting_suicide_desc = "Выстрелить в свою голову из оружия."
    l.setting_kick = "Пинок ногой"
    l.setting_kick_desc = "Ударить ногой."
    l.setting_header = "НАСТРОЙКИ"
    l.setting_tab_general = "Основное"
    l.setting_tab_graphics = "Графика"
    l.setting_tab_keyboard = "Клавиатура"
    l.setting_tab_skins = "Скины"
    l.setting_tab_account = "Аккаунт"
    l.setting_section_settings = "НАСТРОЙКИ"
    l.setting_section_personalization = "ПЕРСОНАЛИЗАЦИЯ"
    l.setting_voice_bg = "Фон голосового чата"
    l.setting_voice_bg_select = "Укажи ссылку на картинку"
    l.setting_voice_bg_choose = "Выбрать фон"
    l.setting_voice_bg_reset = "Сбросить фон"
    l.setting_key_none = "Нет"
    l.setting_skins_title = "Скины сервера"
    l.setting_skins_desc = "Скины будут применены в следующем раунде."
    l.setting_skins_set = "Установить"
    l.setting_skins_unset = "Убрать"
    l.setting_skins_selected = "Выбран"
    l.setting_skins_empty = "Нету скинов."
    l.setting_skins_applied_next = "Скин будет применен в следующем раунде."
    l.setting_tab_bg_title = "Фон TAB"
    l.setting_tab_bg_desc = "Укажи ссылку на картинку"
    l.setting_row_bg_title = "Фон строки TAB"
    l.setting_row_bg_desc = "Укажи ссылку на картинку"
    l.setting_apply = "ОК"
    l.setting_reset = "Сброс"

    l.mvp_soundkit = "Саундкит: %s"
    l.soundkit_Default = "Базовый"
    l.soundkit_HighNoon = "Feed Me - High Noon"
    l.soundkit_DashStar = "Knock2 - Dashstar*"
    l.soundkit_ChipzelYellowMagic = "Chipzel - Yellow Magic"


    // Подсказки
    l.setting_hint_notify = "Отключает/выключает уведомление на главном экране слева сверху, по умолчанию оно выключено."
    l.setting_hint_multicore = "Включает многоядерный рендеринг\n(По умолчанию включено)"
    l.setting_hint_pixels = "Включает пиксельные текстуры\n(По умолчанию выключено)"

    // ретеве
    l.rtv_header = "ГОЛОСУЙ ЗА КАРТУ"
    l.rtv_header_timer = "ГОЛОСУЙ ЗА КАРТУ - %s"
    l.rtv_hint = "ВЫБЕРИ КАРТУ ДЛЯ ГОЛОСОВАНИЯ"
    l.rtv_votes = "голос(ов)"
    l.rtv_time_up = "Время вышло!"
    l.rtv_random = "РАНДОМ"
    l.rtv_randomly = "СЛУЧАЙНАЯ"
    l.rtv_extend = "ЭКСТЕНД"
    l.rtv_continue = "ПРОДОЛЖИТЬ"


l.sc_jb_ranks_title = "Ранги полиции"
l.sc_jb_ranks_manage_hint = "ПКМ по игроку для управления рангами"
l.sc_jb_ranks_view_hint = "Обзор рангов"
l.sc_jb_ranks_search = "Введите ник игрока"
l.sc_jb_rank_remove = "Удалить ранг"
l.sc_jb_only = "Только в JailBreak"

l.sc_event_access_only = "Доступно только для doperator+"
l.sc_event_field_title = "Ивенты"
l.sc_event_field_description = "Описание"
l.sc_event_field_roles = "Роли"
l.sc_event_field_rules = "Правила"
l.sc_event_field_banner = "Баннер / Изображение"
l.sc_event_placeholder_title = "Название ивента"
l.sc_event_placeholder_description = "Описание ивента"
l.sc_event_placeholder_roles = "Роли ивента"
l.sc_event_placeholder_rules = "Правила ивента"
l.sc_event_placeholder_banner = "Баннер / Изображение"
l.sc_event_send = "Отправить ивент"
l.sc_event_loading_preview = "Загрузка предпросмотра..."
l.sc_event_preview_title_fallback = "Название ивента"
l.sc_event_preview_description_fallback = "Описание ивента"
l.sc_event_preview_host = "Организатор"
l.sc_event_preview_rules = "Правила"
l.sc_event_preview_rules_custom = "Пользовательские"
l.sc_event_preview_rules_default = "По умолчанию"
l.sc_event_preview_roles = "Роли"
l.sc_event_preview_roles_empty = "Нет доступных ролей"

hg.Localizations.ru = l
