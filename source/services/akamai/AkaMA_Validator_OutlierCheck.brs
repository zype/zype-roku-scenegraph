' Validator /  outlier check
' This file checks for outliers as well as provides
' validation functions for validating inputs, urls,
' params etc

function AkaMA_Validator_OutlierCheck() as integer
return {
    urlValidator : validateURL
 }
end function