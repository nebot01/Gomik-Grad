-- lua/homigrad/scoreboard/scoreboard_pages/cl_model_selector_page.lua

-- Подключаем конфиг
if file.Exists("homigrad/scoreboard/sh_cases_config.lua", "LUA") then
    include("homigrad/scoreboard/sh_cases_config.lua")
end

-- [[ ШРИФТЫ ]]
surface.CreateFont("HG_Title", { font = "Roboto", size = 30, weight = 800, extended = true })
surface.CreateFont("HG_Subtitle", { font = "Roboto", size = 18, weight = 500, extended = true })
surface.CreateFont("HG_Button", { font = "Roboto", size = 20, weight = 600, extended = true })
surface.CreateFont("HG_ItemName", { font = "Roboto", size = 22, weight = 500, extended = true })
surface.CreateFont("HG_Price", { font = "Roboto", size = 24, weight = 700, extended = true })
surface.CreateFont("HG_Notification", { font = "Roboto", size = 26, weight = 700, extended = true })

-- Если шрифта из твоего скрипта нет, создадим аналог
surface.CreateFont("hg_HomicideSmalles", { font = "Roboto", size = 20, weight = 600, extended = true })

-- [[ ПЕРЕМЕННЫЕ ОСНОВНОГО МЕНЮ ]]
local open_main = false
local panel_main = nil
local active_tab = "cases" 
local current_page_panel = nil -- Текущая активная панель с контентом
local is_animating_tab = false -- Блокировка нажатий во время анимации

local PlayerInventory = {}
local InventoryLoaded = false

-- Переменные Гардероба
local SelectedModelPath = nil
local SelectedSkin = 0
local SelectedBodygroups = {}
local SelectedColor = Vector(1, 1, 1)

-- Переменные Кейсов
local SelectedCaseID = nil
local is_case_opening = false 

-- Переменные Транзакций
local SelectedTransferPlayer = nil

-- Звук наведения
local hoverSound = "homigrad/vgui/csgo_ui_contract_type2.wav"

-- [[ УТИЛИТЫ ]]
local blur = Material("pp/blurscreen")
local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end

local function ApplyColorToModel(ent, colVector)
    if not IsValid(ent) then return end
    if ent.SetPlayerColor then ent:SetPlayerColor(colVector) end
    ent.GetPlayerColor = function() return colVector end
end

-- ==============================================
-- СИСТЕМА УВЕДОМЛЕНИЙ (ВМЕСТО ЧАТА)
-- ==============================================
local TopNotifications = {}

local function AddTopNotification(text)
    table.insert(TopNotifications, {
        text = text,
        time = CurTime(),
        duration = 4,
        y = -60
    })
    surface.PlaySound("homigrad/vgui/contract_type2.wav")
end

