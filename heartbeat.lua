
FORBIDDEN = 'd'..'isco'..'rd'
local v1 = {};
local u1 = nil;
coroutine.wrap(function()
	u1 = require(game.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Library"));
end)();
local v2
if u1.Settings.ReplicateOtherStatsInstantly then
	v2 = 0;
else
	v2 = u1.Settings.ReplicateOtherStatsBuffer or 0.33;
end;
local v4 = u1.RunService:IsStudio() or u1.RunService:IsRunMode();
local u2 = u1.Settings.DisableSaving or false;
local u3 = u1.Settings.SaveDebugging or false;
local data = {};
local u5 = u1.DataStoreService:GetDataStore(u1.Settings.StatsVersion) --(u1.Settings.DisableLoading and false) == false and u1.Settings.StatsVersion or "NonSave0", nil);
function v1.Save(p1, p2, p3)
	local v5 = type(p1) == "number";
	local v6 = v5 and p1 or p1.UserId;
	local v7 = v5 and v6 or p1.Name;
	if u2 then
		if u3 then
			u1.Print("Cancelled save for [bold]" .. v7 .. "[/bold] because saving is disabled");
		end;
		return true;
	end;
	local v8 = p3 or data["u" .. v6];
	if v8 ~= nil then
		local v9 = u1.Datastore.Update(u5, v6, function(p4)
			if p4 ~= nil then
				local l__LastSaveTimestamp__10 = p4.LastSaveTimestamp;
				if u3 and l__LastSaveTimestamp__10 ~= nil then
					u1.Print("Time elapsed since last save for [bold]" .. v7 .. "[/bold]: " .. u1.Functions.TimeString(os.time() - l__LastSaveTimestamp__10));
				end;
			end;
			v8.LastSaveTimestamp = os.time();
			v8.PlayingSession = not (v2 or false)
			local newsave = game:GetService("HttpService"):JSONEncode(v8)
			return newsave;
		end);
		if u3 and v9 then
			u1.Print("Successfully saved [bold]" .. v7 .. "[/bold]'s stats!");
		end;
		if v9 then
			return v9;
		end;
	end;
	u1.Print("Failed to save [bold]" .. v7 .. "[/bold]'s stats", true);
	coroutine.wrap(function()
		if not v5 and p1 then
			u1.Network.Fire("Save Fail", p1);
			wait(5);
			if p1 then
				p1:Kick("Periodic Save Failed");
			end;
		end;
	end)();
	return false;
end;

