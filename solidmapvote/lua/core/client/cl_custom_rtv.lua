-- "addons\\solidmapvote\\lua\\core\\client\\cl_custom_rtv.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local Mat = Material
local str_gsub = string.gsub
local str_upper = string.upper

local function GetPhrase(key, ...) //незнаю зачем эта хуйня, но чтобы секунды работали мне сказало так сделать... ну работает значит ладно
    local text
    if hg and hg.GetPhrase then
        text = hg.GetPhrase(key)
    else
        local lang = GetConVar("gmod_language") and GetConVar("gmod_language"):GetString() or "en"
        local fallback = {
            en = {
                rtv_header = "VOTE FOR NEXT MAP",
                rtv_header_timer = "VOTE FOR NEXT MAP - %ds",
                rtv_votes = "vote(s)",
                rtv_time_up = "Time is up!",
                rtv_random = "RANDOM",
                rtv_randomly = "RANDOMLY",
                rtv_extend = "EXTEND",
                rtv_continue = "CONTINUE"
            },
            ru = {
                rtv_header = "ГОЛОСУЙ ЗА КАРТУ",
                rtv_header_timer = "ГОЛОСУЙ ЗА КАРТУ - %dс",
                rtv_votes = "голос(ов)",
                rtv_time_up = "Время вышло!",
                rtv_random = "РАНДОМ",
                rtv_randomly = "СЛУЧАЙНАЯ",
                rtv_extend = "ЭКСТЕНД",
                rtv_continue = "ПРОДОЛЖИТЬ"
            }
        }
        local dict = fallback[lang] or fallback.en
        text = dict[key] or fallback.en[key] or key
    end
    if ... then return string.format(text, ...) end
    return text
end

surface.CreateFont("H.18", {
    font = "Roboto",
    size = 18,
    weight = 500,
    antialias = true,
})

surface.CreateFont("HomigradFontBig", {
    font = "Roboto",
    size = 32,
    weight = 700,
    antialias = true,
})

local workshopIconCache = {}

local maphovered = Color(97, 94, 94, 200)
local nomaphovered = Color(12, 12, 12, 200)

local function ConvertMapName(map)
    map = str_gsub(map, "_", " ")
    map = str_gsub(map, ".bsp", "")
    map = str_upper(map)
    return map
end

local fExists = file.Exists

local function RTV_LoadMaterial(map)
    local material
    if map == "mu_smallotown_v2_13" then
        map = "mu_smalltown_v2_13"
    end
  
    if workshopIconCache[map] then  
        return workshopIconCache[map]
    end
    
    if fExists("maps/thumb/" .. map .. ".png", "GAME") then
        material = Mat("maps/thumb/" .. map .. ".png")
    elseif fExists("maps/" .. map .. ".png", "GAME") then
        material = Mat("maps/" .. map .. ".png")
    else
        material = Mat("case_shop/checha_case.png")
    end
    
    workshopIconCache[map] = material
    return material
end

local function RTV_LogicStatusVotes(vote, votesTable, totalVotes)
    local status = 0
    if votesTable and totalVotes and totalVotes > 0 then
        status = (votesTable[vote] or 0) / totalVotes
    end
    return status
end

local function RTV_GetTotalVotes(votesTable)
    local count = 0
    if not votesTable then return 0 end
    for _, vote in pairs(votesTable) do
        count = count + vote
    end
    return count
end

local function DrawGradient(x, y, w, h, startColor, endColor, vertical)
    local r = math.floor((startColor.r + endColor.r) / 2)
    local g = math.floor((startColor.g + endColor.g) / 2)
    local b = math.floor((startColor.b + endColor.b) / 2)
    local a = math.floor((startColor.a + endColor.a) / 2)
    
    surface.SetDrawColor(r, g, b, a)
    surface.DrawRect(x, y, w, h)
end

