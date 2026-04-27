local PLAYER = FindMetaTable("Player")
if not HookGetRagdollEntity then HookGetRagdollEntity = PLAYER.GetRagdollEntity end
function PLAYER:GetRagdollEntity()
	local ent = self:GetNWEntity("RagdollDeath")
	return IsValid(ent) and ent or HookGetRagdollEntity(self)
end

function PLAYER:CreateRagdoll()
	return false
end

local hook_Run = hook.Run
hook.Add("OnEntityCreated", "bull_add", function(npc)
	timer.Simple(0, function()
		if IsValid(npc) then
			if npc:IsNPC() or string.Explode( "_" , npc:GetClass() ) == "terminator" then
				for i, ent in pairs(ents.FindByClass("npc_bullseye")) do
					if IsValid(ent) and IsValid(ent.ply) then npc:AddEntityRelationship(ent, npc:Disposition(ent.ply)) end
				end
			end
		end
	end)
end)
local vecZero = Vector(0,0,0)

--[[

ValveBiped.Bip01_Pelvis 12.775918006897
ValveBiped.Bip01_Spine2 24.36336517334
ValveBiped.Bip01_R_UpperArm     3.4941370487213
ValveBiped.Bip01_L_UpperArm     3.441034078598
ValveBiped.Bip01_L_Forearm      1.7655730247498
ValveBiped.Bip01_L_Hand 1.0779889822006
ValveBiped.Bip01_R_Forearm      1.7567429542542
ValveBiped.Bip01_R_Hand 1.0214320421219
ValveBiped.Bip01_R_Thigh        10.212161064148
ValveBiped.Bip01_R_Calf 4.9580898284912
ValveBiped.Bip01_Head1  5.169750213623
ValveBiped.Bip01_L_Thigh        10.213202476501
ValveBiped.Bip01_L_Calf 4.9809679985046
ValveBiped.Bip01_L_Foot 2.3848159313202
ValveBiped.Bip01_R_Foot 2.3848159313202

12.775918006897 0
24.36336517334  3
3.4941370487213 9
3.441034078598  14
1.7655730247498 15
1.0779889822006 16
1.7567429542542 10
1.0214320421219 11
10.212161064148 18
4.9580898284912 19
5.169750213623  6
10.213202476501 22
4.9809679985046 23
2.3848159313202 24
2.3848159313202 20
]]--

hg.cachedmodels = {}

local function cacheModel(ragdoll)
	local model = ragdoll:GetModel()
		
	if not hg.cachedmodels[model] then
		local tbl = {}
		hg.cachedmodels[model] = {}
		for i = 0,ragdoll:GetPhysicsObjectCount()-1 do
			tbl[i] = ragdoll:GetBoneName(ragdoll:TranslatePhysBoneToBone(i))
		end

		for i, bone in pairs(tbl) do
			hg.cachedmodels[model][bone] = i
		end
	end
end

hg.cacheModel = cacheModel

local IdealMassPlayer = {
	["ValveBiped.Bip01_Pelvis"] = 12.775918006897,
	["ValveBiped.Bip01_Spine1"] = 24.36336517334,
	["ValveBiped.Bip01_Spine2"] = 24.36336517334,
	["ValveBiped.Bip01_R_Clavicle"] = 3.4941370487213,
	["ValveBiped.Bip01_L_Clavicle"] = 3.4941370487213,
	["ValveBiped.Bip01_R_UpperArm"] = 3.4941370487213,
	["ValveBiped.Bip01_L_UpperArm"] = 3.441034078598,
	["ValveBiped.Bip01_L_Forearm"] = 1.7655730247498,
	["ValveBiped.Bip01_L_Hand"] = 1.0779889822006,
	["ValveBiped.Bip01_R_Forearm"] = 1.7567429542542,
	["ValveBiped.Bip01_R_Hand"] = 1.0214320421219,
	["ValveBiped.Bip01_R_Thigh"] = 10.212161064148,
	["ValveBiped.Bip01_R_Calf"] = 4.9580898284912,
	["ValveBiped.Bip01_Head1"] = 5.169750213623,
	["ValveBiped.Bip01_L_Thigh"] = 10.213202476501,
	["ValveBiped.Bip01_L_Calf"] = 4.9809679985046,
	["ValveBiped.Bip01_L_Foot"] = 2.3848159313202,
	["ValveBiped.Bip01_R_Foot"] = 2.3848159313202
}

local fixbones = {
	["ValveBiped.Bip01_Pelvis"] = true,
	["ValveBiped.Bip01_L_Thigh"] = true,
	["ValveBiped.Bip01_R_Thigh"] = true,
	["ValveBiped.Bip01_R_Calf"] = true,
	["ValveBiped.Bip01_L_Calf"] = true,
	//["ValveBiped.Bip01_L_Hand"] = true,
}

