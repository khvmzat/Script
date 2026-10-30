local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// SETTINGS
local WIDTH = 500
local HEIGHT = 760
local HEADER = 40
local TAB_HEIGHT = 30
local ROW = 25
local MAX_PLAYERS = 100
local MAX_VISIBLE_ITEMS = 12
local RADIUS = 10
local FONT = 2

local enabled = true
local currentTab = "PLAYERS"
local dropdownOpen = false
local selectedPlayer = nil

local x = 0
local y = 0

--// STAMINA
local MAX_STAMINA = 100
local staminaEnabled = true

--// FIXED BINDS
local TOGGLE_BIND = "ALT"

--// STAT CACHE
local cachedStats = { Money = nil, Bank = nil }
local statScanDone = false
local statTimer = 0

--// MOUSE
local mouse = LocalPlayer:GetMouse()
local mouseWasDown = false

--// COLORS
local COLORS = {
    Background = Color3.fromRGB(25, 25, 30),
    Header = Color3.fromRGB(35, 35, 50),
    TabActive = Color3.fromRGB(80, 110, 175),
    TabInactive = Color3.fromRGB(45, 50, 65),
    Dropdown = Color3.fromRGB(45, 45, 60),
    White = Color3.fromRGB(245, 245, 250),
    Gray = Color3.fromRGB(190, 195, 210),
    Inventory = Color3.fromRGB(215, 220, 235),
    Equipped = Color3.fromRGB(100, 255, 150),
    Health = Color3.fromRGB(100, 255, 150),
    Cash = Color3.fromRGB(100, 220, 255),
    Bank = Color3.fromRGB(190, 140, 255),
    SettingsHeader = Color3.fromRGB(150, 190, 255),
    SettingsValue = Color3.fromRGB(110, 255, 175),
    Row1 = Color3.fromRGB(55, 75, 115),
    Row2 = Color3.fromRGB(70, 60, 110),
    Row3 = Color3.fromRGB(55, 90, 105),
    On = Color3.fromRGB(40, 160, 80),
    Off = Color3.fromRGB(110, 110, 120)
}

--// CENTER
local function centerUI()
    local camera = workspace.CurrentCamera
    if camera then
        x = (camera.ViewportSize.X - WIDTH) / 2
        y = (camera.ViewportSize.Y - HEIGHT) / 2
    end
end

--// ROUNDED SHAPE
local function createRoundedShape(color, transparency, zindex)
    local objects = {}

    local function sq()
        local s = Drawing.new("Square")
        s.Filled = true
        s.Color = color
        s.Transparency = transparency
        s.Visible = true
        s.ZIndex = zindex
        return s
    end

    objects.Center = sq()
    objects.Horizontal = sq()
    objects.Vertical = sq()

    local corners = {}
    for i = 1, 4 do
        local circle = Drawing.new("Circle")
        circle.Filled = true
        circle.Color = color
        circle.Transparency = transparency
        circle.Radius = RADIUS
        circle.Visible = true
        circle.ZIndex = zindex
        corners[i] = circle
    end
    objects.Corners = corners

    return objects
end

local function positionRounded(shape, px, py, width, height)
    shape.Center.Position = Vector2.new(px + RADIUS, py + RADIUS)
    shape.Center.Size = Vector2.new(math.max(width - RADIUS * 2, 1), math.max(height - RADIUS * 2, 1))

    shape.Horizontal.Position = Vector2.new(px + RADIUS, py)
    shape.Horizontal.Size = Vector2.new(math.max(width - RADIUS * 2, 1), height)

    shape.Vertical.Position = Vector2.new(px, py + RADIUS)
    shape.Vertical.Size = Vector2.new(width, math.max(height - RADIUS * 2, 1))

    shape.Corners[1].Position = Vector2.new(px + RADIUS, py + RADIUS)
    shape.Corners[2].Position = Vector2.new(px + width - RADIUS, py + RADIUS)
    shape.Corners[3].Position = Vector2.new(px + RADIUS, py + height - RADIUS)
    shape.Corners[4].Position = Vector2.new(px + width - RADIUS, py + height - RADIUS)
end

local function setRoundedVisible(shape, visible)
    shape.Center.Visible = visible
    shape.Horizontal.Visible = visible
    shape.Vertical.Visible = visible
    for i = 1, 4 do
        shape.Corners[i].Visible = visible
    end
end

local function setRoundedColor(shape, color)
    shape.Center.Color = color
    shape.Horizontal.Color = color
    shape.Vertical.Color = color
    for i = 1, 4 do
        shape.Corners[i].Color = color
    end
end

