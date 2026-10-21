local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local success, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)

if not success or not WindUI then
    warn("[Zinc] Failed to load WindUI:", WindUI)
    return
end

local Window = WindUI:CreateWindow({
    Title = "ZINC HUB",
    Icon = "shield-check",
    Author = "Zinc Team",
    Folder = "ZincHub",
    Size = UDim2.fromOffset(550, 430),
    MinSize = Vector2.new(480, 320),
    Theme = "Dark",
    Transparent = true,
    Resizable = true,
    HasOutline = true,
    SideBarWidth = 170
})

local HalloweenTab = Window:Tab({
    Title = "Halloween",
    Icon = "ghost"
})

local MonsterEnabled = false
local LilPumpEnabled = false
local EchoEnabled = false
local GhostEnabled = false

local SelectedMonster = "All"
local CurrentTarget = nil

local FarmToken = 0
local LilPumpToken = 0
local EchoToken = 0
local GhostToken = 0

local STEP_DISTANCE = 8
local STEP_DELAY = 0.01
local SCAN_DELAY = 0.3
local ATTACK_DISTANCE = 8
local ATTACK_DELAY = 0.25
local MONSTER_TELEPORT_DELAY = 0.1

local FLY_STEP_DISTANCE = 700
local FLY_ARRIVE_DISTANCE = 2

local LILPUMP_CACHE_WAIT = 0.2
local LILPUMP_PROMPT_DELAY = 0.1
local LILPUMP_ARRIVE_DISTANCE = 5
local LILPUMP_SCAN_RADIUS = 500

local ECHO_SCAN_DELAY = 0.25
local ECHO_PROMPT_DELAY = 0.4
local ECHO_TELEPORT_OFFSET = Vector3.new(0, 2, 0)
local ECHO_FOLLOW_DISTANCE = 10
local ECHO_STOP_CHECK_INTERVAL = 0.4
local ECHO_STOP_DURATION = 2
local ECHO_STOP_MOVEMENT_THRESHOLD = 1.5
local ECHO_STOP_TIMEOUT = 120
local GHOST_FISHING_TRIGGER_DISTANCE = 25

local GHOST_SCAN_DELAY = 0.4
local GHOST_PROMPT_DELAY = 0.5
local GHOST_APPROACH_DISTANCE = 8

local GHOST_TOOL_NAMES = {
    "ghostvacuum",
    "vacuumghost",
    "ghostvac",
    "spectralvacuum"
}

local TRAIN_NAMES = {
    "phantomexpress",
    "ghosttrain",
    "halloweenexpress"
}

local GHOST_TARGET_NAMES = {
    "ghost",
    "ghosts",
    "specter",
    "spectre",
    "spirit",
    "phantom"
}

local MonsterPriority = {
    "Soul Phantom",
    "Pumpkin Golem",
    "Scarecrow",
    "Chest Mimic",
    "Candy Corn",
    "Hollow Bat"
}

local WeaponAliases = {
    "Axe", "Rìu", "Hammer", "Búa", "Bat",
    "Gậy", "Katana", "Kiếm", "Sword", "Club"
}

local EchoKeywords = {
    "echo", "squeaky", "squeak", "oldbone", "bone",
    "oldcollar", "collar", "oldphoto", "photo"
}

local MonsterDropdown

local function Notify(title, content)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = 3
        })
    end)
end

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRoot()
    local character = GetCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local character = GetCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function NormalizeName(value)
    return string.lower(tostring(value or "")):gsub("[%s_%-]", "")
end

local function GetObjectPosition(object)
    if not object then
        return nil
    end

    if object:IsA("BasePart") then
        return object.Position
    end

    if object:IsA("Model") then
        local part = object.PrimaryPart
            or object:FindFirstChild("HumanoidRootPart")
            or object:FindFirstChildWhichIsA("BasePart", true)

        return part and part.Position
    end

    return nil
end

local function GetPromptPosition(prompt)
    local parent = prompt and prompt.Parent
    if not parent then
        return nil
    end

    if parent:IsA("Attachment") then
        return parent.WorldPosition
    end

    if parent:IsA("BasePart") then
        return parent.Position
    end

    local part = parent:FindFirstAncestorWhichIsA("BasePart")
    return part and part.Position
end

local function FirePrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false
    end

    if typeof(fireproximityprompt) ~= "function" then
        warn("[Zinc] fireproximityprompt is unavailable")
        return false
    end

    local ok = pcall(function()
        fireproximityprompt(prompt)
    end)

    return ok
end

local function TeleportTo(position)
    local root = GetRoot()
    if not root then
        return false
    end

    return pcall(function()
        root.CFrame = CFrame.new(position)
    end)
end

