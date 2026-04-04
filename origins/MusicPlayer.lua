--[[

This script is responsible for:
  - Improving player performance by locally rendering map chunks dynamically to reduce the amount of assets currently loaded in.
  - Managing the music and ambiance depending on which zone the player is in.

This code reflects an earlier stage of my programming life but showcases a simple, independent script that is well-structured.
My proudest part of this script is the RepeatBack() method, which makes use of recursion to check if the player has entered a new area while a previous one is still loading. It's designed to make sure that eventually, the correct map state will be applied.
At the time, I managed to implement recursion without prior knowledge of what it is, which I feel shows strong problem-solving and reasoning skills.

--]]

local Music = script.Parent.Music
local Folder = workspace.MusicFolder
local CurrentlyPlaying = "Menu"
local Transitioning = false
local TS = game:GetService("TweenService")
local Debounce = false
local Queued = false
local Queue = {}
local LastTouched = false

local BaseThemes = {
	["Desert"] = {FogColor = Color3.fromRGB(122,53,8),Ambient = Color3.fromRGB(255,255,200),FogEnd=1000,ExposureCompensation=0};
	["Ice"] = {FogColor=Color3.fromRGB(170,255,255),Ambient = Color3.fromRGB(168,182,204),FogEnd=2000,ExposureCompensation=0};
	["Volcano"] = {FogColor=Color3.fromRGB(255,85,0),Ambient = Color3.fromRGB(255,216,125),FogEnd=10000,ExposureCompensation=0};
	["Corruption"] = {FogColor=Color3.fromRGB(0,0,0),Ambient = Color3.fromRGB(232,228,255),FogEnd=1600,ExposureCompensation=0.5};
	["Forest"] = {FogColor=Color3.fromRGB(96,194,255),Ambient = Color3.fromRGB(153,153,153),FogEnd=6000,ExposureCompensation=0.5};
	["None"] = {FogColor=Color3.fromRGB(255,255,255),Ambient = Color3.fromRGB(255,255,255),FogEnd=100000,ExposureCompensation=0};
}
local Skyboxes = {game.Lighting.Default,game.Lighting.Volcano,game.Lighting.Corruption}

local function GetTouchingParts(part)
   local connection = part.Touched:Connect(function() end)
   local results = part:GetTouchingParts()
   connection:Disconnect()
   return results
end

delay(.5, function() Music.Playing = true end)

local function Ambience(theme)
	if theme == "Desert" or theme == "DesertBoss" then
		local Theme = "Desert"
		TS:Create(game.Lighting,TweenInfo.new(4),BaseThemes[Theme]):Play()
		Skyboxes[1].Parent = game.Lighting;Skyboxes[2].Parent = game.ReplicatedStorage;Skyboxes[3].Parent = game.ReplicatedStorage
		game.Lighting.TimeOfDay = "10:00:00"
	elseif theme == "Ice" or theme == "IceBoss" then
		local Theme = "Ice"
		TS:Create(game.Lighting,TweenInfo.new(4),BaseThemes[Theme]):Play()
		Skyboxes[1].Parent = game.Lighting;Skyboxes[2].Parent = game.ReplicatedStorage;Skyboxes[3].Parent = game.ReplicatedStorage
		game.Lighting.TimeOfDay = "10:00:00"
	elseif theme == "Volcano" or theme == "VolcanoBoss" then
		local Theme = "Volcano"
		TS:Create(game.Lighting,TweenInfo.new(4),BaseThemes[Theme]):Play()
		Skyboxes[1].Parent = game.ReplicatedStorage;Skyboxes[2].Parent = game.Lighting;Skyboxes[3].Parent = game.ReplicatedStorage
		game.Lighting.TimeOfDay = "18:00:00"
	elseif theme == "Corruption" or theme == "CorruptionBoss" then
		local Theme = "Corruption"
		TS:Create(game.Lighting,TweenInfo.new(4),BaseThemes[Theme]):Play()
		Skyboxes[1].Parent = game.ReplicatedStorage;Skyboxes[2].Parent = game.ReplicatedStorage;Skyboxes[3].Parent = game.Lighting
		game.Lighting.TimeOfDay = "17:40:00"
	elseif theme == "Forest" then
		local Theme = "Forest"
		game.Lighting.TimeOfDay = "20:00:00"
		TS:Create(game.Lighting,TweenInfo.new(4),BaseThemes[Theme]):Play()
		Skyboxes[1].Parent = game.Lighting;Skyboxes[2].Parent = game.ReplicatedStorage;Skyboxes[3].Parent = game.ReplicatedStorage
	else
		local Theme = "None"
		TS:Create(game.Lighting,TweenInfo.new(4),BaseThemes[Theme]):Play()
		Skyboxes[1].Parent = game.Lighting;Skyboxes[2].Parent = game.ReplicatedStorage;Skyboxes[3].Parent = game.ReplicatedStorage
		game.Lighting.TimeOfDay = "10:00:00"
	end
	if theme == "Forest" then
		local ForestTop = workspace:FindFirstChild("ForestTop")
		if ForestTop then
			ForestTop.ForestStars.P1.Enabled = true
			ForestTop.ForestStars.P2.Enabled = true
			ForestTop.ForestStars.P3.Enabled = true
			TS:Create(ForestTop,TweenInfo.new(4),{Transparency = 0}):Play()
		end
	else
		local ForestTop = workspace:FindFirstChild("ForestTop")
		if ForestTop then
			ForestTop.ForestStars.P1.Enabled = false
			ForestTop.ForestStars.P2.Enabled = false
			ForestTop.ForestStars.P3.Enabled = false
			TS:Create(ForestTop,TweenInfo.new(4),{Transparency = 1}):Play()
		end
	end
