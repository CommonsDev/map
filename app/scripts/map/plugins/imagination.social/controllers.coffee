"use strict"

module = angular.module('map.plugins.imaginationsocial.controllers', ['restangular'])

class MapISMarkerDetailCtrl
        """
        Show the full page of a given Imagination Social Project
        """
        constructor: (@$scope, @$routeParams, @$state, @Restangular) ->
                @$scope.isLoading = true

                @$scope.$state = @$state

                @Restangular.one('project/project', @$routeParams.projectId).get().then((marker) =>
                        console.debug("project loaded")
                        @$scope.marker = angular.copy(marker)
                        @$scope.isLoading = false
                )

                @$scope.remove = this.remove


module.controller("MapISMarkerDetailCtrl", ['$scope', '$stateParams', '$state', 'Restangular', MapISMarkerDetailCtrl])
