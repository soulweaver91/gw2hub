angular.module 'service.auth', [
    'restangular'
]
.factory 'authService', [
    'Restangular', '$q',
    (Restangular, $q) ->
        currentUser = null
        init = false

        deferred = $q.defer()

        return {
            user: ->
                return currentUser
            userAsync: ->
                if !init
                    # Wait for the initial status check first.
                    deferred.promise
                else
                    # The application is already running, use current value.
                    $q.when currentUser
            login: (email, pass) ->
                Restangular.all 'auth/login'
                .post {
                    email: email
                    pass: pass
                }
                .then (res) ->
                    currentUser = res
                , (err) ->
            logout: ->
                Restangular.all 'auth/logout'
                .post()
                .then (res) ->
                    currentUser = null
            init: ->
                Restangular.one 'auth', 'status'
                .get()
                .then (res) ->
                    init = true
                    if res.logged_in
                        currentUser = res.user
                    else
                        currentUser = null
                    deferred.resolve currentUser
                , (err) ->
                    init = true
                    currentUser = null
                    deferred.reject err
        }
]