local function makeText(text, size, color, zindex, visible)
    local t = Drawing.new("Text")
    t.Text = text
    t.Size = size
    t.Font = FONT
    t.Color = color
    t.Outline = true
    t.Visible = visible
    t.ZIndex = zindex
    return t
end

--// BACKGROUND / HEADER
local background = createRoundedShape(COLORS.Background, 0.90, 1)
local header = createRoundedShape(COLORS.Header, 0, 2)
local title = makeText("PLAYER INVENTORY", 18, COLORS.White, 3, true)

--// TABS
local playersTab = createRoundedShape(COLORS.TabActive, 0, 4)
local playersTabText = makeText("PLAYERS", 14, COLORS.White, 5, true)
local settingsTab = createRoundedShape(COLORS.TabInactive, 0, 4)
local settingsTabText = makeText("SETTINGS", 14, COLORS.White, 5, true)

--// DROPDOWN
local dropdown = createRoundedShape(COLORS.Dropdown, 0, 20)
local dropdownText = makeText("Select Player", 15, COLORS.White, 21, true)
local selectedPlayerName = makeText("", 14, COLORS.Gray, 3, false)
local dropdownArrow = makeText("v", 16, COLORS.Gray, 21, true)

--// PLAYER ROWS
local playerRows = {}
for i = 1, MAX_PLAYERS do
    local bg = createRoundedShape(COLORS.Row1, 0, 30)
    setRoundedVisible(bg, false)
    local text = makeText("", 14, COLORS.White, 31, false)
    playerRows[i] = { Background = bg, Text = text, Player = nil }
end

--// INVENTORY
local inventoryHeader = makeText("INVENTORY", 17, Color3.fromRGB(120, 200, 255), 3, false)
local inventoryRows = {}
for i = 1, MAX_VISIBLE_ITEMS + 1 do
    inventoryRows[i] = makeText("", 14, COLORS.Inventory, 3, false)
end

--// STATS
local statsHeader = makeText("STATS", 17, Color3.fromRGB(255, 190, 90), 3, false)
local statRows = {}
for i = 1, 3 do
    statRows[i] = makeText("", 14, COLORS.White, 3, false)
end

--// SETTINGS PAGE
local settingsHeader = makeText("SETTINGS", 18, COLORS.SettingsHeader, 3, false)
local bindsHeader = makeText("BINDS", 16, COLORS.White, 3, false)
local toggleLabel = makeText("Toggle UI", 14, COLORS.Gray, 3, false)
local toggleValue = makeText(TOGGLE_BIND, 14, COLORS.SettingsValue, 3, false)
local fixedInfo = makeText("Binds are fixed.", 13, Color3.fromRGB(150, 155, 175), 3, false)

--// FEATURES (stamina)
local featuresHeader = makeText("FEATURES", 16, COLORS.White, 3, false)
local staminaBtn = createRoundedShape(COLORS.On, 0, 4)
setRoundedVisible(staminaBtn, false)
local staminaBtnText = makeText("Infinite Stamina : ON", 14, COLORS.White, 5, false)

local function refreshStaminaBtn()
    setRoundedColor(staminaBtn, staminaEnabled and COLORS.On or COLORS.Off)
    staminaBtnText.Text = "Infinite Stamina : " .. (staminaEnabled and "ON" or "OFF")
end
refreshStaminaBtn()

--// DISPLAY NAME
local function getDisplayName(player)
    if not player then return "Unknown Player" end
    local displayName = nil
    pcall(function() displayName = player.DisplayName end)
    if displayName and displayName ~= "" then
        return tostring(displayName)
    end
    return tostring(player.Name)
end

local function clearPlayerRows()
    for i = 1, MAX_PLAYERS do
        local row = playerRows[i]
        setRoundedVisible(row.Background, false)
        row.Text.Visible = false
        row.Player = nil
    end
end

local function hideMainContent()
    inventoryHeader.Visible = false
    statsHeader.Visible = false
    for i = 1, MAX_VISIBLE_ITEMS + 1 do inventoryRows[i].Visible = false end
    for i = 1, 3 do statRows[i].Visible = false end
end

local function clearInventory()
    inventoryHeader.Visible = false
    for i = 1, MAX_VISIBLE_ITEMS + 1 do inventoryRows[i].Visible = false end
end

local function clearStats()
    statsHeader.Visible = false
    for i = 1, 3 do statRows[i].Visible = false end
end

local function hideDropdown()
    dropdownOpen = false
    clearPlayerRows()
end

