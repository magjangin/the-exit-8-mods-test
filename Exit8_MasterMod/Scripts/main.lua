-- ===================================================================
-- Exit8 MasterMod (v2.3 - Auto-Sustaining Exit 8 Mode: 1-Press Guaranteed)
-- 8번 출구 (The Exit 8) 세이브 완전 초기화 & 즉시 8번 출구 치트 모드
-- ===================================================================

local UEHelpers = require("UEHelpers")

local Config = nil
local configSuccess, loadedConfig = pcall(require, "config")
if configSuccess and loadedConfig then
    Config = loadedConfig
else
    Config = {
        AutoReset = true,
        AutoExit8OnStart = false,
        DisableAnomaliesAtExit8 = true,
        Key_Exit8 = "F8",
        Key_Exit8_Alt = "EIGHT",
        Key_ManualReset = "F7",
        ProtectCorridorSign = true,
        DebugLogging = true
    }
end

local function Log(msg)
    if Config.DebugLogging then
        print(string.format("[Exit8_MasterMod] %s\n", tostring(msg)))
    end
end

Log("Initializing Exit8 MasterMod (v2.3 - Auto-Sustaining Exit 8 Mode)...")

local HasAutoReset = false
local HasAutoExit8Applied = false
local IsExit8CheatActive = false -- 8번 출구 치트 지속 활성화 모드 플래그

-- ===================================================================
-- 1. [이변 제거] 현재 통로의 모든 이상현상 즉시 소멸 및 정상 복원
-- ===================================================================
local function ClearAllAnomalies()
    -- 1) 전역 BP_ChangeManager_C 탐색
    local changeMana = FindFirstOf("BP_ChangeManager_C")
    if changeMana and changeMana:IsValid() then
        pcall(function()
            changeMana.Change = false
            if changeMana.SetNoChange then
                changeMana:SetNoChange()
            elseif changeMana["SetNoChange"] then
                changeMana["SetNoChange"](changeMana)
            end
        end)
    end

    -- 2) 모든 BP_PathBP1_C 및 BP_PathBP_C 액터의 ChangeMana 컴포넌트도 일괄 정리
    local classesToCheck = { "BP_PathBP1_C", "BP_PathBP_C" }
    for _, cls in ipairs(classesToCheck) do
        local paths = FindAllOf(cls)
        if paths then
            for _, path in ipairs(paths) do
                if path:IsValid() and path.ChangeMana and path.ChangeMana:IsValid() then
                    pcall(function()
                        path.ChangeMana.Change = false
                        if path.ChangeMana.SetNoChange then
                            path.ChangeMana:SetNoChange()
                        end
                    end)
                end
            end
        end
    end
end

-- ===================================================================
-- 2. [표지판 보호] 통로 표지판 안전 복원/유지 함수
-- ===================================================================
local function EnsureSignVisible(path)
    if not path or not path:IsValid() then return end

    -- 실제 '표지판 이변'(BP_ChangeActor_Sign)이 진행 중인지 안전 확인
    local hasSignAnomaly = false
    pcall(function()
        local changeSignComp = path.BP_ChangeActor_Sign
        if changeSignComp and changeSignComp:IsValid() and changeSignComp.ChildActor and changeSignComp.ChildActor:IsValid() then
            hasSignAnomaly = true
        end
    end)

    -- 8번 출구 상태가 아닐 때 실제 표지판 이변이 일어난 것이라면 간섭하지 않음
    if hasSignAnomaly and path.Number ~= 8 then
        return
    end

    -- 게임 내부의 HiddenSignMesh 함수를 통해 표지판 가시성 복원
    pcall(function()
        if path.HiddenSignMesh then
            path:HiddenSignMesh(true)
        end
    end)

    -- 천장 표지판 메쉬 컴포넌트들 가시성 강제 유지
    pcall(function()
        if path.Sign and path.Sign:IsValid() then
            path.Sign:SetVisibility(true, true)
        end
    end)
    pcall(function()
        if path.Widget1 and path.Widget1:IsValid() then
            path.Widget1:SetVisibility(true, true)
        end
    end)
    pcall(function()
        if path.Sign_Number and path.Sign_Number:IsValid() then
            path.Sign_Number:SetVisibility(true, true)
        end
    end)

    -- 번호 텍스트 위젯 갱신
    pcall(function()
        local signWidget = path["As W Sign"] or path.As_W_Sign
        if signWidget and signWidget:IsValid() and path.Number ~= nil then
            signWidget:SetNumberText(path.Number)
        end
    end)
