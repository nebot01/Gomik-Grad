-- addons/hg/lua/hgamemode/z_roundsystem_1/dm/dm_sh.lua

table.insert(ROUND_LIST, "dm")

dm = dm or {}

dm.name = "Death Match"
dm.coolname = "Death Match"
dm.TeamBased = false -- В DM обычно каждый сам за себя, но если у вас командный DM, поставьте true

-- В классическом DM обычно нет команд (или есть одна общая "Игроки").
-- Если вы хотите "Все против всех", используйте одну команду.
dm.Teams = {
    [1] = {
        Name = "dm_players",
        Color = Color(200, 50, 50),
        Desc = "dm_desc" -- "Убей всех, останься в живых"
    }
}

-- На всякий случай, если используются поинты
hg.Points = hg.Points or {}
hg.Points.dm_players = hg.Points.dm_players or {}
hg.Points.dm_players.Color = Color(200, 50, 50)
hg.Points.dm_players.Name = "dm_players"