httpStatus = require 'http-status-codes'

module.exports = {
    databaseError: (res) ->
        console.trace()

        res.status httpStatus.INTERNAL_SERVER_ERROR
        .json { status: httpStatus.INTERNAL_SERVER_ERROR, error: 'database error' }
    badID: (res) ->
        res.status httpStatus.NOT_FOUND
        .json { status: httpStatus.NOT_FOUND, error: 'no such id' }
}