local function FlyTo(targetPosition, shouldContinue)
    while true do
        if shouldContinue and not shouldContinue() then
            return false
        end

        local root = GetRoot()
        if not root then
            return false
        end

        local offset = targetPosition - root.Position
        local distance = offset.Magnitude

        if distance <= FLY_ARRIVE_DISTANCE then
            return true
        end

        local direction = offset.Unit
        local moveAmount = math.min(FLY_STEP_DISTANCE, distance)
        local nextPosition = root.Position + direction * moveAmount

        local ok = pcall(function()
            root.CFrame = CFrame.lookAt(
                nextPosition,
                nextPosition + direction
            )
        end)

        if not ok then
            return false
        end

        task.wait(STEP_DELAY)
    end
end

local function PromptStillValid(prompt)
    return prompt ~= nil
        and prompt.Parent ~= nil
        and prompt.Enabled
end

local function NameContainsAny(value, keywords)
    local normalized = NormalizeName(value)

    for _, keyword in ipairs(keywords) do
        if string.find(normalized, NormalizeName(keyword), 1, true) then
            return true
        end
    end

    return false
end

local function IsGhostFishingName(value)
    local name = NormalizeName(value)

    return string.find(name, "ghostfisherman", 1, true) ~= nil
        or string.find(name, "ghostfishing", 1, true) ~= nil
        or string.find(name, "ghostfisher", 1, true) ~= nil
end

local function IsRunningMonster(token)
    return MonsterEnabled and FarmToken == token
end

local function IsRunningLilPump(token)
    return LilPumpEnabled and LilPumpToken == token
end

local function IsRunningEcho(token)
    return EchoEnabled and EchoToken == token
end

local function IsRunningGhost(token)
    return GhostEnabled and GhostToken == token
end

local function WaitWhileRunning(seconds, shouldContinue)
    local finish = os.clock() + seconds

    while os.clock() < finish do
        if shouldContinue and not shouldContinue() then
            return false
        end

        task.wait(0.05)
    end

    return true
end

local function FindPromptInside(target)
    if not target then
        return nil
    end

    for _, object in ipairs(target:GetDescendants()) do
        if object:IsA("ProximityPrompt") and object.Enabled then
            return object
        end
    end

    if target:IsA("ProximityPrompt") and target.Enabled then
        return target
    end

    return nil
end

local function FindPromptNearTarget(target, maxDistance)
    if not target then
        return nil
    end

    local targetPosition = GetObjectPosition(target)
    if not targetPosition then
        return nil
    end

    local bestPrompt
    local bestDistance = maxDistance or 12

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("ProximityPrompt") and object.Enabled then
            local position = GetPromptPosition(object)

            if position then
                local distance = (position - targetPosition).Magnitude

                if distance <= bestDistance then
                    bestPrompt = object
                    bestDistance = distance
                end
            end
        end
    end

    return bestPrompt
end

local function FindPromptForCharacter(character)
    local prompt = FindPromptInside(character)
    if prompt then
        return prompt
    end

    return FindPromptNearTarget(character, 12)
end

local function FindNamedCharacter(nameCheck)
    local bestObject
    local bestPosition
    local bestDistance = math.huge
    local root = GetRoot()

    for _, object in ipairs(Workspace:GetDescendants()) do
        if (object:IsA("Model") or object:IsA("BasePart"))
            and nameCheck(object.Name) then

            local position = GetObjectPosition(object)

            if position then
                local distance = root
                    and (position - root.Position).Magnitude
                    or 0

                if distance < bestDistance then
                    bestObject = object
                    bestPosition = position
                    bestDistance = distance
                end
            end
        end
    end

    return bestObject, bestPosition
end

local function IsGhostVacuumTool(object)
    if not object or not object:IsA("Tool") then
        return false
    end

    return NameContainsAny(object.Name, GHOST_TOOL_NAMES)
        or (
            string.find(NormalizeName(object.Name), "ghost", 1, true)
            and string.find(NormalizeName(object.Name), "vacuum", 1, true)
        )
end

local function FindGhostVacuum()
    local character = GetCharacter()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    if character then
        for _, object in ipairs(character:GetChildren()) do
            if IsGhostVacuumTool(object) then
                return object, true
            end
        end
    end

    if backpack then
        for _, object in ipairs(backpack:GetChildren()) do
            if IsGhostVacuumTool(object) then
                return object, false
            end
        end
    end

    return nil, false
end

local function EquipGhostVacuum()
    local tool, equipped = FindGhostVacuum()

    if not tool then
        return nil
    end

    if equipped then
        return tool
    end

    local humanoid = GetHumanoid()
    if not humanoid then
        return nil
    end

    local ok = pcall(function()
        humanoid:EquipTool(tool)
    end)

    if not ok then
        return nil
    end

    task.wait(0.25)

    local equippedTool, isEquipped = FindGhostVacuum()
    if isEquipped then
        return equippedTool
    end

    return nil
end

local function ActivateVacuum(tool)
    if not tool or not tool.Parent then
        return false
    end

    return pcall(function()
        tool:Activate()
    end)
end

