---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
-- [SDL_RC] Policy support of basic RC functionality
--
-- Description:
-- In case:
-- 1) "moduleType" in app's assigned policies has an empty array
-- 2) and RC app sends GetInteriorVehicleData request with valid parameters
-- SDL must:
-- 1) Allow this RPC to be processed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')
local json = require('modules/json')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDataForModule(pModuleType)
  local mobSession = commonRC.getMobileSession()
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
  local cid = mobSession:SendRPC("GetInteriorVehicleData", {
=======
  local cid = mobileSession1:SendRPC("GetInteriorVehicleData", {
>>>>>>> Changes were done to the rc_seat
    moduleType = pModuleType,
    subscribe = true
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
    moduleType = pModuleType,
    subscribe = true
  })
  :Do(function(_, data)
      commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        isSubscribed = true
      })
    end)

<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
=======
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
>>>>>>> Changes were done to the rc_seat
    isSubscribed = true,
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
end

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = json.EMPTY_ARRAY
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
runner.Step("GetInteriorVehicleData SEAT", getDataForModule, { "SEAT" })
=======

runner.Step("GetInteriorVehicleData  SEAT", getDataForModule, { mod })
>>>>>>> Changes were done to the rc_seat

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)