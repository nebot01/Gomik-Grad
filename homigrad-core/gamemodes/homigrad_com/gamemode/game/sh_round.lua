-- "addons\\homigrad-core\\gamemodes\\homigrad_com\\gamemode\\game\\sh_round.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hg = hg or {}

function TableRound(name) return _G[name or ROUND_NAME] end
    
    CurrentRound = TableRound

function UpdateShit()
    ROUND_LIST = ROUND_LIST or {}
    ROUND_ACTIVE = ROUND_ACTIVE or false
    ROUND_NEXT = ROUND_NEXT or "hmcd"
    ROUND_NAME = ROUND_NAME or "hmcd"
    ROUND_ENDED = ROUND_ENDED or false
    ROUND_ENDSIN = ROUND_ENDSIN or 0

    hg.Points = hg.Points or {}
    
    hg.Points.box_spawn = hg.Points.box_spawn or {}
    hg.Points.box_spawn.Color = Color(150,0,0)
    hg.Points.box_spawn.Name = "box_spawn"
    
    hg.Points.box_spawn_small = hg.Points.box_spawn_small or {}
    hg.Points.box_spawn_small.Color = Color(139,69,19)
    hg.Points.box_spawn_small.Name = "box_spawn_small"
    
    hg.Points.box_spawn_medkit = hg.Points.box_spawn_medkit or {}
    hg.Points.box_spawn_medkit.Color = Color(0,255,0)
    hg.Points.box_spawn_medkit.Name = "box_spawn_medkit"
    
    hg.Points.box_spawn_weapon = hg.Points.box_spawn_weapon or {}
    hg.Points.box_spawn_weapon.Color = Color(255,255,0)
    hg.Points.box_spawn_weapon.Name = "box_spawn_weapon"
    
    hg.Points.box_spawn_medium = hg.Points.box_spawn_medium or {}
    hg.Points.box_spawn_medium.Color = Color(128,128,128)
    hg.Points.box_spawn_medium.Name = "box_spawn_medium"
    
    hg.Points.box_spawn_grenade = hg.Points.box_spawn_grenade or {}
    hg.Points.box_spawn_grenade.Color = Color(255,165,0)
    hg.Points.box_spawn_grenade.Name = "box_spawn_grenade"
    
    hg.Points.box_spawn_melee = hg.Points.box_spawn_melee or {}
    hg.Points.box_spawn_melee.Color = Color(128,0,128)
    hg.Points.box_spawn_melee.Name = "box_spawn_melee"
    
    hg.Points.box_spawn_explosives = hg.Points.box_spawn_explosives or {}
    hg.Points.box_spawn_explosives.Color = Color(255,0,0)
    hg.Points.box_spawn_explosives.Name = "box_spawn_explosives"
end

UpdateShit()

hook.Add("InitPostEntity","shit",function()
    UpdateShit()
end)
