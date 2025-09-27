-- 🧠 ПЕРЕМЕННЫЕ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local username = player.Name
local playerGui = player:WaitForChild("PlayerGui")

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("MultiboxFramework"))
while not Framework.Loaded do
	RunService.Heartbeat:Wait()
end

-- 🎛️ СОСТОЯНИЕ
local isRunning = false
local currentThread = nil

-- 🧩 ЭКИПИРОВКА ПРЕДМЕТА
local function waitAndEquipTool()
	local backpack = player:WaitForChild("Backpack")
	local character = player.Character or player.CharacterAdded:Wait()

	while true do
		for _, item in pairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				item.Parent = character
				print("🧰 Equipped tool:", item.Name)
				return true
			end
		end
		print("⌛ Waiting for new tool...")
		task.wait(1)
	end
end

-- 🧱 ПОИСК УЧАСТКА
local function getPlayerPlot()
	local plotSigns = workspace:WaitForChild("PlotOwnerSigns")
	local plotsFolder = workspace:WaitForChild("Plots")
	for _, plotModel in pairs(plotSigns:GetChildren()) do
		local wall = plotModel:FindFirstChild("Brick_Wall")
		if wall then
			local gui = wall:FindFirstChild("5")
			if gui and gui:IsA("SurfaceGui") then
				local label = gui:FindFirstChild("TextLabel")
				if label and label:IsA("TextLabel") then
					if label.Text == "Owned by " .. username then
						local plotName = plotModel.Name
						return plotsFolder:FindFirstChild(plotName)
					end
				end
			end
		end
	end
	return nil
end

-- 📦 ЦИКЛ РАЗМЕЩЕНИЯ
local function placeObjectsInLoop()
	local playerPlot = getPlayerPlot()
	if not playerPlot then
		warn("❌ Plot not found.")
		return
	end

	print("✅ Found plot:", playerPlot.Name)
	local baseCFrame
	if playerPlot:IsA("Model") then
		local cf, _ = playerPlot:GetBoundingBox()
		baseCFrame = cf
	else
		baseCFrame = playerPlot.CFrame
	end

	local xSteps, zSteps, spacing = 10, 10, 5

	for x = -xSteps/2, xSteps/2 - 1 do
		for z = -zSteps/2, zSteps/2 - 1 do
			if not isRunning then
				print("⏸️ Paused.")
				return
			end

			if not player:FindFirstChildOfClass("Tool") then
				waitAndEquipTool()
			end

			local offset = Vector3.new(x * spacing, 0, z * spacing)
			local newCFrame = CFrame.new(baseCFrame.Position + offset)
			Framework.Network.Invoke("PlaceObjectRequest", newCFrame)
			task.wait(0.1)
		end
	end
end

-- 🧰 GUI КНОПКИ
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlacementControlGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainButton = Instance.new("TextButton")
mainButton.Size = UDim2.new(0, 160, 0, 50)
mainButton.Position = UDim2.new(0, 100, 0, 100)
mainButton.BackgroundColor3 = Color3.fromRGB(65, 180, 75)
mainButton.TextColor3 = Color3.new(1, 1, 1)
mainButton.Font = Enum.Font.GothamBold
mainButton.TextSize = 16
mainButton.Text = "▶️ Start Placement"
mainButton.Parent = screenGui
mainButton.Active = true
mainButton.Draggable = true

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(0, 230, 0, 100)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Text = "❌"
closeButton.Parent = screenGui

-- 🔄 Переключение состояния
mainButton.MouseButton1Click:Connect(function()
	isRunning = not isRunning
	if isRunning then
		mainButton.Text = "⏸️ Pause Placement"
		mainButton.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
		currentThread = task.spawn(placeObjectsInLoop)
	else
		mainButton.Text = "▶️ Resume Placement"
		mainButton.BackgroundColor3 = Color3.fromRGB(65, 180, 75)
	end
end)

-- ❌ Закрытие и выгрузка
closeButton.MouseButton1Click:Connect(function()
	isRunning = false
	if currentThread then
		task.cancel(currentThread)
	end
	screenGui:Destroy()
	print("🛑 Script stopped and GUI removed.")
end)