function hg.Ragdoll_Create(ply)
	local Data = duplicator.CopyEntTable( ply )
	local ragdoll = ents.Create("prop_ragdoll")
	duplicator.DoGeneric( ragdoll, Data )

	ragdoll:SetPos(ply:GetPos())
	ragdoll:SetAngles(ply:GetAngles())
	--ragdoll:SetVelocity(ply:GetVelocity())
	ragdoll:SetModel(ply:GetModel())
	ragdoll.CurAppearance = table.Copy(ply.CurAppearance)

	local bodygroups = ply:GetBodyGroups()
	ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	ragdoll:Spawn()
	ragdoll:Activate()
	ragdoll:AddEFlags(EFL_NO_DAMAGE_FORCES)
	ragdoll:AddFlags(FL_NOTARGET)
	ply:AddFlags(FL_NOTARGET)

	hg.queue_ragdolls[ragdoll] = {}

	if IsValid(ply.bull) then ply.bull:Remove() ply.bull = nil end
	ragdoll.bull = ents.Create("npc_bullseye")
	local bull = ragdoll.bull
	bull.ply = ply
	bull.rag = ragdoll
	local eyeatt = ragdoll:GetAttachment(ragdoll:LookupAttachment("eyes"))
	local bodyphy = ragdoll:GetPhysicsObjectNum(10)
	if !bodyphy then return end
	bull:SetPos(bodyphy:GetPos()+bodyphy:GetAngles():Right()*7)
	--bull:SetPos( eyeatt.Pos + eyeatt.Ang:Up() * 3.5 )
	bull:SetAngles( ragdoll:GetAngles() )
	bull:SetMoveType(MOVETYPE_OBSERVER)
	--bull:SetCollisionGroup(COLLISION_GROUP_BREAKABLE_GLASS)
	bull:SetKeyValue( "targetname", "Bullseye" )
	--bull:SetParent(ragdoll, ragdoll:LookupAttachment("eyes"))
	bull:SetKeyValue( "health","9999" )
	bull:SetKeyValue( "spawnflags","256" )
	bull:Spawn()
	bull:Activate()
	bull:SetNotSolid(true)
	
	--bull:SetCollisionBoundsWS(-Vector(5,5,5),Vector(5,5,5))
	--bull:SetSurroundingBounds(-Vector(50,50,50),Vector(50,50,50))
	--[[local enta = ents.Create("prop_dynamic")
	enta:SetPos(bull:GetPos())
	enta:SetAngles(bull:GetAngles())
	enta:SetModel("models/props_junk/metal_paintcan001a.mdl")
	enta:SetParent(bull)
	enta:Spawn()
	enta:SetNotSolid(true)
	bull:CallOnRemove("asdsad",function() enta:Remove() end)--]]
	
	for i, ent in ipairs(ents.FindByClass("npc_*")) do
		if not IsValid(ent) or not ent.AddEntityRelationship then continue end
		ent:AddEntityRelationship(bull, ent:Disposition(ply))
	end


	for i, ent in ipairs(ents.FindByClass("terminator_*")) do
		if not IsValid(ent) or not ent.AddEntityRelationship then continue end
		ent:AddEntityRelationship(bull, ent:Disposition(ply))
	end

	ragdoll:CallOnRemove("removeBull", function()
		hg.queue_ragdolls[ragdoll] = nil

		if IsValid(ragdoll.bull) then
			ragdoll.bull:Remove()
		end
	end)
	ragdoll:AddCallback("PhysicsCollide", function(outEnt, data) hook_Run("Ragdoll Collide", ragdoll, data) end)
	local velocity = ply:GetVelocity()
	--local phys = ragdoll:GetPhysicsObject()
	--if IsValid(phys) then --phys:SetMass(20)
	--end
	
	--[[local phys = ragdoll:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(20)
	end]]--

	local model = ragdoll:GetModel()
	
	cacheModel(ragdoll)

	local offset = ply:GetPos() - ply:GetBoneMatrix(0):GetTranslation() + vector_up * 36
	
	if ply:InVehicle() then
		local veh = ply:GetVehicle()
		veh.rags = veh.rags or {}
		table.insert(veh.rags, ragdoll)
	end

	for physNum = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local phys = ragdoll:GetPhysicsObjectNum(physNum)
		local bone = ragdoll:TranslatePhysBoneToBone(physNum)
		if bone < 0 then continue end
		local matrix = ply:GetBoneMatrix(bone)
		ply.AddForceRag = ply.AddForceRag or {}
		ply.AddForceRag[physNum] = ply.AddForceRag[physNum] or {}
		local vel = ply.AddForceRag[physNum][2] or vecZero
		
		--print(ragdoll:GetBoneName(ragdoll:TranslatePhysBoneToBone(hg.cachedmodels[model][ragdoll:GetBoneName(bone)])),ragdoll:GetBoneName(bone),IdealMassPlayer[ragdoll:GetBoneName(bone)])
		
		phys:SetMass(IdealMassPlayer[ragdoll:GetBoneName(bone)] or 4)
		phys:SetVelocity(velocity)
		phys:ApplyForceCenter(vel)
		ply.AddForceRag[physNum][2] = vecZero
		/*local ent = Entity(1)
		for i=0, ent:GetNumPoseParameters() - 1 do
			local min, max = ent:GetPoseParameterRange( i )
			print( ent:GetPoseParameterName( i ) .. ' ' .. min .. " / " .. max )
		end*/

		if ply:InVehicle() then
			local veh = ply:GetVehicle()
			local veh2 = IsValid(ply:GetSimfphys()) and ply:GetSimfphys() or ply:GetVehicle()



			//ply.nocollide1 = constraint.NoCollide(ragdoll, veh, physNum, 0)
			//ply.nocollide2 = constraint.NoCollide(ragdoll, IsValid(veh:GetParent()) and veh:GetParent() or veh, physNum, 0)

			ragdoll:SetParent(IsValid(veh:GetParent()) and veh:GetParent() or veh)

			ply:SetEyeAngles(angle_zero)

			local niggaveh = veh:GetModel() == "models/props_junk/popcan01a.mdl"
			local add = vector_origin

			local niggacar = false
			if veh2:GetModel() == "models/vehicles/7seatvan.mdl" then
				niggacar = true
			end

			local matrix = ply:GetBoneMatrix(bone)

			local pos = matrix:GetTranslation() + veh:GetAngles():Up() * 5// + (niggacar and veh:GetAngles():Right() * 3 + veh:GetAngles():Forward() * 2 or vector_origin)
			local ang = matrix:GetAngles()// + (niggacar and Angle(0, -90, 0) or Angle(0, 0, 0))

			//ply:GetBoneMatrix(0):GetTranslation()
			//local pos, ang = hg.RotateAroundPoint2(pos, ang, vector_origin, vector_origin, Angle(-90,0,0))

			phys:SetPos(pos)
			phys:SetAngles(ang)

			//ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)

			if fixbones[ragdoll:GetBoneName(bone)] then
				local weld = constraint.Weld(ragdoll, IsValid(veh:GetParent()) and veh:GetParent() or veh, physNum, 0, 10000, false, false)

				ragdoll.welds = ragdoll.welds or {}
				table.insert(ragdoll.welds, weld)
				weld:CallOnRemove("removenigga", function()
					if ragdoll.removingwelds then return end
					if not IsValid(ply) then return end
					
					//hook.Run("CanExitVehicle", ply, veh)
					hg.leaveveh = true
					ply:ExitVehicle()

					-- Fix nil table error - check if veh.rags exists before removing
					if veh.rags then
						table.RemoveByValue(veh.rags, ragdoll)
					end

					for physNum = 0, ragdoll:GetPhysicsObjectCount() - 1 do
						local phys = ragdoll:GetPhysicsObjectNum(physNum)
						local bone = ragdoll:TranslatePhysBoneToBone(physNum)
						phys:SetMass(IdealMassPlayer[ragdoll:GetBoneName(bone)] or 4)
					end

					if ragdoll.welds then
						for i, weld in pairs(ragdoll.welds) do
							if IsValid(weld) then weld:Remove() end
						end
						
						ragdoll.welds = nil
					end

					if IsValid(ply.nocollide1) then
						ply.nocollide1:Remove()
						ply.nocollide1 = nil
					end

					if IsValid(ply.nocollide2) then
						ply.nocollide2:Remove()
						ply.nocollide2 = nil
					end
				end)
			end

		end

		phys:SetPos(matrix:GetTranslation() + (ply:InVehicle() and vector_origin or offset))
		phys:SetAngles(matrix:GetAngles())
		if ragdoll:GetBoneName(bone) == "ValveBiped.Bip01_Head1" then
			local _,ang = LocalToWorld(vecZero,Angle(-80,0,90),vecZero,ply:EyeAngles())
			phys:SetAngles(ang)
		end
		phys:EnableDrag(1)
		phys:SetDragCoefficient( -1000 )
		phys:SetDamping(0,2)
		--print(bone)
		--[[if !string.find(ragdoll:GetBoneName(bone),"L") then
			phys:EnableMotion(false)
		end--]]
		phys:Wake()
	end

	ragdoll:SetNWString("PlayerName",ply:Name())
	ragdoll:SetNWVector("PlayerColor",ply:GetPlayerColor())
	ragdoll:SetNetVar("Armor",ply.armors)
	--print(ply:GetNetVar("Accessories","none"))
	ragdoll:SetNetVar("Accessories", ply:GetNetVar("Accessories","none"))
	--timer.Simple(1,function()
	--print(ragdoll:GetNetVar("Accessories","none"))
	--end)

	ply:SetNWEntity("FakeRagdoll",ragdoll)

	ragdoll:SetNWEntity("ply", ply)
	--ply:SetPos(ragdoll:GetPos())

	hook_Run("Ragdoll Create", ply, ragdoll)
	
	ragdoll.ply = ply
	ApplyAppearanceRagdoll(ragdoll, ply)
	return ragdoll
