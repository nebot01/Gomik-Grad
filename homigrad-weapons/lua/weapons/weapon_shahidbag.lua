-- "addons\\homigrad-core\\lua\\weapons\\weapon_shahidbag.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
AddCSLuaFile()

SWEP.PrintName = "Сумка шахида"
SWEP.Author = "gomigrad_r"
SWEP.Instructions = "ЛКМ: надеть/взорвать\nПКМ: снять сумку"
SWEP.Category = "Остальное"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Base = "weapon_base"
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/eft_props/gear/backpacks/bp_forward.mdl"
SWEP.HoldType = "normal"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.IconPos = Vector(90, 1, 3)
SWEP.IconAng = Angle(0, 0, 0)
SWEP.WepSelectIcon2 = Material("null")
SWEP.IconOverride = ""

SWEP.Purpose = "Сумка Adidas начиненная 30 килограммами гексогена, ничего необычного, ведь, да?"

local function EnsureArmorTable(ply)
    if not IsValid(ply) then return false end
    if not istable(ply.armor) then
        ply.armor = {
            torso = "NoArmor",
            head = "NoArmor",
            face = "NoArmor",
            back = "NoArmor",
            lleg = "NoArmor",
            rleg = "NoArmor",
            larm = "NoArmor",
            rarm = "NoArmor"
        }
    end
    return true
end

local function SyncArmor(ply)
    if not IsValid(ply) then return end
    if ply.SetNetVar then
        ply:SetNetVar("Armor", ply.armor)
    else
        ply:SetNWString("ArmorSyncFallback", tostring(CurTime()))
    end
end

local function EquipBag(ply)
    if not EnsureArmorTable(ply) then return end
    if ply.armor.back ~= "NoArmor" and ply.armor.back ~= "back1" and hg and hg.DropArmor then
        hg.DropArmor(ply, ply.armor.back, nil, ply:EyeAngles():Forward() * 150)
    end
    if hg and hg.Equip_Armor then
        hg.Equip_Armor(ply, "back1")
    else
        ply.armor.back = "back1"
    end
    sound.Play("eft_gear_sounds/gear_armor_use.wav", ply:GetPos(), 100, 100, 1)
    SyncArmor(ply)
end

local function RemoveBag(ply)
    if not EnsureArmorTable(ply) then return end
    if ply.armor.back == "back1" then
        ply.armor.back = "NoArmor"
        SyncArmor(ply)
    end
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
    hg.DrawWeaponSelection(self, x, y, wide, tall, alpha)
end

if CLIENT then
    function SWEP:DrawWorldModel()
    end

    function SWEP:PreDrawViewModel()
        return true
    end
end

function SWEP:PrimaryAttack()
    if not SERVER then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    if (self._nextAction or 0) > CurTime() then return end
    self._nextAction = CurTime() + 0.35

    if not self.BagArmed then
        EquipBag(ply)
        self.BagArmed = true
        self:SetNextPrimaryFire(CurTime() + 0.35)
        return
    end

    self.BagArmed = false
    local weapon = self
    sound.Play("homigrad/allah/boom.mp3", ply:GetPos(), 100, 100, 1)
    self:SetNextPrimaryFire(CurTime() + 1.2)

    timer.Simple(1, function()
        if not IsValid(weapon) then return end
        local owner = weapon:GetOwner()
        if not IsValid(owner) then
            weapon:Remove()
            return
        end

        local pos = owner:WorldSpaceCenter()
        util.BlastDamage(weapon, owner, pos, 420, 360)

        local ed = EffectData()
        ed:SetOrigin(pos)
        ed:SetScale(2)
        util.Effect("Explosion", ed, true, true)
        ParticleEffect("pcf_jack_groundsplode_large", pos, vector_up:Angle())
        sound.Play("BaseExplosionEffect.Sound", pos, 120, math.random(90, 110), 1)
        for i = 1, math.random(2, 4) do
            sound.Play("explosions/doi_ty_01_close.wav", pos, 140, math.random(80, 110), 1)
        end
        util.ScreenShake(pos, 99999, 99999, 1, 3000)

        RemoveBag(owner)
        owner:Kill()
        weapon:Remove()
    end)
end

function SWEP:SecondaryAttack()
    if not SERVER then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    if (self._nextAction or 0) > CurTime() then return end
    self._nextAction = CurTime() + 0.25

    self.BagArmed = false
    RemoveBag(ply)
    self:SetNextSecondaryFire(CurTime() + 0.25)
end

function SWEP:Holster()
    return true
end

function SWEP:OnRemove()
    if not SERVER then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
end
