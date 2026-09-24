-- ===================================================================
-- Exit8 MasterMod - 게임 오브젝트 접근 & 치트/리셋 로직
--   * 세이브 완전 초기화
--   * 8번 출구 적용 / 이변 제거
--   * 통로 표지판 보호
--   * HUD 용 현재 복도 상태 읽기
-- ===================================================================

local UEHelpers = require("UEHelpers")
local Util = require("exit8.util")

local Game = {}
local Config

local CLASS_CHANGE_MANAGER = "BP_ChangeManager_C"
local CLASS_START_PATH = "BP_PathBP_C"   -- 0번 시작 복도
local CLASS_LOOP_PATH = "BP_PathBP1_C"   -- 1~8번 순환 복도
local CLASS_GAME_INSTANCE = "GameInstance_Exit8_C"

function Game.Init(config)
    Config = config
end

-- ===================================================================
-- 오브젝트 캐시
-- FindAllOf 는 GUObjectArray 전체를 훑기 때문에 매 틱 부르면 게임 스레드가 끊긴다.
-- 목록을 저장해 두고 일정 틱마다, 또는 캐시된 오브젝트가 무효화됐을 때만 다시 탐색한다.
-- ===================================================================
local CACHE_REFRESH_TICKS = 8
local cache = {}

local function Rescan(className)
    local list = {}
    local found = FindAllOf(className)
    if found then
        for _, obj in ipairs(found) do
            if obj:IsValid() then
                list[#list + 1] = obj
            end
        end
    end
    cache[className] = { objs = list, age = 0 }
    return list
end

local function GetAll(className, forceRefresh)
    local entry = cache[className]
    if forceRefresh or not entry or entry.age >= CACHE_REFRESH_TICKS then
        return Rescan(className)
    end
    for _, obj in ipairs(entry.objs) do
        if not obj:IsValid() then
            -- 레벨 전환 등으로 하나라도 사라졌으면 즉시 새로 탐색
            return Rescan(className)
        end
    end
    return entry.objs
end

local function GetAllPaths(forceRefresh)
    local paths = {}
    for _, path in ipairs(GetAll(CLASS_START_PATH, forceRefresh)) do paths[#paths + 1] = path end
    for _, path in ipairs(GetAll(CLASS_LOOP_PATH, forceRefresh)) do paths[#paths + 1] = path end
    return paths
end

-- 틱마다 한 번 호출 (캐시 나이 증가)
function Game.Tick()
    for _, entry in pairs(cache) do
        entry.age = entry.age + 1
    end
end

function Game.GetChangeManager(forceRefresh)
    return GetAll(CLASS_CHANGE_MANAGER, forceRefresh)[1]
end

-- ===================================================================
-- 1. [이변 제거] 현재 통로의 모든 이상현상 즉시 소멸 및 정상 복원
-- ===================================================================
function Game.ClearAllAnomalies(forceRefresh)
    -- 전역 매니저와 각 통로의 ChangeMana 는 보통 같은 객체이므로 주소로 중복 제거
    local cleared = {}
    local function Clear(mgr)
        if not Util.IsValid(mgr) then return end
        local address = mgr:GetAddress()
        if cleared[address] then return end
        cleared[address] = true

        Util.Set(mgr, "Change", false)
        Util.Call(mgr, "SetNoChange")
    end

    Clear(Game.GetChangeManager(forceRefresh))
    for _, path in ipairs(GetAllPaths(forceRefresh)) do
        Clear(Util.Get(path, "ChangeMana"))
    end
end

-- ===================================================================
-- 2. [표지판 보호] 통로 표지판 안전 복원/유지
-- ===================================================================
local SIGN_COMPONENTS = { "Sign", "Widget1", "Sign_Number" }

function Game.EnsureSignVisible(path)
    if not Util.IsValid(path) then return end
    local number = Util.Get(path, "Number")

    -- 표지판 이변(BP_ChangeActor_Sign)이 진행 중이면 8번 출구가 아닐 때는 간섭하지 않음
    local signActorComp = Util.Get(path, "BP_ChangeActor_Sign")
    local hasSignAnomaly = Util.IsValid(signActorComp) and Util.IsValid(Util.Get(signActorComp, "ChildActor"))
    if hasSignAnomaly and number ~= 8 then
        return
    end

    -- 게임 내부 HiddenSignMesh 로 표지판 가시성 복원
    Util.Call(path, "HiddenSignMesh", true)

    -- 천장 표지판 메쉬/위젯 컴포넌트 가시성 강제 유지
    for _, name in ipairs(SIGN_COMPONENTS) do
        local comp = Util.Get(path, name)
        if Util.IsValid(comp) then
            Util.Call(comp, "SetVisibility", true, true)
        end
    end

    -- 번호 텍스트 위젯 갱신
    local signWidget = Util.Get(path, "As W Sign", "As_W_Sign")
    if number ~= nil and Util.IsValid(signWidget) then
        Util.Call(signWidget, "SetNumberText", number)
    end
end

local function IsComponentHidden(path, name)
    local comp = Util.Get(path, name)
    if not Util.IsValid(comp) then return false end
    local ok, visible = pcall(function() return comp:IsVisible() end)
    return ok and visible == false
end

-- 평상시 가디언: 표지판이 사라진 순환 통로만 복원
function Game.GuardSigns()
    for _, path in ipairs(GetAll(CLASS_LOOP_PATH)) do
        if IsComponentHidden(path, "Sign") or IsComponentHidden(path, "Widget1") then
            Game.EnsureSignVisible(path)
        end
    end
end

-- ===================================================================
-- 3. [기능 1] 세이브 및 해금 데이터 완전 초기화 (Clean Vanilla Reset)
-- ===================================================================
local function GetGameInstance()
    local gi = UEHelpers.GetGameInstance()
    if Util.IsValid(gi) then return gi end
    gi = FindFirstOf(CLASS_GAME_INSTANCE)
    if Util.IsValid(gi) then return gi end
    return nil
end

local function GetSaveClear(gi)
    local saveClear = Util.Get(gi, "Save Clear", "Save_Clear")
    if Util.IsValid(saveClear) then return saveClear end

    -- 세이브 객체가 아직 없으면 GetClearSaveData(out) 로 받아본다
    local out = {}
    if Util.Call(gi, "GetClearSaveData", out) then
        saveClear = out[1] or out["Clear Savedata"] or Util.Get(gi, "Save Clear", "Save_Clear")
        if Util.IsValid(saveClear) then return saveClear end
    end
    return nil
end

local function ResetSaveClearObject(saveClear)
    Util.Log("Resetting SaveClear [0x%X] to fresh vanilla state...", saveClear:GetAddress())

    -- 클리어 / 모든 이변 발견 / 튜토리얼 완료 플래그 해제
    Util.Set(saveClear, "Clear", false)
    Util.Set(saveClear, "AllAno", false)
    Util.Set(saveClear, "EndTutorial", false)

    -- 전체 이변 목록을 미발견 이변 목록으로 100% 복원
    local ok, err = pcall(function()
        local allAno = saveClear["All Anomaly"]
        local notFound = saveClear["Not Found Anomaly"]
        if allAno and notFound then
            notFound:Empty()
            for i = 1, #allAno do
                notFound[#notFound + 1] = allAno[i]
            end
            Util.Log("Restored all %d anomalies back into 'Not Found Anomaly'!", #allAno)
        end
    end)
    if not ok then Util.Log("Failed to restore anomaly list: %s", tostring(err)) end

    -- 하드 이변 목록 비우기
    pcall(function()
        local hard = saveClear["Hard Anomaly"]
        if hard then hard:Empty() end
    end)

    -- 이변 컷신 영상 플래그 전부 false
    pcall(function()
        local movies = saveClear.AnoMovie
        if movies then
            for i = 1, #movies do
                movies[i] = false
            end
            Util.Log("Reset all AnoMovie flags to false.")
        end
    end)
end

-- 반환값: GameInstance 를 찾아 초기화를 수행했으면 true
function Game.ResetSaveData()
    Util.Log("Executing FULL RESET of all save data and unlock progress...")

    local gi = GetGameInstance()
    if not gi then
        Util.Log("GameInstance not available yet. Waiting for game load...")
        return false
    end
    Util.Log("Found GameInstance: %s", gi:GetFullName())

    -- 1) 걸음 수 초기화
    Util.Set(gi, "WalkCount", 0)

    -- 2) GameInstance 이변 배열 초기화 (모든 이변을 미발견 상태로)
    if Util.Call(gi, { "Reset AnomalyArray", "Reset_AnomalyArray" }) then
        Util.Log("Called GameInstance:Reset AnomalyArray()")
    end

    -- 3) 세이브 데이터 객체(USave_Clear_C) 순정 상태로 리셋
    local saveClear = GetSaveClear(gi)
    if saveClear then
        ResetSaveClearObject(saveClear)
    end

    -- 4) 세이브 슬롯 초기화 및 클린 저장
    if Util.Call(gi, { "Delete Game SaveData", "Delete_Game_SaveData" }) then
        Util.Log("Called GameInstance:Delete Game SaveData()")
    end
    Util.Call(gi, "SaveClearParam", false)
    if Util.Call(gi, "SaveGameSlot_Clear") then
        Util.Log("Saved clean pristine state to Save.sav!")
    end

    -- 5) 개발자 내장 이변 리셋 이벤트 (Shift+A)
    local pc = UEHelpers.GetPlayerController()
    if Util.IsValid(pc) and Util.Call(pc, "InpActEvt_Shift_A_K2Node_InputDebugKeyEvent_1", {}, {}) then
        Util.Log("Invoked GamePC:InpActEvt_Shift_A (Developer Reset Anomaly)")
    end

    -- 6) 맵 내 잔여 이변 안내 포스터 갱신
    local loopPaths = GetAll(CLASS_LOOP_PATH, true)
    for _, path in ipairs(loopPaths) do
        Util.Call(path, { "Set Anomaly Amount Poster", "Set_Anomaly_Amount_Poster" })
    end
    if #loopPaths > 0 then
        Util.Log("Updated Anomaly Amount Poster in level to clean state.")
    end

    Util.Log(">>> [SUCCESS] Completely reset all save data and unlocks to fresh vanilla state! <<<")
    return true