local function IsWeaponName(name)
    local normalized = NormalizeName(name)

    for _, alias in ipairs(WeaponAliases) do
        local candidate = NormalizeName(alias)

        if normalized == candidate then
            return true
        end

        if #candidate >= 3
            and string.find(normalized, candidate, 1, true) then
            return true
        end
    end

    return false
end

local function FindWeapon(container)
    if not container then
        return nil
    end

    for _, object in ipairs(container:GetChildren()) do
        if object:IsA("Tool") and IsWeaponName(object.Name) then
            return object
        end
    end

    return nil
end

local function EquipWeapon()
    local character = GetCharacter()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local humanoid = GetHumanoid()

    if not character or not backpack or not humanoid then
        return false
    end

    if FindWeapon(character) then
        return true
    end

    local tool = FindWeapon(backpack)
    if not tool then
        return false
    end

    local ok = pcall(function()
        humanoid:EquipTool(tool)
    end)

    if not ok then
        return false
    end

    task.wait(0.1)
    return FindWeapon(character) ~= nil
end

local function FindMonsterFolder()
    local dimension = Workspace:FindFirstChild("HalloweenDimension")

    if not dimension then
        for _, object in ipairs(Workspace:GetDescendants()) do
            if object.Name == "HalloweenDimension" then
                dimension = object
                break
            end
        end
    end

    if not dimension then
        return nil
    end

    local direct = dimension:FindFirstChild("Monsters")
    if direct then
        return direct
    end

    for _, object in ipairs(dimension:GetDescendants()) do
        if object.Name == "Monsters" then
            return object
        end
    end

    return nil
end

local function GetMobRoot(mob)
    if not mob then
        return nil
    end

    if mob:IsA("BasePart") then
        return mob
    end

    if mob:IsA("Model") then
        return mob:FindFirstChild("HumanoidRootPart")
            or mob.PrimaryPart
            or mob:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function GetMobName(mob)
    return mob:GetAttribute("MonsterName")
        or mob:GetAttribute("Name")
        or mob.Name
end

local function IsAlive(mob)
    if not mob or not mob.Parent then
        return false
    end

    if mob:IsA("Model") then
        local humanoid = mob:FindFirstChildWhichIsA("Humanoid", true)

        if humanoid and humanoid.Health <= 0 then
            return false
        end
    end

    return GetMobRoot(mob) ~= nil
end

local function GetMobList()
    local folder = FindMonsterFolder()
    local mobs = {}

    if not folder then
        return mobs
    end

    for _, object in ipairs(folder:GetChildren()) do
        if (object:IsA("Model") or object:IsA("BasePart"))
            and IsAlive(object) then
            table.insert(mobs, object)
        end
    end

    return mobs
end

local function GetMonsterTypes()
    local types = {"All"}
    local seen = {}

    for _, mob in ipairs(GetMobList()) do
        local name = tostring(GetMobName(mob))

        if not seen[name] then
            seen[name] = true
            table.insert(types, name)
        end
    end

    table.sort(types, function(a, b)
        if a == "All" then
            return true
        end

        if b == "All" then
            return false
        end

        return a < b
    end)

    return types
end

local function RefreshMonsterDropdown()
    if MonsterDropdown then
        pcall(function()
            MonsterDropdown:Refresh(GetMonsterTypes())
        end)
    end
end

local function MatchesMonster(mob, targetName)
    local name = NormalizeName(GetMobName(mob))
    local target = NormalizeName(targetName)

    return name == target
        or string.find(name, target, 1, true) ~= nil
end

local function IsValidMonster(mob)
    local folder = FindMonsterFolder()

    if not folder or not IsAlive(mob) then
        return false
    end

    if not mob:IsDescendantOf(folder) then
        return false
    end

    return SelectedMonster == "All"
        or MatchesMonster(mob, SelectedMonster)
end

local function FindMonsterTarget()
    local root = GetRoot()
    if not root then
        return nil
    end

    local mobs = GetMobList()

    for _, priority in ipairs(MonsterPriority) do
        if SelectedMonster == "All"
            or NormalizeName(SelectedMonster) == NormalizeName(priority) then

            local best
            local bestDistance = math.huge

            for _, mob in ipairs(mobs) do
                if IsValidMonster(mob) and MatchesMonster(mob, priority) then
                    local mobRoot = GetMobRoot(mob)

                    if mobRoot then
                        local distance = (mobRoot.Position - root.Position).Magnitude

                        if distance < bestDistance then
                            best = mob
                            bestDistance = distance
                        end
                    end
                end
            end

            if best then
                return best
            end
        end
    end

    if SelectedMonster == "All" then
        local best
        local bestDistance = math.huge

        for _, mob in ipairs(mobs) do
            if IsValidMonster(mob) then
                local mobRoot = GetMobRoot(mob)

                if mobRoot then
                    local distance = (mobRoot.Position - root.Position).Magnitude

                    if distance < bestDistance then
                        best = mob
                        bestDistance = distance
                    end
                end
            end
        end

        return best
    end

    return nil
