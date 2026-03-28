
util.AddNetworkString("JB_PoliceRankSet")

net.Receive("JB_PoliceRankSet", function(len, ply)
    local target = net.ReadEntity()
    local rank = net.ReadUInt(3)

    if not IsValid(ply) or not IsValid(target) then return end

    local allowed = false
    
    if ply:IsSuperAdmin() or ply:IsAdmin() then allowed = true end
    if ply:GetUserGroup() == "owner" or ply:GetUserGroup() == "superadmin" then allowed = true end

    if not allowed then return end

    target:SetNWInt("JBPoliceRank", rank)
end)