---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")
local json = require("modules/json")

--[[ Module ]]
local c = actions

--[[ Variables ]]
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[ Common Functions ]]
function c.registerAppWithOnDD(pAppId)
  c.registerApp(pAppId)
  c.getMobileSession(pAppId):ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
end

function c.onDriverDistraction(pLockScreenDismissalEnabled)
  local function msg(pValue)
    return "Parameter `lockScreenDismissalEnabled` is transfered to Mobile with `" .. tostring(pValue) .. "` value"
  end
  c.getHMIConnection():SendNotification("UI.OnDriverDistraction", { state = "DD_OFF" })
  c.getHMIConnection():SendNotification("UI.OnDriverDistraction", { state = "DD_ON" })
  c.getMobileSession():ExpectNotification("OnDriverDistraction",
    { state = "DD_OFF" },
    { state = "DD_ON", lockScreenDismissalEnabled = pLockScreenDismissalEnabled })
  :ValidIf(function(e, d)
      if e.occurences == 1 and d.payload.lockScreenDismissalEnabled ~= nil then
        return false, d.payload.state .. ": " .. msg(d.payload.lockScreenDismissalEnabled)
      end
      return true
    end)
  :ValidIf(function(e, d)
      if e.occurences == 2 and pLockScreenDismissalEnabled == nil and d.payload.lockScreenDismissalEnabled ~= nil then
        return false, d.payload.state .. ": " .. msg(d.payload.lockScreenDismissalEnabled)
      end
      return true
    end)
  :Times(2)
end

local preconditionsOrig = c.preconditions
function c.preconditions()
  preconditionsOrig()
  commonPreconditions:BackupFile(preloadedPT)
end

local postconditionsOrig = c.postconditions
function c.postconditions()
  postconditionsOrig()
  commonPreconditions:RestoreFile(preloadedPT)
end

function c.updatePreloadedPT(pLockScreenDismissalEnabled, pUpdateFunc)
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.module_config.lock_screen_dismissal_enabled = pLockScreenDismissalEnabled
  if pUpdateFunc then
    pUpdateFunc(pt)
  end
  utils.tableToJsonFile(pt, preloadedFile)
end

local function deactivateAppToLimited()
  c.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = c.getHMIAppId() })
  c.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function deactivateAppToBackground()
  c.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "AUDIO_SOURCE", isActive = true
  })
  c.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

c.hmiLevel = {
  [1] = { name = "NONE", func = function() end },
  [2] = { name = "FULL", func = c.activateApp },
  [3] = { name = "LIMITED", func = deactivateAppToLimited },
  [4] = { name = "BACKGROUND", func = deactivateAppToBackground }
}

c.pairs = utils.spairs

return c
