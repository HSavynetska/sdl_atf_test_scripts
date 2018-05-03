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
-- 2) New app registers and send Alert with ‘FILE’ item in ‘ttsChunks’ parameter
-- SDL does:
-- 1) Send TTS.Speak request to HMI with ‘FILE’ item in ‘ttsChunks’ parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local requestParams = {
	alertText1 = "alertText1",
	alertText2 = "alertText2",
	alertText3 = "alertText3",
	ttsChunks = {
		{
			text = "TTSChunk",
			type = "FILE",
		}
	},
	playTone = true,
	progressIndicator = true
}

local responseUiParams = {
	alertStrings = {
		{
			fieldName = requestParams.alertText1,
			fieldText = requestParams.alertText1
		},
		{
			fieldName = requestParams.alertText2,
			fieldText = requestParams.alertText2
		},
		{ 
			fieldName = requestParams.alertText3,
			fieldText = requestParams.alertText3
		}
	},
	alertType = "BOTH",
	progressIndicator = requestParams.progressIndicator,
}

local ttsSpeakRequestParams = {
	ttsChunks = requestParams.ttsChunks,
	speakType = "ALERT",
	playTone = requestParams.playTone
}

local allParams = {
	requestParams = requestParams,
	responseUiParams = responseUiParams,
	ttsSpeakRequestParams = ttsSpeakRequestParams
}

--[[ Local Functions ]]
local function sendOnSystemContext(pAppId, ctx)
local hmiConnection = common.getHMIConnection()
  	hmiConnection:SendNotification("UI.OnSystemContext",
  		{
  			pAppId = common.getHMIAppId(),
  			systemContext = ctx
  		})
end

local function alert(params)
	-- prepareAlertParams(params, additionalParams)

	local responseDelay = 3000
	local mobSession = common.getMobileSession()
	local hmiConnection = common.getHMIConnection()
	local cid = mobSession:SendRPC("Alert", params.requestParams)

	EXPECT_HMICALL("UI.Alert", params.responseUiParams)
	:Do(function(_,data)
		sendOnSystemContext("ALERT")

		local alertId = data.id
		local function alertResponse()
			hmiConnection:SendResponse(alertId, "UI.Alert", "SUCCESS", { })
			sendOnSystemContext("MAIN")
		end

		RUN_AFTER(alertResponse, responseDelay)
	end)

	params.ttsSpeakRequestParams.appID = common.getHMIAppId()
	EXPECT_HMICALL("TTS.Speak", params.ttsSpeakRequestParams)
	:Do(function(_,data)
		hmiConnection:SendNotification("TTS.Started")

		local speakId = data.id
		local function speakResponse()
			hmiConnection:SendResponse(speakId, "TTS.Speak", "SUCCESS", { })
			hmiConnection:SendNotification("TTS.Stopped")
		end

		RUN_AFTER(speakResponse, responseDelay - 1000)
	end)

	mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {common.hmi_value})
runner.Step("App registration", common.registerApp, {1, pttsName})
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("Alert Positive Case", alert, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
