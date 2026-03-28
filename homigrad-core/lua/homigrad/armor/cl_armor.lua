-- "addons\\homigrad-core\\lua\\homigrad\\armor\\cl_armor.lua"
-- Retrieved by https://github.com/lewisclark/glua-steal
hook.Add("InitArmor_CL","ArmorInit",function(ply)
    ply.armor_render = ply.armor_render or {}
    ply.armor = ply.armor or {}

    ply.armor.torso = "NoArmor"
    ply.armor.head =  "NoArmor"
    ply.armor.face =  "NoArmor"
    ply.armor.back =  "NoArmor"

    ply.armor.lleg =  "NoArmor"
    ply.armor.rleg =  "NoArmor"

    ply.armor.larm =  "NoArmor"
    ply.armor.rarm =  "NoArmor"

    ply:SetNWBool("otrub",false)
    ply:SetNWFloat("pain",0)
end)

//net.Receive("armor_sosal",function()
//    local ent = net.ReadEntity()
//    local arm = net.ReadTable()
//
//    ent.armor = arm
//end)

hook.Add("PostDrawOpaqueRenderables","FixShit",function()
    if (hg._nextArmorPassOpaque or 0) > CurTime() then return end
    hg._nextArmorPassOpaque = CurTime() + 0.08
    for _, ply in ipairs(player.GetAll()) do
        //if ply:GetNWBool("Fake") then
            hook.Run("PostDrawPlayerRagdoll",ply,hg.GetCurrentCharacter(ply))
        //end
    end
end)

hook.Add("PreRender","123123",function()
    if (hg._nextArmorPassPreRender or 0) > CurTime() then return end
    hg._nextArmorPassPreRender = CurTime() + 0.08
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetNWBool("Fake") then
            hook.Run("PostDrawPlayerRagdoll",ply,hg.GetCurrentCharacter(ply))
        end
    end
end)

hook.Add("PrePlayerDraw","DrawArmor",function(ply)
    hook.Run("PostDrawPlayerRagdoll",ply,hg.GetCurrentCharacter(ply))
end)