--// GET INVENTORY
local function getInventory(player)
    local items = {}
    if not player then return items end

    local function addItem(item)
        if not item then return end
        if item.ClassName ~= "Tool" then return end

        local name = tostring(item.Name)
        if string.find(string.lower(name), "ammo") then return end

        local cleanName = string.gsub(name, "[^%w%s%-%_%.%&%(%)]", "")
        if cleanName == "" then return end

        for _, existing in ipairs(items) do
            if existing == cleanName then return end
        end
        table.insert(items, cleanName)
    end

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do addItem(item) end
    end

    local character = player.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do addItem(item) end
    end

    return items
end

--// SCAN STATS
local function scanStats(player)
    cachedStats.Money = nil
    cachedStats.Bank = nil
    statScanDone = false

    if not player then return end

    pcall(function()
        for _, object in ipairs(player:GetDescendants()) do
            local objectName = string.lower(tostring(object.Name))

            if objectName == "money" or objectName == "moneyvalue" or objectName == "moneyamount" then
                if cachedStats.Money == nil then
                    pcall(function()
                        if object.Value ~= nil then cachedStats.Money = object end
                    end)
                end
            elseif objectName == "bank" or objectName == "bankvalue" or objectName == "bankamount" or objectName == "bankbalance" then
                if cachedStats.Bank == nil then
                    pcall(function()
                        if object.Value ~= nil then cachedStats.Bank = object end
                    end)
                end
            end
        end
    end)

    statScanDone = true
end

local function readCachedValue(object)
    if not object then return "N/A" end
    local value = nil
    pcall(function() value = object.Value end)
    if value == nil then return "N/A" end
    return tostring(value)
end

local function getHealth(player)
    local health = "N/A"
    pcall(function()
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            health = tostring(math.floor(humanoid.Health + 0.5))
                .. " / " .. tostring(math.floor(humanoid.MaxHealth + 0.5))
        end
    end)
    return health
end

local function updateStats()
    if not selectedPlayer then return end
    if not statScanDone then scanStats(selectedPlayer) end

    statRows[1].Text = "Health: " .. getHealth(selectedPlayer)
    statRows[1].Color = COLORS.Health

    statRows[2].Text = "Cash: " .. readCachedValue(cachedStats.Money)
    statRows[2].Color = COLORS.Cash

    statRows[3].Text = "Bank: " .. readCachedValue(cachedStats.Bank)
    statRows[3].Color = COLORS.Bank
end

local function selectPlayer(player)
    if not player then return end
    selectedPlayer = player
    scanStats(player)
    dropdownText.Text = "Select Player"
    selectedPlayerName.Text = "Selected: " .. getDisplayName(player)
    selectedPlayerName.Visible = true
    updateStats()
end

