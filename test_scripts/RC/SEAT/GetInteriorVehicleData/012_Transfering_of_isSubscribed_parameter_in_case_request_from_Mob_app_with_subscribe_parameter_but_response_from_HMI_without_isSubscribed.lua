---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description: TRS: GetInteriorVehicleData, #1
-- In case:
-- 1) RC app sends valid and allowed by policies GetInteriorvehicleData_request with "subscribe" parameter
-- 2) and SDL received GetInteriorVehicledata_response with resultCode: <"any_not_erroneous_result">
-- 3) and without "isSubscribed" parameter from HMI
-- SDL must:
-- 1) transfer GetInteriorVehicleData_response with resultCode:<"any_not_erroneous_result">
-- and with added isSubscribed: <"current_subscription_status"> to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getDataForModule(pModuleType, isSubscriptionActive, pSubscribe)
  local mobSession = commonRC.getMobileSession()
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
  local cid = mobSession:SendRPC("GetInteriorVehicleData", {
=======
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
>>>>>>> Changes were done to the rc_seat
    moduleType = pModuleType,
    subscribe = pSubscribe
  })

  local pSubscribeHMI = pSubscribe
  if isSubscriptionActive == pSubscribe then
    pSubscribeHMI = nil
  end

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = commonRC.getHMIAppId(),
    moduleType = pModuleType
  })
  :Do(function(_, data)
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
       commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
=======
      commonRC.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
>>>>>>> Changes were done to the rc_seat
        moduleData = commonRC.getModuleControlData(pModuleType),
        -- no isSubscribed parameter
      })
    end)
  :ValidIf(function(_, data)
      if data.params.subscribe == pSubscribeHMI then
        return true
      end
      return false, 'Parameter "subscribe" is transfered to HMI with value: ' .. tostring(data.params.subscribe)
    end)
<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
=======
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
>>>>>>> Changes were done to the rc_seat
    isSubscribed = isSubscriptionActive, -- return current value of subscription
    moduleData = commonRC.getModuleControlData(pModuleType)
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData SEAT NoSubscription_subscribe", getDataForModule, { "SEAT", false, true })
runner.Step("GetInteriorVehicleData SEAT NoSubscription_unsubscribe", getDataForModule, { "SEAT", false, false })

<<<<<<< 8ac10e1aed2095231a6cb629ea8cf692e92074a9
runner.Step("Subscribe app to SEAT", commonRC.subscribeToModule, { "SEAT" })
runner.Step("GetInteriorVehicleData SEAT ActiveSubscription_subscribe", getDataForModule, { "SEAT", true, true })
runner.Step("GetInteriorVehicleData SEAT ActiveSubscription_unsubscribe", getDataForModule, { "SEAT", true, false })
=======
runner.Step("GetInteriorVehicleData SEAT NoSubscription_subscribe", getDataForModule, { SEAT, false, true })
runner.Step("GetInteriorVehicleData SEAT NoSubscription_unsubscribe", getDataForModule, { SEAT, false, false })


runner.Step("Subscribe app to SEAT", commonRC.subscribeToModule, { SEAT })
runner.Step("GetInteriorVehicleData SEAT ActiveSubscription_subscribe", getDataForModule, { SEAT, true, true })
runner.Step("GetInteriorVehicleData SEAT ActiveSubscription_unsubscribe", getDataForModule, { SEAT, true, false })

>>>>>>> Changes were done to the rc_seat

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
