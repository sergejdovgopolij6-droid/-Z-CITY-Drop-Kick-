
local vecZero = Vector(0, 0, 0)
local vectorUp = Vector(0, 0, 1)
local shadowparams = {}

--[[
local ply = Entity(1)
local tbl = {}
for i = 0,ply:GetBoneCount()-1 do
	local physbone = ply:TranslateBoneToPhysBone(i)
	if physbone != -1 and not tbl[physbone] then
		tbl[physbone] = ply:GetBoneName(i)
	end
end
for i,bon in ipairs(tbl) do
	print("["..i.."] = "..'"'..bon..'"'..",")
end
]]

local defaultBones = {
	[0] = "ValveBiped.Bip01_Pelvis",
	[1] = "ValveBiped.Bip01_Spine2",
	[2] = "ValveBiped.Bip01_R_UpperArm",
	[3] = "ValveBiped.Bip01_L_UpperArm",
	[4] = "ValveBiped.Bip01_L_Forearm",
	[5] = "ValveBiped.Bip01_L_Hand",
	[6] = "ValveBiped.Bip01_R_Forearm",
	[7] = "ValveBiped.Bip01_R_Hand",
	[8] = "ValveBiped.Bip01_R_Thigh",
	[9] = "ValveBiped.Bip01_R_Calf",
	[10] = "ValveBiped.Bip01_Head1",
	[11] = "ValveBiped.Bip01_L_Thigh",
	[12] = "ValveBiped.Bip01_L_Calf",
	[13] = "ValveBiped.Bip01_L_Foot",
	[14] = "ValveBiped.Bip01_R_Foot",
}

--[[
local ent = hg.GetCurrentCharacter(Entity(1))
for i = 0,ent:GetBoneCount()-1 do
	print(i,ent:GetBoneName(i),ent:TranslateBoneToPhysBone(i))
end

for i = 0,ent:GetPhysicsObjectCount()-1 do
	print(i,ent:GetBoneName(ent:TranslatePhysBoneToBone(i)),i)
end
--]]

hg.cachedmodels = hg.cachedmodels or {}



local function realPhysNum(ragdoll, physNumber)
	local bone = defaultBones[physNumber]
	local model = ragdoll:GetModel()
	
	if hg.cachedmodels[model] and hg.cachedmodels[model][bone] then
		return hg.cachedmodels[model][bone]
	else
		hg.cacheModel(ragdoll)
		
		return hg.cachedmodels[model] and hg.cachedmodels[model][bone] or 0
	end
end


hg.realPhysNum = realPhysNum
local oldtime
function hg.ShadowControl(ragdoll, physNumber, ss, ang, maxang, maxangdamp, pos, maxspeed, maxspeeddamp)
	-- Skip head control if neck is broken
	if ragdoll.brokenNeck and realPhysNum(ragdoll, physNumber) == realPhysNum(ragdoll, 10) then
		return -- Don't apply shadow control to head when neck is broken
	end
	
	physNumber = realPhysNum(ragdoll, physNumber) or 0
	physNumber = ragdoll:GetPhysicsObjectNum(physNumber)
	shadowparams.secondstoarrive = ss
	shadowparams.angle = ang
	shadowparams.maxangular = maxang and maxang * (ragdoll.power or 1)
	shadowparams.maxangulardamp = maxangdamp
	shadowparams.pos = pos
	shadowparams.maxspeed = maxspeed and maxspeed * (ragdoll.power or 1)
	shadowparams.maxspeeddamp = maxspeeddamp
	shadowparams.dampfactor = 0.9
	physNumber:Wake()
	physNumber:ComputeShadowControl(shadowparams)
end

local shadowControl = hg.ShadowControl

-- Сделай (префикс z_ гарантирует выполнение позже многих других):
hook.Add("Fake", "z_dropkick_control", function(ply, ragdoll)
    -- Твоя логика подката и дропкика
    local vel = ply:GetVelocity()
    if vel:Length() > 300 then
        if ply:OnGround() then
            ragdoll.isSliding = true
            -- ...
        else
            ragdoll.dropkick = true
            -- ...
        end
    end
end)

--local ragdollFake = hg.ragdollFake or {}
local att, trace, ent
local tr = {
	filter = {}
}

local util_TraceLine, util_TraceHull = util.TraceLine, util.TraceHull
local game_GetWorld = game.GetWorld
local ang, ang2, ang3 = Angle(0, 0, 0), Angle(0, 0, 0),  Angle(0, 0, 0)
local angZero = Angle(0, 0, 0)
local vecZero = Vector(0, 0, 0)
local hullVec = Vector(3, 3, 6)
local vecAimHands = Vector(0, 0, -4.5)
local spine, time, rhand, lhand
--local Organism = hg.organism
local height = Vector(0, 0, 72) --28 eye level if crouched
local util_PointContents, bit_band, hook_Run = util.PointContents, bit.band, hook.Run
local forceArm = 600
local forceArm_dump = 450
local forceArmForward = 120
local forceArmForward_dump = 105
local forceArmWater = 5
local forceArmWater_dump = 0
local forceArmGun = 9000
local forceArmGun_dump = 1000
local fakeshockFall = 0.1
-- Kick force constants
local forceKick = 800
local forceKick_dump = 600
local kickDamage = 12
local kickCooldown = 1.2
local allowFakeKick = true
local models_female = {
	["models/player/group01/female_01.mdl"] = true,
	["models/player/group01/female_02.mdl"] = true,
	["models/player/group01/female_03.mdl"] = true,
	["models/player/group01/female_04.mdl"] = true,
	["models/player/group01/female_05.mdl"] = true,
	["models/player/group01/female_06.mdl"] = true,
	["models/player/group03/female_01.mdl"] = true,
	["models/player/group03/female_02.mdl"] = true,
	["models/player/group03/female_03.mdl"] = true,
	["models/player/group03/female_04.mdl"] = true,
	["models/player/group03/female_05.mdl"] = true,
	["models/player/group03/police_fem.mdl"] = true
}
local hook_Run = hook.Run
local hg_shadow_enable = ConVarExists("hg_shadow_enable") and GetConVar("hg_shadow_enable") or CreateConVar("hg_shadow_enable", 0, FCVAR_SERVER_CAN_EXECUTE, "exact shadown control 1/0", 0, 1)
local hg_cshs_fake = ConVarExists("hg_cshs_fake") and GetConVar("hg_cshs_fake") or CreateConVar("hg_cshs_fake", 0, FCVAR_NONE, "fake from cshs", 0, 1)
local vector_zero = Vector(0,0,0)

