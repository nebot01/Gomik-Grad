-- "addons\\homigrad-core\\gamemodes\\homigrad_com\\gamemode\\modes\\cs\\cs_sh.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
//table.insert(ROUND_LIST,"cs")

cs = cs or {}

cs.name = "Counter-Strike"
cs.coolname = "Counter-Strike"
cs.TeamBased = true

cs.Teams = {
    [1] = {Name = "cs_blue",
           Color = Color(0,0,255),
           Desc = "cs_blue_desc"
        },
    [2] = {Name = "cs_red",
       Color = Color(255,0,0),
       Desc = "cs_red_desc"
    }
}

hg.Points = hg.Points or {}

hg.Points.cs_bomb = hg.Points.cs_bomb or {}
hg.Points.cs_bomb.Color = Color(0,255,0)
hg.Points.cs_bomb.Name = "cs_bomb"