--// UPDATE DROPDOWN
local function updateDropdown()
    clearPlayerRows()
    if not dropdownOpen then return end

    local players = Players:GetPlayers()
    table.sort(players, function(a, b)
        return string.lower(getDisplayName(a)) < string.lower(getDisplayName(b))
    end)

    local LIST_START = y + 125
    local TEXT_START = y + 130
    local count = math.min(#players, MAX_PLAYERS)

    for i = 1, count do
        local player = players[i]
        local row = playerRows[i]
        row.Player = player

        local rowY = LIST_START + ((i - 1) * ROW)

        if rowY + ROW <= y + HEIGHT - 10 then
            local rowColor
            if i % 3 == 1 then rowColor = COLORS.Row1
            elseif i % 3 == 2 then rowColor = COLORS.Row2
            else rowColor = COLORS.Row3 end

            setRoundedColor(row.Background, rowColor)
            positionRounded(row.Background, x + 10, rowY, WIDTH - 20, ROW)

            row.Text.Position = Vector2.new(x + 20, TEXT_START + ((i - 1) * ROW))
            row.Text.Text = getDisplayName(player)

            setRoundedVisible(row.Background, true)
            row.Text.Visible = true
        else
            row.Player = nil
            row.Text.Visible = false
            setRoundedVisible(row.Background, false)
        end
    end
end

--// SETTINGS POSITIONS
local STAM_X, STAM_Y, STAM_W, STAM_H = 25, 290, WIDTH - 50, 30

local function updateSettings()
    settingsHeader.Position = Vector2.new(x + 15, y + 105)
    bindsHeader.Position = Vector2.new(x + 15, y + 140)
    toggleLabel.Position = Vector2.new(x + 25, y + 175)
    toggleValue.Position = Vector2.new(x + WIDTH - 75, y + 175)
    fixedInfo.Position = Vector2.new(x + 25, y + 220)

    featuresHeader.Position = Vector2.new(x + 15, y + 260)
    positionRounded(staminaBtn, x + STAM_X, y + STAM_Y, STAM_W, STAM_H)
    staminaBtnText.Position = Vector2.new(x + STAM_X + 15, y + STAM_Y + 7)
end

local function showSettings()
    settingsHeader.Visible = true
    bindsHeader.Visible = true
    toggleLabel.Visible = true
    toggleValue.Visible = true
    fixedInfo.Visible = true
    featuresHeader.Visible = true
    setRoundedVisible(staminaBtn, true)
    staminaBtnText.Visible = true
end

local function hideSettings()
    settingsHeader.Visible = false
    bindsHeader.Visible = false
    toggleLabel.Visible = false
    toggleValue.Visible = false
    fixedInfo.Visible = false
    featuresHeader.Visible = false
    setRoundedVisible(staminaBtn, false)
    staminaBtnText.Visible = false
end

local function updateTabColors()
    local playerColor, settingsColor
    if currentTab == "PLAYERS" then
        playerColor, settingsColor = COLORS.TabActive, COLORS.TabInactive
    else
        playerColor, settingsColor = COLORS.TabInactive, COLORS.TabActive
    end
    setRoundedColor(playersTab, playerColor)
    setRoundedColor(settingsTab, settingsColor)
end

--// UPDATE
local function update()
    if not enabled then return end

    centerUI()

    positionRounded(background, x, y, WIDTH, HEIGHT)
    positionRounded(header, x, y, WIDTH, HEADER)
    title.Position = Vector2.new(x + 12, y + 10)

    positionRounded(playersTab, x + 10, y + 50, 220, TAB_HEIGHT)
    playersTabText.Position = Vector2.new(x + 85, y + 57)

    positionRounded(settingsTab, x + 235, y + 50, 255, TAB_HEIGHT)
    settingsTabText.Position = Vector2.new(x + 325, y + 57)

    updateTabColors()

    if currentTab == "PLAYERS" then
        hideSettings()

        setRoundedVisible(dropdown, true)
        dropdownText.Visible = true
        dropdownArrow.Visible = true

        positionRounded(dropdown, x + 10, y + 90, WIDTH - 20, 30)
        dropdownText.Position = Vector2.new(x + 20, y + 96)
        dropdownArrow.Position = Vector2.new(x + WIDTH - 35, y + 96)

        if selectedPlayer then
            selectedPlayerName.Position = Vector2.new(x + 15, y + 125)
            selectedPlayerName.Visible = not dropdownOpen
        else
            selectedPlayerName.Visible = false
        end

        clearInventory()
        clearStats()

        if selectedPlayer and not dropdownOpen then
            inventoryHeader.Text = "INVENTORY"
            inventoryHeader.Position = Vector2.new(x + 12, y + 150)
            inventoryHeader.Visible = true

            local inventory = getInventory(selectedPlayer)
            local visibleItemCount = math.min(#inventory, MAX_VISIBLE_ITEMS)
            if visibleItemCount < 1 then visibleItemCount = 1 end

            if #inventory == 0 then
                inventoryRows[1].Text = "No items"
                inventoryRows[1].Color = COLORS.Inventory
                inventoryRows[1].Position = Vector2.new(x + 15, y + 175)
                inventoryRows[1].Visible = true
            else
                for i = 1, visibleItemCount do
                    inventoryRows[i].Text = inventory[i]
                    inventoryRows[i].Color = COLORS.Inventory

                    local character = selectedPlayer.Character
                    if character then
                        local equipped = character:FindFirstChild(inventory[i])
                        if equipped and equipped.ClassName == "Tool" then
                            inventoryRows[i].Color = COLORS.Equipped
                        end
                    end

                    inventoryRows[i].Position = Vector2.new(x + 15, y + 175 + ((i - 1) * ROW))
                    inventoryRows[i].Visible = true
                end

                if #inventory > MAX_VISIBLE_ITEMS then
                    local extra = #inventory - MAX_VISIBLE_ITEMS
                    local row = MAX_VISIBLE_ITEMS + 1
                    inventoryRows[row].Text = "+ " .. tostring(extra) .. " more items"
                    inventoryRows[row].Color = Color3.fromRGB(190, 140, 255)
                    inventoryRows[row].Position = Vector2.new(x + 15, y + 175 + (MAX_VISIBLE_ITEMS * ROW))
                    inventoryRows[row].Visible = true
                end
            end

            local statsY = y + 190 + (visibleItemCount * ROW)
            if #inventory > MAX_VISIBLE_ITEMS then
                statsY = statsY + ROW
            end

            statsHeader.Position = Vector2.new(x + 12, statsY)
            statsHeader.Visible = true

            for i = 1, 3 do
                statRows[i].Position = Vector2.new(x + 15, statsY + 25 + ((i - 1) * ROW))
                statRows[i].Visible = true
            end

        elseif dropdownOpen then
            selectedPlayerName.Visible = false
            hideMainContent()
            updateDropdown()
        else
            hideMainContent()
            clearPlayerRows()
        end

    else
        hideDropdown()
        clearInventory()
        clearStats()

        selectedPlayerName.Visible = false

        setRoundedVisible(dropdown, false)
        dropdownText.Visible = false
        dropdownArrow.Visible = false

        showSettings()
        updateSettings()
    end
end

--// CLICK
local function inside(mx, my, bx, by, bw, bh)
    return mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
end

local function handleClick()
    if not enabled then return end

    local mx = mouse.X
    local my = mouse.Y

    -- PLAYERS TAB
    if inside(mx, my, x + 10, y + 50, 220, 30) then
        currentTab = "PLAYERS"
        hideSettings()
        update()
        return
    end

    -- SETTINGS TAB
    if inside(mx, my, x + 235, y + 50, 255, 30) then
        currentTab = "SETTINGS"
        hideDropdown()
        update()
        return
    end

    -- STAMINA BUTTON (onglet SETTINGS)
    if currentTab == "SETTINGS" then
        if inside(mx, my, x + STAM_X, y + STAM_Y, STAM_W, STAM_H) then
            staminaEnabled = not staminaEnabled
            refreshStaminaBtn()
        end
        return
    end

    if currentTab ~= "PLAYERS" then return end

    -- SELECT PLAYER BOX
    if inside(mx, my, x + 10, y + 90, WIDTH - 20, 30) then
        dropdownOpen = not dropdownOpen

        if dropdownOpen then
            hideMainContent()
            clearPlayerRows()
            updateDropdown()
        else
            hideDropdown()
            update()
        end
        return
    end

    -- PLAYER ROWS
    if dropdownOpen then
        for i = 1, MAX_PLAYERS do
            local row = playerRows[i]
            if row.Player then
                local rowY = y + 125 + ((i - 1) * ROW)
                if inside(mx, my, x + 10, rowY, WIDTH - 20, ROW) then
                    selectPlayer(row.Player)
                    hideDropdown()
                    dropdownText.Text = "Select Player"
                    update()
                    return
                end
            end
        end
    end
end

--// BLOCK GAME INPUT
setrobloxinput(false)

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
    local mouseDown = ismouse1pressed()
    if mouseDown and not mouseWasDown then
        handleClick()
    end
    mouseWasDown = mouseDown
    update()
end)

--// STATS REFRESH
RunService.RenderStepped:Connect(function(dt)
    if not enabled then return end
    if not selectedPlayer then return end
    if currentTab ~= "PLAYERS" then return end
    if dropdownOpen then return end

    statTimer = statTimer + dt
    if statTimer >= 0.25 then
        statTimer = 0
        updateStats()
    end
end)

--// INFINITE STAMINA (tourne meme quand le menu est cache)
task.spawn(function()
    while true do
        if staminaEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    char:SetAttribute("Stamina", MAX_STAMINA)
                end
            end)
        end
        task.wait(0.03)
    end
end)