local function RTV_CreateButtonMap(parent, mapz)
    local buttonMapLabel = vgui.Create("DLabel")
    buttonMapLabel:SetFont("H.18")
    buttonMapLabel:SetText("")
    buttonMapLabel:SetVisible(false)
    
    local buttonMap = vgui.Create("DButton", parent)
    buttonMap:SetText("")
    buttonMap.map = mapz
    buttonMap.votesTable = votesTable
    buttonMap.totalVotes = totalVotes
    buttonMap.vguilabel = buttonMapLabel
    buttonMap.material = RTV_LoadMaterial(mapz)
    
    buttonMap.OnRemove = function(self)
        if IsValid(self.vguilabel) then
            self.vguilabel:Remove()
            self.vguilabel = nil
        end
    end
    
    buttonMap.Paint = function(self, w, h)
        local votes = IsValid(SolidMapVote.CustomMenu) and SolidMapVote.CustomMenu.votes or {}
        local total = RTV_GetTotalVotes(votes)

        local baseColor = self:IsHovered() and maphovered or nomaphovered
        draw.RoundedBox(0, 0, 0, w, h, baseColor)

        local voteStatus = RTV_LogicStatusVotes(self.map, votes, total)
        if voteStatus > 0 then
            local voteAlpha = 165 * voteStatus
            local voteColor1 = Color(200, 50, 50, voteAlpha)
            local voteColor2 = Color(124, 8, 8, voteAlpha)
            DrawGradient(0, 0, w, h, voteColor1, voteColor2, true)
        end

        if self.material then
            surface.SetDrawColor(255, 255, 255, 200)
            surface.SetMaterial(self.material)
            surface.DrawTexturedRect(5, 5, w - 10, h - 40)
        end

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, 0, h, 2)
        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, h, 0, 2)

        draw.SimpleText(ConvertMapName(self.map), "H.18", w / 2, h - 25, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText((votes[self.map] or 0) .. " " .. GetPhrase("rtv_votes"), "H.18", w / 2, h - 10, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    buttonMap.DoClick = function(self)
        if not IsValid(SolidMapVote.CustomMenu) then return end
        surface.PlaySound("buttons/button15.wav")
        local currentTimeLeft = SolidMapVote.CustomMenu.endTime - CurTime()
        if currentTimeLeft <= 0 then
            LocalPlayer():ChatPrint(GetPhrase("rtv_time_up"))
            return
        end
        RunConsoleCommand("solidmapvote_vote", self.map)
    end

    buttonMap.OnCursorEntered = function(self)
        surface.PlaySound("ui/buttonrollover.wav")
    end
    
    return buttonMap
end

local function RTV_CreateRandomMap(parent, maps) //эхты сука не работает
    local buttonMap = vgui.Create("DButton", parent)
    buttonMap:SetText("")
    buttonMap.map = "random"
    buttonMap.last_change = CurTime()
    buttonMap.currentMapIndex = 0
    
    local randomImages = {
        "pluv/pluv.png",
        "pluv/pluv51.png",
        "pluv/pluvberet.png",
        "pluv/pluvboss.png",
        "pluv/pluvdobro.png",
        "pluv/pluvgreen.png",
        "pluv/pluvmad.png",
        "pluv/pluvnerd.png",
        "pluv/pluvred.png",
        "pluv/pluvsad.png"
    }
    
    buttonMap.randomImages = randomImages
    buttonMap.material = Material(randomImages[1])
    
    buttonMap.Paint = function(self, w, h)
        local votes = IsValid(SolidMapVote.CustomMenu) and SolidMapVote.CustomMenu.votes or {}
        local total = RTV_GetTotalVotes(votes)

        local baseColor = self:IsHovered() and maphovered or nomaphovered
        local randomColor1 = Color(
            math.min(255, baseColor.r + 50),
            math.min(255, baseColor.g + 20),
            math.min(255, baseColor.b + 50),
            baseColor.a
        )
        DrawGradient(0, 0, w, h, randomColor1, baseColor, true)
        
        local voteStatus = RTV_LogicStatusVotes("random", votes, total)
        if voteStatus > 0 then
            local voteAlpha = 165 * voteStatus
            local voteColor1 = Color(200, 50, 200, voteAlpha)
            local voteColor2 = Color(124, 8, 124, voteAlpha)
            DrawGradient(0, 0, w, h, voteColor1, voteColor2, true)
        end
        
        if self.material then
            surface.SetDrawColor(255, 255, 255, 200)
            surface.SetMaterial(self.material)
            surface.DrawTexturedRect(5, 5, w - 10, h - 55)
        end
        
        draw.SimpleText(GetPhrase("rtv_random"), "H.18", w / 2, h - 40, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(GetPhrase("rtv_randomly"), "H.18", w / 2, h - 25, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText((votes["random"] or 0) .. " " .. GetPhrase("rtv_votes"), "H.18", w / 2, h - 10, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    buttonMap.DoClick = function(self)
        if not IsValid(SolidMapVote.CustomMenu) then return end
        surface.PlaySound("buttons/button15.wav")
        local currentTimeLeft = SolidMapVote.CustomMenu.endTime - CurTime()
        if currentTimeLeft <= 0 then
            LocalPlayer():ChatPrint(GetPhrase("rtv_time_up"))
            return
        end
        RunConsoleCommand("solidmapvote_vote", "random")
    end

    buttonMap.Think = function(self) //не работае т не рабо те та т сяльжвд а дль дя рабо те та т сяльжвд а д
        if CurTime() - (self.last_change or 0) >= 0.5 then
            self.last_change = CurTime()
            local images = self.randomImages
            if images and #images > 0 then
                self.currentMapIndex = (self.currentMapIndex % #images) + 1
                self.material = Material(images[self.currentMapIndex])
            end
        end
    end
    
    return buttonMap
end

local function RTV_CreateExtendMap(parent)
    local currentMap = game.GetMap()
    local buttonMap = vgui.Create("DButton", parent)
    buttonMap:SetText("")
    buttonMap.map = "extend"
    buttonMap.votesTable = votesTable
    buttonMap.totalVotes = totalVotes
    buttonMap.material = RTV_LoadMaterial(currentMap)
    
    buttonMap.Paint = function(self, w, h)
        local votes = IsValid(SolidMapVote.CustomMenu) and SolidMapVote.CustomMenu.votes or {}
        local total = RTV_GetTotalVotes(votes)

        local baseColor = self:IsHovered() and maphovered or nomaphovered
        local extendColor1 = Color(
            math.min(255, baseColor.r + 30),
            math.min(255, baseColor.g + 50),
            math.min(255, baseColor.b + 30),
            baseColor.a
        )
        DrawGradient(0, 0, w, h, extendColor1, baseColor, true)

        local voteStatus = RTV_LogicStatusVotes("extend", votes, total)
        if voteStatus > 0 then
            local voteAlpha = 165 * voteStatus
            local voteColor1 = Color(50, 200, 50, voteAlpha)
            local voteColor2 = Color(0, 255, 0, voteAlpha)
            DrawGradient(0, 0, w, h, voteColor1, voteColor2, true)
        end

        if self.material then
            surface.SetDrawColor(255, 255, 255, 200)
            surface.SetMaterial(self.material)
            surface.DrawTexturedRect(5, 5, w - 10, h - 55)
        end
        
        draw.SimpleText(GetPhrase("rtv_extend"), "H.18", w / 2, h - 40, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(GetPhrase("rtv_continue"), "H.18", w / 2, h - 25, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText((votes["extend"] or 0) .. " " .. GetPhrase("rtv_votes"), "H.18", w / 2, h - 10, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    buttonMap.DoClick = function(self)
        if not IsValid(SolidMapVote.CustomMenu) then return end
        surface.PlaySound("buttons/button15.wav")
        local currentTimeLeft = SolidMapVote.CustomMenu.endTime - CurTime()
        if currentTimeLeft <= 0 then
            LocalPlayer():ChatPrint(GetPhrase("rtv_time_up"))
            return
        end
        RunConsoleCommand("solidmapvote_vote", "extend")
    end
    
    return buttonMap
end

function SolidMapVote.OpenCustomUI(maps, votes, endTime)
    if IsValid(SolidMapVote.CustomMenu) then
        SolidMapVote.CustomMenu:Remove()
    end

    local screenW, screenH = ScrW(), ScrH()
    local baseW, baseH = 1920, 1080
    local scaleX = screenW / baseW
    local scaleY = screenH / baseH
    local scale = (scaleX + scaleY) / 1.5

    local buttonSize = math.max(40, 140 * scale)
    local spacing = math.max(1, 3 * scale)
    local columns = 5
    local rows = 3

    SolidMapVote.CustomMenu = vgui.Create("DPanel")
    SolidMapVote.CustomMenu:SetPos(0, 0)
    SolidMapVote.CustomMenu:SetSize(0, screenH)
    SolidMapVote.CustomMenu:SetBackgroundColor(Color(20, 20, 20, 245))
    SolidMapVote.CustomMenu:SizeTo(screenW, screenH, 0.3, 0, 0.5, nil)
    SolidMapVote.CustomMenu:MakePopup()
    SolidMapVote.CustomMenu.startTime = SysTime()
    SolidMapVote.CustomMenu.votes = votes or {}
    SolidMapVote.CustomMenu.maps = maps or {}
    SolidMapVote.CustomMenu.endTime = endTime or 0
    
    SolidMapVote.CustomMenu.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 245))
    end
    
    local mainFrame = SolidMapVote.CustomMenu

    local textJoin = vgui.Create("DLabel", mainFrame)
    textJoin:SetTextColor(Color(255, 255, 255, 255))
    textJoin:SetFont("HomigradFontBig")
    textJoin:SetText(GetPhrase("rtv_header"))
    textJoin:SizeToContents()
    textJoin:SetPos(screenW / 2 - textJoin:GetWide() / 2, 30)
    textJoin.timeStarted = CurTime()
    
    textJoin.Think = function(self)
        if not IsValid(SolidMapVote.CustomMenu) then return end
        
        local elapsed = CurTime() - self.timeStarted
        if elapsed >= 2 then
            self:MoveTo(screenW / 2 - self:GetWide() / 2, 30, 0.3, 0, 0.4)
        end
        
        if elapsed >= 3 then
            local timeLeft = math.max(0, math.ceil(SolidMapVote.CustomMenu.endTime - CurTime()))
            if IsValid(self) then
                self:SetText(GetPhrase("rtv_header_timer", timeLeft))
                self:SizeToContents()
                self:SetPos(screenW / 2 - self:GetWide() / 2, 30)
            end
        end
    end

    local gridWidth = columns * buttonSize + (columns - 1) * spacing
    local gridHeight = rows * buttonSize + (rows - 1) * spacing
    local gridStartX = (screenW - gridWidth) / 2
    local gridStartY = screenH / 4
    
    local mapButtons = {}
    local mapsToShow = {}
    
    for i = 1, math.min(15, #maps) do
        mapsToShow[i] = maps[i]
    end
    
    for i = 1, #mapsToShow do
        local map = mapsToShow[i]
        local buttonMap = RTV_CreateButtonMap(mainFrame, map)
        mapButtons[i] = buttonMap
        
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)
        
        buttonMap.x_start = gridStartX
        buttonMap.y_start = -screenH
        buttonMap:SetSize(buttonSize, buttonSize)
        buttonMap.col = col
        buttonMap.row = row
        buttonMap.wa = buttonSize
        buttonMap.ha = buttonSize
        
        buttonMap.Think = function(self)
            if not IsValid(SolidMapVote.CustomMenu) then return end
            
            local targetX = gridStartX + (buttonSize + spacing) * self.col
            local targetY = gridStartY + (buttonSize + spacing) * self.row
            
            local timeLeft = SolidMapVote.CustomMenu.endTime - CurTime()
            local timeElapsed = (SolidMapVote['Config']['Length'] or 25) - timeLeft
            
            local realWinner = SolidMapVote.realWinner or ""
            if timeLeft <= 0 and SolidMapVote.winningMap and self.map ~= SolidMapVote.winningMap and self.map ~= realWinner then
                self.y_start = Lerp(0.08, self.y_start or targetY, -screenH)
            else

                if timeElapsed >= 0.2 then
                    self.y_start = Lerp(0.08, self.y_start or -screenH, targetY)
                end
            end
            
            -- Center the winner //ее гпткод
            if timeLeft <= -0.5 and (self.map == SolidMapVote.winningMap or self.map == realWinner) then
                local xtarget = screenW / 2 - self.wa / 2
                local ytarget = screenH / 2 - self.ha / 2
                self.x_start = Lerp(0.08, self.x_start, xtarget)
                self.y_start = Lerp(0.08, self.y_start or targetY, ytarget)
                self.wa = Lerp(0.08, self.wa or buttonSize, 220 * scale)
                self.ha = Lerp(0.08, self.ha or buttonSize, 220 * scale)
            end
            
            self:SetPos((timeLeft <= -0.5 and (self.map == SolidMapVote.winningMap or self.map == realWinner)) and self.x_start or targetX, self.y_start)
            self:SetSize(self.wa, self.ha)
        end
    end
    
    local rightButtonX = gridStartX + gridWidth + spacing * 2
    local rightButtonY = screenH / 3

    if maps and #maps > 0 then
        local buttonRandomMap = RTV_CreateRandomMap(mainFrame, maps)
        buttonRandomMap.map = "random"
        buttonRandomMap.wa = buttonSize
        buttonRandomMap.ha = buttonSize
        buttonRandomMap:SetSize(buttonRandomMap.wa, buttonRandomMap.ha)
        buttonRandomMap.ystart = -screenH
        buttonRandomMap.xstart = rightButtonX
        
        buttonRandomMap.Think = function(self)
            if not IsValid(SolidMapVote.CustomMenu) then return end
            
            local timeLeft = SolidMapVote.CustomMenu.endTime - CurTime()
            local timeElapsed = (SolidMapVote['Config']['Length'] or 15) - timeLeft
            
            local realWinner = SolidMapVote.realWinner or ""

            if timeLeft <= 0 and SolidMapVote.winningMap and "random" ~= SolidMapVote.winningMap and "random" ~= realWinner then
                self.ystart = Lerp(0.08, self.ystart or rightButtonY, -screenH)
            else
                if timeElapsed >= 0.2 then
                    self.ystart = Lerp(0.08, self.ystart or -screenH, rightButtonY)
                end
            end
            
            local realWinner = SolidMapVote.realWinner or ""
            if timeLeft <= -0.5 and (self.map == SolidMapVote.winningMap or self.map == realWinner) then
                local xtarget, ytarget = screenW / 2 - self.wa / 2, screenH / 2 - self.ha / 2
                self.xstart = Lerp(0.08, self.xstart or rightButtonX, xtarget)
                self.ystart = Lerp(0.08, self.ystart or rightButtonY, ytarget)
                self.wa = Lerp(0.08, self.wa or buttonSize, 220 * scale)
                self.ha = Lerp(0.08, self.ha or buttonSize, 220 * scale)
            end
            
            self:SetPos(self.xstart, self.ystart)
            self:SetSize(self.wa, self.ha)
        end
    end
    
    local buttonExtendMap = RTV_CreateExtendMap(mainFrame)
    buttonExtendMap.map = "extend"
    buttonExtendMap.wa = buttonSize
    buttonExtendMap.ha = buttonSize
    buttonExtendMap:SetSize(buttonExtendMap.wa, buttonExtendMap.ha)
    buttonExtendMap.ystart = -screenH
    buttonExtendMap.xstart = rightButtonX
    buttonExtendMap.targetY = rightButtonY + buttonSize + spacing
    
    buttonExtendMap.Think = function(self)
        if not IsValid(SolidMapVote.CustomMenu) then return end
        
        local timeLeft = SolidMapVote.CustomMenu.endTime - CurTime()
        local timeElapsed = (SolidMapVote['Config']['Length'] or 25) - timeLeft
        
        local realWinner = SolidMapVote.realWinner or ""
        -- Hide when time is up and not the winner
        if timeLeft <= 0 and SolidMapVote.winningMap and "extend" ~= SolidMapVote.winningMap and "extend" ~= realWinner then
            self.ystart = Lerp(0.08, self.ystart or self.targetY, -screenH)
        else
            if timeElapsed >= 0.2 then
                self.ystart = Lerp(0.08, self.ystart or -screenH, self.targetY)
            end
        end
        
        local realWinner = SolidMapVote.realWinner or ""
        if timeLeft <= -0.5 and ("extend" == SolidMapVote.winningMap or "extend" == realWinner) then
            local xtarget, ytarget = screenW / 2 - self.wa / 2, screenH / 2 - self.ha / 2
            self.xstart = Lerp(0.08, self.xstart or rightButtonX, xtarget)
            self.ystart = Lerp(0.08, self.ystart or self.targetY, ytarget)
            self.wa = Lerp(0.08, self.wa or buttonSize, 220 * scale)
            self.ha = Lerp(0.08, self.ha or buttonSize, 220 * scale)
        end
        
        self:SetPos(self.xstart, self.ystart)
        self:SetSize(self.wa, self.ha)
    end
    
    local hintText = vgui.Create("DLabel", mainFrame)
    hintText:SetTextColor(Color(200, 200, 200, 255))
    hintText:SetFont("H.18")
    hintText:SetText("SELECT A MAP TO VOTE")
    hintText:SizeToContents()
    hintText:SetPos(screenW / 2 - hintText:GetWide() / 2, 110 * scaleY)
    hintText.timeStarted = CurTime()
    
    hintText.Think = function(self)
        local elapsed = CurTime() - self.timeStarted
        if elapsed >= 20 then
            self:AlphaTo(0, 0.3, 0, function()
                if IsValid(self) then self:Remove() end
            end)
        end
    end
    
    gui.EnableScreenClicker(true)
end

function SolidMapVote.CloseCustomUI()
    if IsValid(SolidMapVote.CustomMenu) then
        SolidMapVote.CustomMenu:Remove()
        SolidMapVote.CustomMenu = nil
    end
    
    gui.EnableScreenClicker(false)
    SolidMapVote.isOpen = false
end

function SolidMapVote.UpdateCustomVotes(votes)
    if IsValid(SolidMapVote.CustomMenu) then
        SolidMapVote.CustomMenu.votes = votes
        SolidMapVote.CustomMenu:InvalidateLayout(true)
    end
end