end

-- ===================================================================
-- 3. [기능 1] 세이브 및 해금 데이터 완전 초기화 (Clean Vanilla Reset)
-- ===================================================================
local function ResetAllSaveDataAndProgress()
    Log("Executing FULL RESET of all save data and unlock progress...")

    local GI = UEHelpers.GetGameInstance()
    if not GI or not GI:IsValid() then
        GI = FindFirstOf("GameInstance_Exit8_C")
    end

    if not GI or not GI:IsValid() then
        Log("GameInstance not available yet. Waiting for game load...")
        return false
    end

    Log(string.format("Found GameInstance: %s", GI:GetFullName()))

    -- 1) 걸음 수 등 진행 변수 초기화
    pcall(function()
        GI.WalkCount = 0
    end)

    -- 2) GameInstance 이변 배열 초기화 (모든 이변을 다시 미발견 상태로 100% 원복)
    pcall(function()
        if GI["Reset AnomalyArray"] then
            GI["Reset AnomalyArray"](GI)
            Log("Called GameInstance:Reset_AnomalyArray()")
        elseif GI.Reset_AnomalyArray then
            GI:Reset_AnomalyArray()
            Log("Called GameInstance:Reset_AnomalyArray()")
        end
    end)

    -- 3) 세이브 데이터 객체 (USave_Clear_C) 순정 클린 상태로 완전 리셋
    local SaveClear = GI["Save Clear"] or GI.Save_Clear
    if not SaveClear or not SaveClear:IsValid() then
        pcall(function()
            if GI.GetClearSaveData then
                local dummy = {}
                GI:GetClearSaveData(dummy)
                SaveClear = dummy[1] or GI["Save Clear"] or GI.Save_Clear
            end
        end)
    end

    if SaveClear and SaveClear:IsValid() then
        Log(string.format("Resetting SaveClear [0x%X] to fresh vanilla state...", SaveClear:GetAddress()))

        -- 클리어 여부 해제
        SaveClear.Clear = false
        -- 모든 이변 발견 여부 해제
        SaveClear.AllAno = false
        -- 튜토리얼 완료 플래그 해제
        SaveClear.EndTutorial = false

        -- 전체 이변(All Anomaly) 목록을 미발견 이변(Not Found Anomaly) 목록에 다시 100% 복원
        pcall(function()
            local allAno = SaveClear["All Anomaly"]
            local notFound = SaveClear["Not Found Anomaly"]
            if allAno and notFound then
                notFound:Empty()
                for i = 1, #allAno do
                    notFound[#notFound + 1] = allAno[i]
                end
                Log(string.format("Restored all %d anomalies back into 'Not Found Anomaly'!", #allAno))
            end
        end)

        -- 하드 이변 목록 비우기
        pcall(function()
            local hard = SaveClear["Hard Anomaly"]
            if hard then
                hard:Empty()
            end
        end)

        -- 이변 컷신 영상 플래그 전부 초기화(false)
        pcall(function()
            local movies = SaveClear.AnoMovie
            if movies then
                for i = 1, #movies do
                    movies[i] = false
                end
                Log("Reset all AnoMovie flags to false.")
            end
        end)
    end

    -- 4) 게임 세이브 슬롯 완전 초기화 및 클린 저장
    pcall(function()
        if GI["Delete Game SaveData"] then
            GI["Delete Game SaveData"](GI)
            Log("Called GameInstance:Delete Game SaveData()")
        elseif GI.Delete_Game_SaveData then
            GI:Delete_Game_SaveData()
            Log("Called GameInstance:Delete_Game_SaveData()")
        end
    end)

    pcall(function()
        if GI.SaveClearParam then
            GI:SaveClearParam(false)
        end
    end)

    pcall(function()
        if GI.SaveGameSlot_Clear then
            GI:SaveGameSlot_Clear()
            Log("Saved clean pristine state to Save.sav!")
        end
    end)

    -- 5) 개발자 내장 이변 리셋 이벤트 호출 (Shift+A)
    pcall(function()
        local PC = UEHelpers.GetPlayerController()
        if PC and PC:IsValid() and PC.InpActEvt_Shift_A_K2Node_InputDebugKeyEvent_1 then
            PC:InpActEvt_Shift_A_K2Node_InputDebugKeyEvent_1({}, {})
            Log("Invoked GamePC:InpActEvt_Shift_A (Developer Reset Anomaly)")
        end
    end)

    -- 6) 맵 내 잔여 이변 안내 포스터 초기 상태로 갱신
    pcall(function()
        local allPaths = FindAllOf("BP_PathBP1_C")
        if allPaths then
            for _, path in ipairs(allPaths) do
                if path:IsValid() then
                    if path["Set Anomaly Amount Poster"] then
                        path["Set Anomaly Amount Poster"](path)
                    elseif path.Set_Anomaly_Amount_Poster then
                        path:Set_Anomaly_Amount_Poster()
                    end
                end
            end
            Log("Updated Anomaly Amount Poster in level to clean state.")
        end
    end)

        HasAutoReset = true
    Log(">>> [SUCCESS] Completely reset all save data and unlocks to fresh vanilla state! <<<")
    IsExit8CheatActive = false -- 리셋 시 8번 출구 치트 모드도 안전하게 해제
    return true
