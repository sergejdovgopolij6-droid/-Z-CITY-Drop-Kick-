local cooldown = 0.5

util.AddNetworkString("fake")

net.Receive("fake", function(len,ply)
	if not ply:Alive() then return end
	if ply.fakecd and ply.fakecd > CurTime() then return end
	if ply:IsFlagSet( FL_FROZEN ) then return end
	--ply.fakecd = CurTime() + cooldown
	if not IsValid(ply.FakeRagdoll) then
		hg.Fake(ply)
	else
		hg.FakeUp(ply)
	end
end)

hook.Add("PlayerInitialSpawn", "PlayerColideCallback", function(ply) 
	ply:AddCallback("PhysicsCollide", function(ply, data) 
		hook.Run("PlayerCollide", ply, data.HitEntity, data) 
	end) 
end)

hook.Add("Ragdoll Collide", "organism", function(ragdoll, data) -- ниче не помню, но для удобства тут будет
	if ragdoll == data.HitEntity then return end
	if data.DeltaTime < 0.25 then return end
	if not ragdoll:IsRagdoll() then return end
	if data.HitEntity:IsPlayerHolding() then return end

	if data.HitEntity:GetClass() == "func_breakable" and data.Speed > 20 then
		local dmginfo = DamageInfo()
		dmginfo:SetAttacker(ragdoll)
		dmginfo:SetInflictor(ragdoll)
		dmginfo:SetDamage(data.Speed / 5)
		dmginfo:SetDamageForce(data.HitNormal * data.Speed)
		dmginfo:SetDamageType(DMG_CLUB)
		dmginfo:SetDamagePosition(data.HitPos)
		data.HitEntity:TakeDamageInfo(dmginfo)
	end

	if string.find(data.HitEntity:GetClass(), "break") and data.HitEntity.GetBrushSurfaces and data.HitEntity:GetBrushSurfaces()[1] and string.find(data.HitEntity:GetBrushSurfaces()[1]:GetMaterial():GetName(), "glass") then
		if data.Speed > 200 then
			local dmginfo = DamageInfo()
			dmginfo:SetAttacker(ragdoll)
			dmginfo:SetInflictor(ragdoll)
			dmginfo:SetDamage(50)
			dmginfo:SetDamageForce(data.HitNormal * 100)
			dmginfo:SetDamageType(DMG_SLASH)
			dmginfo:SetDamagePosition(data.HitPos)
			data.HitEntity:TakeDamageInfo(dmginfo)
		end
	end

	if hgIsDoor(data.HitEntity) and data.Speed > 400 then
		hgBlastThatDoor(data.HitEntity, data.HitNormal * 200)
	end

   --[[ if string.find(data.HitEntity:GetClass(), "prop_") and not data.HitEntity:IsRagdoll() and not data.HitEntity:IsPlayer() then 
        local phys = data.HitEntity:GetPhysicsObject()                                                                                 --должно работать но я тупой и оно не работает
        if IsValid(phys) then
            phys:EnableMotion(true) 
            phys:Wake()
        end к 
    end]]--
		hg.velocityDamage(ragdoll,data) -- бля, забыл про дамаг
end)

hook.Add("OnPlayerHitGround","asdasd",function(ply,inwater,onfloater,speed)
	local tr = {}
	tr.start = ply:GetPos()
	tr.endpos = ply:GetPos() - vector_up * 2
	tr.filter = ply
	local bottom, top = ply:GetHull()
	bottom[3] = bottom[3] - 5
	tr.mins = bottom
	tr.maxs = top

	tr = util.TraceHull(tr)
	
	if ply.GetPlayerClass and ply:GetPlayerClass() and ply:GetPlayerClass().FallDmgFunc then
		ply:PlayerClassEvent("FallDmgFunc", speed, tr)
		
		return
	end

	if speed > 250 and tr.Entity:IsPlayer() then
		hg.drop(tr.Entity)
		hg.LightStunPlayer(tr.Entity,2)
		--tr.Entity:TakeDamage(speed / 5,ply,ply)
	end

	if speed > 600 then
		hg.LightStunPlayer(ply,2)
	end
end)

concommand.Add("force_fake", function(ply, cmd, args)
	if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin()) then return end
	ply = Player(tonumber(args[1]))
	if not IsValid(ply.FakeRagdoll) then
		hg.Fake(ply)
	else
		hg.FakeUp(ply)
	end
end)

concommand.Add("fake", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:Alive() then return end
    if ply.fakecd and ply.fakecd > CurTime() then return end
    if ply:IsFlagSet( FL_FROZEN ) then return end
    if not IsValid(ply.FakeRagdoll) then
        hg.Fake(ply)
    else
        hg.FakeUp(ply)
    end
end)
