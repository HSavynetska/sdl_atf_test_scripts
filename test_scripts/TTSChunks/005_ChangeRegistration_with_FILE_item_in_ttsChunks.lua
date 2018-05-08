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
-- 2) New app registers and send ChangeRegistration with ‘FILE’ item in ‘ttsName’ parameter
-- SDL does:
-- 1) Send TTS.ChangeRegistration request to HMI with ‘FILE’ item in ‘ttsName’ parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local requestParams = {
  language ="EN-US",
  hmiDisplayLanguage ="EN-US",
  ttsName = {
    {
      text ="SyncProxyTester",
      type ="FILE",
    },
  },
} 

local responseUiParams = {
  hmiDisplayLanguage = requestParams.hmiDisplayLanguage
}

local responseVrParams = {
  language = requestParams.language
}

local responseTtsParams = {
  ttsChunks = requestParams.ttsChunks,
  language = requestParams.language
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
  responseVrParams = responseVrParams,
  responseTtsParams = responseTtsParams
}

local function changeRegistrationSuccess(params)
  if not pAppId then pAppId = 1 end
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("ChangeRegistration", requestParams)

  params.responseUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.ChangeRegistration", {
    language = requestParams.hmiDisplayLanguage,
    appID = common.getHMIAppId()
  })
  :Do(function(_, data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("VR.ChangeRegistration", {
    language = requestParams.language,
    appID = common.getHMIAppId()
  })
  :Do(function(_, data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  params.responseTtsParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("TTS.ChangeRegistration", {
    language = requestParams.language,
    ttsName = requestParams.ttsName,
    appID = common.getHMIAppId()
  })
  :Do(function(_, data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {common.hmi_value})
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("ChangeRegistration Positive Case", changeRegistrationSuccess, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