--[[
	ValveBiped.Bip01_L_Thigh
	ValveBiped.Bip01_L_Calf
	ValveBiped.Bip01_L_Foot
	ValveBiped.Bip01_L_Toe0
]]

--[[local mainbones = {
	["ValveBiped.Bip01_Pelvis"] = true,
	["ValveBiped.Bip01_Spine2"] = true,
	["ValveBiped.Bip01_Head1"] = true,
}--]]

local hg_ragdollcombat = ConVarExists("hg_ragdollcombat") and GetConVar("hg_ragdollcombat") or CreateConVar("hg_ragdollcombat", 0, FCVAR_REPLICATED, "ragdoll combat", 0, 1)
local hg_fake_hand_checks = ConVarExists("hg_fake_hand_checks") and GetConVar("hg_fake_hand_checks") or CreateConVar("hg_fake_hand_checks", 1, FCVAR_SERVER_CAN_EXECUTE, "enable hand strength and velocity checks", 0, 1)

local speedupbones = {
	["ValveBiped.Bip01_L_Foot"] = true,
	["ValveBiped.Bip01_R_Foot"] = true,
}

local vecfive = Vector(5,5,5)

local player_GetHumans = player.GetHumans

hook.Add("Think", "Fake", function()
	hg.humans_cached = player_GetHumans()

	for ply, ragdoll in pairs(hg.ragdollFake) do
		if not IsValid(ragdoll) then
			hg.ragdollFake[ply] = nil
			continue
		end

		local torso = ragdoll:LookupBone("ValveBiped.Bip01_Spine4")
		if torso then
			local torsopos, ang = ragdoll:GetBonePosition(torso)

			if IsValid(ragdoll.bull) then
				--ragdoll.bull:SetPos(torsopos + (math.random(2) == 1 and ang:Right() or math.random(2) == 1 and ang:Up() or ang:Forward()) * (math.random(2) == 1 and -1 or 1) * 15)
				--ragdoll.bull:SetPos(torsopos + ang:Right() * -15)
				ragdoll.bull:SetPos(torsopos + VectorRand(-15,15))
			end
		end

		if hook_Run("CanControlFake",ply,rag) ~= nil then
			ply.lastFake = 0
			ply:SetNetVar("lastFake",0)
			continue
		end

		ragdoll.dtime = SysTime() - (ragdoll.lastCallTime or SysTime())
		ragdoll.lastCallTime = SysTime()

		local org = ply.organism
		local wep = ply:GetActiveWeapon()
		
		-- Check for active neurological posturing - disable E key (IN_USE) during posturing
		local hasActivePosturing = false
		if neurological_reactions and neurological_reactions[ragdoll:EntIndex()] then
			local reaction = neurological_reactions[ragdoll:EntIndex()]
			if reaction.type == "decerebrate" or reaction.type == "decorticate" then
				hasActivePosturing = true
			end
		end
		
		-- Also check for natural posturing based on brain damage
		if org and org.brain then
			local brain = org.brain
			if brain >= 0.4 or (brain >= 0.3 and brain < 0.4) then -- Decerebrate or Decorticate thresholds
				hasActivePosturing = true
			end
		end

		local tr = {}
		tr.start = ply:GetPos()
		tr.endpos = ply:GetPos() - vector_up * 10
		tr.filter = {ply,ragdoll}
		local tracehuy = util.TraceLine(tr)
		
        local power = org.pain and ((org.pain > 50 or org.blood < 2900 or org.o2[1] < 5) and 0.3) or ((org.pain > 20 or org.blood < 4200 or org.o2[1] < 10) and 0.5) or 1
        -- keep corpse stiffness strong
        ragdoll.power = org.alive and power or 1



		local inmove = false
		
		if (org.lightstun < CurTime()) and (tracehuy.Hit or ply.FakeRagdoll ~= ragdoll) and org.spine1 < hg.organism.fake_spine1 and org.canmove and ((ply.lastFake and (ply.lastFake) > CurTime()) or ply.FakeRagdoll ~= ragdoll) then
			local power = 1
			inmove = true
			
			local ragbonecount = ragdoll:GetPhysicsObjectCount()
			for i = 0, ragbonecount - 1 do
				local bone = ragdoll:TranslatePhysBoneToBone(i)
				local bonepos, boneang = ply:GetBonePosition(bone)
				if bonepos and boneang then
					local physobj = ragdoll:GetPhysicsObjectNum(i)
					local mass = physobj:GetMass() / 5
					
					local name = ragdoll:GetBoneName(bone)

					if IsValid(physobj) then
						local bone_impulse = ply.HitBones and ply.HitBones[bonename] or CurTime()
						local amt_impulse = (2 - math.Clamp(bone_impulse - CurTime(),0,2)) / 2
						
						local p = {}
						p.secondstoarrive = 0.01
						p.pos = bonepos
						p.angle = boneang
						p.maxangular = 250 * (hg_ragdollcombat:GetBool() and 1 or 0.25) * mass * power * amt_impulse
						p.maxangulardamp = 100 * (hg_ragdollcombat:GetBool() and 1 or 0.75) * mass * power * amt_impulse
						p.maxspeed = 250 * (hg_ragdollcombat:GetBool() and 1 or 0.25) * mass * power * amt_impulse
						p.maxspeeddamp = 100 * (hg_ragdollcombat:GetBool() and 1 or 0.75) * mass * amt_impulse
						p.teleportdistance = 0

						physobj:Wake()
						physobj:ComputeShadowControl(p)
					end
				end
			end

			if ply.FakeRagdoll ~= ragdoll then continue end
		else
			hg.SetFreemove(ply,false)
			
			local pos = ragdoll:GetBoneMatrix(ragdoll:LookupBone("ValveBiped.Bip01_Head1")):GetTranslation()		
			if not ply:InVehicle() then
				ply:SetPos(pos)
			else
				ply:SetPos(ply:GetVehicle():GetPassengerSeatPoint(0))
				//local ent = ents.Create("prop_physics")
				//ent:SetModel("models/props_interiors/pot01a.mdl")
				//ent:SetPos(ply:GetPos())
				//ent:Spawn()
				//ent:SetMoveType(MOVETYPE_NONE)
				//ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			end
		end

		local angles = ply:EyeAngles()
		local att = ragdoll:GetAttachment(ragdoll:LookupAttachment("eyes"))
		ragdoll:SetFlexWeight(9, 0)
		local vecpos = angles:Forward() * 10000
		local dist = (angles:Forward() * 10000):Distance(vecpos)
		local distmod = math.Clamp(1 - (dist / 20000), 0.35, 1)
		local lookat = LerpVector(distmod, att.Ang:Forward() * 10000, vecpos)
		local LocalPos, LocalAng = WorldToLocal(lookat, angles, att.Pos, att.Ang)
		LocalAng[1] = math.Clamp(LocalAng[1], -30, 30)
		LocalAng[2] = math.Clamp(LocalAng[2], -30, 30)
		
		if ragdoll.organism and not ragdoll.organism.otrub then
			ragdoll.LastAng = LocalAng
		else
			LocalAng = ragdoll.LastAng or LocalAng
		end

		ragdoll:SetEyeTarget(LocalAng:Forward() * 10000)

		local model = ragdoll:GetModel()
		ang:Set(angles)

		if (!ply:InVehicle() && (ply:KeyDown(IN_USE) || (ishgweapon(wep) and ply:KeyDown(IN_ATTACK2)))) || (ply:InVehicle() && not ply:KeyDown(IN_USE)) then
			if org.canmove and (not ply:KeyDown(IN_MOVELEFT) and not ply:KeyDown(IN_MOVERIGHT) or ply:InVehicle()) then
				local angl = angZero
				angl:Set(ang)
				--angl:RotateAroundAxis(angl:Right(), -90)
				angl:RotateAroundAxis(angl:Forward(), 90)
				angl:RotateAroundAxis(angl:Up(), 90)
				angl:RotateAroundAxis(angl:Forward(), ishgweapon(wep) and not wep:IsPistolHoldType() and 120 or 180)
				angl:RotateAroundAxis(angl:Up(), -0)
				shadowControl(ragdoll, 1, 0.1, angl, 120, 20)
			end

			if org.canmovehead then
				--ang2 = Angle(-90,ang[2] - 90,0)
				local angl = angZero
				angl:Set(ang)
				angl:RotateAroundAxis(angl:Forward(), 90)
				angl:RotateAroundAxis(angl:Up(), 90)
				shadowControl(ragdoll, 10, 0.1, angl, 600, 20) --,Vector(0,0,0),1000,1000)
			end
		end

		spine = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,1))
		rhand = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,7))
		lhand = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,5))
		ang = spine:GetAngles()

		local angles2 = -(-angles)
		angles2:RotateAroundAxis(angles2:Right(),30)

		local forward = ply:KeyDown(IN_FORWARD)
		local back = ply:KeyDown(IN_BACK)
		time = CurTime()
		local rulesEnabled = hg_fake_hand_checks:GetBool()
		local mainPhys = ragdoll:GetPhysicsObject()
		local mainVelLen = IsValid(mainPhys) and mainPhys:GetVelocity():Length() or 0
		local pelvisObj = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll, 0))
		local pelvisPos = IsValid(pelvisObj) and pelvisObj:GetPos() or ragdoll:GetPos()
		local gtr = {}
		gtr.start = pelvisPos
		gtr.endpos = pelvisPos - vector_up * 2048
		gtr.filter = {ply,ragdoll}
		local gtrace = util.TraceLine(gtr)
		ragdoll.groundDist = gtrace.Hit and math.max(pelvisPos.z - gtrace.HitPos.z, 0) or 0
		
		local spineBroken = (org.spine1 >= hg.organism.fake_spine1) or (org.spine2 >= hg.organism.fake_spine2) or (org.spine3 >= hg.organism.fake_spine3)
		local canHold = (org.canmove or IsValid(ply.FakeRagdoll)) and not spineBroken and not org.paralyzed
		local hasReaction = (ply.fakecd and (ply.fakecd + 4) > CurTime()) or (org.woundReactionTime and org.woundReactionTime > CurTime())
		local shouldHoldWounds = ply.organism and ply.organism.wounds and not table.IsEmpty(ply.organism.wounds) and canHold and hasReaction
		
		if shouldHoldWounds then
			local tr = {}
			tr.start = ragdoll:GetPos()
			tr.endpos = ragdoll:GetPos() - vector_up * 60
			tr.filter = {ply,ragdoll}
			local tracehuy = util.TraceLine(tr)

			if tracehuy.Hit then
				local wounds = ply.organism.wounds
				-- Find the most severe wound for more realistic reactions
				local mostSevereWound = wounds[1] -- wounds are sorted by severity
				if mostSevereWound then
					-- use bone pos/ang for proper transform
					local bonePos, boneAng = ragdoll:GetBonePosition(mostSevereWound[4])
					local pos, ang
					if bonePos and boneAng then
						pos, ang = LocalToWorld(mostSevereWound[2], mostSevereWound[3], bonePos, boneAng)
					end
					
					-- Enhanced wound holding with pain-based intensity
					local painIntensity = math.Clamp(org.pain / 50, 0.5, 2) -- Scale based on pain level
					local woundSeverity = math.Clamp(mostSevereWound[1] / 20, 0.5, 1.5) -- Scale based on wound severity
					local holdForce = 80 * painIntensity * woundSeverity
					local holdDamping = 60 * painIntensity
					
					-- Both hands try to reach the wound, with slight variation for realism
					if pos then -- skip if bone invalid
						if not ply:KeyDown(IN_ATTACK) then
							local leftOffset = pos - (pos - lhand:GetPos()):GetNormalized() * (2 + math.sin(CurTime() * 2) * 0.5)
							shadowControl(ragdoll, 5, 0.001, nil, nil, nil, leftOffset, holdForce, holdDamping)
						end

						if not ply:KeyDown(IN_ATTACK2) then
							local rightOffset = pos - (pos - rhand:GetPos()):GetNormalized() * (2 + math.cos(CurTime() * 1.8) * 0.5)
							shadowControl(ragdoll, 7, 0.001, nil, nil, nil, rightOffset, holdForce, holdDamping)
						end
					end

					-- Body positioning for pain reaction
					if not ply:KeyDown(IN_USE) and not hasActivePosturing then
						local bodyTension = 15 * painIntensity
						-- Skip head control if neck is broken
						if not ragdoll.brokenNeck then
							shadowControl(ragdoll, 10, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,8)):GetPos(), bodyTension, 10)
						end
						shadowControl(ragdoll, 1, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,8)):GetPos(), bodyTension, 10)
						shadowControl(ragdoll, 2, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,8)):GetPos(), bodyTension * 1.5, 10)
						shadowControl(ragdoll, 3, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,8)):GetPos(), bodyTension * 1.5, 10)
						shadowControl(ragdoll, 11, 0.001, nil, nil, nil, spine:GetPos() + spine:GetAngles():Forward() * 50, bodyTension, 10)
						shadowControl(ragdoll, 8, 0.001, nil, nil, nil, spine:GetPos() + spine:GetAngles():Forward() * 50, bodyTension, 10)
					end
				end
			end
		end
		
		if not wep.RagdollFunc then
			local force = math.max(1 - org.larm / 1.3, 0)
			if (ply:KeyDown(IN_ATTACK) and !ishgweapon(wep)) or (ishgweapon(wep) and (not hasActivePosturing and ply:KeyDown(IN_USE) or ply:KeyDown(IN_ATTACK2))) then// || ply:InVehicle() then
				if org.canmove then
					//if !ply:InVehicle() then
						ang2:Set(angles)
						local lower = (ishgweapon(wep) and (not hasActivePosturing and ply:KeyDown(IN_USE) or ply:KeyDown(IN_ATTACK2)))
						ang2:RotateAroundAxis(angles:Right(), lower and -20 or 0)
						ang2:RotateAroundAxis(angles:Up(), lower and 20 or 10)
						ang2:RotateAroundAxis(angles:Forward(), -45)
						

						shadowControl(ragdoll, 3, 0.002, ang2, forceArm * force, forceArm_dump)
						shadowControl(ragdoll, 4, 0.002, ang2, forceArm * force, forceArm_dump)
						ang2:RotateAroundAxis(ang2:Forward(), 135)
						ang2:RotateAroundAxis(ang2:Up(), 20)
						shadowControl(ragdoll, 5, 0.001, ang2, forceArm * 2, forceArm_dump, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,5)):GetPos() + ang2:Forward() * 15 + ((ragdoll:GetPhysicsObject():GetVelocity():Length() > 150 and ragdoll:GetPhysicsObject():GetVelocity() / 224) or vector_zero), 500, 50)
						if ply:WaterLevel() == 1 then shadowControl(ragdoll, 1, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,5)):GetPos(), forceArmWater, forceArmWater_dump) end
					/*else
						ang2:Set(angles)
						ang2:RotateAroundAxis(angles:Up(), 0)
						ang2:RotateAroundAxis(angles:Right(), 0)
						ang2:RotateAroundAxis(angles:Forward(), -0)
						shadowControl(ragdoll, 5, 0.001, ang2, forceArm * 2, forceArm_dump * 2, ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_L_Hand")):GetTranslation() + ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_R_Hand")):GetAngles():Up() * 4 + ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_R_Hand")):GetAngles():Forward() * -3 + ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_R_Hand")):GetAngles():Right() * 5 + ragdoll:GetVelocity() / 20, 5550, 1550)
					end*/
				end
			end

			if forward and IsValid(ragdoll.ConsLH) and ragdoll.ConsLH.Ent2:GetVelocity():LengthSqr() < 200 then shadowControl(ragdoll, 1, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,5)):GetPos(), forceArmForward * math.max(force, 0.8) * (IsValid(ragdoll.ConsRH) and 1 or 1), forceArmForward_dump) end
			if back and IsValid(ragdoll.ConsLH) and ragdoll.ConsLH.Ent2:GetVelocity():LengthSqr() < 200 then shadowControl(ragdoll, 1, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,0)):GetPos(), forceArmForward * math.max(force, 0.8) * (IsValid(ragdoll.ConsRH) and 1 or 1), forceArmForward_dump) end

			local force = math.max(1 - org.rarm / 1.3, 0)

			if ply:KeyDown(IN_ATTACK2) or (ishgweapon(wep) and not hasActivePosturing and ply:KeyDown(IN_USE)) then// || ply:InVehicle() then
				if org.canmove then
					--if org.shock > 1 and not ply:KeyDown(IN_ATTACK2) then angles = spine:GetAngles() end
					//if !ply:InVehicle() then
						ang2:Set(angles)
						ang2:RotateAroundAxis(angles:Up(), ishgweapon(wep) and -10 or 0)
						ang2:RotateAroundAxis(angles:Right(), ishgweapon(wep) and 10 or 0)
						ang2:RotateAroundAxis(angles:Forward(), -90)

						//if !ishgweapon(wep) then
							shadowControl(ragdoll, 2, 0.001, ang2, forceArm * force, forceArm_dump)
							shadowControl(ragdoll, 6, 0.001, ang2, forceArm * force, forceArm_dump)
						//end

						ang2:RotateAroundAxis(ang2:Forward(), 135)
						ang2:RotateAroundAxis(ang2:Up(), ishgweapon(wep) and 1 or 20)
						ang2:RotateAroundAxis(ang2:Forward(), ishgweapon(wep) and 120 or 0)
						shadowControl(ragdoll, 7, 0.001, ang2, forceArm * 2, forceArm_dump, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,7)):GetPos() + ang2:Forward() * 15 + ((ragdoll:GetPhysicsObject():GetVelocity():Length() > 150 and ragdoll:GetPhysicsObject():GetVelocity() / 224) or vector_zero), ishgweapon(wep) and 500 or 500, ishgweapon(wep) and 50 or 50)
						if ply:WaterLevel() == 1 then shadowControl(ragdoll, 1, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(7):GetPos(), forceArmWater, forceArmWater_dump) end
					/*else
						ang2:Set(angles)
						ang2:RotateAroundAxis(angles:Up(), 0)
						ang2:RotateAroundAxis(angles:Right(), 0)
						ang2:RotateAroundAxis(angles:Forward(), 180)
						shadowControl(ragdoll, 7, 0.001, ang2, forceArm * 2, forceArm_dump * 2, ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_R_Hand")):GetTranslation() + ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_R_Hand")):GetAngles():Up() * 5 + ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_R_Hand")):GetAngles():Forward() * -1 + ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_R_Hand")):GetAngles():Right() * 2 + ragdoll:GetVelocity() / 20, 5550, 1550)
					end*/
				end
			end
			
			if forward and IsValid(ragdoll.ConsRH) and ragdoll.ConsRH.Ent2:GetVelocity():LengthSqr() < 200 then shadowControl(ragdoll, 1, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,7)):GetPos(), forceArmForward * math.max(force, 0.8) * (IsValid(ragdoll.ConsLH) and 1 or 1), forceArmForward_dump) end
			if back and IsValid(ragdoll.ConsRH) and ragdoll.ConsRH.Ent2:GetVelocity():LengthSqr() < 200 then shadowControl(ragdoll, 1, 0.001, nil, nil, nil, ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,0)):GetPos(), forceArmForward * math.max(force, 0.8) * (IsValid(ragdoll.ConsLH) and 1 or 1), forceArmForward_dump) end

			local choking = (IsValid(ragdoll.ConsRH) and IsValid(ragdoll.ConsRH.choking) and ragdoll.ConsRH.choking) or (IsValid(ragdoll.ConsLH) and IsValid(ragdoll.ConsLH.choking) and ragdoll.ConsLH.choking)
			local chokinghead = false

			if ply:KeyDown(IN_SPEED) and ply:KeyDown(IN_WALK) then
				local trace
				tr.start = lhand:GetPos() + lhand:GetAngles():Forward() * 5
				tr.endpos = rhand:GetPos() + lhand:GetAngles():Forward() * 5
				tr.filter = ragdoll
				trace = util_TraceLine(tr)
	
				ent = trace.Entity
				
				--if IsValid(ent) and ent:IsRagdoll() and trace.PhysicsBone == realPhysNum(ent, 10) then -- Отрубил чтобы ошибок не было пока...
				--	choking = ent
				--	local head = ent:GetPhysicsObjectNum(realPhysNum(ent, 10))
				--	chokinghead = head