hook.Add("HUDPaint", "HG_DrawTopNotifications", function()
    local scrW = ScrW()
    local baseY = 50 
    
    for i, notif in ipairs(TopNotifications) do
        if CurTime() > notif.time + notif.duration then
            table.remove(TopNotifications, i)
            continue
        end

        local targetY = baseY + ((i-1) * 70)
        notif.y = Lerp(FrameTime() * 10, notif.y, targetY)

        surface.SetFont("HG_Notification")
        local tw, th = surface.GetTextSize(notif.text)
        local boxW = tw + 100
        local boxH = th + 20
        local boxX = (scrW / 2) - (boxW / 2)

        draw.RoundedBox(0, boxX, notif.y, boxW, boxH, Color(30, 30, 35, 250))
        draw.SimpleText(notif.text, "HG_Notification", scrW / 2, notif.y + (boxH/2), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- ==============================================
-- ОБРАБОТЧИКИ СЕТИ (ИНВЕНТАРЬ И КЕЙСЫ)
-- ==============================================

net.Receive("HG_SendInventory", function() 
    PlayerInventory = net.ReadTable() 
    InventoryLoaded = true 
end)

-- Открытие Кейса (Рулетка)
local function OpenCaseRoulette(caseID, winnerModel, winnerName, isNew)
    is_case_opening = true
    local caseData = HG_CaseConfig.Cases[caseID]
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH()); frame:MakePopup(); frame:SetTitle(""); frame:ShowCloseButton(false)
    frame.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 245)) end

    local centerY = ScrH() / 2
    local itemSize = 250; local itemGap = 10; local totalItems = 50; local winnerIndex = 40
    local items = {}
    local caseItems = caseData.Items

    for i = 1, totalItems do
        if i == winnerIndex then
            local rarColor = HG_CaseConfig.Rarities["legendary"].color
            for _, v in pairs(caseItems) do
                if v.Model == winnerModel then
                    local r = HG_CaseConfig.Rarities[v.Rarity]
                    if r then rarColor = r.color end
                end
            end
            table.insert(items, {model = winnerModel, name = winnerName, rarity = rarColor})
        else
            local rndItem = table.Random(caseItems)
            local rarColor = Color(100,100,100)
            local r = HG_CaseConfig.Rarities[rndItem.Rarity]
            if r then rarColor = r.color end
            table.insert(items, {model = rndItem.Model, name = rndItem.Name, rarity = rarColor})
        end
    end

    local ViewPort = vgui.Create("DPanel", frame)
    ViewPort:SetSize(ScrW(), itemSize + 40); ViewPort:SetPos(0, centerY - (itemSize/2) - 20)
    ViewPort.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20))
        draw.RoundedBox(0, w/2 - 2, 0, 4, h, Color(255, 200, 0, 200))
    end

    local Tape = vgui.Create("DPanel", ViewPort)
    local tapeWidth = (itemSize + itemGap) * totalItems
    Tape:SetSize(tapeWidth, itemSize); Tape:SetPos(0, 20); Tape.Paint = function() end

    for i, item in ipairs(items) do
        local p = vgui.Create("DPanel", Tape)
        p:SetSize(itemSize, itemSize); p:SetPos((i-1) * (itemSize + itemGap), 0)
        p.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40)) 
            draw.RoundedBox(0, 0, h-6, w, 6, item.rarity)
            draw.SimpleText(string.sub(item.name, 1, 15), "HG_ItemName", w/2, 10, Color(200,200,200), 1, 0)
        end
        local mdl = vgui.Create("DModelPanel", p)
        mdl:Dock(FILL); mdl:SetModel(item.model); mdl:SetFOV(35)
        function mdl:LayoutEntity() return end
        if mdl.Entity and IsValid(mdl.Entity) then
            local headpos = mdl.Entity:GetBonePosition(mdl.Entity:LookupBone("ValveBiped.Bip01_Head1") or 0)
            mdl:SetLookAt(headpos - Vector(0, 0, 10)); mdl:SetCamPos(headpos + Vector(40, 0, 0))
        end
    end

    local startTime = CurTime(); local duration = 6
    local jitter = math.random(-itemSize/2 + 20, itemSize/2 - 20)
    local endPos = (ScrW() / 2) - ((winnerIndex-1) * (itemSize + itemGap)) - (itemSize/2) + jitter
    local lastSoundIndex = 0

    frame.Think = function(s)
        local t = CurTime() - startTime
        local fraction = math.min(t / duration, 1)
        local ease = 1 - math.pow(1 - fraction, 4)
        local currentX = Lerp(ease, 0, endPos)
        Tape:SetPos(currentX, 20)

        local centerOffset = (ScrW() / 2) - currentX
        local indexAtCenter = math.floor(centerOffset / (itemSize + itemGap))
        if indexAtCenter > lastSoundIndex then
            surface.PlaySound("homigrad/vgui/csgo_ui_crate_item_scroll.wav")
            lastSoundIndex = indexAtCenter
        end

        if fraction >= 1 then
            s.Think = nil
            surface.PlaySound("homigrad/vgui/csgo_ui_contract_type10.wav")
            frame:Remove()
            is_case_opening = false
            
            local win = vgui.Create("DFrame")
            win:SetSize(ScrW(), ScrH()); win:MakePopup(); win:SetTitle(""); win:ShowCloseButton(false); win:SetAlpha(0); win:AlphaTo(255, 0.5)
            win.Paint = function(s,w,h)
                DrawBlur(s, 8); draw.RoundedBox(0,0,0,w,h,Color(0,0,0,200))
                draw.SimpleText("ВЫ ПОЛУЧИЛИ:", "HG_Button", w/2, 100, Color(255,200,50), 1, 1)
                draw.SimpleText(winnerName, "HG_Title", w/2, 140, Color(255,255,255), 1, 1)
                draw.SimpleText("Нажмите любую кнопку", "HG_Subtitle", w/2, h-100, Color(150,150,150), 1, 1)
            end
            local mdl = vgui.Create("DModelPanel", win)
            mdl:SetSize(ScrW(), ScrH()*0.6); mdl:Center(); mdl:SetModel(winnerModel); mdl:SetFOV(35)
            mdl.LayoutEntity = function(s,e) e:SetAngles(Angle(0, RealTime()*30, 0)); s:RunAnimation() end
            local btn = vgui.Create("DButton", win); btn:SetSize(ScrW(), ScrH()); btn:SetText(""); btn.Paint = function() end
            btn.DoClick = function() win:Remove() net.Start("HG_SendInventory") net.SendToServer() end
        end
    end
end

net.Receive("HG_Case_Open", function()
    local mdl = net.ReadString(); local name = net.ReadString(); local caseID = net.ReadString(); local isNew = net.ReadBool()
    OpenCaseRoulette(caseID, mdl, name, isNew)
end)


-- ==============================================
-- ФУНКЦИИ ИНТЕРФЕЙСА (КОНТЕНТ КЕЙСОВ)
-- ==============================================