end

local Ragdoll_Create = hg.Ragdoll_Create
util.AddNetworkString("Player Ragdoll")
local function NET_Fake(self, ply, send)
	ply:SetNWEntity("FakeRagdoll",self)
	net.Start("Player Ragdoll")
	net.WriteEntity(ply)
	net.WriteEntity(self)
	--net.WriteInt(self:EntIndex(),32)
	if IsValid(send) and send:IsPlayer() then
		net.Send(send)
	else
		net.Broadcast()
	end
end

local function NET_Fake2(num, ply, send)
	ply:SetNWEntity("FakeRagdoll",Entity(num))
	net.Start("Player Ragdoll")
	net.WriteEntity(ply)
	net.WriteEntity(Entity(num) or NULL)
	--net.WriteInt(num,32)
	if IsValid(send) and send:IsPlayer() then
		net.Send(send)
	else
		net.Broadcast()
	end
end

local function NET_Up(ply, send)
	ply:SetNWEntity("FakeRagdoll",NULL)
	net.Start("Player Ragdoll")
	net.WriteEntity(ply)
	net.WriteEntity(NULL)
	--net.WriteInt(0,32)
	if IsValid(send) and send:IsPlayer() then
		net.Send(send)
	else
		net.Broadcast()
	end
end

hook.Add("PlayerSpawn", "Fake", function(ply)
	ply:RemoveFlags(FL_NOTARGET)
	if OverrideSpawn then return end
	if ply.gottarespawn then
		ply:SetNWEntity("RagdollDeath", NULL)
		ply.gottarespawn = nil
	end
	--NET_Fake2(0, ply)
	ply:SetCanZoom(false)
end)

-- local FrameTimeS
-- local LastTick = 0