end

local function TeleportToMonster(position, token)
    if not IsRunningMonster(token) then
        return false
    end

    local root = GetRoot()
    if not root then
        return false
    end

    local ok = pcall(function()
        root.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
    end)

    if not ok then
        return false
    end

    task.wait(MONSTER_TELEPORT_DELAY)
    return IsRunningMonster(token)
end

local function AttackMonster(mob)
    if not EquipWeapon() then
        task.wait(SCAN_DELAY)
        return
    end

    local character = GetCharacter()
    local tool = character and FindWeapon(character)

    if tool then
        pcall(function()
            tool:Activate()
        end)
    end

    task.wait(ATTACK_DELAY)
end

local function MonsterFarmLoop(token)
    while IsRunningMonster(token) do
        local root = GetRoot()

        if not root then
            task.wait(SCAN_DELAY)
            continue
        end

        if not FindMonsterFolder() then
            CurrentTarget = nil
            task.wait(0.5)
            continue
        end

        if not IsValidMonster(CurrentTarget) then
            CurrentTarget = FindMonsterTarget()
        end

        if not CurrentTarget then
            task.wait(SCAN_DELAY)
            continue
        end

        local mobRoot = GetMobRoot(CurrentTarget)

        if not mobRoot then
            CurrentTarget = nil
            task.wait(SCAN_DELAY)
            continue
        end

        local distance = (mobRoot.Position - root.Position).Magnitude

        if distance > ATTACK_DISTANCE then
            TeleportToMonster(mobRoot.Position, token)
        else
            AttackMonster(CurrentTarget)

            if not IsValidMonster(CurrentTarget) then
                CurrentTarget = nil
            end
        end
    end
end

local function IsLilPumpName(name)
    return NormalizeName(name) == "lilpump"
end

local function FindLilPumpCaches()
    local results = {}
    local root = GetRoot()
    local origin = root and root.Position or Vector3.zero

    for _, object in ipairs(Workspace:GetDescendants()) do
        if IsLilPumpName(object.Name)
            and (object:IsA("Model") or object:IsA("BasePart")) then

            local position = GetObjectPosition(object)

            if position
                and (position - origin).Magnitude <= LILPUMP_SCAN_RADIUS then
                table.insert(results, {
                    Object = object,
                    Position = position
                })
            end
        end
    end

    return results
end

local function FindPumpkinDeposit()
    local exactNames = {
        giantpumpkin = true,
        pumpkinaltar = true
    }

    local root = GetRoot()
    local bestObject
    local bestDistance = math.huge

    for _, object in ipairs(Workspace:GetDescendants()) do
        if (object:IsA("Model") or object:IsA("BasePart"))
            and exactNames[NormalizeName(object.Name)] then

            local position = GetObjectPosition(object)

            if position then
                local distance = root
                    and (position - root.Position).Magnitude
                    or 0

                if distance < bestDistance then
                    bestObject = object
                    bestDistance = distance
                end
            end
        end
    end

    return bestObject
end

local function CacheStillExists(cacheObject)
    return cacheObject ~= nil
        and cacheObject:IsDescendantOf(Workspace)
        and IsLilPumpName(cacheObject.Name)
end

local function LilPumpLoop(token)
    while IsRunningLilPump(token) do
        local caches = FindLilPumpCaches()
        local root = GetRoot()

        if #caches == 0 or not root then
            task.wait(SCAN_DELAY)
            continue
        end

        table.sort(caches, function(a, b)
            local currentRoot = GetRoot()

            if not currentRoot then
                return false
            end

            return (a.Position - currentRoot.Position).Magnitude
                < (b.Position - currentRoot.Position).Magnitude
        end)

        local cacheObject = caches[1].Object
        local cachePosition = GetObjectPosition(cacheObject)

        if not cachePosition then
            task.wait(SCAN_DELAY)
            continue
        end

        if not TeleportTo(cachePosition) then
            task.wait(SCAN_DELAY)
            continue
        end

        task.wait(LILPUMP_CACHE_WAIT)

        if not IsRunningLilPump(token) then
            break
        end

        if not CacheStillExists(cacheObject) then
            task.wait(SCAN_DELAY)
            continue
        end

        local pickupPrompt = FindPromptInside(cacheObject)

        if not pickupPrompt then
            pickupPrompt = FindPromptNearTarget(cacheObject, 12)
        end

        if not pickupPrompt or not FirePrompt(pickupPrompt) then
            task.wait(SCAN_DELAY)
            continue
        end

        task.wait(LILPUMP_PROMPT_DELAY)

        if not IsRunningLilPump(token) then
            break
        end

        local deposit = FindPumpkinDeposit()
        local depositPosition = GetObjectPosition(deposit)

        if not deposit or not depositPosition then
            task.wait(1)
            continue
        end

        if not TeleportTo(depositPosition) then
            task.wait(SCAN_DELAY)
            continue
        end

        task.wait(0.2)

        if not IsRunningLilPump(token) then
            break
        end

        local depositPrompt = FindPromptInside(deposit)

        if not depositPrompt then
            depositPrompt = FindPromptNearTarget(deposit, 12)
        end

        if depositPrompt and IsRunningLilPump(token) then
            FirePrompt(depositPrompt)
            task.wait(LILPUMP_PROMPT_DELAY)
        else
            Notify("Auto Lil Pump", "Không tìm thấy prompt nộp bí ngô")
            task.wait(1)
        end

        task.wait(SCAN_DELAY)
    end