function hg.RenderArmor(ply)
    local ent = hg.GetCurrentCharacter(ply)
    
    ply.armor = ply:GetNetVar("Armor")

    if !ply.armor then
        return  
    end
    
    if !ply:Alive() then
        if !ply.armor_render then
            ply.armor_render = {}
        end
        for placement, armor in pairs(ply.armor) do
            if ply.armor_render[placement] != nil then
                ply.armor_render[placement]:Remove()
                ply.armor_render[placement] = nil
            end
        end
        
        return 
    end

    local armor_torso = ply.armor.torso
    local armor_head = ply.armor.head
    local armor_face = ply.armor.face
    local armor_back = ply.armor.back

    ply.armor_render = ply.armor_render or {}
    local activeWeapon = ply:GetActiveWeapon()
    local hideLocalArmorForCSS = GetViewEntity() == ply and IsValid(activeWeapon) and string.match(activeWeapon:GetClass(), "_css") != nil

    for placement, armor in pairs(ply.armor) do
        local tbl = hg.Armors[armor]
        if tbl != nil then
            if ply.armor_render[placement] == nil then
                local mdl = ClientsideModel(tbl.Model,RENDERMODE_NORMAL)
                if !IsValid(mdl) then
                    ply.armor_render[placement] = nil
                    continue
                end

                ply.armor_render[placement] = mdl
                mdl:SetNotSolid(true)
                mdl:SetNWBool("nophys", true)
                mdl:SetSolidFlags(FSOLID_NOT_SOLID)
                mdl:AddEFlags(EFL_NO_DISSOLVE)
                mdl:AddEffects(EF_BONEMERGE)

                ply:CallOnRemove("remove_shit"..placement,function()
                    if IsValid(mdl) then
                        mdl:Remove()
                    end
                end)

                //table.insert(hg.csm,ply.armor_render[placement])
            end

            if !IsValid(ply.armor_render[placement]) then
                ply.armor_render[placement] = nil
            end   
            
            if !ply.armor_render[placement] then
                continue 
            end

            if ply.armor_render[placement]:GetModel() != tbl.Model then
                ply.armor_render[placement]:Remove()
                ply.armor_render[placement] = nil
            end
        
            if ply.armor_render[placement] == nil then
                continue 
            end
            
            ply.armor_render[placement].NoRender = ply.armor_render[placement]:GetNoDraw()

            if hideLocalArmorForCSS then
                ply.armor_render[placement]:SetNoDraw(true)
                ply.armor_render[placement].NoRender = true
                continue
            else
                ply.armor_render[placement]:SetNoDraw(false)
                ply.armor_render[placement].NoRender = false
            end
        
            if tbl.NoDraw and GetViewEntity() == ply then
                ply.armor_render[placement]:SetNoDraw(true)
                ply.armor_render[placement].NoRender = true
                continue 
            elseif tbl.NoDraw and GetViewEntity() != ply then
                //ply.armor_render[placement]:SetNoDraw(false)
                ply.armor_render[placement].NoRender = false
            end
        
            ply.armor_render[placement]:SetModelScale(((hg.IsFemale(ent) and tbl.FemScale) and tbl.FemScale or tbl.Scale) or 1,0)
        
            ply.armor_render[placement]:SetBodygroup(0,1)
        
            if ent == NULL then
                continue 
            end
        
            local bone = ent:LookupBone(tbl.Bone)
            if !bone then
                continue
            end

            local pos,ang = ent:GetBonePosition(bone)
            if !pos or !ang then
                continue
            end
        
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
        
            //ply.armor_render[placement]:SetParent(ent)
        
            ply.armor_render[placement]:SetRenderOrigin(pos)
            ply.armor_render[placement]:SetRenderAngles(ang)
        
            ply.armor_render[placement]:SetPos(pos)
            ply.armor_render[placement]:SetAngles(ang)
        
            //ply.armor_render[placement]:DrawModel()
        else
            if ply.armor_render[placement] != nil then
                ply.armor_render[placement]:Remove()
                ply.armor_render[placement] = nil
            end
        end
    end
end

function hg.RenderArmorEnt(ent)
    if !ent.armor then
        return  
    end

    ent.armor = ent:GetNetVar("Armor")

    if !IsValid(ent) then
        for placement, armor in pairs(ent.armor) do
            if ent.armor_render[placement] != nil then
                ent.armor_render[placement]:Remove()
                ent.armor_render[placement] = nil
            end
        end
        return 
    end

    local armor_torso = ent.armor.torso
    local armor_head = ent.armor.head
    local armor_face = ent.armor.face
    local armor_back = ent.armor.back

    ent.armor_render = ent.armor_render or {}

    for placement, armor in pairs(ent.armor) do
        local tbl = hg.Armors[armor]
        if tbl != nil then
            if ent.armor_render[placement] == nil then
                local mdl = ClientsideModel(tbl.Model,RENDERMODE_NORMAL)
                if !IsValid(mdl) then
                    ent.armor_render[placement] = nil
                    continue
                end

                ent.armor_render[placement] = mdl
                mdl:SetNotSolid(true)
                mdl:SetNWBool("nophys", true)
                mdl:SetSolidFlags(FSOLID_NOT_SOLID)
                mdl:AddEFlags(EFL_NO_DISSOLVE)
                mdl:AddEffects(EF_BONEMERGE)
                table.insert(hg.csm, mdl)
                ent:CallOnRemove("remove_shit"..placement,function()
                    if IsValid(mdl) then
                        mdl:Remove()
                    end
                end)
            end
        
            if !IsValid(ent) then
                continue 
            end

            if !IsValid(ent.armor_render[placement]) then
                ent.armor_render[placement] = nil
                continue 
            end

            if ent.armor_render[placement]:GetModel() != tbl.Model then
                ent.armor_render[placement]:Remove()
                ent.armor_render[placement] = nil
            end
        
            if ent.armor_render[placement] == nil then
                continue 
            end
            
            ent.armor_render[placement].NoRender = ent.armor_render[placement]:GetNoDraw()
        
            ent.armor_render[placement].NoRender = false
        
            ent.armor_render[placement]:SetModelScale(((hg.IsFemale(ent) and tbl.FemScale) and tbl.FemScale or tbl.Scale) or 1,0)
        
            ent.armor_render[placement]:SetBodygroup(0,1)
        
            local bone = ent:LookupBone(tbl.Bone)
            if !bone then
                continue
            end

            local pos,ang = ent:GetBonePosition(bone)
            if !pos or !ang then
                continue
            end
        
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
        
            //ent.armor_render[placement]:SetParent(ent)
        
            ent.armor_render[placement]:SetRenderOrigin(pos)
            ent.armor_render[placement]:SetRenderAngles(ang)
        
            ent.armor_render[placement]:SetPos(pos)
            ent.armor_render[placement]:SetAngles(ang)
        
            //ent.armor_render[placement]:DrawModel()
        else
            if ent.armor_render[placement] != nil then
                ent.armor_render[placement]:Remove()
                ent.armor_render[placement] = nil
            end
        end
    end
