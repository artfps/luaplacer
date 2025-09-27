-- 📦 Получаем сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 🎮 Локальный игрок
local player = Players.LocalPlayer
local username = player.Name

-- 📦 Подключаем MultiboxFramework
local Framework = require(ReplicatedStorage:WaitForChild("MultiboxFramework"))
while not Framework.Loaded do
	RunService.Heartbeat:Wait()
end

-- ✅ Экипировка первого Tool-а
local function equipFirstTool()
	local backpack = player:WaitForChild("Backpack")
	local character = player.Character or player.CharacterAdded:Wait()

	for _, item in pairs(backpack:GetChildren()) do
		if item:IsA("Tool") then
			item.Parent = character
			print("🧰 Equipped tool:", item.Name)
			return true
		end
	end

	warn("❌ No tool found in backpack.")
	return false
end

-- 🔁 Переменные управления
local isRunning = false
local currentThread = nil

-- 🧠 Функция поиска Plot-а игрока
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

-- 🧩 Основной цикл размещения
local function placeObjectsInLoop()
	while isRunning do
		-- Экипировать предмет (если закончились)
		if not player.Character:FindFirstChildOfClass("Tool") then
			if not equipFirstTool() then
				print("🛑 Остановка: нет предметов.")
				isRunning = false
				break
			end
		end

		local playerPlot = getPlayerPlot()
		if playerPlot then
			local centerCFrame
			if playerPlot:IsA("Model") then
				local cf, _ = playerPlot:GetBoundingBox()
				centerCFrame = cf
			else
				centerCFrame = playerPlot.CFrame
			end

			-- 🚀 Размещаем
			Framework.Network.Invoke("PlaceObjectRequest", centerCFrame)
			print("📦 Размещён объект в центр плашки")
		else
			warn("❌ Plot not found")
			break
		end

		task.wait(0.5) -- интервал между размещениями
	end
end

-- 🧱 Интерфейс: Кнопка + X
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlacementControlGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainButton = Instance.new("TextButton")
mainButton.Size = UDim2.new(0, 160, 0, 50)
mainButton.Position = UDim2.new(0, 100, 0, 300)
mainButton.Text = "▶️ Start Placement"
mainButton.BackgroundColor3 = Color3.fromRGB(65, 180, 75)
mainButton.TextSize = 18
mainButton.Font = Enum.Font.SourceSansBold
mainButton.Parent = screenGui
mainButton.Active = true
mainButton.Draggable = true

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(0, 240, 0, 300)
closeButton.Text = "❌"
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = screenGui
closeButton.Active = true
closeButton.Draggable = true

-- ▶️/⏸️ Тоггл цикла размещения
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

-- ❌ Остановка и очистка GUI
closeButton.MouseButton1Click:Connect(function()
	isRunning = false
	if currentThread and coroutine.status(currentThread) == "suspended" then
		task.cancel(currentThread)
		print("⛔ Цикл остановлен")
	end
	screenGui:Destroy()
	currentThread = nil
	print("🧹 Скрипт и интерфейс выгружены")
end)