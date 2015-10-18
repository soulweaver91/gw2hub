privilegeLevels = require './privilegelevels'
httpStatus = require 'http-status-codes'

module.exports =
    requireLoggedIn: (req, res, next) ->
        if !req.isAuthenticated()
            res.status httpStatus.FORBIDDEN
            .json { status: httpStatus.FORBIDDEN, error: 'not logged in' }
        else
            next()

    requireMinPrivilegeLevel: (level) ->
        (req, res, next) ->
            if !req.isAuthenticated()
                res.status httpStatus.FORBIDDEN
                .json { status: httpStatus.FORBIDDEN, error: 'not logged in' }
            else
                if req.user.ulevel >= level
                    return next()

                res.status httpStatus.FORBIDDEN
                .json { status: httpStatus.FORBIDDEN, error: 'insufficient privilege level' }

    requireMinPrivilegeLevelOrSelfID: (level, paramName) ->
        (req, res, next) ->
            if !req.isAuthenticated()
                res.status httpStatus.FORBIDDEN
                .json { status: httpStatus.FORBIDDEN, error: 'not logged in' }
            else
                if req.user.ulevel >= level
                    return next()

                if req.user.id == parseInt req.params[paramName]
                    return next()

                res.status httpStatus.FORBIDDEN
                .json { status: httpStatus.FORBIDDEN, error: 'insufficient privilege level' }
