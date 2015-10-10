bcrypt = require 'bcrypt'

settings = require('../../configmanager').get()

# Only ever use numbers as the salt parameter, to prevent using predetermined salts accidentally in invalid settings
rounds = if typeof settings.saltRounds == 'number' then settings.saltRounds else 8

module.exports =
    hash: (value, callback) ->
        bcrypt.hash value, rounds, callback
    compare: (input, hashed, callback) ->
        bcrypt.compare input, hashed, callback
