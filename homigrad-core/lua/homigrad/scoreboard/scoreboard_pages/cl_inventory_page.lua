-- "addons\\homigrad-core\\lua\\homigrad\\scoreboard\\scoreboard_pages\\cl_inventory_page.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local open = false
local panelka

local lply = LocalPlayer()

local weps = {}
local loot_queue = {} //куэуэ
local obrabotka_active = false
local cur = NULL
local Inventory = {}
local LZMADecompress = util.Decompress
local nRUInt = net.ReadUInt
local nRData = net.ReadData
local RefactoringJSONTable = util.JSONToTable
local ArmorSlots, ArmorSlotsLooting = {}, {}

local vguiCreate = vgui.Create
local surfaceSetMaterial = surface.SetMaterial
local surfaceDrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surfaceSetDrawColor = surface.SetDrawColor
local surfacePlaySound = surface.PlaySound

local function GetItemInSlotSafe(armorTable, slot)
    if JMod and isfunction(JMod.GetItemInSlot) then
        return JMod.GetItemInSlot(armorTable, slot)
    end
    if isfunction(GetItemInSlot) then
        return GetItemInSlot(armorTable, slot)
    end
    if istable(armorTable) and istable(armorTable.items) and JMod and istable(JMod.ArmorTable) then
        for id, armorData in pairs(armorTable.items) do
            local armorInfo = armorData and JMod.ArmorTable[armorData.name]
            if armorInfo and armorInfo.slots and armorInfo.slots[slot] then
                return id, armorData, armorInfo
            end
        end
    end
    return nil, nil, nil
end

local function GetLegacyArmorForSlot(ply, slot)
    if not IsValid(ply) or not istable(ply.armor) then return nil, nil end
    local armorDefTable = hg and hg.Armors
    if not istable(armorDefTable) then return nil, nil end

    local directArmorName = ply.armor[slot]
    if directArmorName and directArmorName ~= "NoArmor" then
        local directArmorDef = armorDefTable[directArmorName]
        if directArmorDef then
            return directArmorName, directArmorDef
        end
    end

    local placementAliases = {
        chest = {"torso"},
        abdomen = {"torso"},
        pelvis = {"torso"},
        waist = {"back"},
        eyes = {"face", "head"},
        mouthnose = {"face", "head"},
        ears = {"head", "face"},
        acc_head = {"head", "face"},
        acc_ears = {"head", "face"},
        leftforearm = {"larm"},
        rightforearm = {"rarm"},
        leftcalf = {"lleg"},
        rightcalf = {"rleg"},
        leftshoulder = {"larm", "torso"},
        rightshoulder = {"rarm", "torso"}
    }

    local wantedPlacements = placementAliases[slot] or {slot}
    for key, value in pairs(ply.armor) do
        local candidateName = nil
        local candidatePlacement = nil

        if isstring(key) and armorDefTable[key] then
            candidateName = key
            candidatePlacement = armorDefTable[key].Placement
        elseif isstring(value) and armorDefTable[value] then
            candidateName = value
            candidatePlacement = armorDefTable[value].Placement
        elseif isstring(key) then
            candidatePlacement = key
        end

        if candidateName and candidatePlacement then
            for _, placement in ipairs(wantedPlacements) do
                if candidatePlacement == placement then
                    return candidateName, armorDefTable[candidateName]
                end
            end
        end
    end

    return nil, nil
end



local function UpdateArmorSlots()
    local drawnItems = {} -- Таблица для хранения ID уже отрисованных предметов

    for _, slot in ipairs(ArmorSlots) do
        if IsValid(slot) then
            local armorName, armorDef = GetLegacyArmorForSlot(LocalPlayer(), slot.Slot)
            
            -- Логика для старой системы брони (не JMod)
            if armorDef then
                slot.ItemInfo = nil
                slot.ItemID = nil
                slot.Item = armorDef
                slot.ItemIcon = armorDef.Icon or "null"
                slot:Droppable("gomigrad_dnd")
                slot:Droppable("gomigrad_slot")
            else
                -- Логика для JMod брони
                local ItemID, ItemData, ItemInfo = GetItemInSlotSafe(LocalPlayer().EZarmor, slot.Slot)

                -- ГЛАВНОЕ ИСПРАВЛЕНИЕ:
                -- Если у предмета есть ID и мы его УЖЕ отрисовали в другом слоте...
                if ItemID and drawnItems[ItemID] then
                    -- ...то очищаем текущий слот, чтобы не было дубликата
                    slot.ItemInfo = nil
                    slot.ItemID = nil
                    slot.Item = nil
                    slot.ItemIcon = "null"
                    -- Важно: убираем возможность взаимодействия с этим "пустым" слотом
                else
                    -- Если это первый раз, когда мы видим этот предмет, запоминаем его ID
                    if ItemID then
                        drawnItems[ItemID] = true
                    end

                    -- Теперь настраиваем слот как обычно
                    if ItemInfo then
                        slot:Droppable("gomigrad_dnd")
                        slot:Droppable("gomigrad_slot")
                    else
                        slot.ItemInfo = nil
                        slot.ItemID = nil
                        slot.Item = nil
                    end

                    slot.ItemInfo = ItemInfo
                    slot.ItemID = ItemID
                    slot.ItemIcon = (ItemInfo and ItemInfo.ent and "entities/" .. ItemInfo.ent .. ".png" or "null")
                    slot.Item = (ItemInfo and {
                        Rarity = 3,
                        PrintName = ItemInfo.PrintName,
                        ClassName = ItemInfo.ent
                    } or nil)
                end
            end
        end
    end
end

net.Receive("HG_ContainerInfo", function()
    local container = net.ReadEntity()
    local inventory = net.ReadTable()
    
    if IsValid(container) and hg.islooting and hg.lootent == container then
        if IsValid(panelka) and IsValid(panelka.LootFrame) and panelka.LootFrame.Container == container then
        else
        end
    end
end)

net.Receive("GGrad_InformationInventory", function()
    Inventory = net.ReadTable()
end)

net.Receive("JMod_Inventory", function()
    timer.Simple(0.1, function()
        UpdateArmorSlots()
    end)
end)

net.Receive("HG_ArmorUpdate", function()
    timer.Simple(0.1, function()
        UpdateArmorSlots()
    end)
end)

surface.CreateFont("InvFont",{
        font = "Arial",
        size = 12 * ScrMul(),
        weight = 0,
        outline = true,
        shadow = true,
        antialias = false,
        additive = true,
    })

local BlackList = {
    ["weapon_hands"] = true,
    ["weapon_physgun"] = true,
    ["gmod_tool"] = true,
    ["gmod_camera"] = true,
}

local function GetWeps(ply)
    local weps = {}
    for _, wep in ipairs(ply:GetWeapons()) do
        if !BlackList[wep:GetClass()] and !table.HasValue(weps,wep) then
            table.insert(weps,wep)
        end
    end
    return weps
end

hook.Add("Think","ObrabotkaQueui",function()
    if LocalPlayer():Alive() and hg.ScoreBoard == 3 then
        if !table.IsEmpty(loot_queue) then
            obrabotka_active = true
            for _, item in ipairs(loot_queue) do
                if cur == NULL then
                    cur = item
                    table.remove(loot_queue,_)
                else
                    if IsValid(item) and item != cur then
                        item.LootIn = CurTime() + 0.3
                        if item.Item then
                            item.LootIn = CurTime() + 0.25 * (item.Item.Weight or 1)
                        end
                    end
                end
            end
        end
    end

    if cur and cur.LootIn and cur.LootIn < CurTime() then
        if cur.AutoLootToBackpack then
            cur:AutoLoot()
        else
            cur:Loot()
        end
        cur = NULL
    end

    if !open then
        obrabotka_active = false
        cur = NULL
    end
end)