-- 1. КОНТЕНТ КЕЙСОВ (SHOP)
local function BuildCasesContent(container)
    local WorkArea = vgui.Create("DPanel", container)
    WorkArea:Dock(FILL); WorkArea.Paint = function() end

    -- Правая панель
    local RightPreview = vgui.Create("DPanel", WorkArea)
    RightPreview:Dock(RIGHT); RightPreview:SetWide(container:GetWide() * 0.40)
    RightPreview.Paint = function(s,w,h) draw.RoundedBox(0,0,0,w,h,Color(0,0,0,100)) end

    local PreviewModel = vgui.Create("DModelPanel", RightPreview)
    PreviewModel:Dock(FILL); PreviewModel:DockMargin(0, 0, 0, 80)
    
    local OpenBtn = vgui.Create("DButton", RightPreview)
    OpenBtn:Dock(BOTTOM); OpenBtn:SetTall(50); OpenBtn:SetText(""); OpenBtn:DockMargin(20, 0, 20, 20)
    OpenBtn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 

    -- Левая панель (Сетка)
    local LeftList = vgui.Create("DScrollPanel", WorkArea)
    LeftList:Dock(FILL); LeftList:DockMargin(0,0,10,0)
    
    local function UpdateRightPanel()
        if not SelectedCaseID or not HG_CaseConfig.Cases[SelectedCaseID] then 
            SelectedCaseID = next(HG_CaseConfig.Cases) 
        end
        if not SelectedCaseID then return end
        local caseData = HG_CaseConfig.Cases[SelectedCaseID]
        
        PreviewModel:SetModel(caseData.Model); PreviewModel:SetFOV(45)
        if IsValid(PreviewModel.Entity) then
            local mn, mx = PreviewModel.Entity:GetRenderBounds()
            local size = math.max(math.abs(mn.x)+math.abs(mx.x), math.abs(mn.y)+math.abs(mx.y), math.abs(mn.z)+math.abs(mx.z))
            PreviewModel:SetCamPos(Vector(size*1.5, size*1.5, size*1.5)); PreviewModel:SetLookAt((mn + mx) * 0.5)
        end
        function PreviewModel:LayoutEntity(ent) ent:SetAngles(Angle(0, RealTime() * 40, 0)) end
        function PreviewModel:PaintOver(w, h)
            local fade = open_fade or 1
            draw.SimpleText(caseData.Name, "HG_Title", w/2, 20, Color(255,255,255, 255*fade), 1, 1)
            draw.SimpleText(caseData.Price .. " pts", "HG_Subtitle", w/2, 55, Color(255,255,255, 255*fade), 1, 1)
        end

        OpenBtn.Paint = function(s, w, h)
            local fade = open_fade or 1
            if s:IsHovered() then
                surface.SetDrawColor(255, 255, 255, 200 * fade); surface.DrawOutlinedRect(0,0,w,h,2)
                draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 10 * fade))
            else
                surface.SetDrawColor(255, 255, 255, 50 * fade); surface.DrawOutlinedRect(0,0,w,h,1)
            end
            draw.SimpleText("ОТКРЫТЬ", "HG_Button", w/2, h/2, Color(255,255,255, 255*fade), 1, 1)
        end

        OpenBtn.DoClick = function() 
            if is_case_opening then return end
            
            local pts = LocalPlayer():GetNWInt("HG_Points", 0)
            if SelectedCaseID and HG_CaseConfig.Cases[SelectedCaseID] then
                if pts < HG_CaseConfig.Cases[SelectedCaseID].Price then
                    AddTopNotification("Недостаточно поинтов! Нужно: " .. HG_CaseConfig.Cases[SelectedCaseID].Price)
                    surface.PlaySound("buttons/button10.wav")
                    return
                end
            end

            net.Start("HG_Case_Open")
            net.WriteString(SelectedCaseID)
            net.SendToServer() 
        end
    end
    UpdateRightPanel()

    local Grid = vgui.Create("DIconLayout", LeftList)
    Grid:Dock(FILL); Grid:SetSpaceX(15); Grid:SetSpaceY(15)

    for id, data in pairs(HG_CaseConfig.Cases) do
        local itemBtn = Grid:Add("DButton"); itemBtn:SetSize(230, 230); itemBtn:SetText("")
        itemBtn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
        
        local iconMdl = vgui.Create("DModelPanel", itemBtn); iconMdl:Dock(FILL); iconMdl:SetMouseInputEnabled(false); iconMdl:SetModel(data.Model)
        if IsValid(iconMdl.Entity) then
            local mn, mx = iconMdl.Entity:GetRenderBounds()
            local size = math.max(math.abs(mn.x)+math.abs(mx.x), math.abs(mn.y)+math.abs(mx.y), math.abs(mn.z)+math.abs(mx.z))
            iconMdl:SetFOV(45); iconMdl:SetCamPos(Vector(size*2.2, size*2.2, size*2.2)); iconMdl:SetLookAt((mn + mx) * 0.5)
        end
        
        itemBtn.Paint = function(s, w, h)
            local fade = open_fade or 1
            local isSelected = (SelectedCaseID == id)
            local isHovered = s:IsHovered()
            
            local alpha = 30
            if isSelected then alpha = 80 
            elseif isHovered then alpha = 60 end

            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, alpha * fade))
            draw.SimpleText(data.Name, "HG_ItemName", w/2, h-30, Color(255,255,255, 255*fade), 1, 1)
        end
        itemBtn.DoClick = function() SelectedCaseID = id; UpdateRightPanel(); surface.PlaySound("homigrad/vgui/contract_type2.wav") end
    end
end