--// ALT TOGGLE
local altWasDown = false

RunService.RenderStepped:Connect(function()
    local altDown = iskeypressed(0x12)

    if altDown and not altWasDown then
        enabled = not enabled

        if enabled then
            setRoundedVisible(background, true)
            setRoundedVisible(header, true)
            setRoundedVisible(playersTab, true)
            setRoundedVisible(settingsTab, true)

            title.Visible = true
            playersTabText.Visible = true
            settingsTabText.Visible = true

            setRoundedVisible(dropdown, currentTab == "PLAYERS")
            dropdownText.Visible = currentTab == "PLAYERS"
            dropdownArrow.Visible = currentTab == "PLAYERS"

            setrobloxinput(false)
            update()
        else
            setRoundedVisible(background, false)
            setRoundedVisible(header, false)
            setRoundedVisible(playersTab, false)
            setRoundedVisible(settingsTab, false)

            title.Visible = false
            playersTabText.Visible = false
            settingsTabText.Visible = false

            setRoundedVisible(dropdown, false)
            dropdownText.Visible = false
            dropdownArrow.Visible = false

            selectedPlayerName.Visible = false
            inventoryHeader.Visible = false
            statsHeader.Visible = false

            hideSettings()
            clearInventory()
            clearStats()
            hideDropdown()

            setrobloxinput(true)
        end

        print("PLAYER INVENTORY:", enabled and "ON" or "OFF")
    end

    altWasDown = altDown
end)