local function CreateArmorSlot(parent,placement,posx,posy,size)
    local zalupa_konya = vguiCreate("hg_slot",parent)
    local button = zalupa_konya
    button:SetPos(posx,posy)
    button:SetSize(size * ScrMul(),size * ScrMul())
    button:SetText(" ")
    button.Slot = placement
    button.IsWhat = "ArmorSlot"

    function button:UpdateSlot()
        local armorName, armorDef = GetLegacyArmorForSlot(LocalPlayer(), self.Slot)
        if armorDef then
            self.ItemInfo = nil
            self.ItemID = nil
            self.Item = armorDef
            self.ItemIcon = armorDef.Icon or "null"
            self:Droppable("gomigrad_dnd")
            self:Droppable("gomigrad_slot")
            return
        end

        local ItemID, ItemData, ItemInfo = GetItemInSlotSafe(LocalPlayer().EZarmor, self.Slot)
        
        if ItemInfo then
            self:Droppable("gomigrad_dnd")
            self:Droppable("gomigrad_slot")
        else
            self.ItemInfo = nil
            self.ItemID = nil
            self.Item = nil
        end
        
        self.ItemInfo = ItemInfo
        self.ItemID = ItemID
        self.ItemIcon = (ItemInfo and ItemInfo.ent and "entities/" .. ItemInfo.ent .. ".png" or "null")
        self.Item = (ItemInfo and {
            Rarity = 3,
            PrintName = ItemInfo.PrintName,
            ClassName = ItemInfo.ent
        } or nil)
    end
    
    button:UpdateSlot()
    button.LootAnim = 0

    function button:Drop()
        if self.Item and not self.ItemInfo then
            self.isdropping = true
            self.dropsin = CurTime() + 0.4
            surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
            local dropSlot = (istable(self.Item) and self.Item.Placement) or self.Slot
            net.Start("hg drop armor")
                net.WriteString(dropSlot)
            net.SendToServer()
            self.Item = nil
            self.ItemIcon = "null"
            timer.Simple(0.2, function()
                UpdateArmorSlots()
            end)
            return
        end

        self.isdropping = true
        self.dropsin = CurTime() + 0.4
        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
        net.Start("JMod_Inventory")
            net.WriteInt(1, 8)
            net.WriteString(self.ItemID)
        net.SendToServer()
        for slot, _ in pairs(self.ItemInfo["slots"]) do
            for _, button_slot in ipairs(ArmorSlots) do
                if slot == button_slot.Slot then
                    button_slot.isdropping = true
                    button_slot.dropsin = CurTime() + 0.4
                    button_slot.Item = nil
                    button_slot.ItemIcon = "null"
                end
            end
        end
        self.Item = nil
        self.ItemIcon = "null"
        
        timer.Simple(0.2, function()
            UpdateArmorSlots()
        end)
    end

    function button:MoveToContainer()
        if not self.ItemInfo or not self.ItemID then return end
        if not hg.lootent or not IsValid(hg.lootent) then return end
        
        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
        
        local armorClass = self.ItemInfo.ent
        self.Item = nil
        self.ItemIcon = "null"
        
        if IsValid(panelka) and IsValid(panelka.LootFrame) then
            local lootFrame = panelka.LootFrame
            
            for i, slot in ipairs(lootFrame.Slots or {}) do
                if IsValid(slot) and (not slot.Item or slot.Item == "") then
                    slot.Item = {
                        ClassName = armorClass,
                        Rarity = 3,
                        PrintName = self.ItemInfo.PrintName or "Броня"
                    }
                    slot.IsArmor = true
                    slot.ItemIcon = "entities/" .. armorClass .. ".png"
                    break
                end
            end
        end
        
        if util.NetworkStringToID("HG_MoveArmorToContainer") > 0 then
            net.Start("HG_MoveArmorToContainer")
                net.WriteEntity(hg.lootent)
                net.WriteString(self.ItemID)
            net.SendToServer()
        end
        
        self.isdropping = true
        self.dropsin = CurTime() + 0.4
        
        timer.Simple(0.2, function()
            UpdateArmorSlots()
        end)
    end

    function button:Think()
        if (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)) and self:IsHovered() and input.IsMouseDown(MOUSE_LEFT) then
            if self.ItemInfo and self.ItemID then
                if not self.LastShiftMove or CurTime() - self.LastShiftMove > 0.3 then
                    self:MoveToContainer()
                    self.LastShiftMove = CurTime()
                end
            end
        end
    end

    table.insert(ArmorSlots, button)

    return button
end

concommand.Add("player_ezarmor_table", function()
    PrintTable(LocalPlayer().EZarmor)
end)

local function CreateArmorSlotOther(parent,placement,posx,posy,size, tbl)
    local zalupa_konya = vguiCreate("hg_slot",ScoreBoardPanel)
    local button = zalupa_konya
    button:SetPos(posx,posy)
    button:SetSize(size * ScrMul(),size * ScrMul())
    button:SetText(" ")
    button.Slot = placement
    local ItemID, ItemData, ItemInfo = GetItemInSlotSafe(tbl, placement)
    if ItemInfo then
        button:Droppable("gomigrad_dnd")
    end
    button.ItemData = ItemData
    button.ItemInfo = ItemInfo
    button.ItemID = ItemID
    button.ItemIcon = (ItemInfo and ItemInfo.ent and "entities/" .. ItemInfo.ent .. ".png" or "null")
    button.Item = {
        Rarity = ItemInfo and 3,
        PrintName = ItemInfo and ItemInfo.PrintName,
    }
    button.LootAnim = 0

    function button:Drop()
        -- ПРОВЕРКА: Нельзя дропнуть воздух
       if not self.Item and not self.ItemInfo then
            return 
        end

        -- Логика для старой брони
        if self.Item and not self.ItemInfo then
            self.isdropping = true
            self.dropsin = CurTime() + 0.4
            surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
            local dropSlot = (istable(self.Item) and self.Item.Placement) or self.Slot
            net.Start("hg drop armor")
                net.WriteString(dropSlot)
            net.SendToServer()
            self.Item = nil
            self.ItemIcon = "null"
            timer.Simple(0.2, function()
                UpdateArmorSlots()
            end)
            return
        end

        -- Логика для JMod брони
        self.isdropping = true
        self.dropsin = CurTime() + 0.4
        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
    
        -- Отправляем команду на сервер только если есть реальный ItemID
        if self.ItemID then
            net.Start("JMod_Inventory")
                net.WriteInt(1, 8)
                net.WriteString(self.ItemID)
            net.SendToServer()
        end
    
        -- Визуально очищаем все связанные слоты
        if self.ItemInfo and istable(self.ItemInfo["slots"]) then
            for slot_name, _ in pairs(self.ItemInfo["slots"]) do
               for _, button_slot in ipairs(ArmorSlots) do
                   if slot_name == button_slot.Slot then
                        button_slot.isdropping = true
                        button_slot.dropsin = CurTime() + 0.4
                        button_slot.Item = nil
                       button_slot.ItemIcon = "null"
                    end
                end
            end
        end
    
        self.Item = nil
        self.ItemIcon = "null"
    
        timer.Simple(0.2, function()
           UpdateArmorSlots()
        end)
    end

    function button:DoClick()
        self.isdropping = true
        self.dropsin = CurTime() + 0.4
        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
        if self.ItemData and self.ItemInfo then
            net.Start("GGrad_ActArmorBody")
                net.WriteInt(2, 4)
                net.WriteTable(self.ItemData)
                net.WriteTable(self.ItemInfo)
            net.SendToServer()
        end
        if self.ItemInfo and istable(self.ItemInfo) and self.ItemInfo["slots"] then
            for slot, _ in pairs(self.ItemInfo["slots"]) do
                for _, button_slot in ipairs(ArmorSlotsLooting) do
                    if slot == button_slot.Slot then
                        button_slot.isdropping = true
                        button_slot.dropsin = CurTime() + 0.4
                        button_slot.Item = nil
                        button_slot.ItemIcon = "null"
                    end
                end
            end
            self.Item = nil
            self.ItemIcon = "null"
        end
    end

    table.insert(ArmorSlotsLooting, button)

    return button
end

local function CoreDND(priem, por, isdrop)
    if isdrop then
        for k, v in pairs( por ) do
            if priem.IsMenu == "DropScreen" then
                v:Drop()
            end
        end
    end
end

local function SlotDND(priem, por, isdrop)
    if isdrop then
        for k, v in pairs( por ) do
            if priem.IsMenu == "DropScreen" then
                v:Drop()
            end
            if v.IsWhat == "Pizdabol" and priem.IsWhat == "Tatarin" then 
                if v.Item and v.Item.ClassName == "ent_jack_gmod_ezammo" then
                    LocalPlayer():ChatPrint("Нельзя перемещать ящик с патронами в инвентарь!")
                    continue
                end
                v.ActionBPaEz = true 
            end
            if v.IsWhat == "Pizdabol" and priem.IsWhat == "ContainerSlot" then
                if v.MoveToContainer then
                    v:MoveToContainer()
                end
                continue
            end
            if priem.IsWhat == "Pizdabol" then v.ActionWithBackpack = true end
            if v.IsWhat == "Pizdabol" and priem.IsWhat == "Pizdabol" then v.ActionWithBPaBP = true end
            v:Refresh()
            v.Transfer = priem
        end
    end
end

local function FindWeaponInSlots(weapon)
    if not Inventory or not Inventory["Slots"] then return nil end
    for _, wep in pairs(Inventory["Slots"]) do
        if wep == weapon then
            return _
        end
    end
end

local function FindWeaponInBPSlots(weapon)
    if not Inventory or not Inventory["Backpack"] or not Inventory["Backpack"]["ISlots"] then return nil end
    for _, wep in pairs(Inventory["Backpack"]["ISlots"]) do
        if wep.Index == weapon then
            return _
        end
    end
