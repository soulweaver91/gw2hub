privilegeLevels = require './privilegelevels'

module.exports =
    requireLoggedIn: (req, res, next) ->
        if !req.isAuthenticated()
            res.status 403
            .json { status: 403, error: 'not logged in' }
        else
            next()

    requireMinPrivilegeLevel: (level) ->
        (req, res, next) ->
            if !req.isAuthenticated()
                res.status 403
                .json { status: 403, error: 'not logged in' }
            else
                if req.user.ulevel >= level
                    return next()

                res.status 403
                .json { status: 403, error: 'insufficient privilege level' }