--
				--	if IsValid(ragdoll.ConsRH) and not IsValid(ragdoll.ConsRH.choking) then
				--		rhand:SetPos(head:GetPos())
				--		ragdoll.cooldownLH = nil
				--		ragdoll.ConsRH:Remove()
				--		ragdoll.ConsRH = nil
				--	end
	--
				--	if IsValid(ragdoll.ConsLH) and not IsValid(ragdoll.ConsLH.choking) then
				--		lhand:SetPos(head:GetPos())
				--		ragdoll.cooldownRH = nil
				--		ragdoll.ConsLH:Remove()
				--		ragdoll.ConsLH = nil
				--	end
				--end
			end

			if ply:KeyDown(IN_SPEED) and org.canmove then
				--and org.shock < fakeshockFall
				phys = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll, 5))
				if (ragdoll.cooldownLH or 0) < time and not IsValid(ragdoll.ConsLH) then
					
					local trace
					for i = 1,3 do
						if trace and trace.Hit and not trace.HitSky then continue end
						tr.start = phys:GetPos()
						tr.endpos = phys:GetPos() + phys:GetAngles():Right() * 6 + phys:GetAngles():Up() * (i - 2) * 3
						tr.filter = ragdoll
						trace = util_TraceLine(tr)
					end
					
					if IsValid(choking) or (trace.Hit and not trace.HitSky) then
						ent = IsValid(choking) and choking or trace.Entity

						if IsValid(choking) then
							lhand:SetPos(chokinghead:GetPos())
						end

						local cons
						if not (rulesEnabled and mainVelLen > 250) then
							cons = constraint.Weld(ragdoll, ent, realPhysNum(ragdoll, 5), IsValid(choking) and realPhysNum(choking, 10) or trace.PhysicsBone, 0, false, false)
						end
						if IsValid(cons) then
							ragdoll.cooldownLH = time + 0.5
							ragdoll.ConsLH = cons
							ragdoll.LHHoldStart = time
							cons.choking = choking
							ragdoll:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 50, math.random(95, 105))
							for i = 1, 4 do
								if not ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1") then continue end
								ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1"), Angle(0, -45, 0))
							end
							--pedor ny norm
						end

						local useent = ent.Use and ent or false 
						if useent and not useent:IsVehicle() then useent:Use(ply) end
						--DA NORM SAM PEDOR!!!!
						local wep = ent:IsWeapon() and ent or false
						ply.force_pickup = true
						if IsValid(wep) and hook.Run("PlayerCanPickupWeapon", ply, wep) then ply:PickupWeapon(wep) end
						ply.force_pickup = nil
					end
				end
			else
				if IsValid(ragdoll.ConsLH) then
					ragdoll.ConsLH:Remove()
					ragdoll.ConsLH = nil
					ragdoll.LHHoldStart = nil
					for i = 1, 4 do
						if not ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1") then continue end
						ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1"), Angle(0, 0, 0))
					end
				end
			end

			if ply:KeyDown(IN_WALK) and org.canmove and !ishgweapon(wep) then
				--and org.shock < fakeshockFall
				phys = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll, 7))
				if (ragdoll.cooldownRH or 0) < time and not IsValid(ragdoll.ConsRH) then
					
					local trace
					for i = 1,3 do
						if trace and trace.Hit and not trace.HitSky then continue end
						tr.start = phys:GetPos()
						tr.endpos = phys:GetPos() + phys:GetAngles():Right() * 6 + phys:GetAngles():Up() * (i - 2) * 3
						tr.filter = ragdoll
						trace = util_TraceLine(tr)
					end
					
					if IsValid(choking) or (trace.Hit and not trace.HitSky) then
						ent = trace.Entity

						if IsValid(choking) then
							rhand:SetPos(chokinghead:GetPos())
						end
						
						local cons
						if not (rulesEnabled and mainVelLen > 250) then
							cons = constraint.Weld(ragdoll, ent, realPhysNum(ragdoll, 7), IsValid(choking) and realPhysNum(choking, 10) or trace.PhysicsBone, 0, false, false)
						end
						if IsValid(cons) then
							ragdoll.cooldownRH = time + 0.5
							ragdoll.ConsRH = cons
							ragdoll.RHHoldStart = time
							cons.choking = choking
							ragdoll:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 55, math.random(95, 105))
							for i = 1, 4 do
								if not ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1") then continue end
								ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1"), Angle(0, -45, 0))
							end
						end

						local useent = ent.Use and ent or false 
						if useent and not useent:IsVehicle() then useent:Use(ply) end

						local wep = ent:IsWeapon() and ent or false
						ply.force_pickup = true
						if IsValid(wep) and hook.Run("PlayerCanPickupWeapon", ply, wep) then ply:PickupWeapon(wep) end
						ply.force_pickup = nil
					end
				end
			else
				if IsValid(ragdoll.ConsRH) then
					ragdoll.ConsRH:Remove()
					ragdoll.ConsRH = nil
					ragdoll.RHHoldStart = nil
					for i = 1, 4 do
						if not ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1") then continue end
						ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1"), Angle(0, 0, 0))
					end
				end
			end
		else
			if ply:KeyDown(IN_ATTACK2) and org.canmove then
				if wep.RagdollFunc then
					wep:RagdollFunc(ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll,7)):GetPos() + angles:Forward() * 15 + ((ragdoll:GetPhysicsObject():GetVelocity():Length() > 150 and ragdoll:GetPhysicsObject():GetVelocity() / 224) or vector_zero), angles, ragdoll)
				end
			end
		end

		-- Zavtra yje
		if IsValid(ragdoll.ConsLH) and IsValid(ragdoll.ConsRH) and IsValid(ragdoll.ConsLH.choking) and ragdoll.ConsLH.choking == ragdoll.ConsRH.choking then
			local choking1 = ragdoll.ConsLH.choking	
			local head = choking1:GetPhysicsObjectNum(realPhysNum(choking1, 10))
			lhand:SetPos(head:GetPos())
			rhand:SetPos(head:GetPos())

			--print("huy")
		end

		-- Stamina loss for climbing/crawling while holding onto objects
		local isMoving = (ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)) and not inmove and not ply:InVehicle()
		local hasLeftHand = IsValid(ragdoll.ConsLH)
		local hasRightHand = IsValid(ragdoll.ConsRH)
		local hasBothHands = hasLeftHand and hasRightHand
		
		-- Initialize stamina loss cooldown if not exists
		ragdoll.staminaLossCooldown = ragdoll.staminaLossCooldown or 0
		
		if isMoving and (hasLeftHand or hasRightHand) and org.canmove and ragdoll.staminaLossCooldown < time then
			local staminaLoss = 0
			
			if hasBothHands then
				staminaLoss = 8 -- Both hands holding while moving
			elseif hasLeftHand or hasRightHand then
				staminaLoss = 4 -- One hand holding while moving
			end
			
			if staminaLoss > 0 and org.stamina and org.stamina[1] then
				org.stamina[1] = math.max(org.stamina[1] - staminaLoss, 0)
				ragdoll.staminaLossCooldown = time + 0.25 -- Cooldown to prevent spam (4 times per second max)
			end
		end

		if rulesEnabled then
			if IsValid(ragdoll.ConsLH) then
				if mainVelLen > 250 then
					ragdoll.ConsLH:Remove()
					ragdoll.ConsLH = nil
					ragdoll.LHHoldStart = nil
					for i = 1, 4 do
						if not ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1") then continue end
						ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1"), Angle(0, 0, 0))
					end
				else
                    if ragdoll.groundDist and ragdoll.groundDist > 5 then
                        ragdoll.LHHoldStart = ragdoll.LHHoldStart or time
                        if (time - ragdoll.LHHoldStart) > 7 then
                            ragdoll.ConsLH:Remove()
                            ragdoll.ConsLH = nil
                            ragdoll.LHHoldStart = nil
                            for i = 1, 4 do
                                if not ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1") then continue end
                                ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1"), Angle(0, 0, 0))
                            end
                        end
                    else
                        ragdoll.LHHoldStart = nil
                    end
				end
			end

			if IsValid(ragdoll.ConsRH) then
				if mainVelLen > 250 then
					ragdoll.ConsRH:Remove()
					ragdoll.ConsRH = nil
					ragdoll.RHHoldStart = nil
					for i = 1, 4 do
						if not ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1") then continue end
						ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1"), Angle(0, 0, 0))
					end
				else
                    if ragdoll.groundDist and ragdoll.groundDist > 5 then
                        ragdoll.RHHoldStart = ragdoll.RHHoldStart or time
                        if (time - ragdoll.RHHoldStart) > 7 then
                            ragdoll.ConsRH:Remove()
                            ragdoll.ConsRH = nil
                            ragdoll.RHHoldStart = nil
                            for i = 1, 4 do
                                if not ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1") then continue end
                                ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1"), Angle(0, 0, 0))
                            end
                        end
                    else
                        ragdoll.RHHoldStart = nil
                    end
				end
			end
		end

		-- почему в последней версии жопкика брисорма нету вібивания дверей 
		if ragdoll.dropkick or ragdoll.isSliding then
			local feet = {realPhysNum(ragdoll, 13), realPhysNum(ragdoll, 14)}
			for _, foot in ipairs(feet) do
				local phys = ragdoll:GetPhysicsObjectNum(foot)
				if IsValid(phys) then
					local pos = phys:GetPos()
					local dir = ragdoll:GetVelocity():GetNormalized()
					local tr = util.TraceLine({
						start = pos,
						endpos = pos + dir * 50,
						filter = ragdoll
					})
					if tr.Hit then
						local ent = tr.Entity
						if ent:GetClass() == "func_breakable_surf" then
							ent:Fire("Break")
						elseif hgIsDoor(ent) then
							hgBlastThatDoor(ent, ragdoll:GetVelocity() * 0.4)
						end
					end
				end
			end
		end		

		if ply:KeyDown(IN_MOVELEFT) and not inmove and !ply:InVehicle() then
			if org.canmove then
				local angle = spine:GetAngles()
				angle[3] = angle[3] - 20 * (ragdoll:IsOnFire() and 1.5 or 1)
				--ragdoll, physNumber, ss, ang, maxang, maxangdamp, pos, maxspeed, maxspeeddamp
				shadowControl(ragdoll, 1, 0.001, angle, 490, 1000)
				if math.random(100) == 1 and ragdoll:IsOnFire() then
					local key, fire = next(ragdoll.fires)
					
					if key then 
						ragdoll.fires[key] = nil

						if IsValid(key) then
							key:Remove()
						end
					end
				end
			end
		end

		if ply:KeyDown(IN_MOVERIGHT) and not inmove and !ply:InVehicle() then
			if org.canmove and not org.otrub then
				local angle = spine:GetAngles()
				angle[3] = angle[3] + 20 * (ragdoll:IsOnFire() and 1.5 or 1)
				shadowControl(ragdoll, 1, 0.001, angle, 490, 90)
				if math.random(100) == 1 and ragdoll:IsOnFire() then
					local key, fire = next(ragdoll.fires)
					
					if key then 
						ragdoll.fires[key] = nil

						if IsValid(key) then
							key:Remove()
						end
					end
				end
			end
		end

        -- підкат
        if ragdoll.isSliding and ply:KeyDown(IN_DUCK) and not inmove and org.canmove and ply.FakeRagdoll == ragdoll then
        
			local angles = ply:EyeAngles()
			local lthigh = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll, 11))
			local rthigh = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll, 8))

			    if lthigh and rthigh then

			    	local legAng1 = Angle(0, 0, 0)
			    	local legAng2 = Angle(0, 0, 0)
			    	local pelvisAng = Angle(0, 0, 0)
			    	local spinaept = Angle(0, 0, 0) 

			    	--сочные бедра
					legAng1:Set(angles)

					legAng1:RotateAroundAxis(angles:Right(), 90)
					legAng1:RotateAroundAxis(angles:Forward(), -90)
					legAng1:RotateAroundAxis(angles:Up(), -80)

					legAng2:Set(angles)

					legAng2:RotateAroundAxis(angles:Right(), 85)
					legAng2:RotateAroundAxis(angles:Forward(), -90)
					legAng2:RotateAroundAxis(angles:Up(), -80)

					spinaept:Set(angles)

					spinaept:RotateAroundAxis(angles:Right(), 120) -- сука ну это пиздец как я заебался нормальную позицию делать, легче себе мозги вынести из 12 калибра лишь ради того чтобы никогда не заходить в код sv_control
					spinaept:RotateAroundAxis(angles:Forward(), 45)
					spinaept:RotateAroundAxis(angles:Up(), -65)

					shadowControl(ragdoll, 1, 0.001, spinaept, 100, 90)
					shadowControl(ragdoll, 11, 0.001, legAng1, 200, 10)
					shadowControl(ragdoll, 8, 0.001, legAng2, 200, 10)
					shadowControl(ragdoll, 0, 0.001, pelvisAng, 200, 10)

