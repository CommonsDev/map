module = angular.module('common.controllers', ['http-auth-interceptor', 'ngCookies'])

class LoginCtrl
        constructor: (@$scope, @$http, @$cookies, @authService) ->
                # set authorization header if already logged in
                @$http.defaults.headers.common['Authorization'] = "ApiKey #{@$cookies.username}:#{@$cookies.key}"

                # On login required
                @$scope.$on('event:auth-loginRequired', =>
                        console.debug("Login required")
                )

                # On login successful
                @$scope.$on('event:auth-loginConfirmed', =>
                        console.debug("Login OK")
                )

                # Add methods to scope
                @$scope.submit = this.submit

        submit: =>
                @$http.post('http://localhost:8000/api/account/v0/user/login/', JSON.stringify( # XXX HARDCODED
                        username: @$scope.username
                        password: @$scope.password
                )).success((data) =>
                        @$cookies.username = data.username
                        @$cookies.key = data.key
                        @$http.defaults.headers.common['Authorization'] = "ApiKey #{data.username}:#{data.key}"
                        @authService.loginConfirmed()
                ).error((data) =>
                        console.debug("LoginController submit error: #{data.reason}")
                        @$scope.errorMsg = data.reason
                )

LoginCtrl.$inject = ['$scope', "$http", "$cookies", "authService"]

module.controller("LoginCtrl", LoginCtrl)