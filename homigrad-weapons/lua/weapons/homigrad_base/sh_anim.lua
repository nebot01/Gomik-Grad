-- "addons\\homigrad-weapons\\lua\\weapons\\homigrad_base\\sh_anim.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
/*
1 - Дефолт
2 - Одна рука | Занижено (ДВУРУЧНЫЕ)
3 - Сверху
4 - Сомали
5 - 
*/

local Postures = {
    [1] = {[0] = {Angle(0,0,0),Vector(0,0,0)}, //ля пистоля
           [1] = {Angle(0,0,0),Vector(0,0,0)}}, //Автомат нахуй

    [2] = {[0] = {Angle(0,0,-25),Vector(2,-1.5,-2)},
           [1] = {Angle(0,0,-15),Vector(0,-2,-1)},
           [2] = true},

    [3] = {[0] = {Angle(0,0,-40),Vector(5,4,5)},
           [1] = {Angle(0,0,-40),Vector(0,2,4)},
           [2] = true},

    [4] = {[0] = {Angle(0,0,20),Vector(4,13.25,6)},
           [1] = {Angle(0,0,20),Vector(0,7.25,4)},
           [2] = true},
    [5] = {[0] = {Angle(0,0,-3),Vector(4,0,-1)},
           [1] = {Angle(0,0,15),Vector(0,-2.25,0)},
           [2] = true},
}

if SERVER then
    util.AddNetworkString("hg posture")

    net.Receive("hg posture",function(l,ply)
        local arg = net.ReadInt(4)
        if arg <= 0 then
            arg = nil
        end
        if !ply.last_post or ply.last_post < CurTime() then
            ply.last_post = CurTime() + 0.5   
            if !arg then
                if !ply.posture then
                    ply.posture = 1
                end
                ply.posture = ply.posture + 1 
                if ply.posture > #Postures then
                    ply.posture = 1
                end
            else
                ply.posture = math.Clamp(arg,1,#Postures)
            end

            ply:SetNWInt("post",ply.posture)
        end
    end)
end

if CLIENT then
    concommand.Add("hg_change_posture",function(ply,cmd,arg)
        net.Start("hg posture")
        if arg[1] then
            net.WriteInt(arg[1],4)
        end
        net.SendToServer()
    end)
end

function SWEP:Post_Hands_Anim()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if SERVER then
        ply:SetNWInt("post",ply.posture or 1)
    end

    /*if !self.Deployed then
        local pos,ang = self:WorldModel_Holster_Transform()

        ply.prev_wep_ang = ang
        self.WorldAng = ang
        return
    end*/

    local cur_pos = ply:GetNWInt("post",1)

    local is = self:IsPistolHoldType() and 0 or 1

    local posture = Postures[cur_pos] or Postures[1]
    local poseData = posture[is] or Postures[1][is] or Postures[1][1]
    local poseAng = poseData[1] or angle_zero
    local posePos = poseData[2] or vector_origin
    local pos,ang = Vector(posePos[1], posePos[2], posePos[3]), Angle(poseAng[1], poseAng[2], poseAng[3])

    if self:IsSighted() then
        ang[3] = 0
    end

    if self:IsPistolHoldType() and posture[2] and !self.reload and !self:IsSprinting() then
        self.NoLHand = true
        self:SetHoldType("melee")
    else
        self:SetHoldType((ply:GetNWBool("suiciding") and "normal" or self.HoldType))
        self.NoLHand = ply:GetNWBool("suiciding") and (self:IsPistolHoldType() and true or false) or ply:GetNWBool("LeftArm")
        cur_pos = 1
        if self.reload or self:IsSprinting() then
            pos = Vector()
            ang = Angle()
        end
    end

    self.WorldPos = self.DWorldPos + pos
    self.WorldAng = self.DWorldAng + ang
end