-- 2. КОНТЕНТ ИНВЕНТАРЯ (WARDROBE)
local function BuildInventoryContent(container)
    local ply = LocalPlayer()
    if not SelectedModelPath then SelectedModelPath = ply:GetModel(); local pCol = ply:GetPlayerColor(); SelectedColor = Vector(pCol.x, pCol.y, pCol.z) end

    local LeftPanel = vgui.Create("DPanel", container)
    LeftPanel:Dock(LEFT); LeftPanel:SetWide(container:GetWide() * 0.3); LeftPanel:DockMargin(0, 0, 10, 0)
    LeftPanel.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 50)) 
        draw.SimpleText("ПРЕДПРОСМОТР", "HG_Subtitle", w/2, 10, Color(150, 150, 150), 1, 1)
    end

    local ModelPreview = vgui.Create("DModelPanel", LeftPanel)
    ModelPreview:Dock(FILL); ModelPreview:DockMargin(0, 30, 0, 0); ModelPreview:SetModel(SelectedModelPath); ModelPreview:SetFOV(40)
    ApplyColorToModel(ModelPreview.Entity, SelectedColor)
    
    function ModelPreview:LayoutEntity(ent)
        ent:SetAngles(Angle(0, RealTime()*30 % 360, 0))
        for id, val in pairs(SelectedBodygroups) do ent:SetBodygroup(id, val) end
        ent:SetSkin(SelectedSkin)
        self:RunAnimation()
        if not self.Ready and IsValid(ent) and ent:GetBodyGroups() then
            self.Ready = true; self:GetParent():GetParent().RebuildSettings() 
        end
    end

    local RightPanel = vgui.Create("DScrollPanel", container)
    RightPanel:Dock(RIGHT); RightPanel:SetWide(container:GetWide() * 0.25)
    
    container.RebuildSettings = function()
        RightPanel:Clear()
        local ent = ModelPreview.Entity
        if not IsValid(ent) then return end

        local l = RightPanel:Add("DLabel"); l:Dock(TOP); l:SetText("ЦВЕТ"); l:SetFont("HG_Subtitle"); l:SetContentAlignment(5); l:SetTall(30)
        local Mixer = RightPanel:Add("DColorMixer"); Mixer:Dock(TOP); Mixer:SetTall(120); Mixer:DockMargin(0,5,0,20); Mixer:SetPalette(false); Mixer:SetAlphaBar(false); Mixer:SetWangs(false); Mixer:SetColor(Color(SelectedColor.x*255, SelectedColor.y*255, SelectedColor.z*255))
        Mixer.ValueChanged = function(s, col) SelectedColor = Vector(col.r/255, col.g/255, col.b/255); ApplyColorToModel(ModelPreview.Entity, SelectedColor) end

        local btnApply = RightPanel:Add("DButton"); btnApply:Dock(TOP); btnApply:SetTall(40); btnApply:DockMargin(0, 0, 0, 10); btnApply:SetText("")
        btnApply.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
        btnApply.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(0, 180, 60) or Color(0, 140, 40)); draw.SimpleText("НАДЕТЬ", "HG_Button", w/2, h/2, Color(255,255,255), 1, 1) end
        btnApply.DoClick = function() net.Start("HG_ModelSelector_Action"); net.WriteString("apply"); net.WriteString(SelectedModelPath); net.WriteUInt(SelectedSkin, 8); net.WriteVector(SelectedColor); net.WriteTable(SelectedBodygroups); net.SendToServer() end

        local bgroups = ent:GetBodyGroups() or {}
        for _, bg in pairs(bgroups) do
            if bg.num > 1 then
                local lab = RightPanel:Add("DLabel")
                lab:Dock(TOP); lab:SetText(string.upper(bg.name)); lab:SetFont("HG_ItemName"); lab:SetContentAlignment(5)
                local sl = RightPanel:Add("DNumSlider")
                sl:Dock(TOP); sl:DockMargin(5,0,5,15); sl:SetText(""); sl:SetMin(0); sl:SetMax(bg.num-1); sl:SetDecimals(0)
                sl:SetValue(SelectedBodygroups[bg.id] or 0)
                sl.OnValueChanged = function(s, val)
                    local v = math.Round(val)
                    SelectedBodygroups[bg.id] = v
                    if IsValid(ent) then ent:SetBodygroup(bg.id, v) end
                end
            end
        end
    end
    
    timer.Simple(0.1, container.RebuildSettings)

    local MiddlePanel = vgui.Create("DScrollPanel", container)
    MiddlePanel:Dock(FILL); MiddlePanel:DockMargin(5, 0, 5, 0)
    local IconLayout = vgui.Create("DIconLayout", MiddlePanel)
    IconLayout:Dock(FILL); IconLayout:SetSpaceX(5); IconLayout:SetSpaceY(5)

    for path, _ in pairs(PlayerInventory) do
        local icon = IconLayout:Add("SpawnIcon"); icon:SetModel(path); icon:SetSize(64, 64)
        icon.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
        icon.DoClick = function() SelectedModelPath = path; SelectedBodygroups = {}; ModelPreview:SetModel(path); ApplyColorToModel(ModelPreview.Entity, SelectedColor); container.RebuildSettings(); surface.PlaySound("homigrad/vgui/page_scroll.wav") end
    end
end

