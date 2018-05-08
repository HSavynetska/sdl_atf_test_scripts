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
-- 1)  HMI provides ‘FILE’ item in ‘speechCapabilities’ parameter of ‘TTS.GetCapabilities’ response
-- 2) New app registers and send PerformInteraction with ‘FILE’ item in ‘initialPrompt’, ‘helpPrompt’, ‘timeoutPrompt’ parameters
-- SDL does:
-- 1) Send VR.PerformInteraction request to HMI with ‘FILE’ item in ‘initialPrompt’, ‘helpPrompt’, ‘timeoutPrompt’ parameters
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

local requestParams = {
  initialText = "initialText",
  initialPrompt = {
    {
      text = "text1",
      type = "FILE"
    },
  },
  interactionMode = "BOTH",
  interactionChoiceSetIDList = {
  100
  },
  helpPrompt = {
    {
      text = "text2",
      type = "FILE"
    },
  },
  timeoutPrompt = {
    {
      text = "text3",
      type = "FILE"
    },
  },
  timeout = 5000,
}

local responseUiParams = {
  timeout = requestParams.timeout,
  interactionChoiceSetIDList = requestParams.choiceSet,
  initialText = requestParams.initialText
}

--[[ Local Functions ]]

local function setChoiseSet(choiceIDValue)
  local temp = {
    {
      choiceID = choiceIDValue,
      menuName ="Choice" .. tostring(choiceIDValue),
      vrCommands = {
        "VrChoice" .. tostring(choiceIDValue),
      },
      image = {
        value ="icon.png",
        imageType ="STATIC",
      }
    }
  }
  return temp
end

local function SendOnSystemContext(ctx)
local hmiConnection = common.getHMIConnection()
  hmiConnection:SendNotification("UI.OnSystemContext",
    { appID = common.getHMIAppId(), systemContext = ctx })
end

local function setExChoiseSet(choiceIDValues)
  local exChoiceSet = { }
  for i = 1, #choiceIDValues do
    exChoiceSet[i] = {
      choiceID = choiceIDValues[i],
      image = {
        value = "icon.png",
        imageType = "STATIC",
      },
      menuName = "Choice" .. choiceIDValues[i]
    }
  end
  return exChoiceSet
end

local function CreateInteractionChoiceSet(choiceSetID)
  local choiceID = choiceSetID
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiseSet(choiceID),
    })
  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(choiceID) }
    })
  :Do(function(_,data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  mobSession:ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

local function PerformInteractionSuccess(paramsSend)
  paramsSend.interactionMode = "BOTH"
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("PerformInteraction",paramsSend)
  EXPECT_HMICALL("VR.PerformInteraction", {
      helpPrompt = paramsSend.helpPrompt,
      initialPrompt = paramsSend.initialPrompt,
      timeout = paramsSend.timeout,
      timeoutPrompt = paramsSend.timeoutPrompt
    })
  :Do(function(_,data)
      hmiConnection:SendNotification("VR.Started")
      hmiConnection:SendNotification("TTS.Started")
      SendOnSystemContext("VRSESSION")
      local function firstSpeakTimeOut()
        hmiConnection:SendNotification("TTS.Stopped")
        hmiConnection:SendNotification("TTS.Started")
      end
      RUN_AFTER(firstSpeakTimeOut, 5)
      local function vrResponse()
        hmiConnection:SendNotification("VR.Stopped")
      end
      RUN_AFTER(vrResponse, 20)
    end)
  EXPECT_HMICALL("UI.PerformInteraction", {
      timeout = paramsSend.timeout,
      choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
      initialText = {
        fieldName = "initialInteractionText",
        fieldText = paramsSend.initialText
      },
      vrHelpTitle = paramsSend.initialText
    })
  :Do(function(_,data)
      local function choiceIconDisplayed()
        SendOnSystemContext("HMI_OBSCURED")
      end
      RUN_AFTER(choiceIconDisplayed, 25)
      local function uiResponse()
        hmiConnection:SendNotification("TTS.Stopped")
        SendOnSystemContext("MAIN")
      end
      RUN_AFTER(uiResponse, 30)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {common.hmi_value})
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile)
runner.Step("CreateInteractionChoiceSet with id 100", CreateInteractionChoiceSet, {100})

runner.Title("Test")
runner.Step("PerformInteraction Positive Case", PerformInteractionSuccess, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

