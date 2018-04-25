---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Module ]]
local m = actions

--[[ @getPutFileAllParams: get all parameter for PutFile
--! @parameters: none
--! @return: parameters for PutFile
--]]
local function getPutFileAllParams()
  return {
    syncFileName = "icon.png",
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false,
    offset = 0,
    length = 11600
  }
end

function m.getPathToFileInStorage(pFileName)
  return commonPreconditions:GetPathToSDL() .. "storage/"
  .. config["application1"].registerAppInterfaceParams.appID .. "_"
  .. utils.getDeviceMAC() .. "/" .. pFileName
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
    cid = mobSession:SendRPC("PutFile", pParamsSend, "files/icon_png.png") --?
  end

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end 

--[[ @AddSubMenu: Successful processing AddSubMenu RPC
--! @parameters:
--! params - Parameters for AddSubMenu RPC
--! pAppId - Application number (1, 2, etc.)
--! @return: none
--]]
function m.AddSubMenu(params, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local cid = mobSession:SendRPC("AddSubMenu", params.requestParams)

  params.responseUiParams.appID = m.getHMIAppId()
  EXPECT_HMICALL("UI.AddSubMenu", params.responseUiParams)
  :Do(function(_,data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  mobSession:ExpectNotification("OnHashChange")
end

return m
