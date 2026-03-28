-- lua/homigrad/scoreboard/sh_cases_config.lua

HG_CaseConfig = HG_CaseConfig or {}
HG_CaseConfig.Cases = {}

-- [[ НАСТРОЙКИ РЕДКОСТИ ]]
HG_CaseConfig.Rarities = {
    ["common"] = { color = Color(150, 150, 150), name = "Обычное" },
    ["uncommon"] = { color = Color(100, 200, 255), name = "Необычное" },
    ["rare"] = { color = Color(50, 50, 255), name = "Редкое" },
    ["legendary"] = { color = Color(255, 215, 0), name = "Легендарное" },
    ["ancient"] = { color = Color(255, 50, 50), name = "Древнее" },
}

-- [[ ФУНКЦИЯ ДОБАВЛЕНИЯ КЕЙСА ]]
function HG_CaseConfig.AddCase(id, data)
    HG_CaseConfig.Cases[id] = data
end

-- ==========================================
-- НАСТРОЙКА КЕЙСОВ НИЖЕ
-- ==========================================
HG_CaseConfig.AddCase("classic_case", {
    Name = "Normal case",
    Desc = "Выпадают модельки мутантов и фурри",
    Model = "models/kali/props/cases/hard case a.mdl", -- Модель самого кейса
    Price = 25, -- Цена открытия
    Items = {
        -- { Model = "путь", Name = "Имя", Rarity = "тип", Chance = число (чем больше, тем выше шанс) }
        { Model = "models/Keith3201/Ligeia/Ligeia_pm.mdl", Name = "Ligeia", Rarity = "uncommon", Chance = 50 },
        { Model = "models/vedatys/orangutan.mdl", Name = "Monke", Rarity = "rare", Chance = 10 },
        { Model = "models/player/darkness8163.mdl", Name = "Protogen", Rarity = "rare", Chance = 10 },
        { Model = "models/gfreakman/gordonf.mdl", Name = "Gordon", Rarity = "uncommon", Chance = 50 },
        { Model = "models/gfreakman/gordonf_cit.mdl", Name = "Citizen Gordon", Rarity = "common", Chance = 100 },
        { Model = "models/player/pissbaby.mdl", Name = "Piss Baby", Rarity = "uncommon", Chance = 80 },
    }
})