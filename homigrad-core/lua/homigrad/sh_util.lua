-- "addons\\homigrad-core\\lua\\homigrad\\sh_util.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
local ENTITY = FindMetaTable("Entity")

function ENTITY:SetBoneMatrix2(boneID,matrix,dontset)
	local localpos = self:GetManipulateBonePosition(boneID)
	local localang = self:GetManipulateBoneAngles(boneID)
	local newmat = Matrix()
	newmat:SetTranslation(localpos)
	newmat:SetAngles(localang)
	local inv = newmat:GetInverse()
	local oldMat = self:GetBoneMatrix(boneID) * inv
	local newMat = oldMat:GetInverse() * matrix
	local lpos,lang = newMat:GetTranslation(),newMat:GetAngles()

	if not dontset then
		self:ManipulateBonePosition(boneID,lpos,false)
		self:ManipulateBoneAngles(boneID,lang,false)
	end

	return lpos,lang
end

FrameTimeClamped = 1/66
ftlerped = 1/66

local def = 1 / 144

local FrameTime, TickInterval, engine_AbsoluteFrameTime = FrameTime, engine.TickInterval, engine.AbsoluteFrameTime
local Lerp, LerpVector, LerpAngle = Lerp, LerpVector, LerpAngle
local math_min = math.min
local math_Clamp = math.Clamp

local host_timescale = game.GetTimeScale

hook.Add("Think", "Mul lerp", function()
	local ft = FrameTime()
	ftlerped = Lerp(0.5,ftlerped,math_Clamp(ft,0.001,0.1))
end)

if CLIENT then
	local PUNCH_DAMPING = 1000
	local PUNCH_SPRING_CONSTANT = 100
	vp_punch_angle = vp_punch_angle or Angle()
	local vp_punch_angle_velocity = Angle()
	vp_punch_angle_last = vp_punch_angle_last or vp_punch_angle

	vp_punch_angle2 = vp_punch_angle2 or Angle()
	local vp_punch_angle_velocity2 = Angle()
	vp_punch_angle_last2 = vp_punch_angle_last2 or vp_punch_angle2

	local PLAYER = FindMetaTable("Player")

	local seteyeangles = PLAYER.SetEyeAngles
	local fuck_you_debil = 0

	hook.Add("Think", "viewpunch_think", function()
		if not vp_punch_angle:IsZero() or not vp_punch_angle_velocity:IsZero() then
			vp_punch_angle = vp_punch_angle + vp_punch_angle_velocity * ftlerped
			local damping = 1 - (PUNCH_DAMPING * ftlerped)
			if damping < 0 then damping = 0 end
			vp_punch_angle_velocity = vp_punch_angle_velocity * damping
			local spring_force_magnitude = PUNCH_SPRING_CONSTANT * ftlerped
			vp_punch_angle_velocity = vp_punch_angle_velocity - vp_punch_angle * spring_force_magnitude
			local x, y, z = vp_punch_angle:Unpack()
			vp_punch_angle = Angle(math.Clamp(x, -89, 89), math.Clamp(y, -179, 179), math.Clamp(z, -89, 89))
		else
			vp_punch_angle = Angle()
			vp_punch_angle_velocity = Angle()
		end

		local ang = LocalPlayer():EyeAngles() + vp_punch_angle - vp_punch_angle_last

		if not vp_punch_angle2:IsZero() or not vp_punch_angle_velocity2:IsZero() then
			vp_punch_angle2 = vp_punch_angle2 + vp_punch_angle_velocity2 * ftlerped
			local damping = 1 - (PUNCH_DAMPING * ftlerped)
			if damping < 0 then damping = 0 end
			vp_punch_angle_velocity2 = vp_punch_angle_velocity2 * damping
			local spring_force_magnitude = PUNCH_SPRING_CONSTANT * ftlerped
			vp_punch_angle_velocity2 = vp_punch_angle_velocity2 - vp_punch_angle2 * spring_force_magnitude
			local x, y, z = vp_punch_angle2:Unpack()
			vp_punch_angle2 = Angle(math.Clamp(x, -89, 89), math.Clamp(y, -179, 179), math.Clamp(z, -89, 89))
		else
			vp_punch_angle2 = Angle()
			vp_punch_angle_velocity2 = Angle()
		end

		if vp_punch_angle:IsZero() and vp_punch_angle_velocity:IsZero() and vp_punch_angle2:IsZero() and vp_punch_angle_velocity2:IsZero() then return end
		local ang = LocalPlayer():EyeAngles() + vp_punch_angle - vp_punch_angle_last

		LocalPlayer():SetEyeAngles(ang + vp_punch_angle2 - vp_punch_angle_last2)
		vp_punch_angle_last = vp_punch_angle
		vp_punch_angle_last2 = vp_punch_angle2
	end)

	function SetViewPunchAngles(angle)
		if not angle then
			print("[Local Viewpunch] SetViewPunchAngles called without an angle. wtf?")
			return
		end

		vp_punch_angle = angle
	end

	function SetViewPunchVelocity(angle)
		if not angle then
			print("[Local Viewpunch] SetViewPunchVelocity called without an angle. wtf?")
			return
		end

		vp_punch_angle_velocity = angle * 20
	end

	function Viewpunch(angle,speed)
		if not angle then
			print("[Local Viewpunch] Viewpunch called without an angle. wtf?")
			return
		end

		vp_punch_angle_velocity = vp_punch_angle_velocity + angle * 20

		PUNCH_DAMPING = speed or 20
	end

	function Viewpunch2(angle,speed)
		if not angle then
			print("[Local Viewpunch] Viewpunch called without an angle. wtf?")
			return
		end

		vp_punch_angle_velocity2 = vp_punch_angle_velocity2 + angle * 20
	end

	function ViewPunch(angle,speed)
		Viewpunch(angle,speed)
	end

	function ViewPunch2(angle,speed)
		Viewpunch2(angle,speed)
	end

	function GetViewPunchAngles()
		return vp_punch_angle
	end

	function GetViewPunchAngles2()
		return vp_punch_angle2
	end

	function GetViewPunchVelocity()
		return vp_punch_angle_velocity
	end

	local prev_on_ground,current_on_ground,speedPrevious,speed = false,false,0,0
	local angle_hitground = Angle(0,0,0)
	hook.Add("Think", "CP_detectland", function()
		prev_on_ground = current_on_ground
		current_on_ground = LocalPlayer():OnGround()

		speedPrevious = speed
		speed = -LocalPlayer():GetVelocity().z

		if prev_on_ground != current_on_ground and current_on_ground and LocalPlayer():GetMoveType() != MOVETYPE_NOCLIP then
			angle_hitground.p = math.Clamp(speedPrevious / 15, 0, 20)

			ViewPunch(angle_hitground / 2)
			Recoil = 2
		end
	end)
end

function hg.RagdollOwner(ent)
    if !IsValid(ent) or not ent:IsRagdoll() then return NULL end

    return ent:GetNWEntity("RagdollOwner",NULL)
end

local lend = 2
local vec = Vector(lend,lend,lend)
local traceBuilder = {
	mins = -vec,
	maxs = vec,
	mask = MASK_SOLID,
	collisiongroup = COLLISION_GROUP_DEBRIS
}

local util_TraceHull = util.TraceHull

function hg.hullCheck(startpos,endpos,ply)
	if ply:InVehicle() then return {HitPos = endpos} end
	traceBuilder.start = IsValid(ply.FakeRagdoll) and endpos or startpos
	traceBuilder.endpos = endpos
	traceBuilder.filter = {ply,hg.GetCurrentCharacter(ply)}
	local trace = util_TraceHull(traceBuilder)

	return trace
end

function hg.ShouldTPIK(wep,ply)
	if !ply:Alive() then
		return false
	end

	return wep.SupportTPIK == true
end

if SERVER then
	concommand.Add("suicide",function(ply,args)
		if ply:GetActiveWeapon().CanSuicide then
			ply.suiciding = not ply.suiciding
		end
	end)

	util.AddNetworkString("GGrad_Notificate")

	function GGrad_SendNotify(target, msg, clr)
		if not isstring(msg) then return end
		net.Start("GGrad_Notificate")
		net.WriteString(msg)
		net.WriteColor(IsColor(clr) and clr or Color(90, 87, 87))
		if istable(target) then
			net.Send(target)
		elseif IsValid(target) then
			net.Send(target)
		else
			net.Broadcast()
		end
	end

	concommand.Add("hg_notifytest", function(ply)
		if not IsValid(ply) then return end
		GGrad_SendNotify(ply, "PLAYER: " .. ply:Nick() .. " | " .. ply:SteamID(), Color(120, 120, 120))
	end)
end

function hg.eyeTrace(ply, dist, ent, aim_vector, startpos)
	local fakeCam = IsValid(ply.FakeRagdoll)
	local ent = IsValid(ent) and ent or hg.GetCurrentCharacter(ply)
	if ent == NULL then return end
	local bon = ent:LookupBone("ValveBiped.Bip01_Head1")
	if not bon then return end
	if not IsValid(ply) then return end
	if not ply.GetAimVector then return end
	
	local aim_vector = aim_vector or ply:GetAimVector()

	if not bon or not ent:GetBoneMatrix(bon) then
		local tr = {
			start = ply:EyePos(),
			endpos = ply:EyePos() + aim_vector * (dist or 60),
			filter = ply
		}
		return util.TraceLine(tr)
	end

	if (ply.InVehicle and ply:InVehicle() and IsValid(ply:GetVehicle())) then
		local veh = ply:GetVehicle()
		local vehang = veh:GetAngles()
		local tr = {
			start = ply:EyePos() + vehang:Right() * -6 + vehang:Up() * 4,
			endpos = ply:EyePos() + aim_vector * (dist or 60),
			filter = ply
		}
		return util.TraceLine(tr), nil, headm
	end

	local headm = ent:GetBoneMatrix(bon)

	if CLIENT and ply.headmat then headm = ply.headmat end

	local eyeAng = aim_vector:Angle()

	local eyeang2 = aim_vector:Angle()
	eyeang2.p = 0

	local pos = startpos or headm:GetTranslation() + (fakeCam and (headm:GetAngles():Forward() * 2 + headm:GetAngles():Up() * -2 + headm:GetAngles():Right() * 3) or (eyeAng:Up() * 1 + eyeang2:Forward() * 4))
	
	local trace = hg.hullCheck(ply:EyePos(),pos,ply)
	
	local tr = {}
	if !ply:IsPlayer() then return false end
	tr.start = trace.HitPos
	tr.endpos = tr.start + aim_vector * (dist or 60)
	tr.filter = {ply,ent}

	return util.TraceLine(tr), trace, headm
end 

function hg.FrameTimeClamped(ft)
	return math_Clamp(1 - math.exp(-0.5 * (ft or ftlerped) * host_timescale()), 0.000, 0.01)
end

local FrameTimeClamped_ = hg.FrameTimeClamped

local function lerpFrameTime(lerp,frameTime)
	return math_Clamp(1 - lerp ^ (frameTime or FrameTime()), 0, 1)
end

local function lerpFrameTime2(lerp,frameTime)
	return math_Clamp(lerp * FrameTimeClamped_(frameTime) * 150, 0, 1)
end

hg.lerpFrameTime2 = lerpFrameTime2
hg.lerpFrameTime = lerpFrameTime

function LerpFT(lerp, source, set)
	return Lerp(lerpFrameTime2(lerp), source, set)
end

function LerpVectorFT(lerp, source, set)
	return LerpVector(lerpFrameTime2(lerp), source, set)
end

function LerpAngleFT(lerp, source, set)
	return LerpAngle(lerpFrameTime2(lerp), source, set)
end

local max, min = math.max, math.min
function util.halfValue(value, maxvalue, k)
	k = maxvalue * k
	return max(value - k, 0) / k
