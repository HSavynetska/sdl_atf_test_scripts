---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0014-adding-audio-file-playback-to-ttschunk.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) HMI provides ‘FILE’ item in ‘speechCapabilities’ parameter of ‘TTS.GetCapabilities’ response 
-- 2) New app registers and send PerformAudioPassThru with ‘FILE’ item in ‘initialPrompt’ parameter
-- SDL does:
-- 1) Send TTS.Speak request to HMI with ‘FILE’ item in ‘ttsChunks’ parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local requestParams = {
  initialPrompt = {
    {
      text = "Makeyourchoice",
      type = "FILE",
    },
  },
  audioPassThruDisplayText1 = "DisplayText1",
  audioPassThruDisplayText2 = "DisplayText2",
  samplingRate = "8KHZ",
  maxDuration = 2000,
  bitsPerSample = "8_BIT",
  audioType = "PCM",
  muteAudio = true
}

local requestUiParams = {
  audioPassThruDisplayTexts = { },
  maxDuration = requestParams.maxDuration,
  muteAudio = requestParams.muteAudio
}

requestUiParams.audioPassThruDisplayTexts[1] = {
  fieldName = "audioPassThruDisplayText1",
  fieldText = requestParams.audioPassThruDisplayText1
}

requestUiParams.audioPassThruDisplayTexts[2] = {
  fieldName = "audioPassThruDisplayText2",
  fieldText = requestParams.audioPassThruDisplayText2
}

local requestTtsParams = {}
requestTtsParams.ttsChunks = commonFunctions:cloneTable(requestParams.initialPrompt)
requestTtsParams.speakType = "AUDIO_PASS_THRU"

local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams,
  requestTtsParams = requestTtsParams
}

--[[ Local Functions ]]
local function file_check(file_name)
  local file_found = io.open(file_name, "r")
  if nil == file_found then
    return false
  end
  return true
end

local function sendOnSystemContext(pCtx, pAppID)
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  hmiConnection:SendNotification("UI.OnSystemContext",
    { appID = pAppID, systemContext = pCtx })
end

local function performAudioPassThru(pParams)
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("PerformAudioPassThru", pParams.requestParams)
  pParams.requestUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("TTS.Speak", pParams.requestTtsParams)
  :Do(function(_,data)
    hmiConnection:SendNotification("TTS.Started")
    local function ttsSpeakResponse()
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      hmiConnection:SendNotification("TTS.Stopped")
    end
    RUN_AFTER(ttsSpeakResponse, 50)
  end)
  EXPECT_HMICALL("UI.PerformAudioPassThru", pParams.requestUiParams)
  :Do(function(_,data)
    sendOnSystemContext("HMI_OBSCURED", pParams.requestUiParams.appID)
    local function uiResponse()
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      sendOnSystemContext("MAIN", pParams.requestUiParams.appID)
    end
    RUN_AFTER(uiResponse, 1500)
  end)
  EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = pParams.requestUiParams.appID})
  mobSession:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(4)
  mobSession:ExpectNotification("OnAudioPassThru")
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function()
    local file = commonPreconditions:GetPathToSDL() .. "storage/" .. "audio.wav"
    if true ~= file_check(file) then
      return false, "Can not found file: audio.wav"
    end
    return true
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {common.hmi_value})
runner.Step("App registration", common.registerApp, {1, pttsName})
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("PerformAudioPassThru Positive Case", performAudioPassThru, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