-- hook.Add("Tick", "FPS Check", function()
-- 	FrameTimeS = SysTime() - (LastTick or SysTime())
-- 	LastTick = SysTime()

-- 	local tps = 1 / FrameTimeS

-- 	if tps < 66 then
-- 		print(tps)
-- 	end
-- end)

hg.ragdollFake = hg.ragdollFake or {}
--local ragdollFake = hg.ragdollFake
hook.Add("DoPlayerDeath", "Fake", function(ply)
	local ragdoll = ply.FakeRagdoll
	--if not IsValid(ragdoll) then return end
	if (not ply.Removed) and not IsValid(ragdoll) then
		ragdoll = Ragdoll_Create(ply)
		ply.FakeRagdoll = ragdoll
		NET_Fake(ragdoll, ply)
	end

	if not IsValid(ragdoll) then return end
	if IsValid(ragdoll.bull) then ragdoll.bull:Remove() end
	
	ply:SetNWEntity("RagdollDeath", ragdoll)
	ragdoll:SetNetVar("wounds", ply:GetNetVar("wounds"))
	ragdoll:SetNetVar("arterialwounds", ply:GetNetVar("arterialwounds"))
	ply.RagdollDeath = ragdoll
end)

hook.Add("PostPlayerDeath", "Garbage", function(ply)
	local ragdoll = HookGetRagdollEntity(ply)
	if IsValid(ragdoll) then ragdoll:Remove() end

	ply:SetNWEntity("FakeRagdoll", NULL)
	--ply:SetNWEntity("RagdollDeath", ragdoll)

	ply.FakeRagdoll = nil
	hg.ragdollFake[ply] = nil
	
	ply.fakecd = 0
	ply.viewmode = 3
end)

local function RemoveRag(self, ply)
	if self.override then return end
	if not IsValid(ply) or ply.FakeRagdoll ~= self then return end
	ply.FakeRagdoll = nil
	ply.Removed = true
	if ply:Alive() then ply:Kill() end
	NET_Fake2(-1, ply)
	ply.Removed = false
end

hg.queue_ragdolls = hg.queue_ragdolls or {}
hg.humans_cached = hg.humans_cached or {}

hook.Add("SetupPlayerVisibility", "fuckragdolls", function( ply )
	local queue = hg.queue_ragdolls

	for ent, tbl in pairs(queue) do--ему, наверное, больно
		if not IsValid(ent) then queue[ent] = nil continue end
		if queue[ent].count == #hg.humans_cached then queue[ent] = nil continue end
		if queue[ent][ply] then continue end

		if IsValid(ent) then
			AddOriginToPVS( ent:GetPos() )
			queue[ent][ply] = true
			queue[ent].count = (queue[ent].count or 0) + 1
		end
	end

end)

hook.Add("SetupPlayerVisibility", "ragdollview", function( ply )
	local ent = IsValid(hg.ragdollFake[ply]) and hg.ragdollFake[ply] or ply:GetNWEntity("FakeRagdoll")
	
	if IsValid(ent) and !ent:TestPVS(ply) then
		AddOriginToPVS(ent:GetPos())
	end
end)

function hg.Fake(ply, huyragdoll, no_freemove, force)
	-- Allow ragdolling in vehicles - store vehicle info for later exit
	local wasInVehicle = ply:InVehicle()
	local vehicle = wasInVehicle and ply:GetVehicle() or nil
	
	-- Handle boolean values for huyragdoll parameter (force ragdoll creation)
	if type(huyragdoll) == "boolean" then
		huyragdoll = nil -- Convert boolean to nil for proper ragdoll creation
	end
	
	if not IsValid(huyragdoll) and (not IsValid(ply) or IsValid(ply.FakeRagdoll) or not (ply:IsPlayer() and ply:Alive())) then return end
	local ragdoll = IsValid(huyragdoll) and huyragdoll or Ragdoll_Create(ply, true)
	ragdoll:CallOnRemove("Fake", RemoveRag, ply)
	-- Enhanced wound reaction system - extend fakecd for wound holding
	local hasWounds = ply.organism and ply.organism.wounds and #ply.organism.wounds > 0
	ply.fakecd = CurTime() + (hasWounds and 2 or 1)// + ply.organism.shock / 10
	NET_Fake(ragdoll, ply)
	
	ply.FakeRagdoll = ragdoll
	
	-- Store vehicle info for potential re-entry
	if wasInVehicle and IsValid(vehicle) then
		ragdoll.ExitedVehicle = vehicle
		-- Don't store role as GetVehicleRole() doesn't exist on all vehicle types
		-- Mark if this is a compatibility ragdoll (auto-ragdolled in vehicle)
		ragdoll.IsCompatibilityRagdoll = force
	end
	
	if IsValid(ply.FakeRagdollOld) then
		ply.FakeRagdollOld:Remove()
	end

	ply.FakeRagdollOld = nil

	if timer.Exists("faking_up"..ply:EntIndex()) then
		timer.Remove("faking_up"..ply:EntIndex(), 0)
	end

	if ragdoll:GetVelocity():LengthSqr() < (200 * 200) or ply:InVehicle() then hg.SetFreemove(ply,not no_freemove) end

	hg.ragdollFake[ply] = ragdoll
	ply.ActiveWeapon = ply:GetActiveWeapon()
	hook_Run("Fake", ply, ragdoll, listArmor)
	
	timer.Simple(0,function()
		ply:DrawWorldModel(false)
		ply:DrawShadow(false)
		local pos = ply:GetPos()
		//ply:Spectate(OBS_MODE_FREEZECAM)
		//ply:UnSpectate()
		ply:SetSolidFlags(bit.bor(ply:GetSolidFlags(),FSOLID_NOT_SOLID))
		ply:SetPos(pos)
		ply:SetNoDraw(false)
		ply:SetRenderMode(RENDERMODE_NONE)
		
		-- For compatibility ragdolls (force=true), don't exit vehicle - player should stay in vehicle
		-- For manual ragdolls (force=false/nil), exit vehicle normally
		if wasInVehicle and IsValid(vehicle) and not force then
			ply:ExitVehicle()
		end
	end)

	if ply:FlashlightIsOn() then ply:Flashlight(false) end
	ply.oldCanUseFlashlight = ply:CanUseFlashlight()
	ply:AllowFlashlight(false)
	if ply:IsOnFire() then
		timer.Simple(0.1,function()
			--ragdoll:Ignite(30 * ((ragdoll.shouldburn or 0) + 1),16)
			ply:Extinguish()
			--ragdoll.fires = ply.fires
			if ply.fires then
				for fire, pos in pairs(ply.fires) do
					fire:Remove()
					local fire = CreateVFire(ragdoll, ragdoll:GetPos(), vector_up, 50, ragdoll)
				end
			end
		end)
	end