--[[
function v1.Save(player, playerLeaving)

	--- Get session stats
	local stats = v1.Get(player)

	--- Main
	if stats ~= nil then
		--- Attempt save
		local success = u1.Datastore.Update(u5, player.UserId, function(oldSave)
			if oldSave ~= nil then
				local lastSaveTimestamp = oldSave.LastSaveTimestamp
			end

			--- Update save timestamp
			stats.LastSaveTimestamp = os.time()

			--- Update session timestamp
			stats.PlayingSession = not (playerLeaving or false)

			local newstats = u1.HttpService:JSONEncode(stats)
			return newstats
		end)

		--- End function is save was completed!
		if success then
			return success
		end
	end

	u1.Print("Failed to save [bold]" .. player.Name .. "[/bold]'s stats", true)

	--- If the function reaches this point, save failed. Let client know this is not good :(
	coroutine.wrap(function()
		u1.Network.Fire("Save Fail", player)
	end)()

	--
	return false
end]]

local u6 = u1.Settings.SavePlayerID or 0;
local u7 = Random.new();
function v1.Retrieve(p5)
	local v11 = false;
	local v12 = false;
	local tries = 0
	local oldsave
	local e
	local v14
	while tries < 6 and not v11 and not v12 do
		if not (tries < 6 and not v11 and not v12) then
			break
		end
		if not p5 then
			break;
		end;
		if not p5.Parent then
			break;
		end;
		local v13
		if v4 then
			v13 = u6 > 0 and u6 or p5.UserId;
		else
			v13 = p5.UserId;
		end;
		oldsave, v11, e = u1.Datastore.Get(u5, v13);
		print("loading")
		if oldsave then
			v14 = game:GetService("HttpService"):JSONDecode(oldsave)
		end
		if e ~= nil then
			warn(tostring(e))
		end
		if v14 and v14.PlayingSession and not v4 then
			v11 = true
			break
		elseif not v14 and v11 then
			v12 = true;
			break
		end;
		tries = tries + 1
		if not v11 then
			wait(u7:NextNumber(2, 5));
		end;	
	end;
	if v14 and v14.PlayingSession then
		--u1.Print("Stats were retrieved, but PlayingSession flag was saved as true. Ignore this if test session.", true);
		v11 = true;
	end;
	if v12 then
		if u3 then
			u1.Print("New player, [bold]" .. p5.Name .. "[/bold], joined the game!");
		end;
		return {};
	end;
	if u3 then
		if v11 then
			if u3 then
				u1.Print("Successfully retrieved stats for [bold]" .. p5.Name .. "[/bold]!");
			end;
		else
			u1.Print("Failed to retrieve stats for [bold]" .. p5.Name .. "[/bold]", true);
		end;
	end;
	if not v11 then
		warn('Returned stats as error!')
		return "Error";
	end;
	if u6 ~= 0 then
	--	print(nil);
	end;
	return v14;
end;


--[[function v1.Retrieve(player)
	--- Variables
	local savedStats
	local attempts = 0
	local success = false
	local newPlayer = false

	--- Wait for most recent save
	while (attempts < 5 and (not success) and (not newPlayer)) do
		savedStats, success = u1.Datastore.Get(u5, player.UserId)
		attempts = attempts + 1

		-- Not recent save!
		if savedStats and savedStats.PlayingSession and (not v4) then
			success = false
		elseif (not savedStats) and success then
			newPlayer = true
		end
		
		if savedStats and type(savedStats) == 'string' then
			savedStats = game.HttpService:JSONDecode(savedStats)
		end
		
		--- Delay
		if not success then
			wait(u7:NextNumber(5, 8))
		end
	end

	--- Stats were retrieved, but failed to get LATEST save. Probably didn't save correctly :/
	if savedStats and savedStats.PlayingSession then
		u1.Print("Stats were retrieved, but PlayingSession flag was saved as true. Ignore this if test session.", true)
		success = true
	end

	--- New player!
	if newPlayer then
		return {}
	end

	--- Debug prints

	if not success then
		return "Error"
	end

	--
	return savedStats
end]]

local u8 = {};
local u9 = {};
function v1.Init(p6)
	if u8[p6.UserId] then
		return;
	end;
	u8[p6.UserId] = true;
	local function v17()
		local l__UserId__18 = p6.UserId;
		while (data["u" .. l__UserId__18] ~= nil or not (not u9["u" .. l__UserId__18])) and p6 do
			if not p6.Parent then
				break;
			end;
			u1.Heartbeat();		
		end;
		if data["u" .. l__UserId__18] == nil and not u9["u" .. l__UserId__18] and p6 and p6.Parent then
			local v19 = v1.Retrieve(p6);
			if not p6 or not p6.Parent then
				return;
			elseif v19 == "Error" then
				u1.Print("_L.Saving.Init | MAJOR ERROR: Stats returned error for [bold]" .. p6.Name .. "[/bold]", true);
				return false;
			elseif v19 then
				v19.PlayingSession = true;
				if not v1.Save(p6, nil, v19) or not p6 or not p6.Parent then
					return false;
				else
					if v19 then
						data["u" .. l__UserId__18] = v19;
						for v20, v21 in pairs(u1.Settings.DefaultStats) do
							if v19[v20] == nil then
								data["u" .. l__UserId__18][v20] = type(v21) == "table" and u1.Functions.CloneTable(v21) or v21;
							end;
						end;
					else
						data["u" .. l__UserId__18] = u1.Functions.CloneTable(u1.Settings.DefaultStats);
						data["u" .. l__UserId__18].PlayingSession = true;
					end;
					u1.Signal.Fire("Player Added", p6);
					local v22 = {};
					local v23 = {};
					local v24 = os.clock();
					while p6 and p6.Parent and data["u" .. l__UserId__18] do
						local v25 = {};
						for v26, v27 in pairs(data["u" .. l__UserId__18]) do
							if not u1.Settings.StatsNetworkingBlacklist[v26] then
								local v28 = v22[v26];
								local v29 = type(v27) == "table";
								if v28 == nil then
									if v29 then
										local v30 = u1.Functions.CloneTable(v27, false);
										v25[v26] = v30;
										v22[v26] = v30;
										v23[v26] = v30;
									else
										v25[v26] = v27;
										v22[v26] = v27;
										v23[v26] = v27;
									end;
									u1.Signal.Fire("Stat Changed", p6, v26);
								elseif v29 then
									if not u1.Functions.CompareTable(v27, v28) then
										local v31 = u1.Functions.CloneTable(v27, false);
										v25[v26] = v31;
										v22[v26] = v31;
										v23[v26] = v31;
										u1.Signal.Fire("Stat Changed", p6, v26);
									end;
								elseif v27 ~= v28 then
									v25[v26] = v27;
									v22[v26] = v27;
									v23[v26] = v27;
									u1.Signal.Fire("Stat Changed", p6, v26);
								end;
							end;
						end;
						if u1.Functions.DictionaryLength(v25) > 0 then
							u1.Network.Fire("New Stats", p6, v25, p6);
						end;
						if v2 <= os.clock() - v24 and u1.Functions.DictionaryLength(v23) > 0 then
							v24 = os.clock();
							for v32, v33 in ipairs(game.Players:GetPlayers()) do
								if v33 ~= p6 then
									coroutine.wrap(function()
										u1.Network.Fire("New Stats", v33, v23, p6);
									end)();
								end;
							end;
							v23 = {};
						end;
						u1.Heartbeat();					
					end;
					return true;
				end;
			else
				if v19 then
					data["u" .. l__UserId__18] = v19;
					for v20, v21 in pairs(u1.Settings.DefaultStats) do
						if v19[v20] == nil then
							data["u" .. l__UserId__18][v20] = type(v21) == "table" and u1.Functions.CloneTable(v21) or v21;
						end;
					end;
				else
					data["u" .. l__UserId__18] = u1.Functions.CloneTable(u1.Settings.DefaultStats);
					data["u" .. l__UserId__18].PlayingSession = true;
				end;
				u1.Signal.Fire("Player Added", p6);
				local v22 = {};
				local v23 = {};
				local v24 = os.clock();
				while p6 and p6.Parent and data["u" .. l__UserId__18] do
					local v25 = {};
					for v26, v27 in pairs(data["u" .. l__UserId__18]) do
						if not u1.Settings.StatsNetworkingBlacklist[v26] then
							local v28 = v22[v26];
							local v29 = type(v27) == "table";
							if v28 == nil then
								if v29 then
									local v30 = u1.Functions.CloneTable(v27, false);
									v25[v26] = v30;
									v22[v26] = v30;
									v23[v26] = v30;
								else
									v25[v26] = v27;
									v22[v26] = v27;
									v23[v26] = v27;
								end;
								u1.Signal.Fire("Stat Changed", p6, v26);
							elseif v29 then
								if not u1.Functions.CompareTable(v27, v28) then
									local v31 = u1.Functions.CloneTable(v27, false);
									v25[v26] = v31;
									v22[v26] = v31;
									v23[v26] = v31;
									u1.Signal.Fire("Stat Changed", p6, v26);
								end;
							elseif v27 ~= v28 then
								v25[v26] = v27;
								v22[v26] = v27;
								v23[v26] = v27;
								u1.Signal.Fire("Stat Changed", p6, v26);
							end;
						end;
					end;
					if u1.Functions.DictionaryLength(v25) > 0 then
						u1.Network.Fire("New Stats", p6, v25, p6);
					end;
					if v2 <= os.clock() - v24 and u1.Functions.DictionaryLength(v23) > 0 then
						v24 = os.clock();
						for v32, v33 in ipairs(game.Players:GetPlayers()) do
							if v33 ~= p6 then
								coroutine.wrap(function()
									u1.Network.Fire("New Stats", v33, v23, p6);
								end)();
							end;
						end;
						v23 = {};
					end;
					u1.Heartbeat();				
				end;
				return true;
			end;
		end;
	end;
	local v34 = 0;
	local v35 = false;
	while not v35 and v34 < 3 and p6 do
		if not p6.Parent then
			break;
		end;
		v35 = v17();
		u1.Heartbeat();
		if not v35 then
			v34 = v34 + 1;
			wait(0.5);
		end;	
	end;
	if( not v35) and p6 then
		u1.Print("MAJOR ERROR: Could not init [bold]" .. p6.Name .. "[/bold]'s stats!", true);
		p6:Kick("Something went wrong. Please rejoin!");
	end;
	u8[p6.UserId] = nil;
end;
function v1.Get(p7, p8)
	local v36
	if p8 == nil then
		v36 = true;
	else
		v36 = p8;
	end;
	p8 = v36;
	if not p7 then
		return;
	end;
	if u9["u" .. p7.UserId] then
		return;
	end;
	local v37 = data["u" .. p7.UserId];
	if not v37 then
		pcall(function()
			local v38 = os.clock();
			if p8 then
				while (not v37) and (os.clock() - v38 <= 5) and p7 do
					if not p7.Parent then
						break;
					end;
					u1.Heartbeat();
					v37 = data["u" .. p7.UserId];				
				end;
			end;
			if not v37 and u3 then
				u1.Print("Failed to index [bold]" .. p7.Name .. "[/bold]'s stats", true);
			end;
		end);
	end;
	return v37;
end;
function v1.Remove(p9)
	local v39 = type(p9) == "number";
	local v40 = v39 and p9 or p9.UserId;
	if not pcall(function()
		data["u" .. v40] = nil;
		wait(10);
		u9["u" .. v40] = nil;
	end) then
		local u11 = v39 and v40 or p9.Name;
		pcall(function()
			u1.Print("Failed to remove session stats for [bold]" .. u11 .. "[/bold]!", true);
		end);
	end;
end;
function v1.Reset(p10)
	if data["u" .. p10.UserId] then
		data["u" .. p10.UserId] = u1.Functions.CloneTable(u1.Settings.DefaultStats);
		v1.Save(p10);
	end;
end;
function v1.IsLoaded(p11)
	local v41 = p11 and p11:FindFirstChild("__LOADED") ~= nil;
	return v41;
end;
local function v42(p12)
	coroutine.wrap(function()
		v1.Init(p12);
	end)();
end;
local function v43(p13)
	local v44 = type(p13) == "number" and p13 or p13.UserId;
	if data["u" .. v44] and not u9["u" .. v44] then
		u9["u" .. v44] = true;
		wait(5);
		v1.Save(v44, true);
		wait(1);
		v1.Remove(v44);
	end;
end;
for v45, v46 in ipairs(game.Players:GetPlayers()) do
	v42(v46);
end;
game.Players.PlayerAdded:Connect(v42);
game.Players.PlayerRemoving:Connect(v43);
coroutine.wrap(function()
	while true do
		for v47, v48 in pairs(data) do
			local v49 = tonumber(string.sub(v47, 2));
			if not u9[v47] and not game.Players:GetPlayerByUserId(v49) then
				v43(v49);
			end;
		end;
		u1.Heartbeat();	
	end;
end)();
function game.OnClose()
	if not u2 then
		coroutine.wrap(function()
			u1.Network.FireAll('Closing Now')
			for v50, v51 in ipairs(game.Players:GetPlayers()) do
				coroutine.wrap(function()
					wait(2.5)
					if v51 then
						game:GetService('TeleportService'):Teleport(9022823046, v51)
						while wait(0.5) do
							game:GetService('TeleportService'):Teleport(9022823046, v51)
						end
					end
				end)();
			end;
		end)()
		u1.Signal.Fire("Server Closing");
		for v50, v51 in ipairs(game.Players:GetPlayers()) do
			coroutine.wrap(function()
				if v51 then
					v1.Save(v51, true);
				end;
			end)();
		end;
		local v52 = Instance.new("Message");
		v52.Text = "\226\154\160\239\184\143 Join our " .. FORBIDDEN .. " please. " .. FORBIDDEN .. ".gg/petsimulatorb.\n\nREJOIN REJOIN REJOIN";
		v52.Parent = game.Workspace;
		if not u1.RunService:IsStudio() then
			wait(30);
		else
			wait(1)
		end
	end;
end;
local u12 = 300 --u1.Settings.SaveDuration or 60;
coroutine.wrap(function()
	while true do
		for v53, v54 in pairs(data) do
			if v53 and v54 then
				wait(u12 / #game.Players:GetPlayers());
				pcall(function()
					local v55 = tonumber(string.sub(v53, 2));
					local v56 = game.Players:GetPlayerByUserId(v55);
					if v56 and not u9["u" .. v55] and data["u" .. v55] then
						coroutine.wrap(function()
							v1.Save(v56);
						end)();
					end;
				end);
			end;
		end;
		u1.Heartbeat();	
	end;
end)();
u1.Network.Invoked("Get Stats").OnInvoke = function(p14, p15, p16)
	if not p15 then
		p15 = p14;
	end;
	local m = v1.Get(p15, p16)
	if not m then
		m = 'Error'
		if p15 == p14 then
			warn('Printed error for plyr ' .. tostring(p14.Name))
		end
	end
	return m
end;
return v1;