end

local function LoadArea(child)
	Transitioning = true
	local Vol = .5
	local BaseTInfo = TweenInfo.new(2,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
	local FadeMusic = TS:Create(Music,BaseTInfo,{Volume = 0})
	local Title = script.Base:Clone();local Creator = script.Base:Clone();local Id = script.Base:Clone();local AreaName = script.Base:Clone();
	Title.Size = UDim2.new(.2,0,.1,0);Title.Position = UDim2.new(.79,0,0,0);Title.Text = child.Title.Value
	Creator.Size = UDim2.new(.2,0,.06,0);Creator.Position = UDim2.new(.79,0,0.08,0);Creator.Text = child.Author.Value
	Id.Size = UDim2.new(.2,0,.04,0);Id.Position = UDim2.new(.79,0,.14,0);Id.Text = "ID: "..child.ID.Value
	AreaName.Size = UDim2.new(.3,0,.08,0);AreaName.Position = UDim2.new(.5,0,0.12,0);AreaName.AnchorPoint = Vector2.new(.5,.5);AreaName.Text = child.AreaName.Value
	AreaName.TextXAlignment = Enum.TextXAlignment.Center
	Ambience(child.Name)
	local Texts = {Title,Creator,Id,AreaName}
	for _, txt in pairs(Texts) do
		spawn(function()
			txt.Parent = script.Parent txt.Visible = true
			local Grow1 = TS:Create(txt,BaseTInfo,{TextTransparency = 0});local Grow2 = TS:Create(txt,BaseTInfo,{TextStrokeTransparency = .5})
			Grow1:Play() Grow2:Play() Grow2.Completed:wait()
			local Fade1 = TS:Create(txt,BaseTInfo,{TextTransparency = 1});local Fade2 = TS:Create(txt,BaseTInfo,{TextStrokeTransparency = 1})
			Fade1:Play() Fade2:Play() Fade2.Completed:wait() txt:Destroy()
		end)
	end
	FadeMusic:Play() FadeMusic.Completed:wait()
	if child:FindFirstChild("ID") then Music.SoundId = "rbxassetid://"..child.ID.Value end
	if child:FindFirstChild("PlaySpeed") then Music.PlaybackSpeed = child.PlaySpeed.Value else Music.PlaybackSpeed = 1 end
	if child:FindFirstChild("TimePos") then Music.TimePosition = child.TimePos.Value else Music.TimePosition = 0 end
	if child:FindFirstChild("Volume") then Vol = child.Volume.Value end
	local GrowMusic = TS:Create(Music,BaseTInfo,{Volume = Vol})
	GrowMusic:Play() GrowMusic.Completed:wait()
	Transitioning = false
end

local function RepeatBack()
	repeat wait(.05) until not Transitioning
	if LastTouched ~= CurrentlyPlaying then
		CurrentlyPlaying = LastTouched
		LoadArea(Folder[LastTouched])
		RepeatBack()
	end
end

for _, child in pairs(Folder:GetChildren()) do
	child.Touched:Connect(function(hit)
		if hit.Parent == game.Players.LocalPlayer.Character then
			if child.Name ~= CurrentlyPlaying and not Transitioning and not Debounce then
				CurrentlyPlaying = child.Name
				LoadArea(child)
			elseif Transitioning and not Debounce then
				Debounce = true
				RepeatBack()
				Debounce = false
			elseif Transitioning then
				LastTouched = child.Name
			end
		end
	end)
end