end

function util.halfValue2(value, maxvalue, k)
	k = maxvalue * k
	return min(value / k, 1)
end

function util.safeDiv(a, b)
	if a == 0 and b == 0 then
		return 0
	else
		return a / b
	end
end

function hg.UseCrate(ply,ent)
	local self = ent
	if !ply:IsPlayer() then
		return
	end

	if hg.eyeTrace(ply,100).Entity == self then
		net.Start("hg inventory")
		net.WriteEntity(self)
		net.WriteTable(self.Inventory)
		net.WriteFloat(self.AmtLoot)
		if self.JModEntInv then
			net.WriteEntity(self.JModEntInv)
		end
		net.Send(ply)
	end
end

hook.Add("Think", "Homigrad_Player_Think", function()
	local tbl = player.GetAll()
	local time = CurTime()

	for _, ply in ipairs(tbl) do
		if (ply._nextHGPlayerThink or 0) > time then continue end
		ply._nextHGPlayerThink = time + 0.03
        hook.Run("Player Think", ply, time)
	end
end)

function PlayerIsCuffs(ply)
	if not ply:Alive() then return end
	local ent = hg.GetCurrentCharacter(ply)
	if not IsValid(ent) then return end

	return ply:GetNWBool("Cuffed",false)
end

function team.GetCountLive(list)
	local count = 0
	local result

	for i,ply in pairs(list) do
		if not IsValid(ply) then continue end

		if not PlayerIsCuffs(ply) and ply:Alive() then count = count + 1 end

		//print(PlayerIsCuffs(ply),ply)
	end

	//print(count)

	return count
end

if SERVER then
    hook.Add("PlayerDeathSound", "DisableDeathSound", function()
        return true
    end)
	hook.Add("Player Think","Homigrad_Organism",function(ply,time)
		if (ply._nextOrganismThink or 0) > time then return end
		ply._nextOrganismThink = time + 0.1

		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and !weapons.Get(wep:GetClass()) then
			local vm = ply:GetViewModel()
			if IsValid(vm) then
				vm:SetPlaybackRate(0)
			end
		end
	end)
else
    hook.Add("DrawDeathNotice", "DisableKillFeed", function()
        return false
    end)
end

hook.Add("PlayerInitialSpawn","Homigrad_KS",function(ply)
	ply.KSILENT = true
end)

gameevent.Listen("player_spawn")
local hull = 10 
local HullMin = -Vector(hull,hull,0)
local Hull = Vector(hull,hull,72)
local HullDuck = Vector(hull,hull,36)
hook.Add("player_spawn","PlayerAdditional",function(data)
    local ply = Player(data.userid)
	if not IsValid(ply) then return end

	if ply.PLYSPAWN_OVERRIDE then return end
	
	hook.Run("InitArmor_CL",ply)

	ply.KillReason = " "
	ply.LastHitBone = " "
	ply.Fake = false 
	ply.SequenceCycle = 0
	ply:SetDSP(0)
	ply.FakeRagdoll = NULL
	ply.otrub = false
	ply.pain = 0

	ply.RenderOverride = hg.RenderOverride

	for bone = 0, ply:GetBoneCount() - 1 do
		ply:ManipulateBoneAngles(bone,Angle(0,0,0))
	end

	ply:SetHull(ply:GetNWVector("HullMin",HullMin) or HullMin,ply:GetNWVector("Hull",Hull) or Hull)
	ply:SetHullDuck(ply:GetNWVector("HullMin",HullMin) or HullMin,ply:GetNWVector("HullDuck",HullDuck) or HullDuck)
	ply:SetViewOffset(Vector(0,0,64))
	ply:SetViewOffsetDucked(Vector(0,0,38))
    ply:SetMoveType(MOVETYPE_WALK)
    ply:DrawShadow(true)
    ply:SetRenderMode(RENDERMODE_NORMAL)

    if SERVER then
        ply:SetSolidFlags(bit.band(ply:GetSolidFlags(),bit.bnot(FSOLID_NOT_SOLID)))
        ply:SetNWEntity("ragdollWeapon", NULL)
        ply:SetNWEntity("ActiveWeapon", NULL)
    end

    timer.Simple(0,function()
		if IsValid(ply) then
        	local ang = ply:EyeAngles()
        	if ang[3] == 180 then
        	    ang[2] = ang[2] + 180
        	end
        	ang[3] = 0
        	ply:SetEyeAngles(ang)
		end
    end)

    if SERVER then
        hg.send(nil,ply,true)
    end
end)

-- ее не нужная функция нахуй!!!!!!!
function hg.Zaebal_Day_VM(wep)
    local self = wep
    local owner = self:GetOwner()
    if !IsValid(owner) then return nil end
    if !owner:IsPlayer() then return nil end
    return owner:GetViewModel()
end

if CLIENT then
	hg_camshake_amount = CreateClientConVar("hg_camshake_amount","1",true,false,nil,0,1.5)
    hg_camshake_enabled = CreateClientConVar("hg_camshake_enabled","1",true,false,nil,0,1)

	hg.DrawModels = {}

	function hg.DrawWeaponSelection(self, x, y, wide, tall, alpha )

		/*wide = wide * 1.1
		tall = tall * 1.1

		x = x / 1.025
		y = y / 1.025*/

		/*x = wide/2
		y = tall/2*/

		//self.PrintName = hg.GetPhrase(self:GetClass())
		
		local WM = self.WorldModelReal or self.WorldModel

		local DrawingModel = hg.DrawModels[(isstring(self) and self or self.ClassName)]
	
		if not IsValid(DrawingModel) then
			DrawingModel = ClientsideModel(self.WorldModelReal or self.WorldModel,RENDERGROUP_OPAQUE)
			DrawingModel.IsIcon = true
			DrawingModel.NoRender = true
			DrawingModel:SetNoDraw(true)
			timer.Simple(0,function()
				if self.Bodygroups then
				    for k, v in ipairs(self.Bodygroups) do
				        DrawingModel:SetBodygroup(k, v)
				    end
				else
				    for i = 0, 8 do
				        DrawingModel:SetBodygroup(i, 0)
				    end
				end
			end)

			hg.DrawModels[(isstring(self) and self or self.ClassName)] = DrawingModel
			DrawingModel:SetNoDraw(true)
		else
			DrawingModel.NoRender = true
			DrawingModel:SetNoDraw(true)
			local vec = Vector(0,0,0)
			local ang = Angle(0,0,0)
	
			cam.Start3D( vec, ang, 20, x, y+(IsValid(self) and 35 or -5), wide, tall, 5, 4096 )
				cam.IgnoreZ( true )
				render.SuppressEngineLighting( true )
	
				render.SetLightingOrigin(DrawingModel:GetPos())
				render.ResetModelLighting( 50/255, 50/255, 50/255 )
				render.SetColorModulation( 1, 1, 1 )
				render.SetBlend( 255 )
	
				render.SetModelLighting( 4, 1, 1, 1 )
	
				DrawingModel:SetRenderAngles(self.IconAng or Angle(0,0,0))
				DrawingModel:SetRenderOrigin((self.IconPos or Vector(0,0,0))-DrawingModel:OBBCenter())
				DrawingModel:SetModel(self.WorldModelReal or self.WorldModel)
				if self.Bodygroups then
				    for k, v in ipairs(self.Bodygroups) do
				        DrawingModel:SetBodygroup(k, v)
				    end
				else
				    for i = 0, 10 do
				        DrawingModel:SetBodygroup(i, 0)
				    end
				end
				DrawingModel:DrawModel()
				if self.Bodygroups then
				    for k, v in ipairs(self.Bodygroups) do
				        DrawingModel:SetBodygroup(k, v)
				    end
				else
				    for i = 0, 10 do
				        DrawingModel:SetBodygroup(i, 0)
				    end
				end
	
				render.SetColorModulation( 1, 1, 1 )
				render.SetBlend( 1 )
				render.SuppressEngineLighting( false )
				cam.IgnoreZ( false )
			cam.End3D()
			DrawingModel:SetNoDraw(true)
		end
	
		surface.SetDrawColor( 255, 255, 255, alpha )
		surface.SetMaterial( (self.WepSelectIcon2 or Material("null")) )
	
		surface.DrawTexturedRect( x, y + 10,  256 * ScrW()/1920 , 128 * ScrH()/1080 )
	
		self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
	
	end
end


function player.GetAlive()
	local alive = {}
	for _, ply in ipairs(player.GetAll()) do
		if !ply:Alive() then
			continue 
		end

		table.insert(alive,ply)
	end

	return alive
end

hook.Add("Move", "Homigrad_Move", function(ply, mv)
    if not ply:Alive() then return end

	local ground = ply:GetGroundEntity()
	if IsValid(ground) then
		local gclass = ground:GetClass()
		if ground:GetMoveType() == MOVETYPE_VPHYSICS
		or string.StartWith(gclass, "prop_")
		or gclass == "func_physbox"
		or gclass == "func_physbox_multiplayer" then
			local vel = mv:GetVelocity()
			if not mv:KeyDown(IN_JUMP) and math.abs(vel.z) < 45 then
				vel.z = 0
			end
			mv:SetVelocity(vel)
		end
	end

	if GetGlobalBool("DefaultMove",false) then
		ply:SetDuckSpeed(0.5)
    	ply:SetUnDuckSpeed(0.5)
    	ply:SetSlowWalkSpeed(30)
    	ply:SetCrouchedWalkSpeed(1)
    	ply:SetWalkSpeed(100) -- пентюх зочем так быстро ходить
    	ply:SetRunSpeed(200) --ты меня опередил.. -- да я такой крутой 
    	ply:SetJumpPower(200)
		return
	end

	local speed = ply:IsSprinting() and 350 or 100

	//Штрафы за бег спиной|боком

	local side = mv:GetSideSpeed()
	local forw = mv:GetForwardSpeed()

	if side < 0 then
		side = side * -1
	end

	if side > 0 then
		speed = speed - ply:GetVelocity():Length() / 4
	end

	if forw < 0 then
		speed = speed - ply:GetVelocity():Length() / 2
	end

	//Штрафы за резкие повороты

	ply.govno_ang = LerpAngle(0.025,ply.govno_ang or ply:EyeAngles(),ply:EyeAngles())

	local diffang = math.AngleDifference(ply.govno_ang[2],ply:EyeAngles()[2]) * 1.2

	if diffang < 0 then
		diffang = diffang * -1
	end

	if ply:IsSprinting() and forw > 0 then
		speed = speed - diffang
	end

	speed = math.Clamp(speed, 80, 350)

	local cur_speed = Lerp(0.1,ply:GetRunSpeed(),ply:GetVelocity():Length() > 50 and speed or 100)
	cur_speed = math.Clamp(cur_speed, 80, 350)

	ply:SetRunSpeed(cur_speed)
    ply:SetJumpPower(150)

	mv:SetMaxSpeed(cur_speed)
	mv:SetMaxClientSpeed(cur_speed)

	if SERVER then
		if ply:GetVelocity():Length() < 50 and !ply:IsSprinting() then
			ply.stamina = ply.stamina + 0.05
		end
	end
end)

hook.Add( "CalcMainActivity", "RunningAnim", function( Player, Velocity )
	if (not Player:InVehicle()) and Player:IsOnGround() and Velocity:Length() > 250 and IsValid(Player:GetActiveWeapon()) and Player:GetActiveWeapon():GetClass() == "weapon_hands" then
		return ACT_HL2MP_RUN_FAST, -1
	end
end)

function hg.GetCurrentCharacter(ent)
    return (ent:IsPlayer() and (ent:GetNWBool("Fake") and ent:GetNWEntity("FakeRagdoll") or ent) or nil)
end

