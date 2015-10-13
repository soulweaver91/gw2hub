settings = require('../../configmanager').get()
httpStatus = require 'http-status-codes'
limiter = require 'simple-rate-limiter'
moment = require 'moment'
_ = require 'lodash'
async = require 'async'
# Not in 2.x, which is required by dependencies for now
_chunk = require 'lodash.chunk'

# Get the API request object and wrap it in a limiter. 10 requests per second should be enough considering that a lot of
# data should be cached anyway.
request = limiter(require('request').defaults {
    headers:
        'User-Agent': "GW2Hub API server v#{settings.fullAppVersion}; +https://github.com/soulweaver91/gw2hub"
        'Authorization': "Bearer #{settings.officialAPIKey}"
    baseUrl: 'https://api.guildwars2.com/v2/'
    timeout: 10000
    json: true
}).to(1).per(100)

ErrorCode =
    UNSPECIFIED_ERROR: 0
    KEY_INVALID: 1
    INSUFFICIENT_PERMISSIONS: 2
    NETWORK_ERROR: 3
    API_BAD_RESPONSE: 4
    API_ENDPOINT_NOT_FOUND: 5
    API_TIMEOUT: 6
    INVALID_WRAPPER_CALL: 7

KeyStatus =
    UNVERIFIED: 0
    VALID: 1
    INVALID: 2
    CONNECTION_ERROR: 3

state =
    keyStatus: KeyStatus.UNVERIFIED
    permissions: []
    lastSeenBuild: 0

cache = {
    responses: {}
    # in milliseconds
    timeout: 300000

    store: (path, response) ->
        @responses[path] = {
            retrievedAt: moment().valueOf()
            response: _.cloneDeep response
        }

    isStale: (path) ->
        !@responses[path]? || (moment().valueOf() - @responses[path].retrievedAt) > @timeout

    get: (path) ->
        if @responses[path]? then _.cloneDeep(@responses[path].response) else null

    purge: (all) ->
        if all
            @responses = {}
        else
            now = moment().valueOf()
            @responses = _.filter @responses, (response) ->
                (now - response.retrievedAt) <= @timeout
}

makeError = (message, type, params) ->
    e = new Error message
    e.apiError = if type? then type else ErrorCode.UNSPECIFIED_ERROR

    if params?
        e = _.extend e, params

    return e

interpreted = (cb) ->
    (err, res, body) ->
        SUCCESS_RANGE_MIN = 200
        SUCCESS_RANGE_MAX = 299

        if err?
            if err.code == 'ETIMEDOUT'
                return (cb) makeError 'request timed out', ErrorCode.API_TIMEOUT
            else
                return (cb) makeError "request failed: #{err.message}", ErrorCode.NETWORK_ERROR

        if res.statusCode == httpStatus.FORBIDDEN
            return (cb) makeError 'bad API key', ErrorCode.KEY_INVALID

        if res.statusCode == httpStatus.NOT_FOUND
            return (cb) makeError 'unknown API', ErrorCode.API_ENDPOINT_NOT_FOUND

        if !(SUCCESS_RANGE_MIN <= res.statusCode <= SUCCESS_RANGE_MAX)
            return (cb) makeError 'other non-OK response', ErrorCode.API_BAD_RESPONSE

        (cb)(null, body)

initialize = (cb) ->
    if state.keyStatus == KeyStatus.VALID
        return (cb)()

    console.log 'Connecting to the Guild Wars 2 API to check permissions for the given API key.'
    request 'tokeninfo', interpreted (err, response) ->
        if err?
            switch err.apiError
                when ErrorCode.NETWORK_ERROR
                    console.log "Connection could not be made! Error: #{err.message}"
                    state.keyStatus = KeyStatus.NETWORK_ERROR
                when ErrorCode.KEY_INVALID
                    console.log 'Connection failed: key not accepted!'
                    state.keyStatus = KeyStatus.INVALID
                when ErrorCode.API_NOT_READY
                    console.log "Code from server could not be handled, trying again later."
                    state.keyStatus = KeyStatus.UNVERIFIED
                else
                    console.log "Unexpected error: #{err.message}"
                    state.keyStatus = KeyStatus.UNVERIFIED
        else
            if response.name? && response.permissions? && _.isArray response.permissions
                console.log "Connection successful. Key: #{response.name}, permissions: #{response.permissions.join ', '}."
                state.keyStatus = KeyStatus.VALID
                state.permissions = response.permissions
            else
                console.log "Connection successful, but response was not of the expected format!"
                state.keyStatus = KeyStatus.UNVERIFIED
                err = makeError 'bad API response'

        return (cb)(err)

