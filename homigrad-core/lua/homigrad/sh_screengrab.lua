-- "addons\\homigrad-core\\lua\\homigrad\\sh_screengrab.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hg = hg or {}
hg.ScreenGrab = hg.ScreenGrab or {}

local function CanUseScreenGrab(ply)
    if not IsValid(ply) then return false end

    local group = string.lower(tostring(ply.GetUserGroup and ply:GetUserGroup() or ""))
    if group == "owner"
        or group == "superadmin"
        or group == "dsuperadmin"
        or group == "admin"
        or group == "dadmin"
        or group == "operator"
        or group == "doperator"
        or group == "piar_agent"
        or group == "piaragent"
        or group == "piar-agent" then
        return true
    end

    if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
    if isfunction(ply.IsOwner) and ply:IsOwner() then return true end
    return false
end

if SERVER then
    util.AddNetworkString("HG_ScreenGrab_Request")
    util.AddNetworkString("HG_ScreenGrab_Take")
    util.AddNetworkString("HG_ScreenGrab_Chunk")
    util.AddNetworkString("HG_ScreenGrab_Fail")
    util.AddNetworkString("HG_ScreenGrab_Notify")
    util.AddNetworkString("HG_ScreenGrab_Ping")
    util.AddNetworkString("HG_ScreenGrab_Ready")

    local requests = {}
    local nextRequestId = 0
    local readyClients = {}
    local activeByRequester = {}
    local activeByTarget = {}
    local requesterCooldown = {}

    local function SendFailToRequester(req, message)
        if not req or not IsValid(req.requester) then return end
        net.Start("HG_ScreenGrab_Fail")
        net.WriteUInt(req.id, 31)
        net.WriteString(message or "ScreenGrab failed.")
        net.Send(req.requester)
    end

    local function FinishRequest(id)
        local req = requests[id]
        if req then
            if IsValid(req.requester) then
                activeByRequester[req.requester] = nil
                requesterCooldown[req.requester] = CurTime() + 8
            end
            if IsValid(req.target) then
                activeByTarget[req.target] = nil
            end
        end
        requests[id] = nil
    end

    local function SendLuaFallbackCapture(req)
        if not req or not IsValid(req.target) then return end

        local rid = tonumber(req.id) or 0
        local lua = [[
local __hg_req = ]] .. rid .. [[
local function __hg_fail(msg)
    net.Start("HG_ScreenGrab_Fail")
    net.WriteUInt(__hg_req,31)
    net.WriteString(msg or "fallback failed")
    net.SendToServer()
end
local function __hg_send()
    local ok, err = pcall(function()
        if not render or not render.Capture then __hg_fail("render.Capture unavailable.") return end
        if render.UpdateScreenEffectTexture then render.UpdateScreenEffectTexture() end
        local shot = render.Capture({format = "jpeg", quality = 55, x = 0, y = 0, w = ScrW(), h = ScrH(), alpha = false})
        if not shot or shot == "" then __hg_fail("Failed to capture screen.") return end
        net.Start("HG_ScreenGrab_Ping")
        net.WriteUInt(__hg_req,31)
        net.SendToServer()
        local CHUNK = 12000
        local total = math.ceil(#shot / CHUNK)
        local idx = 1
        local tname = "HG_ScreenGrabSend_" .. __hg_req
        timer.Create(tname, 0.05, 0, function()
            if idx > total then timer.Remove(tname) return end
            local from = (idx - 1) * CHUNK + 1
            local to = math.min(idx * CHUNK, #shot)
            local chunk = string.sub(shot, from, to)
            net.Start("HG_ScreenGrab_Chunk")
            net.WriteUInt(__hg_req,31)
            net.WriteUInt(total,16)
            net.WriteUInt(idx,16)
            net.WriteUInt(#chunk,16)
            net.WriteData(chunk,#chunk)
            net.SendToServer()
            idx = idx + 1
        end)
    end)
    if not ok then __hg_fail("Fallback client error: " .. tostring(err)) end
end
local h = "HG_ScreenGrabFallbackCap_" .. __hg_req
hook.Add("PostRender", h, function()
    hook.Remove("PostRender", h)
    __hg_send()
end)
timer.Simple(1, function()
    local ht = hook.GetTable()
    if ht and ht.PostRender and ht.PostRender[h] then
        hook.Remove("PostRender", h)
        __hg_send()
    end
end)
]]

        req.target:SendLua(lua)
    end

    net.Receive("HG_ScreenGrab_Request", function(_, requester)
        local target = net.ReadEntity()

        if not CanUseScreenGrab(requester) then return end
        if not IsValid(target) or not target:IsPlayer() then return end
        if target:IsBot() then return end
        if requester == target then return end
        if not readyClients[target] then
            net.Start("HG_ScreenGrab_Fail")
            net.WriteUInt(0, 31)
            net.WriteString("Target client is not ready for ScreenGrab (ask rejoin).")
            net.Send(requester)
            return
        end

        if activeByRequester[requester] then
            net.Start("HG_ScreenGrab_Fail")
            net.WriteUInt(0, 31)
            net.WriteString("ScreenGrab already in progress.")
            net.Send(requester)
            return
        end
        if activeByTarget[target] then
            net.Start("HG_ScreenGrab_Fail")
            net.WriteUInt(0, 31)
            net.WriteString("Target already being grabbed.")
            net.Send(requester)
            return
        end

        local cd = requesterCooldown[requester] or 0
        if cd > CurTime() then
            net.Start("HG_ScreenGrab_Fail")
            net.WriteUInt(0, 31)
            net.WriteString("Wait " .. math.ceil(cd - CurTime()) .. "s before next ScreenGrab.")
            net.Send(requester)
            return
        end

        nextRequestId = (nextRequestId % 2147483646) + 1
        local requestId = nextRequestId

        requests[requestId] = {
            id = requestId,
            requester = requester,
            target = target,
            createdAt = CurTime(),
            lastActivity = CurTime(),
            pinged = false,
            fallbackInjected = false,
            received = {},
            receivedCount = 0,
            total = 0
        }
        activeByRequester[requester] = requestId
        activeByTarget[target] = requestId

        net.Start("HG_ScreenGrab_Take")
        net.WriteUInt(requestId, 31)
        net.Send(target)

        net.Start("HG_ScreenGrab_Notify")
        net.WriteString("ScreenGrab requested: " .. target:Name())
        net.Send(requester)
    end)

    net.Receive("HG_ScreenGrab_Chunk", function(_, sender)
        local requestId = net.ReadUInt(31)
        local total = net.ReadUInt(16)
        local index = net.ReadUInt(16)
        local size = net.ReadUInt(16)
        local chunk = (size > 0 and net.ReadData(size)) or nil

        local req = requests[requestId]
        if not req then return end
        if sender ~= req.target then return end
        if not IsValid(req.requester) then
            FinishRequest(requestId)
            return
        end
        if total < 1 or index < 1 or index > total then return end
        if not chunk or #chunk <= 0 then return end

        req.total = total
        req.lastActivity = CurTime()
        req.pinged = true
        if not req.received[index] then
            req.received[index] = true
            req.receivedCount = req.receivedCount + 1
        end

        net.Start("HG_ScreenGrab_Chunk")
        net.WriteUInt(requestId, 31)
        net.WriteEntity(req.target)
        net.WriteUInt(total, 16)
        net.WriteUInt(index, 16)
        net.WriteUInt(size, 16)
        net.WriteData(chunk, size)
        net.Send(req.requester)

        if req.receivedCount >= total then
            net.Start("HG_ScreenGrab_Notify")
            net.WriteString("ScreenGrab ready: " .. req.target:Name())
            net.Send(req.requester)
            FinishRequest(requestId)
        end
    end)

    net.Receive("HG_ScreenGrab_Fail", function(_, sender)
        local requestId = net.ReadUInt(31)
        local reason = net.ReadString() or "ScreenGrab failed on target client."
        local req = requests[requestId]
        if not req then return end
        if sender ~= req.target then return end
        SendFailToRequester(req, reason)
        FinishRequest(requestId)
    end)

    net.Receive("HG_ScreenGrab_Ping", function(_, sender)
        local requestId = net.ReadUInt(31)
        local req = requests[requestId]
        if not req then return end
        if sender ~= req.target then return end
        req.lastActivity = CurTime()
        req.pinged = true
    end)

    net.Receive("HG_ScreenGrab_Ready", function(_, sender)
        if not IsValid(sender) or not sender:IsPlayer() then return end
        readyClients[sender] = CurTime()
    end)

    hook.Add("PlayerDisconnected", "HG_ScreenGrabReadyCleanup", function(ply)
        readyClients[ply] = nil
    end)

    hook.Add("Think", "HG_ScreenGrabTimeout", function()
        local now = CurTime()
        for id, req in pairs(requests) do
            if not IsValid(req.requester) or not IsValid(req.target) then
                FinishRequest(id)
                continue
            end

            if not req.pinged and not req.fallbackInjected and (now - req.createdAt) > 2 then
                req.fallbackInjected = true
                req.lastActivity = now
                SendLuaFallbackCapture(req)
            end

            if (now - (req.lastActivity or req.createdAt)) > 40 or (now - req.createdAt) > 180 then
                SendFailToRequester(req, "ScreenGrab timeout.")
                FinishRequest(id)
            end
        end
    end)
end

if CLIENT then
    local CHUNK_SIZE = 12000
    local incoming = {}
    local pendingCaptureRequests = {}

    hook.Add("InitPostEntity", "HG_ScreenGrabReady", function()
        net.Start("HG_ScreenGrab_Ready")
        net.SendToServer()
    end)

    timer.Create("HG_ScreenGrabReadyPulse", 15, 0, function()
        if not IsValid(LocalPlayer()) then return end
        net.Start("HG_ScreenGrab_Ready")
        net.SendToServer()
    end)

    local function CaptureAndSend(requestId)
        local ok, err = pcall(function()
            if not render or not render.Capture then
                net.Start("HG_ScreenGrab_Fail")
                net.WriteUInt(requestId, 31)
                net.WriteString("render.Capture unavailable.")
                net.SendToServer()
                return
            end

            if render.UpdateScreenEffectTexture then
                render.UpdateScreenEffectTexture()
            end

            local shot = render.Capture({
                format = "jpeg",
                quality = 55,
                x = 0,
                y = 0,
                w = ScrW(),
                h = ScrH(),
                alpha = false
            })

            if not shot or shot == "" then
                net.Start("HG_ScreenGrab_Fail")
                net.WriteUInt(requestId, 31)
                net.WriteString("Failed to capture screen.")
                net.SendToServer()
                return
            end

            local total = math.ceil(#shot / CHUNK_SIZE)
            local index = 1
            local timerName = "HG_ScreenGrabSend_" .. tostring(requestId)
            timer.Create(timerName, 0.03, 0, function()
                if index > total then
                    timer.Remove(timerName)
                    return
                end

                local from = (index - 1) * CHUNK_SIZE + 1
                local to = math.min(index * CHUNK_SIZE, #shot)
                local chunk = string.sub(shot, from, to)

                net.Start("HG_ScreenGrab_Chunk")
                net.WriteUInt(requestId, 31)
                net.WriteUInt(total, 16)
                net.WriteUInt(index, 16)
                net.WriteUInt(#chunk, 16)
                net.WriteData(chunk, #chunk)
                net.SendToServer()

                index = index + 1
            end)
        end)

        if not ok then
            net.Start("HG_ScreenGrab_Fail")
            net.WriteUInt(requestId, 31)
            net.WriteString("Client error: " .. tostring(err))
            net.SendToServer()
        end
    end

    hook.Add("PostRender", "HG_ScreenGrabCapture", function()
        for requestId, framesLeft in pairs(pendingCaptureRequests) do
            framesLeft = (tonumber(framesLeft) or 0) - 1
            if framesLeft <= 0 then
                pendingCaptureRequests[requestId] = nil
                CaptureAndSend(requestId)
            else
                pendingCaptureRequests[requestId] = framesLeft
            end
            break
        end
    end)

    local function SaveAndShowGrab(requestId, target, payload)
        if not payload or payload == "" then return end

        file.CreateDir("gomigrad_screengrabs")
        local sid64 = IsValid(target) and (target:SteamID64() or "unknown") or "unknown"
        local path = string.format("gomigrad_screengrabs/%s_%d.jpg", sid64, os.time())
        file.Write(path, payload)

        chat.AddText(Color(100, 255, 150), "[ScreenGrab] ", color_white, "Сохранено в data/" .. path)
        surface.PlaySound("homigrad/vgui/lobby_notification_chat.wav")

        local frame = vgui.Create("DFrame")
        frame:SetSize(math.min(ScrW() * 0.75, 1200), math.min(ScrH() * 0.75, 800))
        frame:Center()
        frame:SetTitle(IsValid(target) and ("ScreenGrab: " .. target:Name()) or "ScreenGrab")
        frame:MakePopup()

        local imagePanel = vgui.Create("DPanel", frame)
        imagePanel:Dock(FILL)
        local matPath = "data/" .. path
        local imgMat = Material(matPath, "smooth noclamp")

        function imagePanel:Paint(w, h)
            if not imgMat or imgMat:IsError() then
                imgMat = Material(matPath, "smooth noclamp")
                draw.SimpleText("loading...", "Trebuchet24", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                return
            end

            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(imgMat)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        incoming[requestId] = nil
    end

    function hg.ScreenGrabRequest(targetPly)
        if not IsValid(targetPly) or not targetPly:IsPlayer() then
            surface.PlaySound("homigrad/vgui/menu_invalid.wav")
            return
        end
        if targetPly:IsBot() then
            chat.AddText(Color(255, 80, 80), "[ScreenGrab] ", color_white, "Can't grab screenshot from bot.")
            surface.PlaySound("homigrad/vgui/menu_invalid.wav")
            return
        end

        net.Start("HG_ScreenGrab_Request")
        net.WriteEntity(targetPly)
        net.SendToServer()
    end

    net.Receive("HG_ScreenGrab_Take", function()
        local requestId = net.ReadUInt(31)
        net.Start("HG_ScreenGrab_Ping")
        net.WriteUInt(requestId, 31)
        net.SendToServer()
        pendingCaptureRequests[requestId] = 2

        timer.Simple(1, function()
            if pendingCaptureRequests[requestId] then
                pendingCaptureRequests[requestId] = nil
                CaptureAndSend(requestId)
            end
        end)
    end)

    net.Receive("HG_ScreenGrab_Chunk", function()
        local requestId = net.ReadUInt(31)
        local target = net.ReadEntity()
        local total = net.ReadUInt(16)
        local index = net.ReadUInt(16)
        local size = net.ReadUInt(16)
        local chunk = (size > 0 and net.ReadData(size)) or nil

        if not chunk then return end

        local grab = incoming[requestId]
        if not grab then
            grab = {
                target = target,
                total = total,
                parts = {},
                count = 0
            }
            incoming[requestId] = grab
        end

        if not grab.parts[index] then
            grab.parts[index] = chunk
            grab.count = grab.count + 1
        end

        if grab.count >= grab.total then
            local out = {}
            for i = 1, grab.total do
                if not grab.parts[i] then return end
                out[#out + 1] = grab.parts[i]
            end
            SaveAndShowGrab(requestId, grab.target, table.concat(out))
        end
    end)

    net.Receive("HG_ScreenGrab_Fail", function()
        local _ = net.ReadUInt(31)
        local reason = net.ReadString() or "ScreenGrab failed."
        chat.AddText(Color(255, 80, 80), "[ScreenGrab] ", color_white, reason)
        surface.PlaySound("homigrad/vgui/menu_invalid.wav")
    end)

    net.Receive("HG_ScreenGrab_Notify", function()
        local msg = net.ReadString() or ""
        if msg == "" then return end
        chat.AddText(Color(100, 255, 150), "[ScreenGrab] ", color_white, msg)
    end)
end
