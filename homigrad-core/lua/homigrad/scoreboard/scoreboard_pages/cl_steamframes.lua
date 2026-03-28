-- "addons\\homigrad-core\\lua\\homigrad\\scoreboard\\scoreboard_pages\\cl_steamframes.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SteamFrames = SteamFrames or {}

local RequestQueue = {}

local IsRequesting = false 

local BotFrameURL = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/items/570/28534c7301337153c965df537634500726df52a0.png"



local function ProcessQueue()

    if IsRequesting or #RequestQueue == 0 then return end



    IsRequesting = true

    local steamid64 = table.remove(RequestQueue, 1)



    local url = "https://steamcommunity.com/profiles/" .. steamid64 .. "/"



    http.Fetch(url,

        function(body)

            local frameURL = string.match(body, '<div class="profile_avatar_frame".-<img%s+src="(.-)"')

            SteamFrames[steamid64] = frameURL or false

            

            IsRequesting = false

            timer.Simple(0.2, ProcessQueue) 

        end,

        function()

            SteamFrames[steamid64] = false

            

            IsRequesting = false

            timer.Simple(0.5, ProcessQueue)

        end

    )

end



local function GetPlayerFrameURL(steamid64)

    if SteamFrames[steamid64] ~= nil then return end

    for _, v in ipairs(RequestQueue) do

        if v == steamid64 then return end

    end



    table.insert(RequestQueue, steamid64)

    ProcessQueue()

end



timer.Create("HG_SteamFrames_Check", 5, 0, function()

    for _, ply in ipairs(player.GetAll()) do

        if IsValid(ply) and not ply:IsBot() then

            local sid64 = ply:SteamID64()

            if sid64 and sid64 ~= "0" and SteamFrames[sid64] == nil then

                GetPlayerFrameURL(sid64)

            end

        end

    end

end)



function BuildPlayerScoreHTML(ply)

    if not IsValid(ply) then return "" end



    local frame = nil



    if ply:IsBot() then

        frame = BotFrameURL

    else

        local sid64 = ply:SteamID64() or ""

        frame = SteamFrames[sid64]

    end



    if not frame or frame == false then return "" end



    local html = [[

    <html>

    <head>

    <meta charset="utf-8">

    <style>

    body {

        margin: -3;

        padding: 20;

        background: transparent;

        overflow: hidden;

    }

    .frame {

        width: 96px;

        height: 96px;

        object-fit: contain;

    }

    </style>

    </head>

    <body>

    ]]



    html = html .. string.format('<img class="frame" src="%s">', frame)

    html = html .. [[</body></html>]]



    return html

end