end

local function EchoNameMatches(value)
    local name = NormalizeName(value)

    if IsGhostFishingName(name) then
        return false
    end

    for _, keyword in ipairs(EchoKeywords) do
        if string.find(name, NormalizeName(keyword), 1, true) then
            return true
        end
    end

    return false
end

local function EchoPromptMatches(prompt)
    local current = prompt

    for _ = 1, 8 do
        if not current then
            break
        end

        if IsGhostFishingName(current.Name) then
            return false
        end

        if EchoNameMatches(current.Name) then
            return true
        end

        if current:IsA("ProximityPrompt") then
            if IsGhostFishingName(current.ActionText)
                or IsGhostFishingName(current.ObjectText) then
                return false
            end

            if EchoNameMatches(current.ActionText)
                or EchoNameMatches(current.ObjectText) then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

local function FindEchoPrompt()
    local root = GetRoot()

    if not root then
        return nil
    end

    local bestPrompt
    local bestDistance = math.huge

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("ProximityPrompt")
            and object.Enabled
            and EchoPromptMatches(object) then

            local position = GetPromptPosition(object)

            if position then
                local distance = (position - root.Position).Magnitude

                if distance < bestDistance then
                    bestPrompt = object
                    bestDistance = distance
                end
            end
        end
    end

    return bestPrompt
end

local function FindEchoCharacter()
    return FindNamedCharacter(function(name)
        local normalized = NormalizeName(name)

        if IsGhostFishingName(normalized) then
            return false
        end

        return normalized == "echo"
            or string.find(normalized, "echonpc", 1, true) ~= nil
    end)
end

local function FindGhostFishingCharacter()
    return FindNamedCharacter(IsGhostFishingName)
end

local function WaitForEchoToStop(echoCharacter, isRunning)
    local lastPosition
    local stoppedSince
    local startTime = os.clock()

    while isRunning() do
        if not echoCharacter
            or not echoCharacter:IsDescendantOf(Workspace) then
            return false
        end

        local position = GetObjectPosition(echoCharacter)

        if not position then
            task.wait(ECHO_SCAN_DELAY)
            continue
        end

        if lastPosition then
            local movement = (position - lastPosition).Magnitude

            if movement <= ECHO_STOP_MOVEMENT_THRESHOLD then
                stoppedSince = stoppedSince or os.clock()

                if os.clock() - stoppedSince >= ECHO_STOP_DURATION then
                    return true
                end
            else
                stoppedSince = nil
            end
        end

        lastPosition = position

        if os.clock() - startTime >= ECHO_STOP_TIMEOUT then
            return false
        end

        task.wait(ECHO_STOP_CHECK_INTERVAL)
    end

    return false
end

local function InteractOnceWithCharacter(character, isRunning, label)
    if not character or not character:IsDescendantOf(Workspace) then
        return false
    end

    local prompt = FindPromptForCharacter(character)
    if not prompt or not PromptStillValid(prompt) then
        Notify("Echo Quest", "Không tìm thấy prompt: " .. label)
        return false
    end

    local position = GetPromptPosition(prompt)

    if position then
        local root = GetRoot()

        if root and (root.Position - position).Magnitude > 8 then
            local moved = FlyTo(position + ECHO_TELEPORT_OFFSET, isRunning)

            if not moved or not isRunning() then
                return false
            end
        end
    else
        local characterPosition = GetObjectPosition(character)

        if characterPosition then
            if not TeleportTo(characterPosition + ECHO_TELEPORT_OFFSET) then
                return false
            end
        end
    end

    if not isRunning() or not PromptStillValid(prompt) then
        return false
    end

    local fired = FirePrompt(prompt)
    task.wait(ECHO_PROMPT_DELAY)

    return fired
end

