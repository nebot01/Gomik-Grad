-- "addons\\homigrad-core\\gamemodes\\homigrad_com\\gamemode\\modes\\homicide\\homicide_sh.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
table.insert(ROUND_LIST,"hmcd")

hmcd = hmcd or {}

hmcd.name = "Homicide"
hmcd.coolname = "Homicide"
hmcd.TeamBased = false

hmcd.SubTypes = {
    "gfz",
    "standard",
    "ww", -- ВАЙЛДВЕСТ!!!!!!!!
    "soe"
}

hg.Points.hmcd = hg.Points.hmcd or {}
hg.Points.hmcd.Color = Color(150,0,0)
hg.Points.hmcd.Name = "hmcd"

hg.Points.hmcd_law = hg.Points.hmcd_law or {}
hg.Points.hmcd_law.Color = Color(0, 27, 150)
hg.Points.hmcd_law.Name = "hmcd_law"

hmcd.Teams = {
    [1] = {Name = "hmcd_bystander",
           Color = Color(87,87,255),
           Desc = "hmcd_bystander_desc"
        },
    [2] = {Name = "hmcd_traitor",
       Color = Color(223,0,0),
       Desc = "hmcd_traitor_desc"
    },
    [3] = {Name = "hmcd_police",
       Color = Color(0,140,255),
       Desc = "hmcd_police_desc"
    },
}