-- 3. КОНТЕНТ ТРАНЗАКЦИЙ (ОБНОВЛЕННЫЙ)
local function BuildTransactionsContent(container)
    local WorkArea = vgui.Create("DPanel", container)
    WorkArea:Dock(FILL); WorkArea.Paint = function() end

    -- ПРАВАЯ ЧАСТЬ (СПИСОК ИГРОКОВ)
    local RightPanel = vgui.Create("DPanel", WorkArea)
    RightPanel:Dock(RIGHT)
    RightPanel:SetWide(container:GetWide() * 0.4)
    RightPanel.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,100)) end

    local SearchBar = vgui.Create("DTextEntry", RightPanel)
    SearchBar:Dock(TOP)
    SearchBar:SetTall(40)
    SearchBar:DockMargin(10,10,10,10)
    SearchBar:SetPlaceholderText("Поиск...")
    SearchBar:SetFont("HG_Button")
    SearchBar.Paint = function(s,w,h)
        draw.RoundedBox(0,0,0,w,h,Color(0,0,0,150))
        s:DrawTextEntryText(Color(255,255,255), Color(50,50,255), Color(255,255,255))
    end

    local PlayerList = vgui.Create("DScrollPanel", RightPanel)
    PlayerList:Dock(FILL)
    PlayerList:DockMargin(10,0,10,10)

    -- ЛЕВАЯ ЧАСТЬ (ДЕЙСТВИЕ)
    local LeftPanel = vgui.Create("DPanel", WorkArea)
    LeftPanel:Dock(FILL)
    LeftPanel:DockMargin(0,0,10,0)
    LeftPanel.Paint = function() end

    -- КОНТЕЙНЕР ДЛЯ ЦЕНТРИРОВАНИЯ ЭЛЕМЕНТОВ
    local CenterContainer = vgui.Create("DPanel", LeftPanel)
    CenterContainer:SetSize(400, 300)
    CenterContainer:Center()
    CenterContainer.Paint = function() end

    -- Информация о выбранном
    local InfoLabel = vgui.Create("DLabel", CenterContainer)
    InfoLabel:Dock(TOP)
    InfoLabel:SetTall(50)
    InfoLabel:SetFont("HG_Title")
    InfoLabel:SetText("Никто не выбран")
    InfoLabel:SetTextColor(Color(255,255,255))
    InfoLabel:SetContentAlignment(5)

    -- Ввод суммы
    local AmountEntry = vgui.Create("DTextEntry", CenterContainer)
    AmountEntry:Dock(TOP)
    AmountEntry:SetTall(50)
    AmountEntry:DockMargin(0, 20, 0, 20)
    AmountEntry:SetNumeric(true)
    AmountEntry:SetFont("HG_Title")
    AmountEntry:SetText("0")
    AmountEntry:SetContentAlignment(5) -- Текст по центру
    AmountEntry.Paint = function(s,w,h)
        draw.RoundedBox(0,0,0,w,h,Color(0,0,0,150))
        s:DrawTextEntryText(Color(255,255,255), Color(50,50,255), Color(255,255,255))
    end
    AmountEntry.OnChange = function(s)
        local val = tonumber(s:GetText()) or 0
        if val > 1000 then s:SetText("1000") end
    end

    -- Кнопка отправки
    local SendBtn = vgui.Create("DButton", CenterContainer)
    SendBtn:Dock(TOP)
    SendBtn:SetTall(60)
    SendBtn:SetText("ПЕРЕВЕСТИ")
    SendBtn:SetFont("HG_Button")
    SendBtn:SetTextColor(Color(255,255,255))
    SendBtn.Paint = function(s,w,h)
        draw.RoundedBox(0,0,0,w,h, s:IsHovered() and Color(60,160,60) or Color(40,140,40))
    end
    SendBtn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
    SendBtn.DoClick = function()
        local amt = tonumber(AmountEntry:GetText()) or 0
        if not IsValid(SelectedTransferPlayer) then return end
        if amt <= 0 then AddTopNotification("Введите сумму!") return end
        if amt > 1000 then AddTopNotification("Максимум 1000!") return end
        if LocalPlayer():GetNWInt("HG_Points",0) < amt then AddTopNotification("Недостаточно средств!") return end

        net.Start("HG_TransferPoints")
        net.WriteEntity(SelectedTransferPlayer)
        net.WriteInt(amt, 32)
        net.SendToServer()
        
        surface.PlaySound("homigrad/vgui/contract_type2.wav")
        AmountEntry:SetText("0")
    end

    -- ПЕРЕКРЫВАЮЩАЯ ПАНЕЛЬ (БЛОКИРОВКА)
    -- Она создается поверх CenterContainer и закрывает ввод и кнопку
    local BlockOverlay = vgui.Create("DPanel", CenterContainer)
    BlockOverlay:Dock(FILL) -- Растягивается на весь контейнер (поверх ввода и кнопки)
    BlockOverlay.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 220)) -- Сильное затемнение
        draw.SimpleText("ВЫБЕРИТЕ ИГРОКА", "HG_Title", w/2, h/2 - 15, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("из списка справа", "HG_Subtitle", w/2, h/2 + 15, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Если игрок уже был выбран ранее, скрываем блок
    if IsValid(SelectedTransferPlayer) then
        BlockOverlay:SetVisible(false)
        InfoLabel:SetText("Перевод: " .. SelectedTransferPlayer:Name())
    end

    local function PopulateList(filter)
        PlayerList:Clear()
        for _, ply in ipairs(player.GetAll()) do
            if ply == LocalPlayer() then continue end
            if filter and filter ~= "" and not string.find(string.lower(ply:Name()), string.lower(filter)) then continue end

            local btn = PlayerList:Add("DButton")
            btn:Dock(TOP)
            btn:DockMargin(0,0,0,5)
            btn:SetTall(50)
            btn:SetText(ply:Name())
            btn:SetFont("HG_Button")
            btn:SetTextColor(Color(255,255,255))
            btn.Paint = function(s,w,h)
                local col = (SelectedTransferPlayer == ply) and Color(80,80,80) or Color(40,40,40)
                if s:IsHovered() then col = Color(60,60,60) end
                draw.RoundedBox(0,0,0,w,h,col)
            end
            btn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
            btn.DoClick = function()
                SelectedTransferPlayer = ply
                InfoLabel:SetText("Перевод: " .. ply:Name())
                
                BlockOverlay:SetVisible(false)
                
                surface.PlaySound("homigrad/vgui/contract_type2.wav")
                PopulateList(SearchBar:GetText())
            end
        end
    end

    SearchBar.OnChange = function(s) PopulateList(s:GetText()) end
    PopulateList()
end

-- ==============================================
-- ГЛАВНАЯ ОТРИСОВКА ВКЛАДКИ (ID 9: КЕЙСЫ)
-- ==============================================
hook.Add("HUDPaint", "Cases_Main_Page", function()
    if not hg.ScoreBoard then return end
    if not IsValid(ScoreBoardPanel) then 
        open_main = false; if IsValid(panel_main) then panel_main:Remove() end return 
    end
    
    -- ID 9 = ВКЛАДКА КЕЙСОВ
    if hg.ScoreBoard == 9 and not open_main then
        open_main = true
        net.Start("HG_SendInventory"); net.SendToServer()

        local mainPanel = vgui.Create("DFrame", ScoreBoardPanel)
        mainPanel:SetSize(ScrW() - (ScrW()*0.08), ScrH()); mainPanel:SetPos(0, 0); mainPanel:ShowCloseButton(false); mainPanel:MakePopup(); mainPanel.Paint = function() end 
        
        local content = vgui.Create("DPanel", mainPanel)
        content:SetSize(mainPanel:GetWide() - (ScrW()*0.15) - 20, ScrH() / 1.15)
        content:SetPos(ScrW()*0.15, (ScrH() - content:GetTall()) / 2)
        
        content.Paint = function(s, w, h)
            local fade = open_fade or 1
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 129 * fade))
            local pts = LocalPlayer():GetNWInt("HG_Points", 0)
            draw.SimpleText("БАЛАНС: " .. pts .. " PTS", "HG_Price", w - 20, 20, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_RIGHT)
        end

        local NavBar = vgui.Create("DPanel", content)
        NavBar:SetSize(content:GetWide(), 60); NavBar:SetPos(0, 0); NavBar.Paint = function() end

        local WorkArea = vgui.Create("DPanel", content)
        WorkArea:Dock(FILL); WorkArea:DockMargin(20, 70, 20, 20); 
        WorkArea.Paint = function(s, w, h) end
        WorkArea:DockPadding(0,0,0,0)
        
        local oldPaint = WorkArea.Paint
        WorkArea.Paint = function(s, w, h)
            local x, y = s:LocalToScreen(0,0)
            render.SetScissorRect(x, y, x+w, y+h, true)
            if oldPaint then oldPaint(s, w, h) end
        end
        WorkArea.PaintOver = function(s,w,h)
            render.SetScissorRect(0,0,0,0, false)
        end

        local TabsIndices = {cases = 1, inventory = 2, transactions = 3}

        local function SwitchTab(tab, instant)
            if active_tab == tab and not instant then return end
            if is_animating_tab then return end

            local oldIndex = TabsIndices[active_tab] or 1
            local newIndex = TabsIndices[tab] or 1
            local direction = 1 
            
            if newIndex < oldIndex then direction = -1 end
            
            if instant then
                if IsValid(current_page_panel) then current_page_panel:Remove() end
                current_page_panel = vgui.Create("DPanel", WorkArea)
                current_page_panel:SetSize(WorkArea:GetWide(), WorkArea:GetTall())
                current_page_panel:SetPos(0,0)
                current_page_panel.Paint = function() end
                if tab == "cases" then BuildCasesContent(current_page_panel)
                elseif tab == "inventory" then BuildInventoryContent(current_page_panel)
                elseif tab == "transactions" then BuildTransactionsContent(current_page_panel) end
                active_tab = tab
                return
            end

            is_animating_tab = true
            
            local NewPanel = vgui.Create("DPanel", WorkArea)
            NewPanel:SetSize(WorkArea:GetWide(), WorkArea:GetTall())
            NewPanel.Paint = function() end
            
            local startX = (direction == 1) and WorkArea:GetWide() or -WorkArea:GetWide()
            NewPanel:SetPos(startX, 0)
            
            if tab == "cases" then BuildCasesContent(NewPanel)
            elseif tab == "inventory" then BuildInventoryContent(NewPanel) 
            elseif tab == "transactions" then BuildTransactionsContent(NewPanel) end

            if IsValid(current_page_panel) then
                local endX = (direction == 1) and -WorkArea:GetWide() or WorkArea:GetWide()
                current_page_panel:MoveTo(endX, 0, 0.3, 0, -1, function()
                    if IsValid(current_page_panel) then current_page_panel:Remove() end
                end)
            end

            NewPanel:MoveTo(0, 0, 0.3, 0, -1, function()
                current_page_panel = NewPanel
                is_animating_tab = false
            end)

            active_tab = tab
        end

        local function NavButton(txt, tabID, x)
            local btn = vgui.Create("DButton", NavBar)
            btn:SetText(txt); btn:SetFont("HG_Button"); btn:SetSize(170, 60); btn:SetPos(x, 0); btn:SetTextColor(Color(255,255,255))
            btn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
            btn.Paint = function(s, w, h)
                local fade = open_fade or 1
                if active_tab == tabID then draw.RoundedBox(0, 0, h-4, w, 4, Color(255,255,255, 255*fade)) end
                if s:IsHovered() then draw.SimpleText(txt, "HG_Button", w/2, h/2, Color(200,200,200, 255*fade), 1, 1) end
            end
            btn.DoClick = function() 
                SwitchTab(tabID, false)
                surface.PlaySound("homigrad/vgui/panorama/sidemenu_click_01.wav") 
            end
        end

        NavButton("КЕЙСЫ", "cases", 20)
        NavButton("ГАРДЕРОБ", "inventory", 200)
        NavButton("ПЕРЕВОДЫ", "transactions", 380)

        timer.Simple(0, function()
            if IsValid(WorkArea) then
                WorkArea:InvalidateParent(true)
                SwitchTab(active_tab, true) 
            end
        end)
        
        panel_main = mainPanel

    elseif hg.ScoreBoard ~= 9 and open_main then
        open_main = false; if IsValid(panel_main) then panel_main:Remove() end
        current_page_panel = nil
        is_animating_tab = false
        active_tab = "cases" -- Сброс на вкладку по умолчанию
    end
end)