local function EchoQuestLoop(token)
    local function isRunning()
        return IsRunningEcho(token)
    end

    Notify("Echo Quest", "Đang tìm prompt nhiệm vụ Echo...")

    while isRunning() do
        if not GetRoot() then
            task.wait(ECHO_SCAN_DELAY)
            continue
        end

        local echoPrompt = FindEchoPrompt()

        if not echoPrompt then
            task.wait(ECHO_SCAN_DELAY)
            continue
        end

        local promptPosition = GetPromptPosition(echoPrompt)

        if not promptPosition then
            task.wait(ECHO_SCAN_DELAY)
            continue
        end

        local root = GetRoot()

        if root and (root.Position - promptPosition).Magnitude > 8 then
            FlyTo(promptPosition + ECHO_TELEPORT_OFFSET, isRunning)
        end

        if not isRunning() then
            break
        end

        if PromptStillValid(echoPrompt) then
            FirePrompt(echoPrompt)
        end

        task.wait(ECHO_PROMPT_DELAY)

        if not isRunning() then
            break
        end

        Notify("Echo Quest", "Đang chờ Echo xuất hiện...")

        local echoCharacter
        local findStart = os.clock()

        while isRunning() and not echoCharacter do
            echoCharacter = FindEchoCharacter()

            if not echoCharacter then
                if os.clock() - findStart > 60 then
                    Notify("Echo Quest", "Chưa tìm thấy Echo, tiếp tục quét...")
                    findStart = os.clock()
                end

                task.wait(ECHO_SCAN_DELAY)
            end
        end

        if not isRunning() then
            break
        end

        if not echoCharacter then
            continue
        end

        Notify("Echo Quest", "Đang theo dõi Echo...")

        local lastPosition = GetObjectPosition(echoCharacter)

        while isRunning() do
            if not echoCharacter:IsDescendantOf(Workspace) then
                echoCharacter = FindEchoCharacter()

                if not echoCharacter then
                    task.wait(ECHO_SCAN_DELAY)
                    continue
                end
            end

            local echoPosition = GetObjectPosition(echoCharacter)
            local rootNow = GetRoot()

            if not echoPosition or not rootNow then
                task.wait(ECHO_SCAN_DELAY)
                continue
            end

            if (rootNow.Position - echoPosition).Magnitude > ECHO_FOLLOW_DISTANCE then
                FlyTo(echoPosition + ECHO_TELEPORT_OFFSET, function()
                    return isRunning()
                        and echoCharacter ~= nil
                        and echoCharacter:IsDescendantOf(Workspace)
                end)
            end

            local ghostCharacter, ghostPosition = FindGhostFishingCharacter()

            if ghostCharacter and ghostPosition
                and (ghostPosition - echoPosition).Magnitude
                    <= GHOST_FISHING_TRIGGER_DISTANCE then
                break
            end

            lastPosition = echoPosition
            task.wait(ECHO_SCAN_DELAY)
        end

        if not isRunning() then
            break
        end

        Notify("Echo Quest", "Đợi Echo dừng lại...")

        local stopped = WaitForEchoToStop(echoCharacter, isRunning)

        if not isRunning() then
            break
        end

        if not stopped then
            Notify("Echo Quest", "Chưa xác nhận Echo đã dừng, tiếp tục theo dõi...")
            task.wait(ECHO_SCAN_DELAY)
            continue
        end

        Notify("Echo Quest", "Echo đã dừng, đang tương tác một lần...")

        local echoTalked = InteractOnceWithCharacter(
            echoCharacter,
            isRunning,
            "Echo"
        )

        if not isRunning() then
            break
        end

        if not echoTalked then
            Notify("Echo Quest", "Không thể tương tác với Echo")
            break
        end

        Notify("Echo Quest", "Đang tìm Ghost Fisherman...")

        local fishingMan
        local fishingStart = os.clock()

        while isRunning() and not fishingMan do
            fishingMan = FindGhostFishingCharacter()

            if not fishingMan then
                if os.clock() - fishingStart > 60 then
                    Notify("Echo Quest", "Chưa tìm thấy Ghost Fisherman...")
                    fishingStart = os.clock()
                end

                task.wait(ECHO_SCAN_DELAY)
            end
        end

        if not isRunning() then
            break
        end

        if not fishingMan then
            break
        end

        Notify("Echo Quest", "Đang tương tác Ghost Fisherman một lần...")

        local fishingTalked = InteractOnceWithCharacter(
            fishingMan,
            isRunning,
            "Ghost Fisherman"
        )

        if fishingTalked then
            Notify("Echo Quest", "Đã hoàn thành luồng tương tác")
        else
            Notify("Echo Quest", "Không thể tương tác với Ghost Fisherman")
        end

        break
    end
end

local function FindTrain()
    local bestObject
    local bestPosition
    local bestDistance = math.huge
    local root = GetRoot()

    for _, object in ipairs(Workspace:GetDescendants()) do
        if (object:IsA("Model") or object:IsA("BasePart"))
            and NameContainsAny(object.Name, TRAIN_NAMES) then

            local position = GetObjectPosition(object)

            if position then
                local distance = root
                    and (position - root.Position).Magnitude
                    or 0

                if distance < bestDistance then
                    bestObject = object
                    bestPosition = position
                    bestDistance = distance
                end
            end
        end
    end

    return bestObject, bestPosition