end

-- ===================================================================
-- 4. [기능 2] 8번 출구 적용 함수 (BP_PathBP1_C 및 BP_PathBP_C 모두 지원)
-- ===================================================================
local function ApplyExit8ToAllPaths()
    -- 1) 이변 일체 즉시 소멸
    if Config.DisableAnomaliesAtExit8 then
        ClearAllAnomalies()
    end

    local pathCount = 0

    -- 2) 시작 통로(BP_PathBP_C) 처리
    local startPaths = FindAllOf("BP_PathBP_C")
    if startPaths then
        for _, path in ipairs(startPaths) do
            if path:IsValid() then
                pathCount = pathCount + 1
                path.Number = 8
                pcall(function()
                    path.EndTutorial = true
                end)
                if Config.DisableAnomaliesAtExit8 and path.ChangeMana and path.ChangeMana:IsValid() then
                    pcall(function()
                        path.ChangeMana.Change = false
                        if path.ChangeMana.SetNoChange then
                            path.ChangeMana:SetNoChange()
                        end
                    end)
                end
                EnsureSignVisible(path)
            end
        end
    end

    -- 3) 메인 순환 통로(BP_PathBP1_C) 처리
    local loopPaths = FindAllOf("BP_PathBP1_C")
    if loopPaths then
        for idx, path in ipairs(loopPaths) do
            if path:IsValid() then
                pathCount = pathCount + 1
                path.Number = 8
                pcall(function()
                    path.EndTutorial = true
                end)

                if Config.DisableAnomaliesAtExit8 and path.ChangeMana and path.ChangeMana:IsValid() then
                    pcall(function()
                        path.ChangeMana.Change = false
                        if path.ChangeMana.SetNoChange then
                            path.ChangeMana:SetNoChange()
                        end
                    end)
                end

                -- 8번 출구 계단 액터(BP_Exit) 스폰 및 개방
                pcall(function()
                    if path.NextExit then
                        path:NextExit()
                    end
                end)

                -- BP_Exit 액터 번호와 표지판도 8로 동기화
                pcall(function()
                    if path.Exit and path.Exit:IsValid() then
                        path.Exit.Number = 8
                        local exitSignWidget = path.Exit["As W Sign"] or path.Exit.As_W_Sign
                        if exitSignWidget and exitSignWidget:IsValid() then
                            exitSignWidget:SetNumberText(8)
                        end
                    end
                end)

                EnsureSignVisible(path)
            end
        end
    end

    -- 4) 이변 재차 완벽 차단
    if Config.DisableAnomaliesAtExit8 then
        ClearAllAnomalies()
    end

    return pathCount > 0
end

-- 단축키 트리거: 8번 출구 치트 모드 활성화 (단 1회 입력으로 엔딩까지 지속 유지)
local function MakeExit8()
    Log("Triggering Instant Exit 8 Cheat (Auto-Sustaining Direct 8 Mode)...")
    IsExit8CheatActive = true -- 지속 활성화 모드 켜기!

    local success = ApplyExit8ToAllPaths()
    if success then
        Log("==================================================================")
        Log(">>> DIRECT EXIT 8 ACTIVATED (AUTO-SUSTAIN)! Walk forward to escape! <<<")
        Log("==================================================================")
    else
        Log("Warning: Path actors not ready yet. Auto-sustain guardian will lock Exit 8 as soon as loaded.")
    end
    return success
