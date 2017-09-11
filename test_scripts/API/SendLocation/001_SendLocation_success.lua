---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) Application is registered with REMOTE_CONTROL appHMIType
-- 2) and sends valid SetInteriorVehicleData RPC with valid parameters
-- SDL must:
-- 1) Transfer this request to HMI
-- 2) Respond with <result_code> received from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common_send_location = require('test_scripts/API/SendLocation/common_send_location')

--[[ Local Variables ]]
local request_params = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    address = {
        countryName = "countryName",
        countryCode = "countryName",
        postalCode = "postalCode",
        administrativeArea = "administrativeArea",
        subAdministrativeArea = "subAdministrativeArea",
        locality = "locality",
        subLocality = "subLocality",
        thoroughfare = "thoroughfare",
        subThoroughfare = "subThoroughfare"
    },
    timestamp = {
        second = 40,
        minute = 30,
        hour = 14,
        day = 25,
        month = 5,
        year = 2017,
        tz_hour = 5,
        tz_minute = 30
    },
    locationName = "location Name",
    locationDescription = "location Description",
    addressLines = 
    { 
        "line1",
        "line2",
    }, 
    phoneNumber = "phone Number",
    deliveryMode = "PROMPT",
    locationImage = 
    { 
        value = "icon.png",
        imageType = "DYNAMIC",
    }
}

--[[ Local Functions ]]
local function send_location(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        --hmi side: sending Navigation.SendLocation response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function ptu_update_func(tbl)
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups = { "Base-4", "SendLocation" }
end

local function put_file(file_name, self)
    local CorIdPutFile = self.mobileSession1:SendRPC(
      "PutFile",
      {syncFileName = file_name, fileType = "GRAPHIC_PNG", persistentFile = false, systemFile = false},
      "files/icon.png")

    self.mobileSession1:ExpectResponse(CorIdPutFile, { success = true, resultCode = "SUCCESS"})
    :Timeout(10000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common_send_location.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common_send_location.start)
runner.Step("RAI, PTU", common_send_location.rai_ptu)
runner.Step("Activate App", common_send_location.activate_app)
runner.Step("Upload file", put_file, {"icon.png"})

runner.Title("Test")
runner.Step("SendLocation - all params ", send_location, { request_params })

runner.Title("Postconditions")
runner.Step("Stop SDL", common_send_location.postconditions)
