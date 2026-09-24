-- ===================================================================
-- Exit8 MasterMod Configuration (v2.1 - Clean Exit 8 Mode)
-- 8번 출구 (The Exit 8) - 세이브 완전 초기화 & 8번 출구 무(無)이변 치트 설정
-- ===================================================================

local Config = {
    -- [기능 1] 키 입력 없는 자동 세이브/해금 완전 초기화 여부
    -- true: 게임 시작 시 기존 100% 해금 상태를 완전히 리셋하여 순정(클린 새 게임) 상태로 복원
    AutoReset = true,

    -- [기능 2] 게임 시작 시 즉시 8번 출구로 시작할지 여부
    -- false: 기본값. 원할 때 F8 또는 숫자 8 키를 눌러 8번 출구로 변경
    -- true: 게임 시작하자마자 첫 번째 복도부터 즉시 8번 출구로 생성
    AutoExit8OnStart = false,

    -- [기능 3] 8번 출구에서 이상현상(이변) 완전 차단 여부
    -- true: 8번 출구 활성화 시 모든 이변을 즉시 제거(SetNoChange)하고 정상 복도로 유지
    DisableAnomaliesAtExit8 = true,

    -- [단축키 설정] (UE4SS Key enum 이름)
    -- 8번 출구 즉시 생성 치트 키
    Key_Exit8 = "F8",
    Key_Exit8_Alt = "EIGHT",       -- 키보드 숫자 8 키도 지원

    -- 수동 세이브 완전 초기화 키 (언제든 누르면 새 게임 상태로 완전 리셋)
    Key_ManualReset = "F7",

    -- [표지판 보호] 통로 표지판 증발 방지 가디언 활성화 여부
    ProtectCorridorSign = true,

    -- UE4SS 콘솔 상세 디버그 로그 출력 여부
    DebugLogging = true
}

return Config