-- Прием начисления очков
net.Receive("HG_Points_Notification", function()
    local amount = net.ReadInt(16)
    local text = (amount > 0 and "+" or "") .. amount .. " PTS"
    AddTopNotification(text) 
end)

-- Прием текстовых уведомлений
net.Receive("HG_SendNotification", function()
    local text = net.ReadString()
    AddTopNotification(text)
end)


-- ==============================================
-- ЛОГИКА НОВОГО КАЗИНО (ID 10)
-- ==============================================

local open_casino = false
local panelka_casino
local open_anim_casino = 0

local img_banana = "https://github.com/bebebe3/papochka-ahh/blob/main/banani.png?raw=true"
local img_strawberry = "https://github.com/bebebe3/papochka-ahh/blob/main/klybnika.png?raw=true"
local img_plum = "https://github.com/bebebe3/papochka-ahh/blob/main/sliva.png?raw=true"
local img_pasbalka = "https://github.com/bebebe3/papochka-ahh/blob/main/cazino.png?raw=true"

local fruit_map = {
    [1] = img_plum,
    [2] = img_banana,
    [3] = img_strawberry
}

local function GetcasinoBalance()
    return LocalPlayer():GetNWInt("HG_Points", 0)
end

local currentBet = 50
local isSpinning = false