end

-- ===================================================================
-- 4. [기능 2] 8번 출구 적용 (BP_PathBP_C / BP_PathBP1_C 모두)
-- 멱등(idempotent): 몇 번을 호출해도 결과가 같으므로 가디언 루프에서 반복 호출해도 안전
-- ===================================================================
local function SetPathToExit8(path)
    Util.Set(path, "Number", 8)
    Util.Set(path, "EndTutorial", true)

    if Config.DisableAnomaliesAtExit8 then
        local mgr = Util.Get(path, "ChangeMana")
        if Util.IsValid(mgr) then
            Util.Set(mgr, "Change", false)
            Util.Call(mgr, "SetNoChange")
        end
    end
end

local function OpenExitStairs(path)
    -- 8번 출구 계단 액터(BP_Exit) 스폰 및 개방
    Util.Call(path, "NextExit")

    -- BP_Exit 액터 번호와 표지판도 8로 동기화
    local exit = Util.Get(path, "Exit")
    if Util.IsValid(exit) then
        Util.Set(exit, "Number", 8)
        local exitSign = Util.Get(exit, "As W Sign", "As_W_Sign")
        if Util.IsValid(exitSign) then
            Util.Call(exitSign, "SetNumberText", 8)
        end
    end
end

-- 반환값: 적용한 통로가 하나라도 있으면 true
function Game.ApplyExit8(forceRefresh)
    if Config.DisableAnomaliesAtExit8 then
        Game.ClearAllAnomalies(forceRefresh)
    end

    local pathCount = 0

    -- 시작 통로(BP_PathBP_C)
    for _, path in ipairs(GetAll(CLASS_START_PATH, forceRefresh)) do
        pathCount = pathCount + 1
        SetPathToExit8(path)
        Game.EnsureSignVisible(path)
    end

    -- 메인 순환 통로(BP_PathBP1_C)
    for _, path in ipairs(GetAll(CLASS_LOOP_PATH, forceRefresh)) do
        pathCount = pathCount + 1
        SetPathToExit8(path)
        OpenExitStairs(path)
        Game.EnsureSignVisible(path)
    end

    -- 통로 처리 도중 새로 생긴 이변까지 재차 차단
    if Config.DisableAnomaliesAtExit8 then
        Game.ClearAllAnomalies()
    end

    return pathCount > 0
