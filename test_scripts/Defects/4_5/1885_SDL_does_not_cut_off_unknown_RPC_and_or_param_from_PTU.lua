---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1885
-- Precondition:
-- 1. SDL and HMI are started.
-- 2. App is registered and activated
-- Steps:
-- 1. In case SDL received UpdatedPT with at least one <unknown_parameter> or <unknown_RPC>
-- Expected result:
-- SDL must cut off <unknown_parameter> or <unknown_RPC> continue validating received PTU without <unknown_parameter> or
-- <unknown_RPC> merge valid Updated PT without <unknown_parameter> or <unknown_RPC> with LocalPT in case
-- of no other failures
-- Actual result:N/A
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
-- set default parameters for 'SendLocation' RPC
local SendLocationParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
}
local unknownAPI = "UnknownAPI"
local unknownParameter = "unknownParameter"

local gpsResponse = {
  longitudeDegrees = -180,
  latitudeDegrees = 90,
  utcYear = 2100,
  utcMonth = 12,
  utcDay = 22,
  utcHours = 20,
  utcMinutes = 50,
  utcSeconds = 50,
  compassDirection = "NORTH",
  pdop = 1000,
  hdop = 1000,
  vdop = 1000,
  actual = true,
  satellites = 31,
  dimension = "2D",
  altitude = 10000,
  heading = 359.99,
  speed = 500,
  shifted = true
}

--[[ Local Functions ]]

--[[ @ptuUpdateFuncRPC: update table with unknown RPC for PTU
--! @parameters:
--! tbl - table for update
--! @return: none
--]]
local function ptuUpdateFuncRPC(tbl)
  local VDgroup = {
    rpcs = {
      [unknownAPI] = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      SendLocation = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup1"] = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
    { "Base-4", "NewTestCaseGroup1" }
end

--[[ @ptuUpdateFuncParams: update table with unknown parameters for PTU
--! @parameters:
--! tbl - table for update
--! @return: none
--]]
local function ptuUpdateFuncParams(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps", unknownParameter }
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup2"] = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
    { "Base-4", "NewTestCaseGroup1", "NewTestCaseGroup2" }
end

--[[ @SuccessfulProcessingRPC: Successful processing API
--! @parameters:
--! RPC - RPC name
--! params - RPC params for mobile request
--! interface - interface of RPC on HMI
--! self - test object
--! @return: none
--]]
local function SuccessfulProcessingRPC(RPC, params, interface)
  local cid = common.getMobileSession():SendRPC(RPC, params)
  common.getHMIConnection():ExpectRequest(interface .. "." .. RPC, params)
  -- :Do(function(_,data)
  --     self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  --   end)
  :Do(function(_, data)
    if RPC == "GetVehicleData" then
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {gps = gpsResponse})
    elseif
      RPC == "SubscribeVehicleData" then
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      {gps = { dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS" }})
    else
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end
  end)
  common.getMobileSession():ExpectResponse(cid,{ success = true, resultCode = "SUCCESS" })
end

--[[ @DisallowedRPC: Unsuccessful processing of API with Disallowed status
--! @parameters:
--! RPC - RPC name
--! params - RPC params for mobile request
--! interface - interface of RPC on HMI
--! self - test object
--! @return: none
--]]
local function DisallowedRPC(RPC, params, interface)
  local cid = common.getMobileSession():SendRPC(RPC, params)
  common.getHMIConnection():ExpectRequest(interface .. "." .. RPC)
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerApp)
runner.Step("Activate App1", common.activateApp)

runner.Title("Test")
runner.Step("PTU update with unknown API", common.policyTableUpdate, { ptuUpdateFuncRPC })
runner.Step("Check applying of PT by processing SendLocation", SuccessfulProcessingRPC,
  { "SendLocation", SendLocationParams, "Navigation" })
runner.Step("Register App2", common.registerApp, {2})
runner.Step("PTU update with unknown API", common.policyTableUpdate, { ptuUpdateFuncParams })

runner.Step("Check applying of PT by processing GetVehicleData", SuccessfulProcessingRPC,
  { "GetVehicleData", { gps = true }, "VehicleInfo" })
runner.Step("Check applying of PT by processing SubscribeVehicleData", DisallowedRPC,
  { "SubscribeVehicleData", { gps = true }, "VehicleInfo" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