precheckStatus = (perm, cb) ->
    makeChoice = (err) ->
        switch state.keyStatus
            when KeyStatus.VALID
                if _.intersection(perm, state.permissions).length == perm.length
                    (cb)()
                else
                    (cb) makeError 'permission requirements not met', ErrorCode.INSUFFICIENT_PERMISSIONS, {
                        required: perm
                        have: state.permissions
                    }
            when KeyStatus.INVALID
                (cb) makeError 'bad API key', ErrorCode.KEY_INVALID
            else
                (cb)(err)

    # Attempt to verify the key first if it has failed previously.
    if [KeyStatus.UNVERIFIED, KeyStatus.CONNECTION_ERROR].indexOf state.keyStatus != false
        initialize makeChoice
    else
        makeChoice()

requestWithCache = (path, perms, cb) ->
    precheckStatus perms, (err) ->
        return cb err if err?

        # Callback arguments: error, response, requested item
        if cache.isStale path
            console.log "Requesting /#{path} from the GW2 API."
            request path, interpreted (err, body) ->
                if _.isArray body
                    body = { data: body }

                if !err?
                    cache.store path, body

                if body?
                    body.cachedResponse = false

                (cb)(err, body)
        else
            console.log "Retrieving /#{path} from the cache."
            body = cache.get path
            body.cachedResponse = true

            (cb)(null, body)

requestWithoutCache = (path, perms, cb) ->
    precheckStatus perms, (err) ->
        return cb err if err?

        console.log "Requesting /#{path} from the GW2 API."
        request path, interpreted (err, body) ->
            if _.isArray body
                body = { data: body }

            body.cachedResponse = false

            (cb)(err, body)

standardizeParallelResult = (cb) ->
    # A wrapper to be used with async.parallel; adds generic root level fields which would otherwise only be present
    # on the subobjects individually.
    (err, result) ->
        if !err?
            result.cachedResponse = _.all result, 'cachedResponse'

        (cb)(err, result)

module.exports =
    init: (cb) ->
        initialize cb
        setTimeout ->
            cache.purge false
        , cache.timeout
    getAccount: (cb) ->
        requestWithCache 'account', ['account'], cb
    getCharacters: (cb) ->
        requestWithCache 'characters?page=0', ['account', 'characters'], cb
    getCharacter: (name, cb) ->
        # Assuming the cache database isn't tampered with, these should always be available.
        name = encodeURIComponent name
        requestWithCache "characters/#{name}", ['account', 'characters'], cb
    getBank: (cb) ->
        async.parallel
            bank: (asyncCb) -> requestWithCache 'account/bank', ['account', 'inventories'], asyncCb
            materials: (asyncCb) -> requestWithCache 'account/materials', ['account', 'inventories'], asyncCb
        , standardizeParallelResult cb
    getBuild: (cb) ->
        requestWithCache 'build', [], (err, res) ->
            if !err?
                state.lastSeenBuild = res.id
                (cb)(err, res)
            else
                if state.lastSeenBuild > 0
                    (cb)(null, { id: state.lastSeenBuild, cachedResponse: true })
                else
                    (cb)(err, res)
    getItems: (ids, cb) ->
        if !(_.isArray(ids) && _.all ids, (id) -> _.isNumber id)
            return (cb) makeError 'API wrapper requires the parameter to be an array of IDs', ErrorCode.INVALID_WRAPPER_CALL

        # Hard limit on official API
        idChunks = _chunk _.uniq(ids), 200
        async.map idChunks, (chunk, asyncCb) ->
            requestWithCache "items?ids=#{chunk.join ','}", [], asyncCb
        , (err, partials) ->
            if !err?
                res = []
                _.each partials, (partial) ->
                    res = res.concat partial.data

                res = { data: res }
            else
                res = null

            (cb)(err, res)

    ErrorCode: ErrorCode
    fatalAPIErrorDefaultResponse: (err, res) ->
        if err.apiError?
            switch err.apiError
                when ErrorCode.API_BAD_RESPONSE
                    return res.status httpStatus.BAD_GATEWAY
                    .json { error: err.message }
                when ErrorCode.API_TIMEOUT
                    return res.status httpStatus.REQUEST_TIMEOUT
                    .json { error: err.message }
                when ErrorCode.KEY_INVALID, ErrorCode.INSUFFICIENT_PERMISSIONS, ErrorCode.API_ENDPOINT_NOT_FOUND
                    return res.status httpStatus.INTERNAL_SERVER_ERROR
                    .json { error: err.message }
                else
                    return res.status httpStatus.SERVICE_UNAVAILABLE
                    .json { error: err.message }
        else
            return res.status httpStatus.INTERNAL_SERVER_ERROR
            .json { error: err.message }