gameevent.Listen( "entity_killed" )
hook.Add("entity_killed","player_deathhg",function(data) 
	local ply = Entity(data.entindex_killed)
    local attacker = Entity(data.entindex_attacker)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	
	hook.Run("Player Death", ply, attacker)
end)

hook.Add("Player Death","SetHull",function(ply, attacker)
    timer.Simple(0,function()
        local ang = ply:EyeAngles()
        if ang[3] == 180 then
            ang[2] = ang[2] + 180
        end
        ang[3] = 0
        ply:SetEyeAngles(ang)
    end)
end)

if CLIENT then
    hook.Add("NetworkEntityCreated","huyhuy",function(ent)
        if not ent:IsRagdoll() then return end
        timer.Simple(LocalPlayer():Ping() / 100 + 0.1,function()
            if not IsValid(ent) then return end
            if IsValid(ent:GetNWEntity("RagdollOwner")) then
                hook.Run("Fake",ent:GetNWEntity("RagdollOwner"),ent)
            end
        end)
    end)
end

hook.Add("Fake","faked",function(ply, rag)
    ply:SetHull(-Vector(1,1,1),Vector(1,1,1))
	ply:SetHullDuck(-Vector(1,1,1),Vector(1,1,1))
    ply:SetViewOffset(Vector(0,0,0))
    ply:SetViewOffsetDucked(Vector(0,0,0))
    ply:SetMoveType(MOVETYPE_NONE)
end)

local lend = 2
local vec = Vector(lend,lend,lend)
local traceBuilder = {
	mins = -vec,
	maxs = vec,
	mask = MASK_SOLID,
	collisiongroup = COLLISION_GROUP_DEBRIS
}

local util_TraceHull = util.TraceHull

function hg.hullCheck(startpos,endpos,ply)
	if ply:InVehicle() then return {HitPos = endpos} end
	traceBuilder.start = IsValid(ply.FakeRagdoll) and endpos or startpos
	traceBuilder.endpos = endpos
	traceBuilder.filter = {ply,hg.GetCurrentCharacter(ply)}
	local trace = util_TraceHull(traceBuilder)

	return trace
end

function hg.eyeTrace(ply, dist, ent, aim_vector)
	local fakeCam = IsValid(ply:GetNWEntity("FakeRagdoll"))
	local ent = hg.GetCurrentCharacter(ply)
	if ent == nil then
		ent = ply
	end
	if ent == NULL then
		ent = ply
	end
	local bon = ent:LookupBone("ValveBiped.Bip01_Head1")
	if not bon then return end
	if not IsValid(ply) then return end
	if not ply.GetAimVector then return end
	
	local aim_vector = aim_vector or ply:GetAimVector()

	if not bon or not ent:GetBoneMatrix(bon) then
		local tr = {
			start = ply:EyePos(),
			endpos = ply:EyePos() + aim_vector * (dist or 60),
			filter = ply
		}
		return util.TraceLine(tr)
	end

	if (ply.InVehicle and ply:InVehicle() and IsValid(ply:GetVehicle())) then
		local veh = ply:GetVehicle()
		local vehang = veh:GetAngles()
		local tr = {
			start = ply:EyePos() + vehang:Right() * -6 + vehang:Up() * 4,
			endpos = ply:EyePos() + aim_vector * (dist or 60),
			filter = ply
		}
		return util.TraceLine(tr), nil, headm
	end

	local headm = ent:GetBoneMatrix(bon)

	if CLIENT and ply.headmat then headm = ply.headmat end

	local eyeAng = aim_vector:Angle()
    eyeAng:Normalize()
	local eyeang2 = aim_vector:Angle()
	eyeang2.p = 0
    
	local trace = hg.hullCheck(ply:EyePos()+select(2,ply:GetHull())[2] * eyeAng:Forward(),headm:GetTranslation() + (fakeCam and (headm:GetAngles():Forward() * 2 + headm:GetAngles():Up() * -2 + headm:GetAngles():Right() * 3) or (eyeAng:Up() * 1 + eyeang2:Forward() * ((math.max(eyeAng[1],0) / 90 + 0.5) * 4) + eyeang2:Right() * 0.5)),ply)
	
	local tr = {}
	if !ply:IsPlayer() then return false end
	tr.start = trace.HitPos
	tr.endpos = tr.start + aim_vector * (dist or 60)
	tr.filter = {ply,ent}

	return util.TraceLine(tr), trace, headm
end

function hg.KeyDown(owner,key)
	if not IsValid(owner) then return false end
	owner.keydown = owner.keydown or {}
	local localKey
	if CLIENT then
		if owner == LocalPlayer() then
			localKey = owner:KeyDown(key)
		else
			localKey = owner.keydown[key]
		end
	end
	return SERVER and owner:IsPlayer() and owner:KeyDown(key) or CLIENT and localKey
end

function hg.KeyPressed(owner,key)
	if not IsValid(owner) then return false end
	owner.keypressed = owner.keypressed or {}
	local localKey
	if CLIENT then
		if owner == LocalPlayer() then
			localKey = owner:KeyPressed(key)
		else
			localKey = owner.keypressed[key]
		end
	end
	return SERVER and owner:IsPlayer() and owner:KeyPressed(key) or CLIENT and localKey
end

//Функция с гита гмод-а

if ( SERVER ) then

	function StatueDuplicator( ply, ent, data )

		if ( !data ) then

			duplicator.ClearEntityModifier( ent, "statue_property" )
			return

		end

		-- We have been pasted from duplicator, restore the necessary variables for the unstatue to work
		
		if ( ent.StatueInfo == nil ) then

			-- Ew. Have to wait a frame for the constraints to get pasted
			timer.Simple( 0, function()
				if ( !IsValid( ent ) ) then return end

				local bones = ent:GetPhysicsObjectCount()
				if ( bones < 2 ) then return end

				ent:SetNWBool( "IsStatue", true )
				ent.StatueInfo = {}

				local con = constraint.FindConstraints( ent, "Weld" )
				for id, t in pairs( con ) do
					if ( t.Ent1 != t.Ent2 || t.Ent1 != ent || t.Bone1 != 0 ) then continue end

					ent.StatueInfo[ t.Bone2 ] = t.Constraint
				end

				local numC = table.Count( ent.StatueInfo )
				if ( numC < 1 --[[or numC != bones - 1]] ) then duplicator.ClearEntityModifier( ent, "statue_property" ) end
			end )
		end

		duplicator.StoreEntityModifier( ent, "statue_property", data )

	end
	duplicator.RegisterEntityModifier( "statue_property", StatueDuplicator )

end

if CLIENT then

--
local reloadCSFile = {
}
local OptiLerp = Lerp

local gunrotate = CreateClientConVar("grad_gunrotate", "0", true, false, nil, -25, 0)



--[[local function ReloadCS()
    for _, path in ipairs(reloadCSFile) do
        include(path)
    end
    --print("[CSS Reload] Файлы обновлены: " .. table.concat(reloadCSFile, ", "))
end


hook.Add("InitPostEntity", "ReloadCSSOnJoin", function()

    timer.Simple(1, function()
        ReloadCS()


        timer.Create("PeriodicReloadCS", 180, 0, function()
            ReloadCS()
        end)
    end)
end)


hook.Add("OnEntityCreated", "ReloadCSSOnRespawn", function(ent)
    if ent == LocalPlayer() then
        timer.Simple(2, function()
            if not timer.Exists("PeriodicReloadCS") then
                ReloadCS()
                timer.Create("PeriodicReloadCS", 120, 0, function()
                    ReloadCS()
                end)
            end
        end)
    end
end)


ReloadCS()


timer.Create("CS_AutoReload", 120, 0, ReloadCS)--]]


net.Receive("GGrad_SendTableToClient", function()
    PrintTable(net.ReadTable())
end)

local GGrad_Message = {}

function cGui_Center(w, h)
    return (ScrW() - w) / 2, (ScrH() - h) / 2
end

function cGui_ManualCenter(w, h, manualx, manualy)
    return (ScrW() - w) / (manualx or 2), (ScrH() - h) / (manualy or 2)
end

function GGrad_Notify(msg, color)
	if not IsColor(color) or color == nil then
		color = Color(90,87,87)
	end
	if not isstring(msg) then return end
	if not IsColor(color) then return end
    table.ForceInsert(GGrad_Message,
    {
        message = msg,
        color = color,
        start = CurTime(),
        animation_pos = -250,
        animation_alpha = 0,
        subup = 1,
    })
end

local Icons = {
    ["https://i.imgur.com/hxoygbM.png"] = "logo",
    ["https://i.imgur.com/Iylncml.png"] = "logout",
    ["https://i.imgur.com/H1W30lV.png"] = "discord",
    ["https://i.imgur.com/g7DNaCS.png"] = "settings",
    ["https://i.imgur.com/wIMTnhc.png"] = "play",
    ["https://i.imgur.com/G4uwVYk.png"] = "steam",
    ["https://i.imgur.com/keihjE1.png"] = "content",
    ["https://i.imgur.com/DBjWIy4.png"] = "mainmenu",
    ["https://i.imgur.com/Ew1VNOy.png"] = "stomach",
    ["https://i.imgur.com/CuG5C4e.png"] = "hungerfood",
    ["https://i.imgur.com/9f1v7sR.png"] = "loading32",
    ["https://i.yapx.ru/ZjIHA.jpg"] = "klubnika_bomba_chestno_govorya",
    ["https://i.yapx.ru/ZjITC.png"] = "hasbik",
    ["https://i.yapx.ru/ZjIk2.png"] = "macan",
    ["https://i.yapx.ru/ZA3FL.png"] = "no_thumb",
    ["https://i.ibb.co/4nL0L9W6/dfhdfhimage.png"] = "focusdebil",
    ["https://i.ibb.co/tTBSg44h/xczbcnbcxnv123123image.png"] = "focusdebil2",
}

local Sounds = {
    ["https://files.catbox.moe/1icbj7.mp3"] = "mapvote",
    ["https://files.catbox.moe/xvzj2k.mp3"] = "scarymusic",
}

local url = "https://i.imgur.com/hxoygbM.png"
file.CreateDir("gomigrad_datacontent")
file.CreateDir("gomigrad_imageavatar")

local DefaultSettingsValues = {
    ["show_notify"] = true,
    ["show_historyweapon"] = true,
    ["show_afkscreen"] = true,
    --["hide_usergroup"] = false,
}

if not file.Exists("gomigrad_datacontent/settings.xml", "DATA") then
    file.Write("gomigrad_datacontent/settings.xml", util.TableToJSON(DefaultSettingsValues))
end

--[[timer.Create("FixConfigSettings", 5, 0, function()
    local cfg = file.Read("gomigrad_datacontent/settings.xml", "DATA")
    local tbl = util.JSONToTable(cfg)
    for k, v in pairs(DefaultSettingsValues) do
		if tbl[k] == nil then
			tbl[k] = v
            file.Write("gomigrad_datacontent/settings.xml", util.TableToJSON(tbl))
		end
	end
end)--]]

GGrad_ConfigSettings = util.JSONToTable(file.Read("gomigrad_datacontent/settings.xml", "DATA"), true)

local function ConfigSettingSync()
    file.Write("gomigrad_datacontent/settings.xml", util.TableToJSON(GGrad_ConfigSettings))
end

for url, name in pairs(Icons) do
    if not file.Exists("gomigrad_datacontent/"..name..".png", "DATA") then
        http.Fetch(url,
        function(body, size, headers, code)
            file.Write("gomigrad_datacontent/"..name..".png", body)
            GGrad_Notify("Download [" .. name .. "] in data content.", Color(19,197,46))
        end,
        function(error)
            --print("Ошибка загрузки: " .. error)
            --GGrad_Notify("Can't download [" .. name .. "] in data content.", Color(176,28,28))
            -- убрал потому-что писалось в чате это нескольок раз
        end)
    end
end