--изи катка
local boost = 570
if ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2) then boost = 250 end
if IsValid(wep) and wep:GetClass() != "weapon_hands_sh" then boost = 250 end

local phys = ragdoll:GetPhysicsObject()
if IsValid(phys) then
    local dir = ragdoll.slideDir

    -- если slideDir не Vector — пересчитаем
    if not isvector(dir) then
        dir = phys:GetVelocity()
        if dir:LengthSqr() < 1 then
            dir = ply:EyeAngles():Forward()
        end
        dir:Normalize()
        ragdoll.slideDir = dir
    end

    phys:ApplyForceCenter(dir * boost)
end


			if ragdoll:GetPhysicsObject():GetVelocity():Length() < 120 or CurTime() - ragdoll.slideStart > 3.5 then
				ragdoll.isSliding = false
				ragdoll.dropkick = true
			end
		end

		if not inmove and org.canmove and ply.FakeRagdoll == ragdoll then 
			if ply:KeyDown(IN_DUCK) then					
				local lthigh = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll, 11))
				local rthigh = ragdoll:GetPhysicsObjectNum(realPhysNum(ragdoll, 8))

				if lthigh and rthigh then

					local legAng1 = Angle(0, 0, 0)
					local legAng2 = Angle(0, 0, 0)
					local spinaept = Angle(0, 0, 0) -- спина хуево работает, а pelvis не дает ноге вперед перекинуться, оставлю углы но передвижение уберу нахуй (я это написал для владика или других кто в код полезет)

					--сочные бедра
					legAng1:Set(angles)

					legAng1:RotateAroundAxis(angles:Right(), 80)
					legAng1:RotateAroundAxis(angles:Forward(), -40)
					legAng1:RotateAroundAxis(angles:Up(), -70)

					legAng2:Set(angles)

					legAng2:RotateAroundAxis(angles:Right(), 65)
					legAng2:RotateAroundAxis(angles:Forward(), -40)
					legAng2:RotateAroundAxis(angles:Up(), -70)

					--spine228 или pelvis upd:оказалось хуйнёй
					spinaept:Set(angles)

					spinaept:RotateAroundAxis(angles:Right(), 0)
					spinaept:RotateAroundAxis(angles:Forward(), 0)
					spinaept:RotateAroundAxis(angles:Up(), 0)

					--shadowControl(ragdoll, 1, 0.001, spinaept, 1000, 200)

					shadowControl(ragdoll, 11, 0.001, legAng1, 200, 10)
					shadowControl(ragdoll, 8, 0.001, legAng2, 200, 10)


					local calfAng1 = Angle(0, 0, 0)
					local calfAng2 = Angle(0, 0, 0)

					--нажки (удалили ступни чтобы не выглядело херово и топорно)
					calfAng1:Set(legAng1)

					calfAng1:RotateAroundAxis(angles:Right(), -90)
					calfAng1:RotateAroundAxis(angles:Forward(), 0)
					calfAng1:RotateAroundAxis(angles:Up(), 0)

					calfAng2:Set(legAng2)

					calfAng2:RotateAroundAxis(angles:Right(), -90)
					calfAng2:RotateAroundAxis(angles:Forward(), 0)
					calfAng2:RotateAroundAxis(angles:Up(), 0)

					shadowControl(ragdoll, 12, 0.001, calfAng1, 250, 20)
					shadowControl(ragdoll, 9, 0.001, calfAng2, 250, 20)

					if ply:KeyDown(IN_JUMP) then-- свинопас

						legAng1:Set(angles)

						legAng1:RotateAroundAxis(angles:Right(), 75)
						legAng1:RotateAroundAxis(angles:Forward(), -100)
						legAng1:RotateAroundAxis(angles:Up(), -70)

						legAng2:Set(angles)

						legAng2:RotateAroundAxis(angles:Right(), 75)
						legAng2:RotateAroundAxis(angles:Forward(), -100)
						legAng2:RotateAroundAxis(angles:Up(), -70)

						calfAng1:Set(legAng1)

						calfAng1:RotateAroundAxis(angles:Right(), 20)
						calfAng1:RotateAroundAxis(angles:Forward(), 0)
						calfAng1:RotateAroundAxis(angles:Up(), 0)

						calfAng2:Set(legAng2)

						calfAng2:RotateAroundAxis(angles:Right(), 20)
						calfAng2:RotateAroundAxis(angles:Forward(), 0)
						calfAng2:RotateAroundAxis(angles:Up(), 0)

						local foot1 = Angle(0, 0, 0)
						local foot2 = Angle(0, 0, 0)

						foot1:Set(calfAng1)

						foot1:RotateAroundAxis(angles:Right(), 90)
						foot1:RotateAroundAxis(angles:Forward(), 0)
						foot1:RotateAroundAxis(angles:Up(), 0)

						foot2:Set(calfAng2)

						foot2:RotateAroundAxis(angles:Right(), 90)
						foot2:RotateAroundAxis(angles:Forward(), 0)
						foot2:RotateAroundAxis(angles:Up(), 0)

						shadowControl(ragdoll, 11, 0.001, legAng1, 250, 10)
						shadowControl(ragdoll, 8, 0.001, legAng2, 250, 10)

						shadowControl(ragdoll, 13, 0.001, foot1, 200, 10)
						shadowControl(ragdoll, 14, 0.001, foot2, 200, 10)

						shadowControl(ragdoll, 12, 0.001, calfAng1, 200, 10)
						shadowControl(ragdoll, 9, 0.001, calfAng2, 200, 10)

					end
				 --******* Э-upd(11.25):как он заблюрился блять, я ничего не делал, по верхнему комментам можно понятьЭ, я не думаю что код на тот подкат подойдет, как только будет время сделай сюды новый, я углы поменяю потом и сделаю дропкик upd: мне лень, идите нахуй
				 -- удачи твины✌️ 
				 -- не хател называть пидорасами, обобщал всех людей из тт. сорре всех лублу
				end
			end
		end



	end
end)

hook.Add("PlayerDeath", "homigrad-fake-control", function(ply)
	local ragdoll = ply.FakeRagdoll
	if not IsValid(ragdoll) then return end
	if IsValid(ragdoll.ConsLH) then
		ragdoll.ConsLH:Remove()
		ragdoll.ConsLH = nil
		for i = 1, 4 do
			ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_L_Finger" .. tostring(i) .. "1"), Angle(0, 0, 0))
		end
	end

	if IsValid(ragdoll.ConsRH) then
		ragdoll.ConsRH:Remove()
		ragdoll.ConsRH = nil
		for i = 1, 4 do
			ragdoll:ManipulateBoneAngles(ragdoll:LookupBone("ValveBiped.Bip01_R_Finger" .. tostring(i) .. "1"), Angle(0, 0, 0))
		end
	end
end)