end

local hg_ragdollcombat = ConVarExists("hg_ragdollcombat") and GetConVar("hg_ragdollcombat") or CreateConVar("hg_ragdollcombat", 0, FCVAR_REPLICATED, "ragdoll combat", 0, 1)

function hg.SetFreemove(ply, set)
	if set then
		ply.lastFakeTime = hg_ragdollcombat:GetBool() and 9999 or 1.15
		ply.lastFake = CurTime() + ply.lastFakeTime
		ply:SetNetVar("lastFake",ply.lastFake)
		ply:SetMoveType(MOVETYPE_WALK)
		local hull = Vector(5,5,5)
		--ply:SetHull(-Vector(hull,hull,0),Vector(hull,hull,72))
		--ply:SetHullDuck(-Vector(hull,hull,0),Vector(hull,hull,36))
		--ply:SetViewOffset(Vector(0,0,64))
		--ply:SetViewOffsetDucked(Vector(0,0,34))
	else
		ply.lastFake = 0
		ply:SetNetVar("lastFake",0)
		ply:SetMoveType(ply:InVehicle() and MOVETYPE_NOCLIP or MOVETYPE_NONE)
		//ply:SetMoveType(MOVETYPE_NONE)
		local hull = Vector(5,5,5)
		ply:SetHull(-hull,hull)
		ply:SetHullDuck(-hull,hull)
		ply:SetViewOffset(Vector(0,0,0))
		ply:SetViewOffsetDucked(Vector(0,0,0))
	end
end

local CurTime = CurTime

hook.Add("PreCleanupMap","VSEM_VSTAT",function()
	for i,ply in ipairs(player.GetAll()) do
		hg.FakeUp(ply)
	end
end)

hook.Add("PlayerSpawn", "!!!!!!", function() if OverrideSpawn then return false end end)
hook.Add("PlayerSpawn", "z", function() if OverrideSpawn then return false end end)
hook.Add("Player Spawn", "!!!!!!", function() if OverrideSpawn then return false end end)
hook.Add("Player Spawn", "z", function() if OverrideSpawn then return false end end)

util.AddNetworkString("Override Spawn")
function hg.OverrideSpawn(ply)
	net.Start("Override Spawn")
	net.WriteEntity(ply)
	net.Broadcast()
end

local vecZero = Vector(0, 0, 0)
local tr = {
	filter = {}
}

hook.Add("Should Fake Up","speedhuy",function(ply)
	if IsValid(ply.FakeRagdoll) then
		if ply.FakeRagdoll:GetVelocity():Length() > 200 then return false end
		if (ply.organism.stun - CurTime()) > 0 then return false end
		if (ply.organism.lightstun - CurTime()) > 0 then return false end
		if bit.band(ply.FakeRagdoll:GetFlags(),FL_DISSOLVING) == FL_DISSOLVING then return false end
	end
end)

hook.Add("Player Spawn", "fuckingremoveragdoll", function(ply)
	local ragdoll = ply:GetNWEntity("FakeRagdoll")
	
	if IsValid(ragdoll) then
		ragdoll:SetNWEntity("ply", NULL)
	end

	ply:SetNWEntity("FakeRagdoll", NULL)
	ply:SetNWEntity("RagdollDeath", NULL)
end)

hook.Add("CanControlFake","stunnednocontrol",function(ply,rag)
	if (ply.organism.stun - CurTime()) > 0 then return false end
end)

