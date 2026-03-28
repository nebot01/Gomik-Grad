-- "addons\\homigrad-core\\gamemodes\\homigrad_com\\gamemode\\shared.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
AddCSLuaFile()
DeriveGamemode("sandbox")

GM.Name = "HOMIGRADCOM"
GM.Author = "0oa"
GM.Email = "N/A"
GM.Website = "N/A"
GM.TeamBased = true

hg = hg or {}

if SERVER then
	function hg.SafeCleanUpMap(keep)
		hg._cleanupUntil = hg._cleanupUntil or 0
		if hg._cleanupUntil > RealTime() then
			return false
		end
		hg._cleanupUntil = RealTime() + 1
		game.CleanUpMap(keep)
		return true
	end
end

include("homigrad_com/gamemode/loader.lua")
AddCSLuaFile("homigrad_com/gamemode/loader.lua")

hg.IncludeDir("homigrad")
GM.includeDir("homigrad_com/gamemode/game/")
GM.includeDir("homigrad_com/gamemode/modes/")
GM.includeDir("homigrad/")

function GM:CreateTeams()
	team.SetUp(1,"Terrorists",Color(255,0,0))
	team.SetUp(2,"Counter Terrorists",Color(0,0,255))
	team.SetUp(3,"Other",Color(0,255,0))

	team.MaxTeams = 3
end

function GM:OnReloaded()
	//table.Empty(ROUND_LIST)
	//hg.IncludeDir("homigrad_com/gamemode/modes")
end

local spawn = {"PlayerGiveSWEP", "PlayerSpawnEffect", "PlayerSpawnNPC", "PlayerSpawnObject", "PlayerSpawnProp", "PlayerSpawnRagdoll", "PlayerSpawnSENT", "PlayerSpawnSWEP", "PlayerSpawnVehicle"}

local valid = {
    owner = true,
    doperator = true,
    piar_agent = true,
    piaragent = true,
    ["piar-agent"] = true,
    dadmin = true,
    dsuperadmin = true,
    admin = true,
    superadmin = true
}

local function CanOpenQMenu(ply)
	if not IsValid(ply) then return false end

    -- === ДОБАВЛЕНО: Проверка на JB ранг ===
    -- Проверяем, является ли карта JB (функция jb.CanStart есть в вашем коде)
    if jb and jb.CanStart and jb.CanStart() then
        -- Если ранг 4 (Капитан) или выше -> разрешаем
        if ply:GetNWInt("JBPoliceRank", 0) >= 4 then
            return true
        end
        -- Если ранг меньше 4 и у игрока нет админки -> запрещаем (код пойдет дальше и проверит админку, но если вы хотите запретить даже админам без ранга, раскомментируйте return false ниже)
        -- return false 
    end
    -- =======================================

	if CLIENT and ply:GetNWBool("HG_CanOpenSpawnMenu", false) then return true end
	if GetGlobalBool("AccessSpawn", false) then return true end
	if ply:IsAdmin() then return true end
    
	local group = string.lower(tostring(ply:GetUserGroup() or ""))
	if valid[group] then return true end
    
	group = string.Replace(group, "_", "")
	group = string.Replace(group, "-", "")
	return valid[group] == true
end

local function BlockSpawn(ply)
	//do return true end	
	if game.SinglePlayer() or CanOpenQMenu(ply) then return true end

	return false
end

for _, v in ipairs(spawn) do
	hook.Add(v, "BlockSpawn", BlockSpawn)
end

hook.Add( "PlayerNoClip", "FeelFreeToTurnItOff", function( ply, desiredState )
	if ( desiredState == false ) then
		return true
	elseif ( ply:IsAdmin() ) then
		return true
	end

	return false
end )

if CLIENT then
	hook.Add( "PlayerBindPress", "PlayerBindPressExample", function( ply, bind, pressed )
		if ( string.find( bind, "+menu" ) ) then
		if ( not CanOpenQMenu(LocalPlayer())) then
			return true
		end
		end
	end )

	hook.Add( "SpawnMenuOpen", "SpawnMenuWhitelist", function()
		if ( not CanOpenQMenu(LocalPlayer())) then
			return false
		end
	end )
end

function OpposingTeam(team)
	if team == 1 then return 2 elseif team == 2 then return 1 end
end

function ReadPoint(point)
	if TypeID(point) == TYPE_VECTOR then
		return {point,Angle(0,0,0)}
	elseif type(point) == "table" then
		if type(point[2]) == "number" then
			point[3] = point[2]
			point[2] = Angle(0,0,0)
		end

		return point
	end
end

local team_GetPlayers = team.GetPlayers

function PlayersInGame()
    local newTbl = {}

    for i,ply in pairs(team_GetPlayers(1)) do newTbl[i] = ply end
    for i,ply in pairs(team_GetPlayers(2)) do newTbl[#newTbl + 1] = ply end
    for i,ply in pairs(team_GetPlayers(3)) do newTbl[#newTbl + 1] = ply end

    return newTbl
end