end

local function FindTrainPrompt(train)
    return FindPromptInside(train)
end

local function FindGhostTargets()
    local results = {}
    local seen = {}
    local character = GetCharacter()

    for _, object in ipairs(Workspace:GetDescendants()) do
        if (object:IsA("Model") or object:IsA("BasePart"))
            and NameContainsAny(object.Name, GHOST_TARGET_NAMES)
            and not IsGhostFishingName(object.Name)
            and not (character and object:IsDescendantOf(character)) then

            local position = GetObjectPosition(object)

            if position and not seen[object] then
                seen[object] = true

                table.insert(results, {
                    Object = object,
                    Position = position
                })
            end
        end
    end

    return results
end

local function FindGhostPrompt(ghost)
    return FindPromptInside(ghost)
end

local function GhostVacuumLoop(token)
    local lastStatus = 0
    local boardingAttempted = false

    local function isRunning()
        return IsRunningGhost(token)
    end

    local function status(message)
        if os.clock() - lastStatus >= 4 then
            Notify("Auto Ghost", message)
            lastStatus = os.clock()
        end
    end

    while isRunning() do
        if not GetRoot() then
            task.wait(GHOST_SCAN_DELAY)
            continue
        end

        local vacuum = EquipGhostVacuum()

        if not vacuum then
            status("Đang tìm Ghost Vacuum trong Backpack...")
            task.wait(GHOST_SCAN_DELAY)
            continue
        end

        if not boardingAttempted then
            local train, trainPosition = FindTrain()

            if train and trainPosition then
                status("Đang tìm prompt lên Phantom Express...")

                local prompt = FindTrainPrompt(train)

                if prompt then
                    local promptPosition = GetPromptPosition(prompt)

                    if promptPosition then
                        local root = GetRoot()

                        if root and (root.Position - promptPosition).Magnitude > 8 then
                            FlyTo(promptPosition + Vector3.new(0, 2, 0), isRunning)
                        end

                        if isRunning() and PromptStillValid(prompt) then
                            FirePrompt(prompt)
                            boardingAttempted = true
                            Notify("Auto Ghost", "Đã thử kích hoạt prompt lên tàu")
                            task.wait(2)
                        end
                    end
                else
                    local root = GetRoot()

                    if root and (root.Position - trainPosition).Magnitude > 8 then
                        FlyTo(trainPosition + Vector3.new(0, 3, 0), isRunning)
                    end

                    status("Đã tìm thấy tàu nhưng chưa thấy prompt lên tàu")
                    task.wait(1)
                end
            else
                status("Đang dò Phantom Express trong Workspace...")
                task.wait(GHOST_SCAN_DELAY)
                continue
            end
        end

        if not isRunning() then
            break
        end

        vacuum = EquipGhostVacuum()

        if not vacuum then
            task.wait(GHOST_SCAN_DELAY)
            continue
        end

        local ghosts = FindGhostTargets()
        local root = GetRoot()

        if #ghosts == 0 or not root then
            status("Đang tìm ma trong khu vực...")
            task.wait(GHOST_SCAN_DELAY)
            continue
        end

        table.sort(ghosts, function(a, b)
            local currentRoot = GetRoot()

            if not currentRoot then
                return false
            end

            return (a.Position - currentRoot.Position).Magnitude
                < (b.Position - currentRoot.Position).Magnitude
        end)

        local ghost = ghosts[1].Object
        local position = GetObjectPosition(ghost)

        if not position then
            task.wait(GHOST_SCAN_DELAY)
            continue
        end

        local distance = (root.Position - position).Magnitude

        if distance > GHOST_APPROACH_DISTANCE then
            FlyTo(position + Vector3.new(0, 2, 0), function()
                if not isRunning() then
                    return false
                end

                if not ghost or not ghost:IsDescendantOf(Workspace) then
                    return false
                end

                local currentRoot = GetRoot()
                local currentPosition = GetObjectPosition(ghost)

                return currentRoot ~= nil
                    and currentPosition ~= nil
                    and (currentRoot.Position - currentPosition).Magnitude
                        > GHOST_APPROACH_DISTANCE
            end)
        end

        if not isRunning() then
            break
        end

        vacuum = EquipGhostVacuum()

        if vacuum then
            ActivateVacuum(vacuum)

            local prompt = FindGhostPrompt(ghost)

            if prompt and PromptStillValid(prompt) then
                FirePrompt(prompt)
            end

            task.wait(GHOST_PROMPT_DELAY)
        else
            task.wait(GHOST_SCAN_DELAY)
        end
    end
end

HalloweenTab:Section({
    Title = "Monster Farm"
})

MonsterDropdown = HalloweenTab:Dropdown({
    Title = "Select Monster",
    Desc = "Choose the monster type",
    Values = {"All"},
    Value = "All",
    AllowNone = false,
    Callback = function(value)
        if typeof(value) == "table" then
            value = value[1]
        end

        if typeof(value) == "string" then
            SelectedMonster = value
            CurrentTarget = nil
        end
    end
})