end

-- ===================================================================
-- 5. HUD 용 현재 복도 상태 읽기
-- ===================================================================
local function FirstPathNumber(className)
    for _, path in ipairs(GetAll(className)) do
        local number = Util.Get(path, "Number")
        if number ~= nil then return number end
    end
    return nil
end

-- 반환: { found, number, anomalyActive, anomalyClass, anomalyTag }
function Game.ReadCorridorState()
    local state = { found = false, number = nil, anomalyActive = false, anomalyClass = "", anomalyTag = "" }

    local mgr = Game.GetChangeManager()
    if mgr then
        state.found = true

        local currentPath = Util.Get(mgr, "CurrentPathBP")
        if Util.IsValid(currentPath) then
            state.number = Util.Get(currentPath, "Number")
        end

        -- Change 플래그가 이번 복도의 이변 여부를 결정하는 게임 내부 값
        state.anomalyActive = Util.Get(mgr, "Change") == true
        state.anomalyTag = Util.TagName(Util.Get(mgr, "CurrentChangeTag"))

        local actor = Util.Get(mgr, "CurrentChangeActor")
        if Util.IsValid(actor) then
            state.anomalyClass = Util.ClassName(actor)
        end
    end

    if state.number == nil then
        state.number = FirstPathNumber(CLASS_LOOP_PATH) or FirstPathNumber(CLASS_START_PATH)
        if state.number ~= nil then state.found = true end
    end
    state.number = state.number or 0

    return state
end

return Game
