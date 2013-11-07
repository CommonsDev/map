module = angular.module('common.controllers', ['http-auth-interceptor', 'ngCookies', 'googleOauth'])

class LoginCtrl
        """
        Login a user
        """
        constructor: (@$scope, @$rootScope, @$http, @$state, @Restangular, @$cookies, @authService, @Token) ->
                @$scope.isAuthenticated = false
                @$scope.username = ""
                @$scope.loginrequired = false

                # On login required
                @$scope.$on('event:auth-loginRequired', =>
                        @$scope.loginrequired = true
                        console.debug("Login required")
                )

                # On login successful
                @$scope.$on('event:auth-loginConfirmed', =>
                        console.debug("Login OK")
                        @$scope.loginrequired = false
                        @$scope.username = @$cookies.username
                        @$scope.isAuthenticated = true
                )

                # set authorization header if already logged in
                if @$cookies.username and @$cookies.key
                        console.debug("Already logged in.")
                        @$http.defaults.headers.common['Authorization'] = "ApiKey #{@$cookies.username}:#{@$cookies.key}"
                        @authService.loginConfirmed()


                @$scope.accessToken = @Token.get()

                # Add methods to scope
                @$scope.submit = this.submit
                @$scope.authenticateGoogle = this.authenticateGoogle
                @$scope.forceLogin = this.forceLogin
                @$scope.logout = this.logout

        forceLogin: =>
                @$scope.loginrequired = true

        logout: =>
                @$scope.isAuthenticated = false
                delete @$http.defaults.headers.common['Authorization']
                delete @$cookies['username']
                delete @$cookies['key']
                @$scope.username = ""

                @$state.go('index')


        submit: =>
                console.debug('submitting login...')
                @Restangular.all('account/user').customPOST("login", {}, {},
                                username: @$scope.username
                                password: @$scope.password
                        ).then((data) =>
                                @$cookies.username = data.username
                                @$cookies.key = data.key
                                @$http.defaults.headers.common['Authorization'] = "ApiKey #{data.username}:#{data.key}"
                                @authService.loginConfirmed()
                        , (data) =>
                                console.debug("LoginController submit error: #{data.reason}")
                                @$scope.errorMsg = data.reason
                )

        authenticateGoogle: =>
                extraParams = {}
                if @$scope.askApproval
                        extraParams = {approval_prompt: 'force'}

                @Token.getTokenByPopup(extraParams).then((params) =>

                        # Verify the token before setting it, to avoid the confused deputy problem.
                        @Restangular.all('account/user/login').customPOST("google", {}, {},
                                access_token: params.access_token
                        ).then((data) =>
                                @$cookies.username = data.username
                                @$cookies.key = data.key
                                @$http.defaults.headers.common['Authorization'] = "ApiKey #{data.username}:#{data.key}"
                                @authService.loginConfirmed()
                        , (data) =>
                                console.debug("LoginController submit error: #{data.reason}")
                                @$scope.errorMsg = data.reason
                        )
                , ->
                        # Failure getting token from popup.
                        alert("Failed to get token from popup.")
                )

LoginCtrl.$inject = ['$scope', '$rootScope', "$http", "$state", "Restangular", "$cookies", "authService", "Token"]

module.controller("LoginCtrl", LoginCtrl)