end

hook.Add("PostDrawRagdoll","RenderArmor",function(rag)
    if !IsValid(hg.RagdollOwner(rag)) then
        return
    end
    if rag:GetNWBool("NoHead") then
        rag:ManipulateBoneScale(6,Vector(0,0,0))
    else
        rag:ManipulateBoneScale(6,Vector(1,1,1))
    end

    rag.armor = rag:GetNetVar("Armor")

    if IsValid(hg.RagdollOwner(rag)) and (!hg.RagdollOwner(rag):Alive() or hg.RagdollOwner(rag):GetNWEntity("FakeRagdoll") != rag) then
        hg.RenderArmorEnt(rag)
    end
end)

hook.Add("PostDrawPlayerRagdoll","Render_Armor",function(ply,rag)
    hg.RenderArmor(ply)
end)

hook.Add("Think","RenderRagdoll",function()
    if (hg._nextArmorRagdollThink or 0) > CurTime() then return end
    hg._nextArmorRagdollThink = CurTime() + 0.15
    for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
        if IsValid(hg.RagdollOwner(ent)) and (hg.RagdollOwner(ent).Fake and hg.RagdollOwner(ent).FakeRagdoll == ent and hg.RagdollOwner(ent):Alive()) then
            continue 
        end

        hook.Run("PostDrawRagdoll",ent)
    end
end)

hook.Add("Player Think","shit",function(ply)
    if (ply._nextArmorDeadRender or 0) > CurTime() then return end
    ply._nextArmorDeadRender = CurTime() + 0.15
    if ply:Alive() then
        return
    end

    hg.RenderArmor(ply)
end)

hook.Add("HUDPaint","Armor_Overlay",function()
    local ply = LocalPlayer()

    if !ply:Alive() then
        return
    end

    if GetViewEntity() != ply then
        return
    end

    if !ply.armor then
        return 
    end

    local armor_head = ply.armor.head
    local armor_face = ply.armor.face

    local tbl_head = hg.Armors[armor_head]
    local tbl_face = hg.Armors[armor_face]

    if tbl_face != nil and tbl_face.Overlay != nil then
        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(Material(tbl_face.Overlay))
        surface.DrawTexturedRect(0,0,ScrW(),ScrH())
    end

    if tbl_head != nil and tbl_head.Overlay != nil then
        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(Material(tbl_head.Overlay))
        surface.DrawTexturedRect(0,0,ScrW(),ScrH())
    end
end)
