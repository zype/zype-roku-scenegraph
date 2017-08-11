
' **************************************************
' State Service
'   - Service for variable states management
'
' Functions in service
'     
'
' Usage
'     state_service = StateService()
'     state_service.InitGlobalVars()
' **************************************************

Function StateService(global) as object
    this = {}
    this.global = global
    this.InitGlobalVars = function()
        ' m.global.addFields({test: true})
        ' m.global.swaf = false
        ' m.global = global
        ' print "m.global:: "; m.global
        ' print "this:: "; this
        m.global.addFields({ HasNativeSubscription: false, isLoggedIn: false, UniversalSubscriptionsCount: 0, auth: {}, usvod: {}, nsvod: {} })
        m.global.usvod = {
            UniversalSubscriptionsCount: 0,
            isLoggedInViaUniversalSVOD: false
        }

        m.global.nsvod = {
            isLoggedInViaNativeSVOD: false
        }
        _isLoggedIn = isLoggedIn()
        ' m.global.isLoggedIn = _isLoggedIn
        ' m.global.isLoggedInWithSubscription = _isLoggedIn AND (m.global.usvod.UniversalSubscriptionsCount > 0 OR m.global.nsvod.isLoggedInViaNativeSVOD = true)
        ' m.global.UniversalSubscriptionsCount = m.detailsScreen.UniversalSubscriptionsCount

        m.global.auth = {
            isLoggedIn: _isLoggedIn,
            isLoggedInWithSubscription: _isLoggedIn AND (m.global.usvod.UniversalSubscriptionsCount > 0 OR m.global.nsvod.isLoggedInViaNativeSVOD = true) 
        }

        ' print "m.global test: "; m.global
        ' print "m.global.auth: "; m.global.auth
        return this
    End Function
    return this
End Function