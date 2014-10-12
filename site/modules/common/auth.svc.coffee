angular.module 'service.auth', [
    'restangular'
]
.factory 'authService', [
    'Restangular',
    (Restangular) ->
        currentUser = null

        return {
            user: ->
                return currentUser
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
            update: ->
                Restangular.one 'auth', 'status'
                .get()
                .then (res) ->
                    if res.logged_in
                        currentUser = res.user
                    else
                        currentUser = null
        }
]