local util_TraceLine = util.TraceLine
function hg.FakeUp(ply, forced, respawn_like)
	if ply:InVehicle() then forced = true end
	if ply:InVehicle() and ply:GetVehicle():WaterLevel() >= 3 then return end
	if not forced and (not IsValid(ply.FakeRagdoll) or not ply:Alive() or hook_Run("Should Fake Up", ply) ~= nil) then return false end
	ply.fakecd = CurTime() + 2
	local ragdoll = ply.FakeRagdoll

	if ply:InVehicle() then
		local veh = ply:GetVehicle()
		
		-- Vehicle handling for simfphys and regular vehicles
		hg.leaveveh = true
		ply:ExitVehicle()
		//ragdoll:SetParent()
		if ragdoll.welds then
			ragdoll.removingwelds = true
			for i, weld in pairs(ragdoll.welds) do
                if IsValid(weld) then
                    weld:Remove()
                end
			end

			-- Fix nil table error - check if veh.rags exists before removing
			if veh.rags then
				table.RemoveByValue(veh.rags, ragdoll)
			end

			timer.Simple(0.5, function()
				ragdoll:SetParent()	
			end)

			ragdoll.removingwelds = nil

			if IsValid(ply.nocollide1) then
				ply.nocollide1:Remove()
				ply.nocollide1 = nil
			end

			if IsValid(ply.nocollide2) then
				ply.nocollide2:Remove()
				ply.nocollide2 = nil
			end

			/*for i, cons in pairs(constraint.GetTable(ragdoll)) do
				if IsValid(cons) then
					cons:Remove()
					cons = nil
				end
			end*/

			ragdoll.welds = nil
		end

        -- continue fake up after detaching from vehicle
	end

    local ent = (IsValid(ragdoll) and ragdoll or ply)
    local posit = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_Pelvis")):GetTranslation()
    local pos = ply.hg_exit_pos or hg.GetUpPos(ply,posit,50,50)
	
	if not pos and not forced then return end
	local oldpos = pos

	hook_Run("Fake Up", ply, ragdoll)

	ply.FakeRagdollOld = ragdoll
	ply:SetNWEntity("FakeRagdollOld", ragdoll)
	ply.FakeRagdoll = nil
	
	ply:ConCommand("+duck")
	timer.Simple(0.5,function()
		if IsValid(ply) then
			ply:ConCommand("-duck")
		end
	end)

	if IsValid(ragdoll) and ragdoll:IsOnFire() then
		timer.Simple(0.1,function()
			--ply.fires = ragdoll.fires
			--ply:Ignite(30 * ((ply.shouldburn or 0) + 1),16)
			if ragdoll.fires then
				for fire, pos in pairs(ragdoll.fires) do
					local fire = CreateVFire(ply, ply:GetPos(), vector_up, 50, ply)
				end
			end
		end)--]]
	end	

	if IsValid(ragdoll) and ragdoll.welds then
		for i, weld in pairs(ragdoll.welds) do
			if IsValid(weld) then weld:Remove() end
		end

		ragdoll.welds = nil
	end

	OverrideSpawn = true
	local hp, armor = ply:Health(), ply:Armor()
	local ang, wep = ply:EyeAngles(), ply:GetActiveWeapon()
	hg.OverrideSpawn(ply)
	//local pos = ply:GetPos()
	ply:Spawn()
	ply:SetRenderMode(RENDERMODE_NORMAL)
	ply.LastFakeUp = CurTime()
	ply:DrawWorldModel(true)
	ply:SetHealth(hp)
	ply:SetArmor(armor)
	ply:SetEyeAngles(ang)
	if IsValid(wep) then ply:SelectWeapon(wep:GetClass()) else ply:SelectWeapon("weapon_hands_sh") end
	
	if IsValid(ragdoll) and ragdoll.rope_attach then
		ply:PickupWeapon(ragdoll.rope_attach)
		ragdoll.rope_attach = nil
	end

	OverrideSpawn = nil

	if IsValid(ragdoll) then
		local phys = ragdoll:GetPhysicsObject()
		ply:SetVelocity(-ply:GetVelocity() + (IsValid(phys) and phys:GetVelocity() or vecZero)) --как это работает б**н
		hg.SetFreemove(ply, true)
		if pos then
			ply:SetPos(pos)
		end

		ragdoll.override = true
		--ragdoll:SetMoveType(MOVETYPE_NONE)
		--ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)
		--ragdoll:SetRenderMode(RENDERMODE_NONE)
		ply:SetRenderMode(RENDERMODE_NORMAL)
		ply:SetSolidFlags(bit.bor(ply:GetSolidFlags(),FSOLID_NOT_SOLID))
		ply:DrawShadow(false)
		--ragdoll.organism = nil
		if not respawn_like then
			timer.Create("faking_up"..ply:EntIndex(), 1, 1, function()
				if IsValid(ragdoll) then
					local posit = ragdoll:GetBoneMatrix(ragdoll:LookupBone("ValveBiped.Bip01_Pelvis")):GetTranslation()
					//pos = hg.GetUpPos(ply, posit, 50, 50) or oldpos
				end
				
				--ply:ConCommand("-duck")

				if IsValid(ragdoll) then
					ragdoll:Remove()
				end
				
				if pos then
					//ply:SetPos(pos)
				end

				NET_Up(ply)

				ply:DrawShadow(true)
				ply:SetRenderMode(RENDERMODE_NORMAL)
				ply:SetSolidFlags(bit.band(ply:GetSolidFlags(),bit.bnot(FSOLID_NOT_SOLID)))
				hg.ragdollFake[ply] = nil
			end)
		else
			ply:DrawShadow(true)
			ply:SetRenderMode(RENDERMODE_NORMAL)
			ply:SetSolidFlags(bit.band(ply:GetSolidFlags(),bit.bnot(FSOLID_NOT_SOLID)))
			hg.ragdollFake[ply] = nil
			NET_Up(ply)

			if IsValid(ragdoll) then
				ragdoll:Remove()
			end
		end
	end

	if IsValid(ragdoll) then ragdoll:SetNWEntity("ply", NULL) end
	if ply.oldCanUseFlashlight and not ply:CanUseFlashlight() then ply:AllowFlashlight(true) end
	local time = (ply.lastFake or 0) > 0 and 0.1 or 1.5
	--[[timer.Simple(time,function()
		if IsValid(ply) then
			ply:ConCommand("-duck")
		end
	end)--]]

    ply.hg_exit_pos = nil
    return true