for url, name in pairs(Sounds) do
    if not file.Exists("gomigrad_datacontent/"..name..".mp3", "DATA") then
        http.Fetch(url,
        function(body, size, headers, code)
            file.Write("gomigrad_datacontent/"..name..".mp3", body)
            GGrad_Notify("Download [" .. name .. "] in data content.", Color(19,197,46))
        end,
        function(error)
            --print("Ошибка загрузки: " .. error)
            --GGrad_Notify("Can't download [" .. name .. "] in data content.", Color(176,28,28))
        end)
    end
end

local afktime = afktime or 0

net.Receive("GGrad_AFKTime", function()
	afktime = net.ReadFloat()
end)

local lerpblackout = 0
local sizegoida = 0
local seppec = 0
local fminute = 0
local mnogo = 0
local gradient = Material("gui/gradient_up")

local particles = {}

local function CreateParticle()
	local particle = {
		x = math.random(0, ScrW()),
		y = math.random(0, ScrH()),
		size = math.random(5, 20),
		vx = math.random(-100, 100),
		vy = math.random(-100, 100),
		alpha = 255
	}
	table.insert(particles, particle)
end

GGrad_dmtimer_h = 0
local elapsedTime = 0

--[[hook.Add("DrawOverlay", "afktimerdfhdfgh", function()

    if roundActiveName == "dm" then
        elapsedTime = CurTime() - roundTimeStart
        if elapsedTime < 15 then
            local seconds = math.floor((elapsedTime-10))
            local milliseconds = math.floor(((elapsedTime-10) - seconds) * 1000)

            local timerText = string.format("%02d:%03d", seconds, milliseconds)

            surface.SetFont("SolidMapVote.Title")
            local textWidth, textHeight = surface.GetTextSize(timerText)

            draw.DrawText(string.Replace(timerText, "-", ""), "SolidMapVote.Title", ScrW()/2.05, GGrad_dmtimer_h, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end

        if elapsedTime > 10 then
            GGrad_dmtimer_h = OptiLerp(0.04, GGrad_dmtimer_h or 0, ScrH()*99)
        else
            GGrad_dmtimer_h = OptiLerp(0.08, GGrad_dmtimer_h or 0, ScrH()/1.09)
        end
    end

    if not IsValid(LocalPlayer()) then return end
    if not LocalPlayer():Alive() or LocalPlayer():Team() == 1002 then return end
    if not GGrad_ConfigSettings["show_afkscreen"] then return end
    if cCustomRTV.active then return end

	lerpblackout = Lerp(0.04, lerpblackout or 0, (afktime >= 30 and 210 or 0))
	sizegoida = Lerp(0.07, sizegoida or 0, (afktime >= 30 and ScrH()+1 or 0))
	seppec = Lerp(0.07, seppec or 0, (afktime >= 120 and 255 or 0))
	fminute	= Lerp(0.07, fminute or 0, (afktime >= 300 and 255 or 0))
	mnogo = Lerp(0.07, mnogo or 0, (afktime >= 600 and 255 or 0))

	draw.RoundedBox(0, 0, 0, ScrW(), sizegoida, Color(0, 0, 0, lerpblackout))

	surface.SetDrawColor(0, 0, 0, lerpblackout)
	surface.SetMaterial(gradient)
	surface.DrawTexturedRect(0, 0, ScrW(), sizegoida)
	draw.SimpleText("You're in AFK", "BudgetLabel", ScrW()/2, sizegoida/2, Color(255,255,255,(lerpblackout >= 10 and lerpblackout+45 or 0)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("It's been " .. math.floor(afktime) .. " sec.", "BudgetLabel", ScrW()/2, sizegoida/1.95, Color(255,255,255,(lerpblackout >= 10 and lerpblackout+45 or 0)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("If you are in AFK for 120+ seconds, you will be moved to spectators.", "BudgetLabel", ScrW()/2, sizegoida/1.9, Color(255,255,255,(lerpblackout >= 10 and lerpblackout+45 or 0)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("You've been standing in the AFK for 120+ seconds.", "BudgetLabel", ScrW()/2, sizegoida/1.85, Color(194,39,39,seppec), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("Why did you fall asleep there? You've been sitting here for over 5 minutes now...", "BudgetLabel", ScrW()/2, sizegoida/1.8, Color(224,163,8,fminute), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("I think you really fell asleep.", "BudgetLabel", ScrW()/2, sizegoida/1.75, Color(28,160,197,mnogo), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if math.random(1, 5) == 1 and afktime >= 30 then
        CreateParticle()
    end

	if afktime >= 30 then
		for i, particle in ipairs(particles) do
        	particle.x = particle.x + particle.vx * FrameTime()
        	particle.y = particle.y + particle.vy * FrameTime()
        	particle.alpha = particle.alpha - 1

        	surface.SetDrawColor(255, 255, 255, particle.alpha)
        	surface.DrawCircle(particle.x, particle.y, particle.size, Color(255, 255, 255, particle.alpha))

        	if particle.alpha <= 0 then
            	table.remove(particles, i)
        	end
    	end
	end
end)--]]

concommand.Add("getafktime", function()
	print(afktime)
end)

surface.CreateFont("EmojiFont", {
    font = "Segoe UI Emoji",
    size = 32,
    weight = 500,
    antialias = true,
})

surface.CreateFont("perfecztddd", {
    font = "Roboto-Bold",
    size = 32,
    weiht = 150,
})

surface.CreateFont("parashafont", {
    font = "Trebuchet",
    size = 90,
    weight = 800,
    antialias = true,
})

local function SmoothColor(col, factor)
    factor = math.Clamp(factor or 0.5, 0, 1)
    return Color(
        Lerp(factor, col.r, 128),
        Lerp(factor, col.g, 128),
        Lerp(factor, col.b, 128),
        col.a
    )
end

local alpha = 0
local posX = ScrW()
local dots = ""
local lastDotUpdate = 0
local factor = 0
local increasing = true
local speed = 0.5

hook.Add("HUDPaint", "DrawVoiceHUD", function()
    local screenW, screenH = ScrW(), ScrH()
    local padding = 6
    local baseText = "Вы говорите"

    if CurTime() - lastDotUpdate >= 0.4 then
        if #dots >= 3 then
            dots = ""
        else
            dots = dots .. "."
        end
        lastDotUpdate = CurTime()
    end

    local finalText = baseText .. dots

    surface.SetFont("BudgetLabel")
    local textW, textH = surface.GetTextSize(finalText)

    local boxW = textW + padding * 2.5
    local boxH = textH + padding * 2
    local posY = screenH - boxH - 400

    local targetAlpha = LocalPlayer():IsSpeaking() and 200 or 0
    local targetposX = LocalPlayer():IsSpeaking() and screenW - boxW - 20 or ScrW()

    alpha = Lerp(FrameTime() * 10, alpha, targetAlpha)
    posX = Lerp(FrameTime() * 5, posX, targetposX)
    if alpha <= 1 then return end
    local col = LocalPlayer():GetPlayerColor():ToColor()

    col.a = alpha * 0.7

    local invertcol = SmoothColor(col, factor)
    invertcol.a = alpha * 0.7

    if increasing then
        factor = math.min(factor + FrameTime() * speed, 1)
        if factor >= 1 then increasing = false end
    else
        factor = math.max(factor - FrameTime() * speed, 0)
        if factor <= 0 then increasing = true end
    end

    draw.RoundedBox(0, posX, posY, boxW, boxH, col)

    for i = 1, 3 do
        local glowAlpha = (alpha * 0.4) / i
        draw.RoundedBox(0,
            posX - i, posY - i,
            boxW + i * 2, boxH + i * 2,
            Color(col.r, col.g, col.b, glowAlpha)
        )
    end

    surface.SetDrawColor(invertcol)
    surface.SetMaterial(gradient)
    surface.DrawTexturedRect(posX, posY, boxW, boxH)

    draw.SimpleText(finalText, "HomigradFontSmall", posX + padding, posY + padding, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)

local gradient = Material("vgui/gradient-u")

net.Receive("GGrad_Notificate", function()
    if not GGrad_ConfigSettings or GGrad_ConfigSettings["show_notify"] == false then return end
    local msg = net.ReadString()
    local clr = net.ReadColor()
    if string.find(msg, "ВЫ ЗАБАНЕНЫ") then
        msg = "Кто-то был забанен..."
        clr = Color(213,145,18)
    end
    table.ForceInsert(GGrad_Message,
    {
        message = msg,
        color = clr,
        start = CurTime(),
        animation_pos = -250,
        animation_alpha = 0,
        subup = 1,
    })
end)

local animationjoin = 5

hook.Add("DrawOverlay", "worakwr", function()
    if not GGrad_ConfigSettings["show_notify"] then return end
    local outerMinW, outerH = 817, 54
    local innerMinW, innerH = 801, 44
    local outerPadding = 8
    local innerTextPadding = 24
    local startY = 12
    local stackGap = 8

    for index_subup, value in pairs(GGrad_Message) do
        local msg = tostring(value.message or "")
        surface.SetFont("BudgetLabel")
        local textW = select(1, surface.GetTextSize(msg))
        local innerW = math.max(innerMinW, textW + innerTextPadding * 2)
        local outerW = math.max(outerMinW, innerW + outerPadding * 2)
        outerW = math.min(outerW, ScrW() - 20)
        innerW = math.min(innerW, outerW - outerPadding * 2)
        local x = ScrW() * 0.5 - outerW * 0.5

        if CurTime() - value.start > animationjoin then
            value.animation_pos = Lerp(0.08, value.animation_pos or 0, -30)
            value.animation_alpha = Lerp(0.05, value.animation_alpha or 0, 0)
        else
            value.animation_pos = Lerp(0.12, value.animation_pos or 0, 0)
            value.animation_alpha = Lerp(0.1, value.animation_alpha or 0, 255)
        end

        value.subup = Lerp(0.1, value.subup or 0, index_subup)
        local y = startY + (value.subup - 1) * (outerH + stackGap) + (value.animation_pos or 0)
        local a = math.Clamp(value.animation_alpha or 0, 0, 180)

        draw.RoundedBox(0, x, y, outerW, outerH, Color(6, 11, 31, a))
        draw.RoundedBox(0, x + (outerW - innerW) * 0.5, y + (outerH - innerH) * 0.5, innerW, innerH, Color(26, 26, 26, a))
        draw.SimpleText(msg, "HS.25", x + outerW * 0.5, y + outerH * 0.5, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local msgCount = #GGrad_Message
        local deleteTime = animationjoin + 1.5
        if msgCount > 3 then
            deleteTime = animationjoin + 1.5 - (msgCount - 3) * 0.8
            deleteTime = math.max(deleteTime, 1.5)
        end

        if CurTime() - value.start > deleteTime then
            table.RemoveByValue(GGrad_Message, value)
        end
    end
end)

local function ScaleFromCenter(pnl, newW, newH, time, delay, ease)
    if not IsValid(pnl) then return end

    local cx, cy = pnl:GetPos()
    local cw, ch = pnl:GetSize()

    local nx = cx - (newW - cw) / 2
    local ny = cy - (newH - ch) / 2

    time = time or 0
    delay = delay or 0
    ease = ease or 0

    if time > 0 then
        pnl:MoveTo(nx, ny, time, delay, ease)
        pnl:SizeTo(newW, newH, time, delay, ease)
    else
        pnl:SetPos(nx, ny)
        pnl:SetSize(newW, newH)
    end
end

local function LerpColor(t, from, to)
    return Color(
        Lerp(t, from.r, to.r),
        Lerp(t, from.g, to.g),
        Lerp(t, from.b, to.b),
        Lerp(t, from.a, to.a)
    )
end

local notifyesc = false
ESCMenu = ESCMenu or nil
--SettingsMenu = SettingsMenu or nil

local function CreateCustomCheckbox(parent, text, var)
    --if var == "hide_usergroup" and LocalPlayer():GetUserGroup() == "user" then return end
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(30)
    panel:Dock(TOP)
    panel:DockMargin(5, 5, 5, 0)
    panel.Paint = function(self, w, h)
        draw.SimpleText(text, "BudgetLabel", 40, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local btn = vgui.Create("DButton", panel)
    btn:SetSize(24, 24)
    btn:SetPos(5, 3)
    btn:SetText("")
    btn.coloract = Color(0,0,0,0)
    btn.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(50,50,50,255))

        draw.RoundedBox(4, 4, 4, w-8, h-8, self.coloract)

        if GGrad_ConfigSettings[var] then
            self.coloract = LerpColor(0.1, self.coloract, Color(240, 237, 237, 255))
        else
            self.coloract = LerpColor(0.1, self.coloract, Color(0, 0, 0, 0))
        end
    end
    btn.DoClick = function()
        local whatbool = nil
        GGrad_ConfigSettings[var] = not GGrad_ConfigSettings[var]
        whatbool = GGrad_ConfigSettings[var]
        ConfigSettingSync()
    end
end

local function CreateCustomButton(parent, text, callback)
    local btn = vgui.Create("DButton", parent)
    btn:SetTall(30)
    btn:Dock(TOP)
    btn:DockMargin(5, 5, 5, 0)
    btn:SetText(text)
    btn.Paint = function(self, w, h)
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(self:GetText(), "BudgetLabel", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btn.DoClick = function()
        if callback then callback() end
    end
end

function CreateCustomNumSlider(parent, text, min, max, decimals, var)
    -- asyan
    --if IsValid(CreateCustomNumSlider) then return end
    -- done
    local slider = vgui.Create("DNumSlider", parent)
    slider:Dock(TOP)
    slider:DockMargin(5, 5, 5, 0)
    slider:SetValue(GetConVar(var):GetInt())
    slider:SetConVar(var)
    slider:SetTall(35)
    slider:SetText(text)
    slider:SetMin(min)
    slider:SetMax(max)
    slider:SetDecimals(decimals or 0)
    slider:SetValue(min)

    slider.Slider.Knob.Paint = function(self, w, h)
        draw.RoundedBox(32, 0, 0, w-3, h-2, Color(240, 237, 237))
    end

    slider.Slider.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, h/2 - 2, w, 1.5, Color(80, 80, 80, 100))
    end

    return slider
end

function CreateCustomNumCombobox(parent, text, list, var)
    local label = vgui.Create("DLabel", parent)
    label:Dock(TOP)
    label:DockMargin(5, 5, 5, 0)
    label:SetText(text)
    label:SetFont("DermaDefaultBold")
    label:SetTextColor(Color(240, 237, 237))
    label:SizeToContents()

    local combo = vgui.Create("DComboBox", parent)
    combo:Dock(TOP)
    combo:DockMargin(5, 2, 5, 0)
    combo:SetTall(25)

    for _, value in ipairs(list) do
        combo:AddChoice(value)
    end

    local convarValue = GGrad_ConfigSettings[var]
    if convarValue and convarValue ~= "" then
        combo:SetValue(convarValue)
    end

    combo.OnSelect = function(panel, index, value)
        GGrad_ConfigSettings[var] = value
        ConfigSettingSync()
    end

    combo.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
        --draw.SimpleText(self:GetValue(), "DermaDefault", 8, h / 2, Color(240, 237, 237), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    combo.DropButton.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(80, 80, 80, 200))
        draw.SimpleText("▼", "DermaDefault", w / 2, h / 2, Color(240, 237, 237), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return combo
end




--[[local function GGrad_CustomESC_Settings()
    local settings = vgui.Create( "DFrame" )
    settings:SetSize( 1200, 800 )
    settings:Center()
    settings:SetDraggable()
    settings:SetTitle("GOMIGRAD.COM - Settings")
    settings:MakePopup()

    settings.Paint = function(_,w,h)
        draw.RoundedBox(10,0,0,w,h,Color(0,0,0,225))
    end

    settings.OnKeyCodePressed = function(self, keycode)
        if keycode == KEY_R or keycode == KEY_W or keycode == KEY_S or keycode == KEY_A or keycode == KEY_D then
            self:Remove()
            settings = nil
        end
    end

    local sheet = vgui.Create( "DPropertySheet", settings )
    sheet.Paint = function(_,w,h)
        draw.RoundedBox(10,0,0,w,h,Color(0,0,0,0))
    end


    sheet:Dock( FILL )
    -- вкладка 1

    local panel1 = vgui.Create( "DPanel", sheet )
    for _, setting in ipairs(SettingsList) do
        if setting.type == "button" then
            CreateCustomButton(panel1, setting.name, setting.callback)
        elseif setting.type == "slider" then
            CreateCustomNumSlider(panel1, setting.name, setting.min, setting.max, setting.decimal, setting.var)
        elseif setting.type == "combobox" then
            CreateCustomNumCombobox(panel1, setting.name, setting.list, setting.var)
        else
            CreateCustomCheckbox(panel1, setting.name, setting.var)
        end
    end

    panel1.Paint = function(_, w, h )
        draw.RoundedBox( 4, 0, 0, w, h, Color(0,0,0,100) )
    end
    sheet:AddSheet( "Основное", panel1, "icon16/cross.png" )
    -- все

    -- вкладка 2
    local panel2 = vgui.Create( "DPanel", sheet )
    panel2.Paint = function(_, w, h )
        draw.RoundedBox( 4, 0, 0, w, h, Color(0,0,0,100) )
    end
    sheet:AddSheet( "Оптимизация", panel2, "icon16/tick.png" )
    -- все

    local panel3 = vgui.Create( "DPanel", sheet )
    panel3.Paint = function(_, w, h )
        draw.RoundedBox( 4, 0, 0, w, h, Color(0,0,0,100) )
        draw.SimpleText("Падать в регдолл","HO.18",80,50,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_LEFT)
    end
    local binder = vgui.Create( "DBinder", panel3 )
    binder:SetSize( 120, 50 )
    binder:SetPos( 190, 35 )


    if file.Exists("gomigradtop.txt", "DATA") then

        local savedKey = file.Read("gomigradtop.txt", "DATA")
        if savedKey then
            huy = tonumber(savedKey)
            binder:SetSelectedNumber(huy)
        end
    end

    local huy = nil

    function binder:OnChange( num )
        huy = num
	    LocalPlayer():ChatPrint("Ты еблан: "..input.GetKeyName( num ))
    end

    hook.Add("PlayerButtonDown", "MyBind", function(ply, button)

        if ply == LocalPlayer() and huy and button == huy then
            RunConsoleCommand("fake")
        end
    end)





    sheet:AddSheet( "Клавиатура", panel3, "icon16/tick.png" )









    --[[SettingsMenu = vgui.Create("DPanel")
    SettingsMenu:SetPos(0, 0)
    SettingsMenu:SetAlpha(10)
    SettingsMenu:SetSize(0, ScrH())
    SettingsMenu:SetBackgroundColor(Color(0,0,0,0))
    SettingsMenu:AlphaTo(245, 0.2, 0, nil)
    SettingsMenu:SizeTo(ScrW(), ScrH(), 0.3, 0, 0.5, nil)
    SettingsMenu.Paint = function(self,w,h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))

        surface.SetDrawColor(0, 0, 0, self:GetAlpha())
        surface.SetMaterial(gradient)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    SettingsMenu.OnKeyCodePressed = function(self, keycode)
        if keycode == KEY_R or keycode == KEY_W or keycode == KEY_S or keycode == KEY_A or keycode == KEY_D then
            self:Remove()
            SettingsMenu = nil
        end
    end

    local Frame = vgui.Create("DFrame", SettingsMenu)
    Frame:SetSize(1200, 900)
    Frame:SetPos(ScrW()/2 - 1200/2, ScrH()/2 - 900/2)
    Frame:SetTitle("")
    Frame:ShowCloseButton(false)
    Frame:SetDraggable(false)
    Frame:MakePopup()
    Frame.Paint = function(self,w,h)
        --draw.SimpleText("КЛИЕНТСКИЕ НАСТРОЙКИ", "BudgetLabel", w/2, h/2, Color(255,255,255,55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.RoundedBox(0, 0, 0, w, h, Color(36,34,34,125))

        surface.SetDrawColor(0, 0, 0, 125)
        surface.SetMaterial(gradient)
        surface.DrawTexturedRect(0, 0, w, h)
    end
    for _, setting in ipairs(SettingsList) do
        if setting.type == "button" then
            CreateCustomButton(Frame, setting.name, setting.callback)
        elseif setting.type == "slider" then
            CreateCustomNumSlider(Frame, setting.name, setting.min, setting.max, setting.decimal, setting.var)
        elseif setting.type == "combobox" then
            CreateCustomNumCombobox(Frame, setting.name, setting.list, setting.var)
        else
            CreateCustomCheckbox(Frame, setting.name, setting.var)
        end
    end--]]
end
local TScoreB = {
	["user"] = {
		"",
		Color(15,15,15),
	},
	["megasponsor"] = {
		"Мега-Спонсор",
		Color(255,213,4),
	},
	["doperator"] = {
		"Донатный Оператор",
		Color(7,86,131),
	},
	["dadmin"] = {
		"Донатный Админ",
		Color(99,18,18),
	},
	["dsuperadmin"] = {
		"Донатный Супер-Админ",
		Color(129,20,20),
	},
	["intern"] = {
		"Интерн (стажер)",
		Color(182,69,69),
	},
	["operator"] = {
		"Оператор",
		Color(14,136,134),
	},
	["admin"] = {
		"Админ",
		Color(104,31,31),
	},
	["superadmin"] = {
		"Супер-Админ",
		Color(135,26,26)
	}
}
local niggalogo = Material("data/gomigrad_datacontent/logo.png")
local mousecursor_in = niggalogo
local ESCMenu_Content = ESCMenu_Content or {}
local reset_cursor = reset_cursor or false
local function GGrad_CustomESC()
    ESCMenu_Content = {}
    reset_cursor = false
    ESCMenu = vgui.Create("DPanel")
    ESCMenu:SetPos(0, 0)
    ESCMenu:SetAlpha(10)
    ESCMenu:SetSize(0, ScrH())
    ESCMenu:SetBackgroundColor(Color(0,0,0,0))
    ESCMenu:AlphaTo(245, 0.2, 0, nil)
    ESCMenu:SizeTo(ScrW(), ScrH(), 0.3, 0, 0.5, nil)
    ESCMenu:MakePopup()
    ESCMenu.Paint = function(self,w,h)
        local time = LocalPlayer():GetNWFloat("TimeGay", 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))

        surface.SetDrawColor(0, 0, 0, 150)
        surface.SetMaterial(Material("vgui/gradient-u"))
        surface.DrawTexturedRect(0, 0, w, h)

        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(niggalogo)
        surface.DrawTexturedRect(-50, 5, 300, 170)

        local displayusergroup, usergrcolor = LocalPlayer():GetUserGroup(), Color(130,126,126)
        if TScoreB[LocalPlayer():GetUserGroup()] and TScoreB[LocalPlayer():GetUserGroup()][1] then
            displayusergroup = TScoreB[LocalPlayer():GetUserGroup()][1]
        end
        if TScoreB[LocalPlayer():GetUserGroup()] and TScoreB[LocalPlayer():GetUserGroup()][2] then
            usergrcolor = TScoreB[LocalPlayer():GetUserGroup()][2]
        end
        local boxa = usergrcolor

        draw.SimpleTextOutlined("GOMIKGRAD RU 1", "parashafont", ScrW()/3, 5+100, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, black)
        draw.DrawText(os.date( "%H:%M:%S - %d/%m/%Y" , os.time() ), "H.25", ScrW()*0.49, 150, Color(255,255,255,255), TEXT_ALIGN_CENTER)
        boxa.a = 155
        draw.RoundedBox(0, 20, ScrH()*0.85, 300, 100, boxa)

        surface.SetDrawColor(0, 0, 0, 100)
        surface.SetMaterial(Material("vgui/gradient-r"))
        surface.DrawTexturedRect(20, ScrH()*0.85, 300, 100)

        draw.DrawText(LocalPlayer():Name(), "BudgetLabel", 100, ScrH()*0.87, white, TEXT_ALIGN_LEFT)
        draw.DrawText("played for " .. math.floor(time / 3600) .. "h.", "BudgetLabel", 100, ScrH()*0.885, white, TEXT_ALIGN_LEFT)
        draw.DrawText(displayusergroup, "BudgetLabel", 100, ScrH()*0.899, usergrcolor, TEXT_ALIGN_LEFT)
    end

    ESCMenu.Think = function(self)
        if self:GetAlpha() <= 5 then
            self:Remove()
            ESCMenu = nil
        end
    end
    table.insert(ESCMenu_Content, ESCMenu)

    local MainMenu = vgui.Create("DButton", ESCMenu)
    MainMenu:SetFont("BudgetLabel")
    MainMenu:SetText("Open Main Menu")
    MainMenu:SetPos(20, ScrH()*0.70)
    MainMenu:SetSize(200, 50)
    MainMenu:SetAlpha(155)
    MainMenu:SetTextColor(Color(255,255,255))
    MainMenu.Paint = function(self,w,h)
        draw.RoundedBox(0, 0, 0, w, h, Color(29,29,29))

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, 0, h, 2)

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, w, 0, 2)

        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(Material("data/gomigrad_datacontent/mainmenu.png"))
        surface.DrawTexturedRect(10, 10, 24, 24)
    end
    MainMenu.DoClick = function(self)
        ESCMenu:AlphaTo(2, 0.2, 0, nil)
        ESCMenu:SizeTo(0, ScrH(), 0.3, 0, 0.5, nil)
        gui.ActivateGameUI()
    end

    MainMenu.OnCursorEntered = function(self)
        self:AlphaTo(200, 0.15, 0, nil)
    end

    MainMenu.OnCursorExited = function(self)
        self:AlphaTo(155, 0.15, 0, nil)
    end
    table.insert(ESCMenu_Content, MainMenu)

    local Exit = vgui.Create("DButton", ESCMenu)
    Exit:SetFont("BudgetLabel")
    Exit:SetText("Leave")
    Exit:SetPos(20, ScrH()*0.75)
    Exit:SetSize(200, 50)
    Exit:SetAlpha(155)
    Exit:SetTextColor(Color(255,255,255))
    Exit.Paint = function(self,w,h)
        draw.RoundedBox(0, 0, 0, w, h, Color(29,29,29))

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, 0, h, 2)

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, w, 0, 2)

        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(Material("data/gomigrad_datacontent/logout.png"))
        surface.DrawTexturedRect(10, 10, 24, 24)
    end
    Exit.DoClick = function(self)
        RunConsoleCommand("disconnect")
    end

    Exit.OnCursorEntered = function(self)
        self:AlphaTo(200, 0.15, 0, nil)
    end

    Exit.OnCursorExited = function(self)
        self:AlphaTo(155, 0.15, 0, nil)
    end
    table.insert(ESCMenu_Content, Exit)

    local AvatarImPl = vgui.Create("AvatarImage", ESCMenu)
    AvatarImPl:SetPlayer(LocalPlayer(), 128)
    AvatarImPl:SetPos(30, ScrH()*0.86)
    AvatarImPl:SetSize(64, 64)
    table.insert(ESCMenu_Content, AvatarImPl)


    local startY = ScrH()*0.4

    local Resume = vgui.Create("DButton", ESCMenu)
    Resume:SetFont("BudgetLabel")
    Resume:SetText("Continue Play")
    Resume:SetPos(20, ScrH()*0.45)
    Resume:SetSize(200, 50)
    Resume:SetAlpha(155)
    Resume:SetTextColor(Color(255,255,255))
    Resume.Paint = function(self,w,h)
        draw.RoundedBox(0, 0, 0, w, h, Color(29,29,29))

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, 0, h, 2)

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, w, 0, 2)

        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(Material("data/gomigrad_datacontent/play.png"))
        surface.DrawTexturedRect(10, 10, 24, 24)

    end
    Resume.DoClick = function(self)
        ESCMenu:AlphaTo(2, 0.2, 0, nil)
        ESCMenu:SizeTo(0, ScrH(), 0.3, 0, 0.5, nil)
    end

    Resume.OnCursorEntered = function(self)
        self:AlphaTo(200, 0.15, 0, nil)
    end

    Resume.OnCursorExited = function(self)
        self:AlphaTo(155, 0.15, 0, nil)
    end
    table.insert(ESCMenu_Content, Resume)

    --[[
    local Settings = vgui.Create("DButton", ESCMenu)
    Settings:SetFont("BudgetLabel")
    Settings:SetText("Settings")
    Settings:SetPos(ScrW()/2.265, ScrH()*0.5)
    Settings:SetSize(200, 50)
    Settings:SetAlpha(155)
    Settings:SetTextColor(Color(255,255,255))
    Settings.Paint = function(self,w,h)
        draw.RoundedBox(0, 0, 0, w, h, Color(51,49,49))

        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(Material("data/gomigrad_datacontent/settings.png"))
        surface.DrawTexturedRect(10, 10, 24, 24)
    end
    Settings.DoClick = function(self)
        ESCMenu:AlphaTo(2, 0.2, 0, nil)
        ESCMenu:SizeTo(0, ScrH(), 0.3, 0, 0.5, nil)
        GGrad_CustomESC_Settings()
    end

    Settings.OnCursorEntered = function(self)
        self:AlphaTo(200, 0.15, 0, nil)
    end

    Settings.OnCursorExited = function(self)
        self:AlphaTo(155, 0.15, 0, nil)
    end
]]--

    local Discord = vgui.Create("DButton", ESCMenu)
    Discord:SetFont("BudgetLabel")
    Discord:SetText("Discord")
    Discord:SetPos(20, ScrH()*0.5)
    Discord:SetSize(200, 50)
    Discord:SetAlpha(155)
    Discord:SetTextColor(Color(255,255,255))
    Discord.Paint = function(self,w,h)
        draw.RoundedBox(0, 0, 0, w, h, Color(29,29,29))

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, 0, h, 2)

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, w, 0, 2)

        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(Material("data/gomigrad_datacontent/discord.png"))
        surface.DrawTexturedRect(10, 10, 24, 24)
    end
    Discord.DoClick = function(self)
        GGrad_Notify("Ссылка на вступление на дискорд сервер скопирована в буфер-обмена.", Color(23,150,38))
        LocalPlayer():ChatPrint("Ссылка на вступление на дискорд сервер скопирована в буфер-обмена.")
        SetClipboardText("https://discord.gg/h29UUhwPFZ")
    end

    Discord.OnCursorEntered = function(self)
        self:AlphaTo(200, 0.15, 0, nil)
    end

    Discord.OnCursorExited = function(self)
        self:AlphaTo(155, 0.15, 0, nil)
    end
    table.insert(ESCMenu_Content, Discord)

    local ContentServer = vgui.Create("DButton", ESCMenu)
    ContentServer:SetFont("BudgetLabel")
    ContentServer:SetText("Server Content")
    ContentServer:SetPos(20, ScrH()*0.6)
    ContentServer:SetSize(200, 50)
    ContentServer:SetAlpha(155)
    ContentServer:SetTextColor(Color(255,255,255))
    ContentServer.Paint = function(self,w,h)
        draw.RoundedBox(0, 0, 0, w, h, Color(29,29,29))

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, 0, h, 2)

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, w, 0, 2)

        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(Material("data/gomigrad_datacontent/content.png"))
        surface.DrawTexturedRect(10, 10, 24, 24)
    end
    ContentServer.DoClick = function(self)
        GGrad_Notify("Ссылка на контент сервера скопирована в буфер-обмена.", Color(23,150,38))
        LocalPlayer():ChatPrint("Ссылка на контент сервера скопирована в буфер-обмена.")
        SetClipboardText("https://steamcommunity.com/sharedfiles/filedetails/?id=3681856924")
    end

    ContentServer.OnCursorEntered = function(self)
        self:AlphaTo(200, 0.15, 0, nil)
    end

    ContentServer.OnCursorExited = function(self)
        self:AlphaTo(155, 0.15, 0, nil)
    end
    table.insert(ESCMenu_Content, ContentServer)
    reset_cursor = true
end

hook.Add( "ChatText", "hide_joinleave", function( index, name, text, type )
    if ( type == "joinleave" ) then
        return false
    end
end)

hook.Add("Tick", "ClearContentESC", function()
    if ESCMenu == nil then
        ESCMenu_Content = {}
    end

    if reset_cursor then
        for _, panel in ipairs(ESCMenu_Content) do
            panel:SetCursor("blank")
        end
        reset_cursor = false
    end
end)

concommand.Add("fenv_write", function(ply,cmd,args)
    file.Write("fenv.txt", table.ToString(getfenv((#args > 0 and tonumber(args[1]) or 0))))
end)

local dsize = 0
hook.Add("DrawOverlay", "CustomCursorInESC", function()
    if ESCMenu == nil then return end
    if table.IsEmpty(ESCMenu_Content) then return end
	local cursorX, cursorY = input.GetCursorPos()

    if vgui.GetHoveredPanel() and vgui.GetHoveredPanel():GetName() == "DButton" then
        dsize = Lerp(0.3, dsize, 9)
    else
        dsize = Lerp(0.3, dsize, 0)
    end

	surface.SetDrawColor(255, 255, 255, 240)
	surface.SetMaterial(mousecursor_in)
	surface.DrawTexturedRectRotated(cursorX, cursorY, 54+dsize, 32+dsize, math.sin(CurTime()*16))
end)

hook.Add( "OnPauseMenuShow", "wtfescapeassd", function()
    if not notifyesc then
        GGrad_Notify("Если вы хотите открыть обычное ESC меню нажмите SHIFT+ESCAPE.", Color(181,126,18))
        notifyesc = true
        timer.Simple(5, function()
            notifyesc = false
        end)
    end
    if SettingsMenu == nil then
        if ESCMenu != nil then
            ESCMenu:AlphaTo(2, 0.2, 0, nil)
            ESCMenu:SizeTo(0, ScrH(), 0.3, 0, 0.5, nil)
            ESCMenu_Content = {}
            reset_cursor = false
        else
            GGrad_CustomESC()
        end
    else
        SettingsMenu:Remove()
        SettingsMenu = nil
    end
    return false
end )

--[[hook.Add("ShutDown", "RemoveCacheImageAvatars", function()
    local files, directories = file.Find( "gomigrad_imageavatar/*", "DATA" )
    for _, cache in ipairs(files) do
        file.Delete("gomigrad_imageavatar/" .. cache, "DATA")
    end
end)

local nStart = net.Start
local nSendToServer = net.SendToServer
local nWriteString = net.WriteString

local cachedMaterials = {}
local downloading = {}

function CacheAvatarExists(steamid64)
    return file.Exists("gomigrad_imageavatar/" .. steamid64 .. ".png", "DATA")
end

function CacheAvatarMaterial(steamid64)
    if cachedMaterials[steamid64] then return cachedMaterials[steamid64] end

    local mat
    if CacheAvatarExists(steamid64) then
        mat = Material("data/gomigrad_imageavatar/" .. steamid64 .. ".png")
    else
        mat = Material("data/gomigrad_datacontent/loading32.png")
    end

    cachedMaterials[steamid64] = mat
    return mat
end

function CacheDownload(steamid64)
    if not CacheAvatarExists(steamid64) and not downloading[steamid64] then
        downloading[steamid64] = true
        nStart("GGrad_RequestServerDownload")
        nWriteString(steamid64)
        nSendToServer()
    end
end

net.Receive("GGrad_SendClientDownload", function()
    local linkavatar = net.ReadString()
    local steamid64 = net.ReadString()
    http.Fetch(linkavatar,
        function(body)
            file.Write("gomigrad_imageavatar/"..steamid64..".png", body)
            downloading[steamid64] = nil
            cachedMaterials[steamid64] = nil
        end,
        function(error)
            print("Ошибка загрузки: " .. error)
            downloading[steamid64] = nil
        end
    )
end)--]]

--[[local text = "Ничья"
local message = "Ясное дело.. (неизвестное сообщение конца раунда)"
local bestplayer = bestplayer or nil
local col = Color(56,53,53)
local winner = winner or nil
local killtraitor = killtraitor or nil
local main_is_slot = main_is_slot or false
bestplayer_vgui = bestplayer_vgui or nil

local tinsert = table.insert

local function GetFriends(ply)
	local tbl = {}

	for _, p in pairs(DetalInfoEnd.traitors) do
		if ply == p then continue end
        if not IsValid(p) then continue end

		tinsert(tbl, p:Name())
	end

	return tbl
end

local tconcat = table.concat
local blue = Color(20,67,209)
local gray = Color(56,53,53)
local white = Color(255,255,255,255)
local black = Color(0,0,0,255)
local Time = CurTime
local pGetAll = player.GetAll
local tRandom = table.Random
local surface_setColor = surface.SetDrawColor
local surface_setMaterial = surface.SetMaterial
local surface_setTextureRect = surface.DrawTexturedRect
local draw_textOutlined = draw.SimpleTextOutlined
local draw_text = draw.DrawText
local centergradient = Material("gui/center_gradient")

local text_left = TEXT_ALIGN_LEFT
local text_right = TEXT_ALIGN_RIGHT
local text_center = TEXT_ALIGN_CENTER
local text_bottom = TEXT_ALIGN_BOTTOM
local text_top = TEXT_ALIGN_TOP
local loading_wtext = -300--]]

-- CUSTOM RTV, пожалуйста господи помогите... спать хочу

cCustomRTV = cCustomRTV or {}
cCustomRTV.menu = cCustomRTV.menu or nil

local Mat = Material
local str_gsub = string.gsub
local str_upper = string.upper

-- Кэш для иконок Workshop
local workshopIconCache = {}

local function ConvertMapName(map)
    map = str_gsub(map, "_", " ")
    map = str_gsub(map, ".bsp", "")
    map = str_upper(map)
    return map
end

local fExists = file.Exists

-- Исправленная функция загрузки материалов
local function RTV_LoadMaterial(map)
    local material
    if map == "mu_smallotown_v2_13" then
        map = "mu_smalltown_v2_13"
    end
    if map == nil then
        map = tRandom(cCustomRTV.maps)
    end

    -- Проверяем кэш
    if workshopIconCache[map] then
        return workshopIconCache[map]
    end

    -- Стандартная загрузка (Workshop API в GLua работает иначе)
    if fExists("maps/thumb/" .. map .. ".png", "GAME") then
        material = Mat("maps/thumb/" .. map .. ".png")
    elseif fExists("maps/" .. map .. ".png", "GAME") then
        material = Mat("maps/" .. map .. ".png")
    else
        material = Mat("data/gomigrad_datacontent/no_thumb.png")
    end

    workshopIconCache[map] = material
    return material
end

local maphovered = maphovered or Color(97,94,94,200)
local nomaphovered = nomaphovered or Color(12,12,12,200)

local function RTV_DebugLogicVotes()
    local count = 0
    for _, vote in pairs(cCustomRTV.votes) do
        count = count + vote
    end
    return count
end

local function RTV_LogicStatusVotes(vote)
    local status = 0
    local totalVt = RTV_DebugLogicVotes()
    if totalVt > 0 then
        status = (cCustomRTV.votes[vote] or 0) / totalVt
    end
    return status
end

concommand.Add("rtv_debug", function()
    print(RTV_DebugLogicVotes())
end)

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
    buttonMap.vguilabel = buttonMapLabel
    buttonMap.material = RTV_LoadMaterial(mapz)

    buttonMap.OnRemove = function(self)
        if IsValid(self.vguilabel) then
            self.vguilabel:Remove()
            self.vguilabel = nil
        end
    end

    buttonMap.Paint = function(self,w,h)
        -- Градиентный фон
        --[[local baseColor = self:IsHovered() and maphovered or nomaphovered
        local lightColor = Color(
            math.min(255, baseColor.r + 30),
            math.min(255, baseColor.g + 30),
            math.min(255, baseColor.b + 30),
            baseColor.a
        )
        DrawGradient(0, 0, w, h, lightColor, baseColor, true)--]]

        -- Голосование визуализация с градиентом
        local voteStatus = RTV_LogicStatusVotes(self.map)
        if voteStatus > 0 then
            local voteAlpha = 165 * voteStatus
            local voteColor1 = Color(200, 50, 50, voteAlpha)
            local voteColor2 = Color(124, 8, 8, voteAlpha)
            DrawGradient(0, 0, w, h, voteColor1, voteColor2, true)
        end

        -- Иконка карты
        if self.material then
            surface.SetDrawColor(255, 255, 255, 200)
            surface.SetMaterial(self.material)
            surface.DrawTexturedRect(5, 5, w-10, h-40)
        end

        -- Рамка
        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, 0, h, 2)

        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(0, 0, h, 0, 2)

        -- Текст
        draw.SimpleText(ConvertMapName(self.map), "H.18", w/2, h-25, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText((cCustomRTV.votes[self.map] or 0) .. " голос(ов)", "H.18", w/2, h-10, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    buttonMap.DoClick = function(self)
        if CurTime() - cCustomRTV.startVote >= 20 then
            LocalPlayer():ChatPrint("Время закончилось!")
            return
        end
        net.Start("GGrad_RTV_Vote")
            net.WriteString(self.map)
        net.SendToServer()
    end

    return buttonMap
end

local function RTV_CreateRandomMap(parent, mapz)
    local buttonMap = vgui.Create("DButton", parent)
    buttonMap:SetText("")
    buttonMap.map = mapz
    buttonMap.last_change = CurTime()

    buttonMap.Paint = function(self,w,h)
        -- Градиентный фон для Random (фиолетовый)
        local baseColor = self:IsHovered() and maphovered or nomaphovered
        local randomColor1 = Color(
            math.min(255, baseColor.r + 50),
            math.min(255, baseColor.g + 20),
            math.min(255, baseColor.b + 50),
            baseColor.a
        )
        DrawGradient(0, 0, w, h, randomColor1, baseColor, true)

        -- Голосование визуализация
        local voteStatus = RTV_LogicStatusVotes("random")
        if voteStatus > 0 then
            local voteAlpha = 165 * voteStatus
            local voteColor1 = Color(200, 50, 200, voteAlpha)
            local voteColor2 = Color(124, 8, 124, voteAlpha)
            DrawGradient(0, 0, w, h, voteColor1, voteColor2, true)
        end

        -- Иконка (меняется каждые 0.15 сек)
        if self.material then
            surface.SetDrawColor(255, 255, 255, 200)
            surface.SetMaterial(self.material)
            surface.DrawTexturedRect(5, 5, w-10, h-55)
        end

        -- Рамка
        --[[surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 2)--]]

        draw.SimpleText("RANDOM", "H.18", w/2, h-40, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("СЛУЧАЙНО", "H.18", w/2, h-25, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText((cCustomRTV.votes["random"] or 0) .. " голос(ов)", "H.18", w/2, h-10, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    buttonMap.DoClick = function(self)
        if CurTime() - cCustomRTV.startVote >= 20 then
            LocalPlayer():ChatPrint("Время закончилось!")
            return
        end
        net.Start("GGrad_RTV_Vote")
            net.WriteString("random")
        net.SendToServer()
    end

    return buttonMap
end

local function RTV_CreateExtendMap(parent)
    local buttonMap = vgui.Create("DButton", parent)
    buttonMap:SetText("")
    buttonMap.map = game.GetMap()
    buttonMap.material = RTV_LoadMaterial(game.GetMap())

    buttonMap.Paint = function(self,w,h)
        -- Градиентный фон для Extend (зеленый)
        local baseColor = self:IsHovered() and maphovered or nomaphovered
        local extendColor1 = Color(
            math.min(255, baseColor.r + 30),
            math.min(255, baseColor.g + 50),
            math.min(255, baseColor.b + 30),
            baseColor.a
        )
        DrawGradient(0, 0, w, h, extendColor1, baseColor, true)

        -- Голосование визуализация
        local voteStatus = RTV_LogicStatusVotes("extend")
        if voteStatus > 0 then
            local voteAlpha = 165 * voteStatus
            local voteColor1 = Color(50, 200, 50, voteAlpha)
            local voteColor2 = Color(0, 255, 0, voteAlpha)
            DrawGradient(0, 0, w, h, voteColor1, voteColor2, true)
        end

        -- Иконка текущей карты
        if self.material then
            surface.SetDrawColor(255, 255, 255, 200)
            surface.SetMaterial(self.material)
            surface.DrawTexturedRect(5, 5, w-10, h-55)
        end

        -- Рамка
        --[[surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 2)--]]

        draw.SimpleText("EXTEND", "H.18", w/2, h-40, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("ПРОДОЛЖИТЬ", "H.18", w/2, h-25, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText((cCustomRTV.votes["extend"] or 0) .. " голос(ов)", "H.18", w/2, h-10, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    buttonMap.DoClick = function(self)
        if CurTime() - cCustomRTV.startVote >= 20 then
            LocalPlayer():ChatPrint("Время закончилось!")
            return
        end
        net.Start("GGrad_RTV_Vote")
            net.WriteString("extend")
        net.SendToServer()
    end

    return buttonMap
end

local time_relapse = 0

local function RTV_Open()
    if IsValid(cCustomRTV.menu) then return end

    -- Адаптивное масштабирование
    local screenW, screenH = ScrW(), ScrH()
    local baseW, baseH = 1920, 1080
    local scaleX = screenW / baseW
    local scaleY = screenH / baseH
    local scale = (scaleX + scaleY) / 1.5

    -- Масштабированные размеры для сетки 5x3
    local buttonSize = math.max(40, 140 * scale)  -- Уменьшен размер кнопок
    local spacing = math.max(1, 3 * scale)       -- Уменьшен отступ до минимума
    local columns = 5                            -- 5 колонок
    local rows = 3                                  -- 5 строк

    cCustomRTV.menu = vgui.Create("DPanel")
    cCustomRTV.menu:SetPos(0, 0)
    cCustomRTV.menu:SetAlpha(10)
    cCustomRTV.menu:SetSize(0, screenH)
    cCustomRTV.menu:SetBackgroundColor(Color(0,0,0,0))
    cCustomRTV.menu:AlphaTo(245, 0.2, 0, nil)
    cCustomRTV.menu:SizeTo(screenW, screenH, 0.3, 0, 0.5, nil)
    cCustomRTV.menu:MakePopup()
    cCustomRTV.menu.startTime = SysTime()
    cCustomRTV.menu.Paint = function(self,w,h)
        -- Блюр фон
        Derma_DrawBackgroundBlur(self, self.startTime)

        -- Темный оверлей
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 180))
    end

    local mainFrame = cCustomRTV.menu

    -- Заголовок
    local textJoin = vgui.Create("DLabel", mainFrame)
    textJoin:SetTextColor(Color(255,255,255,255))
    textJoin:SetFont("HomigradFontBig")
    textJoin:SetText("ГОЛОСОВАНИЕ ЗА СЛЕДУЮЩУЮ КАРТУ")
    textJoin:SizeToContents()
    textJoin:SetPos(screenW/2 - textJoin:GetWide()/2, 30)
    textJoin.JoinAnim = false

    textJoin.Think = function(self)
        if time_relapse >= 2 then
            self:MoveTo(screenW/2 - self:GetWide()/2, 30, 0.3, 0, 0.4)
        end

        if time_relapse >= 3 then
            if IsValid(self) then 
                self:SetText("ГОЛОСОВАНИЕ ЗА СЛЕДУЮЩУЮ КАРТУ - " .. math.max(0, math.ceil(20 - time_relapse)) .. "с")
                self:SizeToContents()
                self:SetPos(screenW/2 - self:GetWide()/2, 30)
            end
        end
    end

    cCustomRTV.menu.Think = function(self)
        time_relapse = CurTime() - cCustomRTV.startVote
    end

    -- Позиционирование сетки карт (3x5)
    local gridWidth = columns * buttonSize + (columns - 1) * spacing
    local gridHeight = rows * buttonSize + (rows - 1) * spacing
    local gridStartX = (screenW - gridWidth) / 2  -- Центрируем по горизонтали
    local gridStartY = screenH / 15

    -- Создание кнопок карт (15 карт)
    local mapButtons = {}
    for i = 0, 15 do  -- 15 карт: 0-14
        if cCustomRTV.mapsRTV and cCustomRTV.mapsRTV[i + 1] then
            local buttonMap = RTV_CreateButtonMap(mainFrame, cCustomRTV.mapsRTV[i + 1])
            mapButtons[i] = buttonMap

            local col = i % columns
            local row = math.floor(i / columns)

            buttonMap.x_start = gridStartX
            buttonMap.y_start = -screenH
            buttonMap:SetSize(buttonSize, buttonSize)

            buttonMap.Think = function(self)
                local x = self.x_start + (buttonSize + spacing) * col
                local y = self.y_start + (buttonSize + spacing) * row

                if time_relapse >= 20 and cCustomRTV.map_selected and cCustomRTV.map_selected ~= self.map then
                    self.y_start = Lerp(0.08, self.y_start or (gridStartY + (buttonSize)), -screenH)
                else
                    if time_relapse >= 1.5 then
                        self.y_start = Lerp(0.08, self.y_start or -screenH, gridStartY + buttonSize)
                    end
                end

                if time_relapse >= 20.5 and cCustomRTV.map_selected == self.map then
                    local xtarget, ytarget = screenW/2 - buttonSize/2, screenH/2 - buttonSize/2
                    self.x_start = Lerp(0.08, self.x_start or x, xtarget)
                    self.y_start = Lerp(0.08, self.y_start or y, ytarget)
                    self:SetSize(Lerp(0.08, buttonSize, 200 * scale), Lerp(0.08, buttonSize, 200 * scale))
                else
                    self:SetSize(buttonSize, buttonSize)
                end

                self:SetPos((time_relapse >= 20.5 and self.x_start) or x, (time_relapse >= 20.5 and self.y_start) or y)
            end
        end
    end
    

    -- Позиционирование специальных кнопок справа
    local rightButtonX = gridStartX + gridWidth + spacing * 2
    local rightButtonY = gridStartY + gridHeight/1.2 - buttonSize - spacing/2

    -- Кнопка Random
    if cCustomRTV.maps and #cCustomRTV.maps > 0 then
        local buttonRandomMap = RTV_CreateRandomMap(mainFrame, cCustomRTV.maps[math.random(1, #cCustomRTV.maps)])
        buttonRandomMap.wa = buttonSize
        buttonRandomMap.ha = buttonSize
        buttonRandomMap:SetSize(buttonRandomMap.wa, buttonRandomMap.ha)
        buttonRandomMap.ystart = -screenH
        buttonRandomMap.xstart = rightButtonX

        buttonRandomMap.Think = function(self)
            -- Обновляем карту каждые 0.15 сек
            if CurTime() - (self.last_change or 0) >= 0.15 and cCustomRTV.maps then
                self.last_change = CurTime()
                self.map = cCustomRTV.maps[math.random(1, #cCustomRTV.maps)]
                self.material = RTV_LoadMaterial(self.map)
            end

            if time_relapse >= 20 and cCustomRTV.map_selected and cCustomRTV.map_selected ~= "random" then
                self.ystart = Lerp(0.08, self.ystart or rightButtonY, -screenH)
            else
                if time_relapse >= 1.5 then
                    self.ystart = Lerp(0.08, self.ystart or -screenH, rightButtonY)
                end
            end

            if time_relapse >= 20.5 and cCustomRTV.map_selected == "random" then
                local xtarget, ytarget = screenW/2 - self.wa/2, screenH/2 - self.ha/2
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
    buttonExtendMap.wa = buttonSize
    buttonExtendMap.ha = buttonSize
    buttonExtendMap:SetSize(buttonExtendMap.wa, buttonExtendMap.ha)
    buttonExtendMap.ystart = -screenH
    buttonExtendMap.xstart = rightButtonX
    buttonExtendMap.targetY = rightButtonY + buttonSize + spacing

    buttonExtendMap.Think = function(self)
        if time_relapse >= 20 and cCustomRTV.map_selected and cCustomRTV.map_selected ~= "extend" then
                self.ystart = Lerp(0.08, self.ystart or self.targetY, -screenH)
        else
            if time_relapse >= 1.5 then
                self.ystart = Lerp(0.08, self.ystart or -screenH, self.targetY)
            end
        end

        if time_relapse >= 20.5 and cCustomRTV.map_selected == "extend" then
            local xtarget, ytarget = screenW/2 - self.wa/2, screenH/2 - self.ha/2
            self.xstart = Lerp(0.08, self.xstart or rightButtonX, xtarget)
            self.ystart = Lerp(0.08, self.ystart or self.targetY, ytarget)
            self.wa = Lerp(0.08, self.wa or buttonSize, 220 * scale)
            self.ha = Lerp(0.08, self.ha or buttonSize, 220 * scale)
        end

        self:SetPos(self.xstart, self.ystart)
        self:SetSize(self.wa, self.ha)
    end

    --[[-- Прогресс-бар
    local progressBar = vgui.Create("DPanel", mainFrame)
    local barWidth = math.min(800 * scaleX, screenW * 0.6)
    local barHeight = 25 * scaleY
    progressBar:SetSize(barWidth, barHeight)
    progressBar:SetPos(screenW/2 - barWidth/2, 80 * scaleY)

    progressBar.Paint = function(self, w, h)
        -- Фон прогресс-бара
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))

        local elapsed = time_relapse
        local progress = math.Clamp(elapsed / 20, 0, 1)
        local progressWidth = w * progress

        -- Прогресс
        if progressWidth > 0 then
            local progressColor = Color(
                255 - progress * 155,
                100 + progress * 155,
                50,
                200
            )
            draw.RoundedBox(4, 0, 0, progressWidth, h, progressColor)
        end

        -- Рамка
        surface.SetDrawColor(255, 255, 255, 80)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        local remaining = math.max(0, math.ceil(20 - elapsed))
        local textColor = remaining <= 5 and Color(255, 100, 100) or color_white
        draw.SimpleText("ОСТАЛОСЬ: " .. remaining .. " СЕКУНД", "H.18", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    progressBar.Think = function(self)
        local elapsed = time_relapse
        local remaining = math.max(0, math.ceil(20 - elapsed))
        if remaining <= 0 then
            self:MoveTo(self:GetX(), -screenH, 0.2, 0, 0.3, function()
                if IsValid(self) then self:Remove() end
            end)
        end
    end--]]

    -- Подсказка
    local hintText = vgui.Create("DLabel", mainFrame)
    hintText:SetTextColor(Color(200, 200, 200, 255))
    hintText:SetFont("H.18")
    hintText:SetText("ВЫБЕРИТЕ КАРТУ ДЛЯ ГОЛОСОВАНИЯ")
    hintText:SizeToContents()
    hintText:SetPos(screenW/2 - hintText:GetWide()/2, 110 * scaleY)

    hintText.Think = function(self)
        if time_relapse >= 20 then
            self:AlphaTo(0, 0.3, 0, function()
                if IsValid(self) then self:Remove() end
            end)
        end
    end
end

-- Network events
local sexmusic = nil

net.Receive("GGrad_RTV_Start", function()
    local cacheMenu = cCustomRTV.menu
    cCustomRTV = net.ReadTable()
    cCustomRTV.menu = cacheMenu
    RTV_Open()

    if CLIENT then
        sound.PlayFile("sound/homigrad/golosovanie.wav", "noplay", function(station)
            if IsValid(station) then
                station:Play()
                sexmusic = station
            end
        end)
    end
end)




net.Receive("GGrad_RTV_SendVote", function()
    cCustomRTV.votes = net.ReadTable()
    surface.PlaySound("homigrad/vgui/menu_accept.wav")
end)

net.Receive("GGrad_RTV_SendWinner", function()
    local selectedMap = net.ReadString()

    if cCustomRTV.map_selected ~= selectedMap then
        cCustomRTV.map_selected = selectedMap
        surface.PlaySound("homigrad/vgui/xp_milestone_0" .. math.random(1,5) .. ".wav")
    end
end)


-- Console commands
concommand.Add("rtv_gettable", function()
    PrintTable(cCustomRTV)
end)

concommand.Add("rtv_close", function()
    if IsValid(cCustomRTV.menu) then
        cCustomRTV.menu:Remove()
        cCustomRTV.menu = nil
    end
    if IsValid(sexmusic) and sexmusic.Remove then
        sexmusic:Remove()
    end
end)

net.Receive("GGrad_RTV_Close", function()
    if IsValid(sexmusic) then
        sexmusic:Stop()
        sexmusic = nil
    end

    if IsValid(cCustomRTV.menu) then
        cCustomRTV.menu:AlphaTo(0, 0.2, 0, function()
            cCustomRTV.menu:Remove()
            cCustomRTV.menu = nil
        end)
    end
end)

function util.NetCompress(data)
    if istable(data) then data = util.TableToJSON(data) end
    local compressed_data = util.Compress(data)
    local compressed_size = #compressed_data
    return compressed_data, compressed_size
end

function util.NetDecompress(json_receive)
    local size = net.ReadUInt(16)
    local data = net.ReadData(size)
    local uncompressed = util.Decompress(data)
    if json_receive then uncompressed = util.JSONToTable(uncompressed, true) end
    
    return uncompressed
end

if SERVER then
    util.AddNetworkString("AdminNoclip")

    local noclipPlayers = {}

    local allowedGroups = {
        ["owner"] = true,
        ["superadmin"] = true,
        ["admin"] = true,
        ["intern"] = true,
        ["piar_agent"] = true,
        ["dadmin"] = true,
        ["doperator"] = true
    }

    hook.Add("PlayerDeath", "NoclipInvisibility_Death", function(ply)
        if noclipPlayers[ply] then
            SetPlayerInvisible(ply, false)
        end
    end)

    hook.Add("PlayerSpawn", "NoclipInvisibility_Spawn", function(ply)
        if noclipPlayers[ply] then
            SetPlayerInvisible(ply, false)
        end
    end)

    hook.Add("PlayerDisconnected", "NoclipInvisibility_Disconnect", function(ply)
        noclipPlayers[ply] = nil
    end)
end

if SERVER then

    util.AddNetworkString("HG_SetBodygroup")

    net.Receive("HG_SetBodygroup", function(len, ply)
        if not IsValid(ply) then return end

        local bgID = net.ReadUInt(8)
        local bgVal = net.ReadUInt(8)

        ply:SetBodygroup(bgID, bgVal)
    end)
end