local slotData = {
    {y = 0, speed = 0, stopTime = 0, result = 3, bounce = 0},
    {y = 0, speed = 0, stopTime = 0, result = 3, bounce = 0},
    {y = 0, speed = 0, stopTime = 0, result = 3, bounce = 0}
}
local TILE_SIZE = 100 

local function StartSpinAnimation()
    isSpinning = true
    local timeNow = CurTime()
    
    for i = 1, 3 do
        slotData[i].speed = 1500 + (i * 200) 
        slotData[i].stopTime = timeNow + 2 + (i * 0.5) 
        slotData[i].y = 0
        slotData[i].bounce = 0
    end
end

net.Receive("HG_Casino_Spin", function() 
    local s1 = net.ReadUInt(4)
    local s2 = net.ReadUInt(4)
    local s3 = net.ReadUInt(4)
    local winAmt = net.ReadUInt(32)
    local winType = net.ReadUInt(4)

    slotData[1].result = s1
    slotData[2].result = s2
    slotData[3].result = s3

    timer.Simple(4, function()
        if not IsValid(panelka_casino) then return end
        isSpinning = false
        
        if winAmt > 0 then
            local msg = ""
            if winType == 3 then msg = "КЛУБНИЧКА! x5 (+" .. winAmt .. ")"
            elseif winType == 2 then msg = "БАНАНЫ! x3 (+" .. winAmt .. ")"
            elseif winType == 1 then msg = "СЛИВЫ! x2 (+" .. winAmt .. ")"
            end
            AddTopNotification(msg) 
        else
            AddTopNotification("Проигрыш")
        end
    end)
end)

