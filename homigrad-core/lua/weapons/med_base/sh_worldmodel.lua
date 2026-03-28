-- "addons\\homigrad-core\\lua\\weapons\\med_base\\sh_worldmodel.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
SWEP.WorldAng = Angle(0,0,0)
SWEP.WorldPos = Vector(0,0,0)

function SWEP:CreateWorldModel()
    if not IsValid(self:GetOwner()) then return end
    if IsValid(self.worldModel) then return end
    local WorldModel = ClientsideModel(self.WorldModelReal or self.WorldModel)
    if not IsValid(WorldModel) then return end

    WorldModel:SetOwner(self:GetOwner())

    WorldModel.IsIcon = true

    self:CallOnRemove("RemoveWM", function()
        if IsValid(WorldModel) then
            WorldModel:Remove()
        end
    end)

    self.worldModel = WorldModel

    return WorldModel
end

function SWEP:DrawWM()
    if not IsValid(self:GetOwner()) then return end 
    local WM = self.worldModel
    local owner = self:GetOwner()
    if owner:GetActiveWeapon() != self then
        return
    end
    if not IsValid(WM) then self:CreateWorldModel() return end
    if owner.Fake then
        if IsValid(self.worldModel) then
            self.worldModel:Remove()
        end
        self.worldModel = nil
        return
    end
    if !owner:Alive() then return end

    local attIndex = owner:LookupAttachment("anim_attachment_RH")
    local Att = attIndex and attIndex > 0 and owner:GetAttachment(attIndex) or nil
    WM.IsIcon = true

    local Pos, Ang
    if Att and Att.Pos and Att.Ang then
        Pos = Att.Pos
        Ang = Angle(Att.Ang.p, Att.Ang.y, Att.Ang.r)
    else
        local handBone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
        if handBone then
            Pos, Ang = owner:GetBonePosition(handBone)
        end
        if not Pos or not Ang then
            Pos = owner:GetShootPos()
            Ang = owner:EyeAngles()
        end
    end

    WM:SetModelScale(self.CorrectScale or 1,0)

    local worldPos = self.WorldPos or Vector(0,0,0)
    local worldAng = self.WorldAng or Angle(0,0,0)

    Pos = Pos + Ang:Forward() * worldPos[1] + Ang:Right() * worldPos[2] + Ang:Up() * worldPos[3]
    Ang:RotateAroundAxis(Ang:Forward(), worldAng[1])
    Ang:RotateAroundAxis(Ang:Right(), worldAng[2])
    Ang:RotateAroundAxis(Ang:Up(), worldAng[3])

    WM:SetAngles(Ang)
    WM:SetPos(Pos)
    WM:SetOwner(owner)
    WM:SetParent(owner)
    WM:SetPredictable(true)

    WM:SetRenderAngles(Ang)
    WM:SetRenderOrigin(Pos)

    return Pos,Ang
end

function SWEP:DrawWorldModel()
    if not IsValid(self:GetOwner()) then self:DrawModel() return end
    local owner = self:GetOwner()

	local Pos,Ang = self:DrawWM()

	if IsValid(self.worldModel) and Pos then
		self.worldModel:SetPos(Pos)
		self.worldModel:SetAngles(Ang)
	end
end
