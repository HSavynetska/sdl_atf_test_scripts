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

local function changeRegistrationSuccess()
  local requestParams = {
    language ="EN-US",
    hmiDisplayLanguage ="EN-US",
    appName ="SyncProxyTester",
    ttsName = {
      {
        text ="SyncProxyTester",
        type ="FILE",
      },
    },
    ngnMediaScreenAppName ="SPT",
    vrSynonyms = {
      "VRSyncProxyTester",
    }
  }
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("ChangeRegistration", requestParams)

  EXPECT_HMICALL("UI.ChangeRegistration", {
    appName = requestParams.appName,
    language = requestParams.hmiDisplayLanguage,
    ngnMediaScreenAppName = requestParams.ngnMediaScreenAppName,
    appID = common.getHMIAppId()
  })
  :Do(function(_, data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("VR.ChangeRegistration", {
    language = requestParams.language,
    vrSynonyms = requestParams.vrSynonyms,
    appID = common.getHMIAppId()
  })
  :Do(function(_, data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

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
runner.Step("App registration", common.registerApp, {1, pttsName})
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("ChangeRegistration Positive Case", changeRegistrationSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