HalloweenTab:Toggle({
    Title = "Auto Farm Monster",
    Desc = "Instant teleport to monster, 0.1s delay",
    Value = false,
    Callback = function(value)
        if value and (EchoEnabled or GhostEnabled or LilPumpEnabled) then
            Notify("Zinc Hub", "Tắt các chức năng di chuyển khác trước")
            return
        end

        MonsterEnabled = value
        FarmToken += 1
        CurrentTarget = nil

        if not value then
            return
        end

        local token = FarmToken

        task.spawn(function()
            for _ = 1, 10 do
                if not IsRunningMonster(token) then
                    return
                end

                RefreshMonsterDropdown()
                task.wait(0.2)
            end
        end)

        task.spawn(function()
            local ok, err = pcall(function()
                MonsterFarmLoop(token)
            end)

            if not ok then
                warn("[Zinc] Monster Farm Error:", err)
                Notify("Zinc Hub", "Monster Farm error")
            end
        end)
    end
})

HalloweenTab:Section({
    Title = "Lil Pump"
})

HalloweenTab:Toggle({
    Title = "Auto Lil Pump",
    Desc = "Scan Workspace, collect pumpkins, deliver to altar",
    Value = false,
    Callback = function(value)
        if value and (EchoEnabled or GhostEnabled or MonsterEnabled) then
            Notify("Zinc Hub", "Tắt các chức năng di chuyển khác trước")
            return
        end

        LilPumpEnabled = value
        LilPumpToken += 1

        if not value then
            Notify("Zinc Hub", "Auto Lil Pump stopped")
            return
        end

        if typeof(fireproximityprompt) ~= "function" then
            LilPumpEnabled = false
            Notify("Zinc Hub", "fireproximityprompt is unavailable")
            return
        end

        local token = LilPumpToken

        task.spawn(function()
            local ok, err = pcall(function()
                LilPumpLoop(token)
            end)

            if not ok then
                warn("[Zinc] Auto Lil Pump Error:", err)
                Notify("Zinc Hub", "Auto Lil Pump error")
            end
        end)

        Notify("Zinc Hub", "Auto Lil Pump enabled")
    end
})

HalloweenTab:Section({
    Title = "Echo Quest"
})

HalloweenTab:Toggle({
    Title = "Auto Echo quest & Get fishing rod",
    Desc = "Interact with Echo once, wait for it to stop, then Ghost Fisherman once",
    Value = false,
    Callback = function(value)
        if value and (MonsterEnabled or LilPumpEnabled or GhostEnabled) then
            Notify("Zinc Hub", "Tắt các chức năng di chuyển khác trước")
            return
        end

        EchoEnabled = value
        EchoToken += 1

        if not value then
            Notify("Zinc Hub", "Auto Echo Quest stopped")
            return
        end

        if typeof(fireproximityprompt) ~= "function" then
            EchoEnabled = false
            Notify("Zinc Hub", "fireproximityprompt is unavailable")
            return
        end

        local token = EchoToken

        task.spawn(function()
            local ok, err = pcall(function()
                EchoQuestLoop(token)
            end)

            if not ok then
                warn("[Zinc] Auto Echo Quest Error:", err)
                Notify("Zinc Hub", "Auto Echo Quest error")
            end

            if EchoToken == token then
                EchoEnabled = false
            end
        end)

        Notify("Zinc Hub", "Auto Echo Quest enabled")
    end
})

HalloweenTab:Section({
    Title = "Ghost Vacuum"
})

HalloweenTab:Toggle({
    Title = "Auto Ghost",
    Desc = "Equip Ghost Vacuum, search Phantom Express and vacuum nearby ghosts",
    Value = false,
    Callback = function(value)
        if value and (MonsterEnabled or LilPumpEnabled or EchoEnabled) then
            Notify("Zinc Hub", "Tắt Monster Farm, Lil Pump và Echo Quest trước")
            return
        end

        GhostEnabled = value
        GhostToken += 1

        if not value then
            Notify("Zinc Hub", "Auto Ghost stopped")
            return
        end

        if typeof(fireproximityprompt) ~= "function" then
            GhostEnabled = false
            Notify("Zinc Hub", "fireproximityprompt is unavailable")
            return
        end

        local token = GhostToken

        task.spawn(function()
            local ok, err = pcall(function()
                GhostVacuumLoop(token)
            end)

            if not ok then
                warn("[Zinc] Auto Ghost Error:", err)
                Notify("Zinc Hub", "Auto Ghost error")
            end

            if GhostToken == token then
                GhostEnabled = false
            end
        end)

        Notify("Zinc Hub", "Auto Ghost enabled")
    end
})

Notify("Zinc Hub", "Halloween tab loaded")