hook.Add("HUDPaint", "casino_Page_Logic_Main", function()
    if not hg.ScoreBoard then return end
    if not IsValid(ScoreBoardPanel) then 
        open_casino = false 
        open_anim_casino = 0
        if IsValid(panelka_casino) then panelka_casino:Remove() end
        return 
    end

    if hg.ScoreBoard == 10 and not hg.score_closing then
        open_anim_casino = Lerp(FrameTime() * 10, open_anim_casino, 1)
    else
        open_anim_casino = Lerp(FrameTime() * 10, open_anim_casino, 0)
    end

    if hg.ScoreBoard ~= 10 and open_casino then
        open_casino = false
        if IsValid(panelka_casino) then panelka_casino:Remove() end
        return
    end

    if hg.ScoreBoard == 10 and not open_casino then
        open_casino = true
        
        local MainPanel = vgui.Create("DFrame", ScoreBoardPanel)
        MainPanel:SetSize(ScrW(), ScrH())
        MainPanel:Center()
        MainPanel:SetDraggable(false)
        MainPanel:SetTitle(" ")
        MainPanel:ShowCloseButton(false)
        
        MainPanel.Paint = function(s, w, h)
            local targetX = (1 - open_anim_casino) * (ScrW()/1.5)
            s:SetX(targetX)
        end

        local Content = vgui.Create("DPanel", MainPanel)
        Content:SetSize(600, 500)
        Content:Center()
        Content.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 129))
            
            if hg.GetURLMaterial then
                local eggMat = hg.GetURLMaterial(img_pasbalka, "casino_egg")
                if eggMat then
                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.SetMaterial(eggMat)
                    surface.DrawTexturedRect(w - 110, h - 110, 100, 100)
                end
            end

            draw.SimpleText("МЕЛЛ КАЗИК", "hg_HomicideSmalles", w/2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) -- Белый цвет
            draw.SimpleText("Баланс: " .. GetcasinoBalance() .. " pts", "hg_HomicideSmalles", w/2, 70, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) -- Белый цвет
            draw.SimpleText("Ставка: " .. currentBet, "hg_HomicideSmalles", w/2, 360, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        for i = 1, 3 do
            local pnl = vgui.Create("DPanel", Content)
            pnl:SetSize(100, 100)
            pnl:SetPos(150 + (i-1)*110, 150)
            
            pnl.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
                
                local data = slotData[i]
                if isSpinning and CurTime() < data.stopTime then
                    data.y = data.y + data.speed * FrameTime()
                    if data.y >= TILE_SIZE * 3 then data.y = 0 end 
                    
                    if not data.lastTick or (data.y > TILE_SIZE and data.lastTick < TILE_SIZE) then
                        if i == 1 then
                            surface.PlaySound("homigrad/vgui/csgo_ui_crate_item_scroll.wav")
                        end
                        data.lastTick = 0
                    end
                    data.lastTick = data.y

                elseif isSpinning and CurTime() >= data.stopTime then
                    if data.bounce == 0 then
                        data.bounce = 1
                        surface.PlaySound("homigrad/vgui/contract_type2.wav")
                    end
                    data.y = 0 
                end

                local currentRes = data.result
                local prevRes = currentRes - 1; if prevRes < 1 then prevRes = 3 end
                local nextRes = currentRes + 1; if nextRes > 3 then nextRes = 1 end
                
                local renderList = {prevRes, currentRes, nextRes}
                if isSpinning and CurTime() < data.stopTime then
                    renderList = {math.random(1,3), math.random(1,3), math.random(1,3)}
                end

                local yOffset = (data.y % TILE_SIZE) 
                local sx, sy = s:LocalToScreen(0, 0)
                render.SetScissorRect(sx+2, sy+2, sx+w-2, sy+h-2, true)
                
                for k, fruitIdx in ipairs(renderList) do
                    local fruitUrl = fruit_map[fruitIdx]
                    if fruitUrl and hg.GetURLMaterial then
                        local mat = hg.GetURLMaterial(fruitUrl, "casino_fruit_"..fruitIdx)
                        if mat then
                            surface.SetDrawColor(255, 255, 255, 255)
                            surface.SetMaterial(mat)
                            local drawY = (k-2) * TILE_SIZE + yOffset
                            surface.DrawTexturedRect(5, drawY + 5, w-10, h-10)
                        end
                    end
                end
                render.SetScissorRect(0, 0, 0, 0, false)
            end
        end

        local SpinBtn = vgui.Create("DButton", Content)
        SpinBtn:SetText("КРУТИТЬ")
        SpinBtn:SetFont("hg_HomicideSmalles")
        SpinBtn:SetSize(200, 50)
        SpinBtn:SetPos(200, 420)
        SpinBtn:SetTextColor(Color(255, 255, 255))
        SpinBtn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
        SpinBtn.Paint = function(s, w, h)
            local col = s:IsHovered() and Color(60, 160, 60) or Color(40, 140, 40)
            if isSpinning then col = Color(50, 50, 50) end
            draw.RoundedBox(0, 0, 0, w, h, col)
        end
        
        SpinBtn.DoClick = function()
            if isSpinning then return end
            
            local bal = GetcasinoBalance()
            if bal < currentBet then
                AddTopNotification("Недостаточно средств!") 
                surface.PlaySound("buttons/button10.wav")
                return
            end

            StartSpinAnimation() 
            surface.PlaySound("buttons/lever7.wav")
            
            net.Start("HG_Casino_Spin")
            net.WriteUInt(currentBet, 32)
            net.SendToServer()
        end

        local MinusBtn = vgui.Create("DButton", Content)
        MinusBtn:SetText("-")
        MinusBtn:SetFont("hg_HomicideSmalles")
        MinusBtn:SetSize(40, 40)
        MinusBtn:SetPos(150, 340)
        MinusBtn:SetTextColor(Color(255,255,255))
        MinusBtn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
        MinusBtn.Paint = function(s, w, h) draw.RoundedBox(0,0,0,w,h,Color(60,60,60)) end
        MinusBtn.DoClick = function()
            if currentBet > 10 then 
                currentBet = currentBet - 10 
                surface.PlaySound("homigrad/vgui/panorama/sidemenu_click_01.wav")
            end
        end

        local PlusBtn = vgui.Create("DButton", Content)
        PlusBtn:SetText("+")
        PlusBtn:SetFont("hg_HomicideSmalles")
        PlusBtn:SetSize(40, 40)
        PlusBtn:SetPos(410, 340)
        PlusBtn:SetTextColor(Color(255,255,255))
        PlusBtn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
        PlusBtn.Paint = function(s, w, h) draw.RoundedBox(0,0,0,w,h,Color(60,60,60)) end
        PlusBtn.DoClick = function()
            if currentBet < GetcasinoBalance() then 
                currentBet = currentBet + 10 
                surface.PlaySound("homigrad/vgui/panorama/sidemenu_click_01.wav")
            end
        end
        
        local MaxBtn = vgui.Create("DButton", Content)
        MaxBtn:SetText("MAX")
        MaxBtn:SetSize(60, 20)
        MaxBtn:SetPos(270, 390)
        MaxBtn:SetTextColor(Color(255,255,255))
        MaxBtn.OnCursorEntered = function() surface.PlaySound(hoverSound) end 
        MaxBtn.Paint = function(s, w, h) draw.RoundedBox(0,0,0,w,h,Color(100,60,60)) end
        MaxBtn.DoClick = function()
            local bal = GetcasinoBalance()
            if bal > 0 then
                currentBet = math.floor(bal / 10) * 10
                if currentBet == 0 then currentBet = 10 end
            else
                currentBet = 10
            end
            surface.PlaySound("homigrad/vgui/panorama/sidemenu_click_01.wav")
        end

        panelka_casino = MainPanel
    end
end)