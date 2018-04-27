--This script contains all test cases to verify TTSChunk parameter
--How to use:
	--1. local TTSChunkParameter = require('user_modules/shared_testcases/testCasesForTTSChunkParameter')
	--2. TTSChunkParameter:verify_TTSChunk_Parameter(Request, Parameter, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForTTSChunkParameter = {}

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')




---------------------------------------------------------------------------------------------
--Test cases to verify a TTSChunk parameter
---------------------------------------------------------------------------------------------
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongDataType
	--4. text: minlength="0" maxlength="500" type="String"
	--5. type: type="SpeechCapabilities": "TEXT", "SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE"

	
function testCasesForTTSChunkParameter:verify_TTSChunk_Parameter(Request, Parameter, Mandatory)
	
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local resultCode = "INVALID_DATA"
		if Mandatory == false then
			resultCode = "SUCCESS"
		end
		
		commonFunctions:TestCase(self, Request, Parameter, "IsMissed", nil, resultCode)		
		
		
		--2. IsEmpty
		commonFunctions:TestCase(self, Request, Parameter, "IsEmpty", {}, "INVALID_DATA")		
		
		
		--3. IsWrongDataType
		commonFunctions:TestCase(self, Request, Parameter, "IsWrongDataType", 123, "INVALID_DATA")
		
		
		--Check parameters in side TTSChunk:
		
		--4. text: minlength="0" maxlength="500" type="String"
		local Boundary = {0, 500}
		local parameter_text = commonFunctions:BuildChildParameter(Parameter, "text")

		stringParameter:verify_String_Parameter(Request, parameter_text, Boundary, true)
		
		--5. type: type="SpeechCapabilities": "TEXT", "SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE"
		local ExistentValues = {"TEXT", "SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE"}
		local parameter_type = commonFunctions:BuildChildParameter(Parameter, "type")
		
		enumerationParameter:verify_Enum_String_Parameter(Request, parameter_type, ExistentValues, true)			

end


return testCasesForTTSChunkParameter