end

function hg.GetCurrentCharacter(ply)
    if not IsValid(ply) then return false end
    -- prefer live fake ragdoll, then death ragdoll, otherwise player
    local rag = (IsValid(ply.FakeRagdoll) and ply.FakeRagdoll)
        or (IsValid(ply:GetNWEntity("RagdollDeath", NULL)) and ply:GetNWEntity("RagdollDeath", NULL))
        or (IsValid(ply:GetNWEntity("FakeRagdoll", NULL)) and ply:GetNWEntity("FakeRagdoll", NULL))
    return (IsValid(rag) and rag) or ply
end


hook.Add("PlayerDisconnected", "Fake", function(ply) hg.ragdollFake[ply] = nil end)
hook.Add("PlayerFootstep", "CustomFootstep", function(ply) if IsValid(ply.FakeRagdoll) then return true end end)
function hg.RagdollOwner(ragdoll)
	if not IsValid(ragdoll) then return end
	local ply = ragdoll.ply
	return IsValid(ply) and ply.FakeRagdoll == ragdoll and ply
end

hook.Add("PlayerDisconnected", "hg-killniers", function(ply)
	if ply:Alive() then
		ply:Kill()
		local ragdoll = ply:GetNWEntity("RagdollDeath")
		if IsValid(ragdoll) then
			local newOrg = hg.organism.Add(ragdoll)
			table.Merge(newOrg,ply.organism)
			newOrg.alive = false
			newOrg.owner = ragdoll
			ragdoll:CallOnRemove("organism", hg.organism.Remove, ragdoll)
		end
		hg.organism.Clear(ply.organism)
	end
end)

-- Allow ragdolled players to enter vehicles (crawl back in)
-- This enables the core functionality of ragdolling in vehicles and crawling out/back in
hook.Add("CanPlayerEnterVehicle","fake_enterveh",function(ply, vehicle, role) 
	-- Always allow vehicle entry - ragdolled players should be able to crawl into vehicles
	return true 
end)
hook.Add("PlayerEnteredVehicle","allowweapons",function(ply,veh,role)
	ply:SetEyeAngles(angle_zero)
	
	-- Handle existing ragdoll welds cleanup
	if veh.rags then
		for i, ragdoll in pairs(veh.rags) do
			if !ragdoll.ply or ragdoll.ply.FakeRagdoll != ragdoll then continue end
			ragdoll.removingwelds = true
			if ragdoll.welds then
				for i, weld in pairs(ragdoll.welds) do
					if IsValid(weld) then weld:Remove() end
				end
				ragdoll.welds = nil
			end
			ragdoll.removingwelds = nil
		end
	end
	
	-- If player was ragdolled when entering, clean up the ragdoll
	if IsValid(ply.FakeRagdoll) then
		hg.FakeUp(ply)
	end
	
	-- Universal vehicle compatibility - auto-ragdoll after entering vehicle
	-- This allows the ragdoll system to work with all vehicle types
	local delay = 0.3 -- Reasonable delay for all vehicles
	if veh:GetClass() == "prop_vehicle_prisoner_pod" then
		delay = 0.5 -- Slightly longer for pods
	end
	
	timer.Create("EnterVehicleRag"..ply:EntIndex(), delay, 1, function()
		if IsValid(ply) and IsValid(veh) and ply:InVehicle() and ply:GetVehicle() == veh then
			ply:SetEyeAngles(angle_zero)
			hg.Fake(ply, nil, nil, true)
		end
	end)

	-- Allow weapons in vehicles
	if (role != 0) or (veh:GetClass() == "prop_vehicle_prisoner_pod") then
		ply:SetAllowWeaponsInVehicle(true)
	else
		ply:SetAllowWeaponsInVehicle(true)
	end
end)

hook.Add("PlayerLeaveVehicle","allowweapons",function(ply,veh)
    ply:SetAllowWeaponsInVehicle(false)
end)

hook.Add("PlayerLeaveVehicle","HG_FakeUpOnExit",function(ply,veh)
    if not IsValid(ply) then return end
    timer.Simple(FrameTime() * 2, function()
        if not IsValid(ply) then return end
        local base = (IsValid(veh) and (veh.base or veh:GetParent())) or veh
        local ang = IsValid(base) and base:GetAngles() or Angle(0,0,0)
        local right = ang:Right()
        local forward = ang:Forward()
        local up = ang:Up()

        local origin = ply:GetPos()
        local target = origin + right * -40 + forward * 8 + up * 6
        local tr = {
            start = target + up * 24,
            endpos = target - up * 96,
            mins = Vector(-12,-12,0),
            maxs = Vector(12,12,72),
            filter = {ply, ply.FakeRagdoll, veh, base},
            mask = MASK_PLAYERSOLID
        }
        local res = util.TraceHull(tr)
        local safe = res.Hit and (res.HitPos + up * 2) or target
        ply.hg_exit_pos = safe
        local rag = ply.FakeRagdoll
        if IsValid(rag) then
            if rag.welds then
                for i, weld in pairs(rag.welds) do
                    if IsValid(weld) then weld:Remove() end
                end
                rag.welds = nil
            end
            rag:SetParent()
            if IsValid(ply.nocollide1) then ply.nocollide1:Remove() ply.nocollide1 = nil end
            if IsValid(ply.nocollide2) then ply.nocollide2:Remove() ply.nocollide2 = nil end
            hg.FakeUp(ply, true)
        end
    end)
end)

