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
local config = require('config')
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
m.timeout = 5000
m.minTimeout = 500

m.cloneTable = utils.cloneTable

--[[ Variables ]]
local hmiAppIds = {}
local ptu_table = {}

m.hmi_value = hmi_values.getDefaultHMITable()
m.hmi_value.TTS.GetCapabilities.params.speechCapabilities = { "SILENCE" }

config.application1.registerAppInterfaceParams.ttsName = {{ text = "string", type = "SILENCE" }}

local function jsonFileToTable(pFileName)
  local f = io.open(pFileName, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

--[[ @getPTUFromPTS: create policy table update table (PTU)
--! @parameters:
--! pTbl - table with policy table snapshot (PTS)
--! @return: table with PTU
--]]
local function getPTUFromPTS(tbl)
  tbl.policy_table.consumer_friendly_messages.messages = nil
  tbl.policy_table.device_data = nil
  tbl.policy_table.module_meta = nil
  tbl.policy_table.usage_and_error_counts = nil
  tbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  tbl.policy_table.module_config.preloaded_pt = nil
  tbl.policy_table.module_config.preloaded_date = nil
end

--[[ @policyTableUpdate: perform PTU
--! @parameters:
--! pPTUpdateFunc - function with additional updates (optional)
--! pExpNotificationFunc - function with specific expectations (optional)
--! @return: none
--]]
local function ptu(id, pUpdateFunction)
  local function getAppsCount()
    local count = 0
    for _ in pairs(hmiAppIds) do
      count = count + 1
    end
    return count
  end

  function m.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  if pExpNotificationFunc then
    pExpNotificationFunc()
  else
    test.hmiConnection:ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
    test.hmiConnection:ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  end
  local ptsFileName = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptuFileName = os.tmpname()
  local requestId = test.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  test.hmiConnection:ExpectResponse(requestId)
  :Do(function()
      test.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = ptsFileName })
      getPTUFromPTS(ptuTable)
      for i = 1, m.getAppsCount() do
        ptuTable.policy_table.app_policies[m.getConfigAppParams(i).appID] = m.getAppDataForPTU(i)
      end
      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
      local event = events.Event()
      event.matches = function(e1, e2) return e1 == e2 end
      EXPECT_EVENT(event, "PTU event")
      for id = 1, m.getAppsCount() do
        local session = m.getMobileSession(id)
        session:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function()
            utils.cprint(35, "App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            local corIdSystemRequest = session:SendRPC("SystemRequest",
              { requestType = "PROPRIETARY" }, ptuFileName)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                test.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                test.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
              end)
            session:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptuFileName) end)
          end)
        :Times(AtMost(1))
      end
    end)
end
end

function m.getSelfAndParams(...)
  local out = { }
  local selfIdx = nil
  for i,v in pairs({...}) do
    if type(v) == "table" and v.isTest then
      table.insert(out, v)
      selfIdx = i
      break
    end
  end
  local idx = 2
  for i = 1, table.maxn({...}) do
    if i ~= selfIdx then
      out[idx] = ({...})[i]
      idx = idx + 1
    end
  end
  return table.unpack(out, 1, table.maxn(out))
end

--[[ @activateApp: activate application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.activateApp(pAppId)
  pAppId = m.getSelfAndParams(pAppId)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
  local mobSession = m.getMobileSession(pAppId)
  local hmiConnection = m.getHMIConnection()
  local requestId = hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = m.GetAudibleState(pAppId), systemContext = "MAIN"})
  commonTestCases:DelayedExp(m.minTimeout)
end


--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pttsName - params fot items TTSChunk
--! @return: none
--]]
function m.registerApp(pAppId, pttsName)
  if not pttsName then
    pttsName = {{
      text = "string",
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

function m.getMobileAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams.appID
end

--[[ @getPathToFileInStorage: get all parameter for PutFile
--! @parameters:
--! pFileName - The path to the App Store folder with the given image name
--! @return: none 
--]]
function m.getPathToFileInStorage(pFileName)
  return commonPreconditions:GetPathToSDL() .. "storage/"
  .. config["application1"].registerAppInterfaceParams.appID .. "_"
  .. utils.getDeviceMAC() .. "/" .. pFileName
end

function m.getSmokeAppPoliciesConfig()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" }
  }
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

--[[ @SetAppType: Select an application type
--! @parameters:
--! HMIType - selected for mobile app
--! @return: none
--]]
function m.SetAppType(HMIType)
  for _,v in pairs(HMIType) do
    if v == "NAVIGATION" then
      m.HMITypeStatus["NAVIGATION"] = true
    elseif v == "COMMUNICATION" then
      m.HMITypeStatus["COMMUNICATION"] = true
    end
  end
end

--[[ @GetAudibleState: Audible State Selection
--! @parameters:
--! pAppId - Application number (1, 2, etc.)
--! @return: none
--]]
function m.GetAudibleState(pAppId)
  if not pAppId then pAppId = 1 end
  m.SetAppType(config["application" .. pAppId].registerAppInterfaceParams.appHMIType)
  if config["application" .. pAppId].registerAppInterfaceParams.isMediaApplication == true or
    m.HMITypeStatus.COMMUNICATION == true or
    m.HMITypeStatus.NAVIGATION == true then
    return "AUDIBLE"
  elseif
    config["application" .. pAppId].registerAppInterfaceParams.isMediaApplication == false then
    return "NOT_AUDIBLE"
  end
end

return m
