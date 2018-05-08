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
-- 2) New app registers and send AlertManeuver with ‘FILE’ item in ‘ttsChunks’ parameter
-- SDL does:
-- 1) Send TTS.Speak request to HMI with ‘FILE’ item in ‘ttsChunks’ parameter 
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  ttsChunks = {
    {
      text = "FirstAlert",
      type = "FILE",
    },
    {
      text = "SecondAlert",
      type = "FILE",
    },
  },
}

local responseTtsParams = {
  ttsChunks = requestParams.ttsChunks
}

local allParams = {
  requestParams = requestParams,
  responseTtsParams = responseTtsParams
}

--[[ Local Functions ]]
local function PTUpdateFunc(tbl)
  local AlertMgroup = {
    rpcs = {
      AlertManeuver = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
      }
    }
  }
  tbl.policy_table.functional_groupings.NewTestCaseGroup = AlertMgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
  { "Base-4", "NewTestCaseGroup" }
end

local function alertManeuver(pParams)
	local mobSession = common.getMobileSession()
	local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("AlertManeuver", pParams.requestParams)
  EXPECT_HMICALL("Navigation.AlertManeuver", pParams.responseNaviParams)
  :Do(function(_, data)
    local function alertResp()
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end
    RUN_AFTER(alertResp, 2000)
  end)
  EXPECT_HMICALL("TTS.Speak", pParams.responseTtsParams)
  :Do(function(_, data)
    hmiConnection:SendNotification("TTS.Started")
    local function SpeakResp()
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      hmiConnection:SendNotification("TTS.Stopped")
    end
    RUN_AFTER(SpeakResp, 1000)
  end)
  mobSession:ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("AlertManeuver Positive Case", alertManeuver, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)