end

-- ===================================================================
-- 5. 단축키 안전 등록 (F8/숫자8 치트, F7 수동 초기화)
-- ===================================================================
local function RegisterKeySafe(keyName, callback)
    if not keyName or keyName == "" then return end
    local keyVal = Key[keyName]
    if keyVal then
        local status, err = pcall(function()
            RegisterKeyBind(keyVal, function()
                ExecuteInGameThread(callback)
            end)
        end)
        if status then
            Log(string.format("Registered hotkey: [%s]", keyName))
        else
            Log(string.format("Failed to register key [%s]: %s", keyName, tostring(err)))
        end
    else
        Log(string.format("Warning: Key '%s' not recognized in UE4SS Key enum.", keyName))
    end
end

-- 8번 출구 생성 단축키 등록 (F8 및 숫자 8)
RegisterKeySafe(Config.Key_Exit8, function()
    MakeExit8()
end)
if Config.Key_Exit8_Alt and Config.Key_Exit8_Alt ~= Config.Key_Exit8 then
    RegisterKeySafe(Config.Key_Exit8_Alt, function()
        MakeExit8()
    end)
end

-- 수동 세이브 완전 초기화 단축키 등록 (F7)
RegisterKeySafe(Config.Key_ManualReset, function()
    HasAutoReset = false
    ResetAllSaveDataAndProgress()
end)

-- ===================================================================
-- 6. 키 입력 없는 자동 실행 스케줄러 (완전 초기화)
-- ===================================================================
local function TryAutoRun()
    if Config.AutoReset and not HasAutoReset then
        ResetAllSaveDataAndProgress()
    end

    if Config.AutoExit8OnStart and not HasAutoExit8Applied then
        local success = MakeExit8()
        if success then
            HasAutoExit8Applied = true
        end
    end
end

-- 플레이어 폰 생성 시점 훅 (새 게임 시작 또는 리스폰 시)
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(Context)
    ExecuteInGameThread(function()
        IsExit8CheatActive = false -- 새 맵/리스폰 시 이전 치트 상태 리셋
        TryAutoRun()
    end)
end)

-- 백업 폴링: 게임 레벨 로드 대기 (최대 5회 시도 후 자동 종료)
local PollCount = 0
LoopAsync(2000, function()
    if HasAutoReset and (not Config.AutoExit8OnStart or HasAutoExit8Applied) then
        return true
    end

    PollCount = PollCount + 1
    ExecuteInGameThread(function()
        TryAutoRun()
    end)

    if PollCount >= 5 then
        return true
    end
    return false
end)

-- ===================================================================
-- 7. [지속 감시 & 가디언 엔진] 300ms 초고속 반응 루프
-- ===================================================================
-- 시작 직후 F8을 1번만 누르고 복도를 걸어가거나 표지판을 지나도,
-- 다음 복도가 스폰되는 즉시 8번 출구와 8번 표지판을 자동으로 유지시켜 줍니다!
LoopAsync(300, function()
    ExecuteInGameThread(function()
        -- 1) 8번 출구 치트가 켜져 있을 때: 지속적으로 출구 유지 및 이변 차단
        if IsExit8CheatActive then
            ApplyExit8ToAllPaths()
            return
        end

        -- 2) 평상시 표지판 보호 가디언
        local allPaths = FindAllOf("BP_PathBP1_C")
        if allPaths then
            for _, path in ipairs(allPaths) do
                if path:IsValid() then
                    if Config.ProtectCorridorSign then
                        local isHidden = false
                        pcall(function()
                            if path.Sign and path.Sign:IsValid() and not path.Sign:IsVisible() then
                                isHidden = true
                            elseif path.Widget1 and path.Widget1:IsValid() and not path.Widget1:IsVisible() then
                                isHidden = true
                            end
                        end)

                        if isHidden then
                            EnsureSignVisible(path)
                        end
                    end
                end
            end
        end
    end)
    return false
end)

Log("Exit8 MasterMod (v2.3 - Auto-Sustaining Exit 8 Mode) loaded successfully! Ready.")