end

local function CreateLocalInvSlot(Parent,SlotsSize,PosI)
    local InvButton = vguiCreate("hg_slot",Parent)
    InvButton:SetSize(SlotsSize, SlotsSize)
    InvButton:SetPos(SlotsSize * (PosI - 1),0)
    InvButton:Dock(LEFT)
    InvButton:SetText(" ")
    InvButton.IsWhat = "Tatarin"
    InvButton.index = PosI
    InvButton.LowerText = ""
    InvButton.ActionWithBackpack = false
    InvButton.ActionWithBPaBP = false
    InvButton.LowerFont = "HS.10"
    InvButton:Receiver("gomigrad_slot", SlotDND)

    function InvButton:Drop()
        -- ФИКС: Проверяем, есть ли вообще оружие в слоте перед тем как пытаться его выкинуть
        if not IsValid(self.Weapon) then 
            return 
        end

        if self.IsDropping then
            return
        end
        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
        self.DropIn = CurTime() + 0.2
        self.IsDropping = true
    end

    function InvButton:MoveToContainer()
        
        if not self.Weapon or not IsValid(self.Weapon) then return end
        if not hg.lootent or not IsValid(hg.lootent) then return end
    
        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
    
        local weaponClass = self.Weapon:GetClass()
        self.Weapon = nil
        self.Item = nil
    
        if IsValid(panelka) and IsValid(panelka.LootFrame) then
            local lootFrame = panelka.LootFrame
        
            for i, slot in ipairs(lootFrame.Slots or {}) do
                if IsValid(slot) and (not slot.Item or slot.Item == "") then
                    local wepData = weapons.Get(weaponClass)
                    if wepData then
                        slot.Item = wepData
                        slot.Weapon = wepData
                        break
                    end
                end
            end
        end
    
        if util.NetworkStringToID("HG_MoveToContainer") > 0 then
            net.Start("HG_MoveToContainer")
                net.WriteEntity(hg.lootent)
                net.WriteString(weaponClass)
            net.SendToServer()
        end
    end

    function InvButton:Refresh()
        self.AnimRefresh = true
    end

    function InvButton:Think()
        if (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)) and self:IsHovered() and input.IsMouseDown(MOUSE_LEFT) then
            if self.Weapon and IsValid(self.Weapon) then
                if not self.LastShiftMove or CurTime() - self.LastShiftMove > 0.3 then
                    self:MoveToContainer()
                    self.LastShiftMove = CurTime()
                end
            end
        end

        if self.Weapon != "" then
            self:Droppable("gomigrad_slot")
            self:Droppable("gomigrad_dnd")
        end
    end

    function InvButton:SubPaint(w, h)
        local fade = open_fade or 1
        local weps = {}
        for _, wep in ipairs(LocalPlayer():GetWeapons()) do
            if not BlackList[wep:GetClass()] and !table.HasValue(weps, wep) then
                table.insert(weps, wep)
            end
        end

        draw.SimpleText("Shift + ПКМ - быстро переместить в контейнер", "HS.12", w/2, -10, Color(255,255,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

        if IsValid(self.Weapon) and self.Weapon:GetOwner() ~= LocalPlayer() then
            self.Weapon = nil
        end

        if self:IsHovered() and self.Weapon and fastloot then
            self:MoveToContainer()
        end
        local liveWeapon = weps[self.index]
        if IsValid(liveWeapon) and (not IsValid(self.Weapon) or self.Weapon ~= liveWeapon) then
            self.Weapon = liveWeapon
            self.Item = liveWeapon
        elseif not IsValid(self.Weapon) then
            self.Weapon = nil
            self.Item = nil
        end


        for i, w in ipairs(weps) do
            if not self.Weapon then continue end
            if PosI == i and (not IsValid(self.Weapon) or (IsValid(self.Weapon) and self.Weapon:GetOwner() != LocalPlayer())) then
                if w == NULL then
                    continue
                end
                if not Parent[PosI].Weapon then continue end
                if not IsValid(Parent[PosI].Weapon) then continue end
                if Parent[PosI].Weapon.GetOwner then
                    if Parent[PosI] and Parent[PosI].Weapon == nil or Parent[PosI] and Parent[PosI].Weapon != nil and Parent[PosI].Weapon:GetOwner() != LocalPlayer() then
                        Parent[PosI].Weapon = w

                        if Parent[PosI + 1] and Parent[PosI + 1].Weapon == w or IsValid(Parent[PosI + 1].Weapon) and Parent[PosI + 1].Weapon:GetOwner() != LocalPlayer() then
                            Parent[PosI + 1].Weapon = nil
                        end

                        if Parent[PosI - 1] then
                            local prevWeapon = Parent[PosI - 1].Weapon
                            if prevWeapon == nil or (IsValid(prevWeapon) and prevWeapon:GetOwner() != LocalPlayer()) then
                                Parent[PosI - 1].Weapon = w
                            end
                        end
                    end
                end
            end
        end

        self.Item = self.Weapon

        self:LoadPaint()

        if IsValid(self.Weapon) and self.Weapon.GetClass then
            local weaponClass = self.Weapon:GetClass()
            local weaponData = weapons.Get(weaponClass)
            if weaponData then
                surface.SetDrawColor(255, 255, 255, 255 * fade)
                hg.DrawWeaponSelection(weaponData,
                    Parent:GetX() + SlotsSize * (PosI - 1), Parent:GetY(),
                    self:GetWide(), self:GetTall(), 0)
            end
        end
    end
    
    return InvButton
end

local function GetSafeMaterial(path, fallback)
    local material = Material(path)
    if material:IsError() then
        return Material(fallback or "null")
    end
    return material
end

local function CreateBackpackLocalInvSlot(Parent, PosI)
    local InvButton = vguiCreate("hg_slot", Parent)
    InvButton:SetSize(50, 50)
    InvButton:SetText(" ")
    InvButton.IsWhat = "Pizdabol"
    InvButton.index = PosI
    InvButton.ActionWithBackpack = false
    InvButton.ActionWithBPaBP = false
    InvButton.LowerText = ""
    InvButton.LowerFont = "HS.10"
    InvButton:Receiver("gomigrad_slot", SlotDND)

    function InvButton:Drop()
        if self.IsDropping then
            return
        end
        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
        self.DropIn = CurTime() + 0.2
        self.IsDropping = true
    end

    function InvButton:MoveToContainer()
        local itemData = self.Item
        local slotIndex = self.index
    
        if not itemData or not itemData.ClassName then 
            return 
        end

        if not hg.lootent or not IsValid(hg.lootent) then 
            return 
        end

        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")

        local itemClass = itemData.ClassName

        self.Weapon = nil
        self.Item = nil
        self.ItemIcon = "null"
        self.LastItemData = nil

        if IsValid(panelka) and IsValid(panelka.LootFrame) then
            local lootFrame = panelka.LootFrame
        
            for i, slot in ipairs(lootFrame.Slots or {}) do
                if IsValid(slot) and (not slot.Item or slot.Item == "") then
                    if itemData.IsEntity then
                        slot.Item = {
                            ClassName = itemClass,
                            Rarity = 2,
                            PrintName = itemData.PrintName or itemClass,
                            IsEntity = true
                        }
                        slot.IsEntity = true
                        if itemClass == "ent_jack_gmod_ezammo" then
                            slot.ItemIcon = "ez_resource_icons/ammo.png"
                        else
                            if itemClass then
                                local testMaterial = Material("entities/" .. itemClass .. ".png")
                                if not testMaterial:IsError() then
                                    slot.ItemIcon = "entities/" .. itemClass .. ".png"
                                else
                                    slot.ItemIcon = "null"
                                end
                            else
                                slot.ItemIcon = "null"
                            end
                        end
                    else
                        local wepData = weapons.Get(itemClass)
                        if wepData then
                            slot.Item = wepData
                            slot.Weapon = wepData
                            if itemClass then
                                local testMaterial = Material("entities/" .. itemClass .. ".png")
                                if not testMaterial:IsError() then
                                    slot.ItemIcon = "entities/" .. itemClass .. ".png"
                                else
                                    slot.ItemIcon = "null"
                                end
                            else
                                slot.ItemIcon = "null"
                            end
                        end
                    end
                break
            end
        end
    end

    net.Start("HG_MoveFromBackpackToContainer")
        net.WriteEntity(hg.lootent)
        net.WriteUInt(slotIndex, 7)
        net.WriteString(itemClass)
    net.SendToServer()
end

    function InvButton:Refresh()
        self.AnimRefresh = true
    end

    function InvButton:Think()
        if (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)) and self:IsHovered() and input.IsMouseDown(MOUSE_LEFT) then
            if self.Item and self.Item.ClassName then
                if not self.LastShiftMove or CurTime() - self.LastShiftMove > 0.3 then
                    self:MoveToContainer()
                    self.LastShiftMove = CurTime()
                end
            end
        end

        if self.Weapon and not table.IsEmpty(self.Weapon) then
            self:Droppable("gomigrad_slot")
            self:Droppable("gomigrad_dnd")
        end
    end

    function InvButton:SubPaint(w, h)
        local fade = open_fade or 1
        if not Inventory or not Inventory["Backpack"] or not Inventory["Backpack"]["ISlots"] then return end
        
        local itemData = Inventory["Backpack"]["ISlots"][self.index]
        
        if itemData ~= self.LastItemData then
            if itemData and itemData ~= "" then
                if itemData.IsEntity then
                    self.Weapon = itemData
                    self.Item = itemData
                    
                    if itemData.Class == "ent_jack_gmod_ezammo" then
                        self.ItemIcon = "ez_resource_icons/ammo.png"
                    else
                        if itemData.Class then
                            local testMaterial = Material("entities/" .. itemData.Class .. ".png")
                            if not testMaterial:IsError() then
                                self.ItemIcon = "entities/" .. itemData.Class .. ".png"
                            else
                                self.ItemIcon = "null"
                            end
                        else
                            self.ItemIcon = "null"
                        end
                    end
                    
                    self.Item = {
                        ClassName = itemData.Class,
                        Rarity = 2,
                        PrintName = itemData.PrintName or itemData.Class,
                        IsEntity = true
                    }
                else
                    self.Weapon = weapons.Get(itemData.Class) or {}
                    self.Item = weapons.Get(itemData.Class) or {}
                    if itemData.Class then
                        local testMaterial = Material("entities/" .. itemData.Class .. ".png")
                        if not testMaterial:IsError() then
                            self.ItemIcon = "entities/" .. itemData.Class .. ".png"
                        else
                            self.ItemIcon = "null"
                        end
                    else
                        self.ItemIcon = "null"
                    end
                end
            else
                self.Weapon = {}
                self.Item = {}
                self.ItemIcon = "null"
            end
            self.LastItemData = itemData
        end

        draw.SimpleText("Shift + ЛКМ - быстро переместить в контейнер", "HS.10", w/2, -5, Color(255,255,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

        self:LoadPaint()

        if self.Weapon and type(self.Weapon) == "table" and self.Weapon.ClassName then
            local weaponData = weapons.Get(self.Weapon.ClassName)
            if weaponData then
                local x,y = self:GetPos()
                surface.SetDrawColor(255, 255, 255, 255 * fade)
                hg.DrawWeaponSelection(weaponData, Parent:GetX() + x, Parent:GetY() + y, self:GetWide(), self:GetTall(), 0)
            end
        end
    end
    
    return InvButton
end

concommand.Add("getinventorytable", function()
    PrintTable(Inventory)
end)

hook.Add("Think", "ArmorSlotsUpdate", function()
    if open and IsValid(panelka) then
        if (panelka.NextArmorUpdate or 0) < CurTime() then
            UpdateArmorSlots()
            panelka.NextArmorUpdate = CurTime() + 0.5
        end
    end
end)

hook.Add("HUDPaint","InventoryPage",function()

    if not hg.ScoreBoard then return end
    if not IsValid(ScoreBoardPanel) then 
        open = false 
        if !table.IsEmpty(loot_queue) then table.Empty(loot_queue) end 
        if IsValid(panelka) then
            panelka:Remove()
        end
        return 
    end
    if !LocalPlayer():Alive() and hg.ScoreBoard == 3 then
        hg.ScoreBoard = 1
        if IsValid(ScoreBoardPanel) then
            ScoreBoardPanel:Remove()
        end
    end
    if open and hg.islooting then
        if input.IsKeyDown(KEY_W) or input.IsKeyDown(KEY_D) or input.IsKeyDown(KEY_S) or input.IsKeyDown(KEY_A) then
            ScoreBoardPanel:Remove()
            hg.islooting = false
            hg.lootent = nil
        end
    end
    if hg.ScoreBoard == 3 and not open then

        table.Empty(weps)

        if IsValid(panelka) then
            panelka:Remove()
        end

        open = true

        local MainFrame = vguiCreate("hg_frame",ScoreBoardPanel)
        MainFrame:ShowCloseButton(false)
        MainFrame:SetTitle(" ")
        MainFrame:SetDraggable(false)
        MainFrame:SetSize(ScrW(), ScrH())
        MainFrame.IsMenu = "DropScreen"
        MainFrame:Receiver("gomigrad_dnd", CoreDND)
        //MainFrame:SetMouseInputEnabled(false)
        MainFrame.NoDraw = true
        panelka = MainFrame

        local CenterX = ScoreBoardPanel:GetWide() / 2
        //MainFrame:Center()

        local daun1 = 0

        local lootent = NULL

        function MainFrame:SubPaint(w,h)
            local fade = open_fade or 1
            daun1 = LerpFT(0.3,daun1,(hg.islooting and 1 or 0))

            if hg.islooting and lootent:IsRagdoll() then
                lootent = hg.lootent
                draw.SimpleText(lootent:GetNWString("PlayerName"),"HS.18",w/2,h/1.85,Color(255,255,255,255 * daun1 * fade),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            elseif hg.islooting and IsValid(hg.lootent) and hg.lootent != NULL then
                lootent = hg.lootent
                draw.SimpleText(hg.GetPhrase(lootent:GetClass()),"HS.18",w/2,h/1.85,Color(255,255,255,255 * daun1 * fade),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            elseif !hg.islooting and lootent != NULL then
                if !lootent:IsRagdoll() then
                    draw.SimpleText(hg.GetPhrase(lootent:GetClass()),"HS.18",w/2,h/1.85,Color(255,255,255,255 * daun1 * fade),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText(lootent:GetNWString("PlayerName"),"HS.18",w/2,h/1.85,Color(255,255,255,255 * daun1 * fade),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                end
            end


            for _, a in ipairs(MainFrame:GetChildren()) do
                if isentity(a) then
                    continue
                end
                a:SetAlpha(255 * open_fade + 0.05)

                if #a:GetChildren() > 0 then
                    for _, a in ipairs(a:GetChildren()) do
                        if isentity(a) then
                            continue
                        end

                        a:SetAlpha(255 * open_fade + 0.05)
                    end
                end
            end
        end

        local SlotsSize = 75 * math.min(ScrW()/1920,ScrH()/1080)

        local InvFrame = vguiCreate("hg_frame",MainFrame)
        InvFrame:ShowCloseButton(false)
        InvFrame:SetTitle(" ")
        InvFrame:SetDraggable(false)
        InvFrame:SetSize(ScrW() / 3.2, SlotsSize)
        InvFrame:Center()
        InvFrame:SetPos(InvFrame:GetX(),ScrH()-SlotsSize)
        InvFrame:DockMargin(0,0,0,0)
        InvFrame:DockPadding(0,0,0,0)
        if Inventory["Backpack"] then
            if Inventory["Backpack"]["Slots"] > 0 then
                local BackpackFrame = vguiCreate("hg_frame",MainFrame)
                BackpackFrame:ShowCloseButton(false)
                BackpackFrame:SetTitle(" ")
                BackpackFrame:SetDraggable(false)
                BackpackFrame:Center()
                BackpackFrame:DockMargin(0,0,0,0)
                BackpackFrame:DockPadding(0,0,0,0)
                function BackpackFrame:Think()
                    if Inventory["Backpack"]["Slots"] <= 0 then
                        self:Remove()
                    end
                end
                local b_x, b_y, y_grid = 0, 0, 1
                for index, value in pairs(Inventory["Backpack"]["ISlots"]) do
                    local SlotBackpack = CreateBackpackLocalInvSlot(BackpackFrame, index)
                    SlotBackpack.LootAnim = 0
                    SlotBackpack.Weapon = weapons.Get(value.Class) or {}
                    SlotBackpack.Item = weapons.Get(value.Class) or {}
                    SlotBackpack:SetPos(b_x,b_y)
                    SlotBackpack.Pos = {
                        x = b_x,
                        y = b_y,
                    }
                    b_x = b_x + 50

                    if b_x + 50 > 300 then
                        b_x = 0
                        b_y = b_y + 50
                        y_grid = y_grid + 1
                    end

                    BackpackFrame:SetSize(300, 50*y_grid)
                    BackpackFrame:SetPos((ScrW()-180)-300,ScrH()-50*y_grid)

                    SlotBackpack.index = index
                    function SlotBackpack:LoadPaint()
                        local fade = open_fade or 1
                        local w,h = self:GetSize()
                        if not table.IsEmpty(self.Weapon) and self.DropIn then
                            if self.DropIn < CurTime() then
                                self.IsDropping = false
                                self.DropIn = nil
                                net.Start("GGrad_DropItemBackpack")
                                    net.WriteInt(self.index, 7)
                                net.SendToServer()
                            end
                        end
                        if self.AnimRefresh then
                            surfaceSetDrawColor(225,225,225, 255 * fade)

                            self.LootAnim = LerpFT(0.2,self.LootAnim,self.LootAnim + 100)

                            surfaceSetMaterial(Material("homigrad/vgui/loading.png"))
                            surfaceDrawTexturedRectRotated(w/2,h/2,w/1.75,h/1.75,self.LootAnim)
                            if self.LootAnim >= 350 then
                                surfacePlaySound("homigrad/vgui/panorama/rotate_weapon_0"..math.random(1,3)..".wav")
                                self.AnimRefresh = false
                                net.Start("GGrad_InventoryMoveSlot")
                                    net.WriteInt(self.index, 7)
                                    net.WriteInt(self.Transfer.index, 7)
                                    net.WriteBool(self.ActionWithBackpack)
                                    net.WriteBool(self.ActionWithBPaBP)
                                    net.WriteBool(self.ActionBPaEz)
                                    net.WriteEntity(self.Weapon)
                                net.SendToServer()
                                self.ActionWithBackpack = false
                                self.Transfer = nil
                            end
                        end
                    end
                end
            end
        end

        local ModelFrame = vguiCreate("DModelPanel",MainFrame)
        ModelFrame:SetSize(ScrW()/3.0, ScrH()/1.5)
        ModelFrame:SetCamPos(Vector(-50, 0, 0)) 
        ModelFrame:SetLookAt(Vector(0, 40, 50)) 
        ModelFrame:SetFOV(55)
        ModelFrame:MoveTo(1, 100, 0, 0, 1)

        ModelFrame:SetModel(LocalPlayer():GetModel())
        local ent = ModelFrame:GetEntity()
        if IsValid(ent) then
            ent:SetSkin(LocalPlayer():GetSkin())
    
            for i = 0, LocalPlayer():GetNumBodyGroups() - 1 do
                ent:SetBodygroup(i, LocalPlayer():GetBodygroup(i))
            end
        end 
        ModelFrame:GetEntity().GetPlayerColor = function()
            return LocalPlayer():GetPlayerColor()
        end

        local zaebal = 1
        local mdls = {
        }

        function ModelFrame:Paint( w, h )
            local fade = open_fade or 1
            local SetDrawColor,DrawRect = surfaceSetDrawColor,surface.DrawRect

            SetDrawColor(25,25,25,170 * fade)
            DrawRect(w/4,0,w/2,h)


            local ply = LocalPlayer()

            local armor_torso = ply.armor.torso
            local armor_head = ply.armor.head
            local armor_face = ply.armor.face
            local armor_back = ply.armor.back

            if ( !IsValid( self.Entity ) ) then return end

            local x, y = self:LocalToScreen( 0, 0 )

            self:LayoutEntity( self.Entity )

            local ang = self.aLookAngle
            if ( !ang ) then
                ang = ( self.vLookatPos - self.vCamPos ):Angle()
            end

            -- //local xshit,yshit = self:ScreenToLocal(gui.MouseX(),gui.MouseY() - h/2)

            cam.Start3D( self.vCamPos + Vector(3,0,0), ang, self.fFOV, x, y, w, h, 5, self.FarZ )

            render.SetBlend(fade)

            render.SuppressEngineLighting( true )
            render.SetLightingOrigin( self.Entity:GetPos() )
            render.ResetModelLighting( self.colAmbientLight.r / 255, self.colAmbientLight.g / 255, self.colAmbientLight.b / 255 )
            render.SetColorModulation( self.colColor.r / 255, self.colColor.g / 255, self.colColor.b / 255 )

            for i = 0, 6 do
                local col = self.DirectionalLight[ i ]
                if ( col ) then
                    render.SetModelLighting( i, col.r / 255, col.g / 255, col.b / 255 )
                end
            end

            self:DrawModel()

            local ent = self.Entity

            ent.IsIcon = true
            ent.NoRender = true

            for placement, armor in pairs(ply.armor) do
                    local tbl = hg.Armors[armor]
                    if tbl != nil then

                        if mdls[placement] == nil then
                            mdls[placement] = ClientsideModel(tbl.Model,RENDERGROUP_OTHER)
                            mdls[placement]:SetNoDraw( true )
                            mdls[placement]:SetIK( false )
                            mdls[placement]:SetParent(ent)
                            mdls[placement]:AddEffects(EF_BONEMERGE)
                            mdls[placement].DontOptimise = true
                        end

                        if mdls[placement]:GetModel() != tbl.Model then
                            mdls[placement]:Remove()
                            mdls[placement] = nil
                        end

                        if mdls[placement] == nil then
                            continue
                        end
                        
                        -- Также устанавливаем прозрачность для брони
                        render.SetBlend(fade)
                        mdls[placement]:DrawModel()

                        local pos,ang = ent:GetBonePosition(ent:LookupBone(tbl.Bone))

                        ang:RotateAroundAxis(ang:Forward(),tbl.Ang[1])
                        ang:RotateAroundAxis(ang:Up(),tbl.Ang[2])
                        ang:RotateAroundAxis(ang:Right(),tbl.Ang[3])

                        if !hg.IsFemale(ent) or !tbl.FemPos then
                            pos = pos + ang:Forward() * tbl.Pos[1]
                            pos = pos + ang:Right() * tbl.Pos[2]
                            pos = pos + ang:Up() * tbl.Pos[3]
                        else
                            pos = pos + ang:Forward() * tbl.FemPos[1]
                            pos = pos + ang:Right() * tbl.FemPos[2]
                            pos = pos + ang:Up() * tbl.FemPos[3]
                        end

                        -- //ent:SetPredictable(true)
                        -- //ent:SetupBones()

                        mdls[placement]:SetBodygroup(0,1)
                        mdls[placement]:SetParent(ent)

                        mdls[placement]:SetRenderOrigin(pos)
                        mdls[placement]:SetRenderAngles(ang)

                        mdls[placement]:SetModelScale(((hg.IsFemale(ent) and tbl.FemScale) and tbl.FemScale or tbl.Scale) or 1,0)

                        mdls[placement]:SetPos(pos)
                        mdls[placement]:SetAngles(ang)

                        -- //mdls[placement]:SetPredictable(true)
                        -- //mdls[placement]:SetupBones()

                        -- //ent.armor_render[placement]:DrawModel()
                    else
                        -- //if ent.armor_render[placement] != nil then
                        -- //    ent.armor_render[placement]:Remove()
                        -- //    ent.armor_render[placement] = nil
                        -- //end
                    end
                end

            render.SuppressEngineLighting( false )
            
            -- Сбрасываем прозрачность
            render.SetBlend(1)
            cam.End3D()

            self.LastPaint = RealTime()

        end

        local daun_rubat = 1
        function ModelFrame:PostDrawModel(ent)
            if not IsValid(ent) then return end
            local lp = LocalPlayer()
            if IsValid(lp) then
                ent.EZarmor = lp.EZarmor
            end
            if JMod and isfunction(JMod.ArmorPlayerModelDraw) then
                JMod.ArmorPlayerModelDraw(ent, nil)
            end
        end

        function ModelFrame:LayoutEntity(ent)
            if not IsValid(ent) then return end

            ent.IsIcon = true
            local xshit = gui.MouseX()

            if !rot_suka then
                rot_suka = 0  
            end

            if self:IsHovered() and input.IsMouseDown(MOUSE_LEFT) then
                if not isDragging then
                    isDragging = false
                    xshit_old = xshit
                end

                local delta = (xshit - xshit_old or 0) * 0.75
                rot_suka = rot_suka + delta
                xshit_old = xshit
            else
                isDragging = false
            end

            local pos = ent:GetBonePosition(ent:LookupBone("ValveBiped.Bip01_Pelvis")) or ent:GetPos()
            self:SetCamPos( Vector( 75, 0, 50 ) )
            self:SetLookAt(Vector(0, 0, pos.z))

            zalupa_konya = LerpFT(0.9, zalupa_konya or 90, rot_suka)
            ent:SetAngles(Angle(0, zalupa_konya, 0))  
        end

        ArmorSlots = {}
        
        -- Настройки
        local BaseSize = 64          -- Размер иконки
        local RealSize = BaseSize * ScrMul() 
        local Padding = 10 * ScrMul() -- Расстояние между слотами
        
        -- Размеры окна
        local FrameW = ModelFrame:GetWide()
        local FrameH = ModelFrame:GetTall()
        
        -- СПИСОК СЛОТОВ (Убрал 'eyes', оставил 4 основных)
        -- head = Шлем
        -- mouthnose = Маска/Лицо
        -- chest = Броник/Разгрузка
        -- back = Рюкзак
        local slotsRow = { "head", "mouthnose", "chest", "back" }
        
        -- Считаем ширину чтобы было по центру
        local totalRowWidth = (#slotsRow * RealSize) + ((#slotsRow - 1) * Padding)
        local startX = (FrameW / 2) - (totalRowWidth / 2) 
        local startY = FrameH - RealSize - (30 * ScrMul()) -- Отступ снизу

        for i, slotName in ipairs(slotsRow) do
            local currentX = startX + (i - 1) * (RealSize + Padding)
            
            -- Создаем слоты
            -- Для mouthnose делаем иконку чуть меньше или такой же (тут одинаковые)
            CreateArmorSlot(ModelFrame, slotName, currentX, startY, BaseSize)
        end
        

        local SlotsSize = 75 * ScrMul()

        local JModFrame = vguiCreate("hg_frame",MainFrame)
        JModFrame:ShowCloseButton(false)
        JModFrame:SetTitle(" ")
        JModFrame:SetDraggable(false)
        JModFrame:SetSize(SlotsSize, SlotsSize)
        JModFrame:Center()
        JModFrame:SetPos(JModFrame:GetX() - SlotsSize * 6.5,ScrH()-SlotsSize)
        JModFrame:DockMargin(0,0,0,0)
        JModFrame:DockPadding(0,0,0,0)
        JModFrame.NoDraw = true

        local SlotsSize = 75 * ScrMul()

        //CreateLootFrame({[1] = "weapon_ak74"})
        for _, wep in ipairs(LocalPlayer():GetWeapons()) do
            if !BlackList[wep:GetClass()] and !table.HasValue(weps,wep) then
                table.insert(weps,wep)
            end
        end


        --[[function slotjmod:LoadPaint()
            local w,h = self:GetSize()
            if LocalPlayer():GetNWEntity("JModEntInv") and self.DropIn then
                if self.DropIn < CurTime() then
                    self.IsDropping = false
                    self.DropIn = nil
                    net.Start("hg drop jmod")
                    net.SendToServer()
                end
            end
            if self.IsDropping then
                surfaceSetDrawColor(225,225,225)
                self.LootAnim = LerpFT(0.2,self.LootAnim,self.LootAnim + 100)

                surfaceSetMaterial(Material("homigrad/vgui/loading.png"))
                surfaceDrawTexturedRectRotated(w/2,h/2,w/1.75,h/1.75,self.LootAnim)
            end

        end--]]
        local invSlots = Inventory and Inventory["Slots"] or {}
        local maxSlots = math.max(8, table.Count(invSlots))
        for index = 1, maxSlots do
                local value = invSlots[index]
                local Slot = CreateLocalInvSlot(InvFrame,SlotsSize,index)
                InvFrame[index] = Slot
                Slot.LootAnim = 0
                Slot.Weapon = IsValid(value) and value or nil
                Slot.Item = IsValid(value) and value or nil
                function Slot:DoRightClick()
                    if self.Weapon then
                        local Menu = DermaMenu(true,self)

                        Menu:SetPos(input.GetCursorPos())
                        Menu:MakePopup()

                            --[[Menu:AddOption(hg.GetPhrase("inv_drop"),function()
                                self:Drop()
                            end)--]]
                            Menu:AddOption(hg.GetPhrase("Разрядить"),function()
                                LocalPlayer():ConCommand("hg_unload")
                            end)
                            Menu:AddOption(hg.GetPhrase("Поменять позу держание"),function()
                                LocalPlayer():ConCommand("hg_change_posture")
                            end)
                            Menu:AddOption(hg.GetPhrase("Сбросить позу держание"),function()
                                LocalPlayer():ConCommand("hg_change_posture 1")
                            end)

                            if self.Weapon.Roll and self.Weapon == LocalPlayer():GetActiveWeapon() then
                                Menu:AddOption(hg.GetPhrase("inv_roll"),function()
                                    RunConsoleCommand("hg_roll")
                                end)
                            end
                        end
                end

                function Slot:LoadPaint()
                    local fade = open_fade or 1
                    local w,h = self:GetSize()
                    if self.Weapon and IsValid(self.Weapon) and self.DropIn then
                        if self.DropIn < CurTime() then
                            self.IsDropping = false
                            self.DropIn = nil
                            net.Start("DropItemInv")
                            net.WriteString(self.Weapon:GetClass())
                            net.SendToServer()
                        end
                    end
                    if self.IsDropping then
                        surfaceSetDrawColor(225,225,225, 255 * fade)

                        self.LootAnim = LerpFT(0.2,self.LootAnim,self.LootAnim + 100)

                        surfaceSetMaterial(Material("homigrad/vgui/loading.png"))
                        surfaceDrawTexturedRectRotated(w/2,h/2,w/1.75,h/1.75,self.LootAnim)
                    end
                    if self.AnimRefresh then
                        surfaceSetDrawColor(225,225,225, 255 * fade)

                        self.LootAnim = LerpFT(0.2,self.LootAnim,self.LootAnim + 100)

                        surfaceSetMaterial(Material("homigrad/vgui/loading.png"))
                        surfaceDrawTexturedRectRotated(w/2,h/2,w/1.75,h/1.75,self.LootAnim)
                        if self.LootAnim >= 350 then
                            surfacePlaySound("homigrad/vgui/panorama/rotate_weapon_0"..math.random(1,3)..".wav")
                            self.AnimRefresh = false
                            net.Start("GGrad_InventoryMoveSlot")
                                net.WriteInt(self.index, 7)
                                net.WriteInt(self.Transfer.index, 7)
                                net.WriteBool(self.ActionWithBackpack)
                                net.WriteBool(self.ActionWithBPaBP)
                                net.WriteBool(self.ActionBPaEz)
                                net.WriteEntity(self.Weapon)
                            net.SendToServer()
                            self.ActionWithBackpack = false
                            self.Transfer = nil
                        end
                    end
                end
            end
    elseif hg.ScoreBoard != 3 then
        hg.islooting = false
        if !table.IsEmpty(loot_queue) then table.Empty(loot_queue) end
        
        open = false
        if IsValid(panelka) then
            panelka:Remove()
        end
    end
end)

function CreateLootSlot(Parent,SlotsSize,PosI,ent,xisarmor)
    local InvButton = vguiCreate("hg_slot",Parent)
    InvButton:SetSize(SlotsSize, SlotsSize)
    InvButton:SetPos(Parent:GetWide()/2,0)
    InvButton:Center()
    InvButton:SetText(" ")
    InvButton.Container = ent

    InvButton:Receiver("gomigrad_slot", function(priem, por, isdrop)
        if isdrop then
            for k, v in pairs(por) do
                if not v or not IsValid(v) then continue end
                
                if v.Weapon and IsValid(v.Weapon) then
                    surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
                    
                    local weaponClass = v.Weapon:GetClass()
                    
                    v.Weapon = nil
                    v.Item = nil
                    
                    local lootFrame = Parent
                    if IsValid(lootFrame) then
                        for i, slot in ipairs(lootFrame:GetChildren()) do
                            if IsValid(slot) and slot.Container == ent and (not slot.Item or slot.Item == "") then
                                local wepData = weapons.Get(weaponClass)
                                if wepData then
                                    slot.Item = wepData
                                    slot.Weapon = wepData
                                end
                                break
                            end
                        end
                    end
                    
                    if util.NetworkStringToID("HG_MoveToContainer") > 0 then
                        net.Start("HG_MoveToContainer")
                            net.WriteEntity(ent)
                            net.WriteString(weaponClass)
                        net.SendToServer()
                    end
                    
                elseif v.ItemInfo and v.ItemID then
                    surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
                    
                    local armorClass = v.ItemInfo.ent
                    local itemID = v.ItemID
                    
                    v.Item = nil
                    v.ItemIcon = "null"
                    
                    local lootFrame = Parent
                    if IsValid(lootFrame) then
                        for i, slot in ipairs(lootFrame:GetChildren()) do
                            if IsValid(slot) and slot.Container == ent and (not slot.Item or slot.Item == "") then
                                slot.Item = {
                                    ClassName = armorClass,
                                    Rarity = 3,
                                    PrintName = v.ItemInfo.PrintName or "Броня"
                                }
                                slot.IsArmor = true
                                slot.ItemIcon = "entities/" .. armorClass .. ".png"
                                break
                            end
                        end
                    end
                    
                    if util.NetworkStringToID("HG_MoveArmorToContainer") > 0 then
                        net.Start("HG_MoveArmorToContainer")
                            net.WriteEntity(ent)
                            net.WriteString(itemID)
                        net.SendToServer()
                    end
                    
                    v.isdropping = true
                    v.dropsin = CurTime() + 0.4
                    
                    timer.Simple(0.2, function()
                        UpdateArmorSlots()
                    end)
                else
                    print("[HG_Inventory] Drop attempt with invalid item - Weapon:", v.Weapon, "ItemInfo:", v.ItemInfo, "ItemID:", v.ItemID)
                end
            end
        end
    end)

    function InvButton:DoRightClick()
    end

    function InvButton:AutoLootToBackpack()
        if self.Looting then return end
        if not self.Item then return end

        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
        self.Looting = true
        self.LootIn = CurTime() + 0.4 * (self.Item.Weight or 1)
    
        self.AutoLootToBackpack = true
    
        table.insert(loot_queue, self)
    end

    function InvButton:AutoLoot()
        if not self.Item then
            self.Looting = false
            self.LootAnim = 0
            return
        end

        local itemClass = self.Item.ClassName or self.Item.Class
        local isArmor = self.IsArmor or false

        if util.NetworkStringToID("HG_AutoLoot") > 0 then
            net.Start("HG_AutoLoot")
                net.WriteEntity(ent)
                net.WriteString(itemClass)
                net.WriteBool(isArmor)
            net.SendToServer()
        else
            net.Start("hg loot")
                net.WriteEntity(ent)
                net.WriteString(itemClass)
            net.SendToServer()
        end

        self.Item = nil
        self.ItemIcon = "null"
        
        surfacePlaySound("homigrad/vgui/panorama/inventory_new_item_scroll_01.wav")
        
        if isArmor then
            timer.Simple(0.2, function()
                UpdateArmorSlots()
            end)
        end
    end

    function InvButton:Loot_Take()
        if self.Looting then return end
        if not self.Item then return end
        
        if Inventory and Inventory["Backpack"] and Inventory["Backpack"]["Slots"] > 0 then
            self:AutoLootToBackpack()
        else
            surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
            self.Looting = true
            self.LootIn = CurTime() + 0.4 * (self.Item.Weight or 1)
            table.insert(loot_queue, self)
        end
    end

    function InvButton:Loot()
        if not self.Item then
            self.Looting = false
            self.LootAnim = 0
            return
        end

        if self.Item.ishgwep then
            surfacePlaySound("homigrad/vgui/panorama/rotate_weapon_0"..math.random(1,3)..".wav")
        else
            surfacePlaySound("homigrad/vgui/panorama/inventory_new_item_scroll_01.wav")
        end

        local name = self.Item.ClassName or self.Item.Class

        net.Start("hg loot")
            net.WriteEntity(ent)
            net.WriteString(name)
        net.SendToServer()
        self.Item = nil
        self.ItemIcon = "null"
        
        if self.IsArmor then
            timer.Simple(0.2, function()
                UpdateArmorSlots()
            end)
        end
    end

    function InvButton:SubPaint(w,h)
        local fade = open_fade or 1
        if not xisarmor then
            if self.Item then
                surface.SetDrawColor(255, 255, 255, 255 * fade)
                hg.DrawWeaponSelection(weapons.Get(self.Item.ClassName or self.Item.Class),
                Parent:GetX() + SlotsSize * (PosI - 1), Parent:GetY(),
                self:GetWide(), self:GetTall(), 0)

                if self.Looting then
                    self.LootAnim = LerpFT(0.2,self.LootAnim or 0,(self.LootAnim or 0) + 100)

                    surfaceSetDrawColor(255,255,255, 255 * fade)
                    surfaceSetMaterial(Material("homigrad/vgui/loading.png"))
                    surfaceDrawTexturedRectRotated(w/2,h/2,w/1.75,h/1.75,self.LootAnim)
                end
            end
        else
            if self.Item then
                if self.Looting then
                    self.LootAnim = LerpFT(0.2,self.LootAnim or 0,(self.LootAnim or 0) + 100)

                    surfaceSetDrawColor(255,255,255, 255 * fade)
                    surfaceSetMaterial(Material("homigrad/vgui/loading.png"))
                    surfaceDrawTexturedRectRotated(w/2,h/2,w/1.75,h/1.75,self.LootAnim)
                end
            end
        end
    end

    function InvButton:DoClick()
        self:Loot_Take()
    end

    function InvButton:Think()
        local w,h = Parent:GetSize()

        if self:IsHovered() and fastloot then
            self:Loot_Take()
        end

        self:SetWide(SlotsSize * Parent.CurSize)
        self:SetX((w / 2) * (1-Parent.CurSize) + ((SlotsSize * (PosI - 1))) * Parent.CurSize)
    end

    return InvButton
end

concommand.Add('gays', function(ply)
    PrintTable(GetWeps(ply))
end)

function CreateJModFrame(weps,ent1,ent)
    local MainFrame = panelka
    local SlotsSize = 75

    if !IsValid(ScoreBoardPanel) then
        return
    end

    local CenterX = ScoreBoardPanel:GetWide() / 2

    hg.islooting = true

    local LootFrame = vguiCreate("hg_frame",MainFrame)
    LootFrame:ShowCloseButton(false)
    LootFrame:SetTitle(" ")
    LootFrame:SetDraggable(false)
    LootFrame:SetSize(SlotsSize, SlotsSize)
    LootFrame:Center()
    LootFrame:SetX(LootFrame:GetX() - SlotsSize * (table.IsEmpty(weps) and 0 or 5))
    //LootFrame:SetPos(CenterX - ScrW()/6.4,ScrH()/2.14)
    LootFrame:DockMargin(0,0,0,0)
    LootFrame:DockPadding(0,0,0,0)
    LootFrame.NoDraw = true
    LootFrame.CurSize = 0.3
    LootFrame.CurSizeTarget = 1

    function LootFrame:Think()
        local targetsize = LootFrame.CurSizeTarget

        if !hg.islooting then
            LootFrame.CurSizeTarget = 0
            if self.CurSize <= 0.01 then
                self:Remove()
            end
        end
        self.CurSize = LerpFT((hg.islooting and 0.15 or 0.3),self.CurSize,targetsize)
        //self:Center()
        //self:SetWide(SlotsSize * slotsamt * self.CurSize)
    end

end

function cGui_Center(w, h)
    return (ScrW() - w) / 2, (ScrH() - h) / 2
end

local function ObjectIsNull(object)
    return not object or object == NULL or type(object) ~= "Panel" or tostring(object) == "Panel [NULL]"
end

function CreateLootFrame(weps, slotsamt, ent, ezarmor_table)
    local MainFrame = panelka
    local SlotsSize = 75
    weps = istable(weps) and weps or {}
    ezarmor_table = istable(ezarmor_table) and ezarmor_table or {}
    slotsamt = tonumber(slotsamt) or #weps or 0
    if slotsamt < 1 then
        slotsamt = 1
    end
    
    if MainFrame then
        if IsValid(MainFrame.LootFrame) then
            MainFrame.LootFrame:Remove()
        end
    end

    if table.IsEmpty(weps) and IsValid(ent) and ent:GetNWEntity("JModEntInv", Entity(-1)) != NULL then
        return
    end

    if !IsValid(ScoreBoardPanel) then
        return
    end

    hg.islooting = true
    local LootFrame = vguiCreate("hg_frame", MainFrame)
    LootFrame:ShowCloseButton(false)
    LootFrame:SetTitle(" ")
    LootFrame:SetDraggable(false)
    LootFrame:SetSize(SlotsSize * slotsamt, SlotsSize)
    LootFrame:SetPos(cGui_Center(SlotsSize * slotsamt, SlotsSize))
    LootFrame:DockMargin(0,0,0,0)
    LootFrame:DockPadding(0,0,0,0)
    LootFrame.NoDefault = true
    LootFrame.CurSize = 0
    LootFrame.Container = ent
    if ObjectIsNull(MainFrame) then 
    return end
    
    MainFrame.LootFrame = LootFrame
    local SlotsSizeSix = 64 * ScrMul()
    local SlotsSizeFive = 50 * ScrMul()

    ArmorSlotsLooting = {}
    local defx, defy, chestdefx = 2.9, 3.2, 64*4

    if not table.IsEmpty(ezarmor_table) then
        CreateArmorSlotOther(MainFrame,"acc_head",ScrW()/defx,ScrH()/defy,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"head",ScrW()/defx,(ScrH()/defy)+64,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"eyes",(ScrW()/defx)+64,(ScrH()/defy)+64,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"mouthnose",(ScrW()/defx)+64,ScrH()/defy,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"ears",(ScrW()/defx)+(64*2),ScrH()/defy,64,ezarmor_table)

        CreateArmorSlotOther(MainFrame,"acc_ears",(ScrW()/defx)+(64*2),ScrH()/defy+64,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"abdomen",(ScrW()/defx)+(64*3),ScrH()/defy,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"waist",(ScrW()/defx)+(64*3),ScrH()/defy+64,64,ezarmor_table)



        CreateArmorSlotOther(MainFrame,"chest",(ScrW()/defx)+chestdefx,ScrH()/defy,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"back",(ScrW()/defx)+chestdefx,(ScrH()/defy)+64,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"pelvis",(ScrW()/defx)+(chestdefx+64),(ScrH()/defy)+64,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"acc_chestrig",(ScrW()/defx)+(chestdefx+64),ScrH()/defy,64,ezarmor_table)

        CreateArmorSlotOther(MainFrame,"leftthigh",(ScrW()/defx)+(chestdefx+128),ScrH()/defy,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"leftcalf",(ScrW()/defx)+(chestdefx+128),ScrH()/defy+64,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"rightthigh",(ScrW()/defx)+(chestdefx+192),ScrH()/defy,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"rightcalf",(ScrW()/defx)+(chestdefx+192),ScrH()/defy+64,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"leftshoulder",(ScrW()/defx)+(chestdefx+256),ScrH()/defy,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"leftforearm",(ScrW()/defx)+(chestdefx+256),ScrH()/defy+64,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"rightshoulder",(ScrW()/defx)+(chestdefx+320),ScrH()/defy,64,ezarmor_table)
        CreateArmorSlotOther(MainFrame,"rightforearm",(ScrW()/defx)+(chestdefx+320),ScrH()/defy+64,64,ezarmor_table)

    end

    local targetsize = 1

    function LootFrame:Think()
        local w,h = self:GetSize()
        if hg.islooting then
            targetsize = 1
        else
            targetsize = 0
            if self.CurSize <= 0.01 then
                self:Remove()
            end
        end
        self.CurSize = LerpFT((hg.islooting and 0.15 or 0.3),self.CurSize,targetsize)
        self:Center()
    end

    LootFrame.Slots = {}
    for i = 1, slotsamt do
        local item = weps[i]
        
        if not item then
            local Slot = CreateLootSlot(LootFrame, SlotsSize, i, ent, false)
            LootFrame.Slots[i] = Slot
            Slot.Item = nil
            Slot.ItemIcon = "null"
            continue
        end

        local is_armor = false
        local is_entity = false

        if isstring(item) then
            if string.StartsWith(item, "ent_jack_gmod_ezarmor") or item == "ent_jack_gmod_ezammo" or item == "flashlight" then
                is_armor = true
            elseif string.StartsWith(item, "ent_") then
                is_entity = true
            end
        end

        local Slot = CreateLootSlot(LootFrame, SlotsSize, i, ent, is_armor)
        LootFrame.Slots[i] = Slot
        
        Slot.IsEntity = is_entity
        
        if not is_armor and not is_entity then
            local wep = weapons.Get(item)
            Slot.Item = wep
            if item then
                local testMaterial = Material("entities/" .. item .. ".png")
                if not testMaterial:IsError() then
                    Slot.ItemIcon = "entities/" .. item .. ".png"
                else
                    Slot.ItemIcon = "null"
                end
            else
                Slot.ItemIcon = "null"
            end
        elseif item == "ent_jack_gmod_ezammo" then
            Slot.Item = {
                ClassName = "ent_jack_gmod_ezammo",
                Rarity = 2,
                PrintName = "Ящик патронов",
            }
            Slot.ItemIcon = "ez_resource_icons/ammo.png"
        elseif is_entity then
            Slot.IsEntity = true
            Slot.Item = {
                ClassName = item,
                Rarity = 2,
                PrintName = item,
                IsEntity = true
            }
            if item then
                local testMaterial = Material("entities/" .. item .. ".png")
                if not testMaterial:IsError() then
                    Slot.ItemIcon = "entities/" .. item .. ".png"
                else
                    Slot.ItemIcon = "null"
                end
            else
                Slot.ItemIcon = "null"
            end
        else
            local armorKey = FindArmorKeyByEnt(item)
            local armorInfo = armorKey and JMod and JMod.ArmorTable and JMod.ArmorTable[armorKey]
            Slot.IsArmor = true
            Slot.Item = {
                ClassName = item,
                Rarity = 3,
                PrintName = (armorInfo and armorInfo.PrintName) or item,
            }
            if item then
                local testMaterial = Material("entities/" .. item .. ".png")
                if not testMaterial:IsError() then
                    Slot.ItemIcon = "entities/" .. item .. ".png"
                else
                    Slot.ItemIcon = "null"
                end
            else
                Slot.ItemIcon = "null"
            end
        end
    end
    
    function LootFrame:UpdateSlots(newInventory)
        for i, slot in ipairs(self.Slots) do
            if IsValid(slot) then
                slot:Remove()
            end
        end
        self.Slots = {}
        
        for i = 1, #newInventory do
            local item = newInventory[i]
            
            if not item then
                local Slot = CreateLootSlot(self, SlotsSize, i, ent, false)
                self.Slots[i] = Slot
                Slot.Item = nil
                Slot.ItemIcon = "null"
                continue
            end

            local is_armor = false
            local is_entity = false

            if isstring(item) then
                if string.StartsWith(item, "ent_jack_gmod_ezarmor") or item == "ent_jack_gmod_ezammo" or item == "flashlight" then
                    is_armor = true
                elseif string.StartsWith(item, "ent_") then
                    is_entity = true
                end
            end

            local Slot = CreateLootSlot(self, SlotsSize, i, ent, is_armor)
            self.Slots[i] = Slot
            
            Slot.IsEntity = is_entity
            
            if not is_armor and not is_entity then
                local wep = weapons.Get(item.ClassName or item)
                Slot.Item = wep

                if item.Ammo then
                    Slot.Item.Ammo = item.Ammo
                end
                if item then
                    local testMaterial = Material("entities/" .. item .. ".png")
                    if not testMaterial:IsError() then
                        Slot.ItemIcon = "entities/" .. item .. ".png"
                    else
                        Slot.ItemIcon = "null"
                    end
                else
                    Slot.ItemIcon = "null"
                end
            elseif item == "ent_jack_gmod_ezammo" then
                Slot.Item = {
                    ClassName = item,
                    Rarity = 2,
                    PrintName = "Ящик патронов",
                    IsEntity = true
                }
                Slot.ItemIcon = "ez_resource_icons/ammo.png"
            elseif is_entity then
                Slot.IsEntity = true
                Slot.Item = {
                    ClassName = item,
                    Rarity = 2,
                    PrintName = item,
                    IsEntity = true
                }
                if item then
                    local testMaterial = Material("entities/" .. item .. ".png")
                    if not testMaterial:IsError() then
                        Slot.ItemIcon = "entities/" .. item .. ".png"
                    else
                        Slot.ItemIcon = "null"
                    end
                else
                    Slot.ItemIcon = "null"
                end
            else
                local armorKey = FindArmorKeyByEnt(item)
                local armorInfo = armorKey and JMod and JMod.ArmorTable and JMod.ArmorTable[armorKey]
                Slot.IsArmor = true
                Slot.Item = {
                    ClassName = item,
                    Rarity = 3,
                    PrintName = (armorInfo and armorInfo.PrintName) or item,
                }
                if item then
                    local testMaterial = Material("entities/" .. item .. ".png")
                    if not testMaterial:IsError() then
                        Slot.ItemIcon = "entities/" .. item .. ".png"
                    else
                        Slot.ItemIcon = "null"
                    end
                else
                    Slot.ItemIcon = "null"
                end
            end
        end
    end
end

hook.Add("Think", "PickupEntityWithAltE", function()
    if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
    
    if (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)) and input.IsKeyDown(KEY_E) then
        if (LocalPlayer().NextAltEPickup or 0) > CurTime() then return end
        LocalPlayer().NextAltEPickup = CurTime() + 0.5
        
        local activeWeapon = LocalPlayer():GetActiveWeapon()
        if not IsValid(activeWeapon) or activeWeapon:GetClass() ~= "weapon_hands" then return end
        
        local trace = LocalPlayer():GetEyeTrace()
        if not IsValid(trace.Entity) then return end
        
        if trace.Entity:GetClass() ~= "ent_jack_gmod_ezammo" then return end
        if trace.HitPos:Distance(LocalPlayer():GetShootPos()) > 100 then return end
        
        if not Inventory or not Inventory["Backpack"] or Inventory["Backpack"]["Slots"] <= 0 then
            LocalPlayer():ChatPrint("Вы не можете положить тяжелый ящик в карман, нужен рюкзак!")
            return
        end
        
        local freeSlots = 0
        for i = 1, #Inventory["Backpack"]["ISlots"] do
            if Inventory["Backpack"]["ISlots"][i] == "" then
                freeSlots = freeSlots + 1
            end
        end
        
        if freeSlots <= 0 then
            LocalPlayer():ChatPrint("В рюкзаке нет свободного места!")
            return
        end
        
        net.Start("HG_PickupEntToBackpack")
            net.WriteEntity(trace.Entity)
        net.SendToServer()
        
        surfacePlaySound("homigrad/vgui/item_scroll_sticker_01.wav")
    end
end)