/*
local PLAYER = FindMetaTable("Player")

hg.ExitVehicle = hg.ExitVehicle or PLAYER.ExitVehicle

function PLAYER:ExitVehicle()
	//if hg.leaveveh then hg.ExitVehicle(self) hg.leaveveh = nil end
	hg.ExitVehicle(self)
end
*/



hook.Add("CanExitVehicle","huyhuy",function(a,b)
    local ply = IsValid(a) and a:IsPlayer() and a or b
    if not IsValid(ply) then return false end
    if hg.leaveveh then return true end
    if ply:KeyDown(IN_USE) then return true end
    return false
end)

local poses = {}

function hg.GetUpPos(target,pos,tries,starttries)
	if not IsValid(target) then return pos end

	local hull = 10
	local mins,maxs = -Vector(hull,hull,0),Vector(hull,hull,36)

	if tries <= 0 then
		table.sort(poses,function(a,b) return a[2] < b[2] end)
		
		local vec = #poses > 0 and Vector(poses[1][1],poses[1][2],poses[1][3])-- or pos - vector_up * 72
		
		poses = {}

		if vec then
			local t = {}
			t.start = vec
			t.endpos = vec - vector_up * 128
			t.mins = mins
			t.maxs = maxs
			t.filter = {target,target.FakeRagdoll,target.ply}
			t.mask = MASK_PLAYERSOLID
			local tr = util.TraceHull( t )

			return tr.HitPos
		end

		return vec
	end
	tries = tries - 1


	local offset = tries == starttries and vector_origin or VectorRand(-32,32)
	local newpos = pos + offset

	local t = {}
	t.start = pos
	t.endpos = newpos
	t.filter = {target,target.FakeRagdoll,target.ply}
	t.mask = MASK_PLAYERSOLID

	local tr = util.TraceLine( t )

	if not tr.Hit then
		local t = {}
		t.start = newpos
		t.endpos = newpos
		t.mins = mins
		t.maxs = maxs
		t.filter = {target,target.FakeRagdoll,target.ply}
		t.mask = MASK_PLAYERSOLID
		local tr = util.TraceHull( t )
		
		if not tr.Hit then
			table.insert(poses,{newpos,(tr.HitPos - pos):LengthSqr()})
		end
	end

	return hg.GetUpPos(target,pos,tries,starttries)
end
/*
local ent = Entity(1)
local ragdoll = ents.Create("prop_ragdoll")
ragdoll.Appearance = ent.Appearance
ragdoll:SetModel(ent:GetModel())
ragdoll:SetPos(ent:GetPos())
ragdoll:Spawn()
ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
ent:SetRenderMode(RENDERMODE_NONE)
ent:SetNWEntity("huy",ragdoll)
ApplyAppearanceRagdoll(ent,ragdoll)
hook.Add("Think","asdasd",function()
	local ragbonecount = ragdoll:GetBoneCount()
	for i = 0, ragbonecount - 1 do
		local bonename = ragdoll:GetBoneName(i)
		local boneent = ent:LookupBone(bonename)
		--[[ for _,name in ipairs(boneDamage) do
			if name==bonename and gotdamaged==true then return end
		end]]
		if boneent then
			local bonepos,boneang = ent:GetBonePosition(ent:TranslatePhysBoneToBone(i))
			if bonepos and boneang then
				local bonerag = ragdoll:LookupBone(bonename)
				if bonerag then
					if bonerag == 0 then bonepos = ent:GetPos() end
					local physobj = ragdoll:GetPhysicsObjectNum(bonerag)
					if IsValid(physobj) then
						local p = {}
						p.secondstoarrive = 0.01
						p.pos = bonepos
						p.angle = boneang
						p.maxangular = 650
						p.maxangulardamp = 500
						p.maxspeed = 45
						p.maxspeeddamp = 35
						p.teleportdistance = 0

						physobj:Wake()
						physobj:ComputeShadowControl(p)
					end
				end
			end
		end
	end
end)
*/
local ents_FindInSphere = ents.FindInSphere
local sphereRadius = 25
hook.Add("Move","PushAwayRagdolls",function(ply, mv)
	do return end
	if not ply:Alive() or not hg.GetCurrentCharacter(ply):IsPlayer() then return end
    local sphereCenter = ply:GetPos()
    local entities = ents_FindInSphere(sphereCenter, sphereRadius)

    for _, ent in ipairs(entities) do
		if ent:GetCollisionGroup() == COLLISION_GROUP_WEAPON then
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local physObj = ent:GetPhysicsObjectNum(i)
				local limbPos = physObj:GetPos()

				local pushDir = (limbPos - sphereCenter):GetNormalized()
				if limbPos:Distance(sphereCenter) < sphereRadius then
					physObj:ApplyForceCenter(pushDir * math.min(ply:GetVelocity():Length()/3,200) *  (physObj:GetMass()/5))
				end
				--ply:SetVelocity(-pushDir * 2)
			end
		end

		if not ent:IsRagdoll() then continue end
		ent.pushCooldown = ent.pushCooldown or 0
		if ent.pushCooldown < CurTime() then
			if ply:GetVelocity():Length() > 200 then
				--print(ply:EyeAngles()[1])
				if math.random(1,ply:EyeAngles()[1] < 20 and 3 or 10) == 2 then
					hg.LightStunPlayer(ply,2)
				else
					--ply:SetVelocity(-ply:GetVelocity())
					ply:SetVelocity(-ply:GetVelocity()*0.5)
				end
			end
		end
		ent.pushCooldown = CurTime() + 0.5
    end
end)