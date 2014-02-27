module = angular.module('common.controllers', ['angular-unisson-auth'])

class LoginCtrl
        constructor: (@$scope, @loginService) ->
                @$scope.loginService = @loginService

module.controller("LoginCtrl", ['$scope','loginService', LoginCtrl])
