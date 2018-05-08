---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local hmi_values = require("user_modules/hmi_values")
local test = require("user_modules/dummy_connecttest")
local utils = require("user_modules/utils")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ Module ]]
local m = actions

m.HMITypeStatus = {
  NAVIGATION = false,
  COMMUNICATION = false
}

--[[ Variables ]]
local hmiAppIds = {}
local ptu_table = {}

m.hmi_value = hmi_values.getDefaultHMITable()
m.hmi_value.TTS.GetCapabilities.params.speechCapabilities = { "FILE" }

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pttsName - params fot items TTSChunk
--! @return: none
--]]
function m.registerAppWithTTS(pAppId, pttsName)
  if not pttsName then
    pttsName = {{
      text = "MP3_123kb.mp3",
      type = "FILE"
    }}
  end
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local hmiConnection = m.getHMIConnection()
  mobSession:StartService(7)
  :Do(function()
    local RAIparams = m.getConfigAppParams(pAppId)
    RAIparams.ttsName = pttsName
      local corId = mobSession:SendRPC("RegisterAppInterface", RAIparams)
      test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getConfigAppParams(pAppId).appName },
        ttsName = pttsName })
      :Do(function(_, d1)
          hmiAppIds[m.getConfigAppParams(pAppId).appID] = d1.params.application.appID
          test.hmiConnection:ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
          :Times(2)
          test.hmiConnection:ExpectRequest("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              test.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptuTable = utils.jsonFileToTable(d2.params.file)
            end)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ @getPutFileAllParams: get all parameter for PutFile
--! @parameters: none
--! @return: parameters for PutFile
--]]
local function getPutFileAllParams()
  return {
    syncFileName = "MP3_123kb.mp3",
    fileType = "AUDIO_MP3",
    persistentFile = false,
    systemFile = false,
    offset = 0,
    length = 11600
  }
end

--[[ @putFile: Successful processing PutFile RPC
--! @parameters:
--! pParamsSend - parameters for PutFile RPC
--! pFile - file will be used to send to SDL
--! pAppId - Application number (1, 2, etc.)
--! @return: none
--]]
function m.putFile(pParamsSend, pFile, pAppId)
  if pParamsSend then
    pParamsSend = pParamsSend
  else
    pParamsSend = getPutFileAllParams()
  end
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local cid
  if pFile ~= nil then
    cid = mobSession:SendRPC("PutFile", pParamsSend, pFile)
  else
    cid = mobSession:SendRPC("PutFile", pParamsSend, "files/".. "MP3_123kb.mp3")
  end

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end  

return m
