module = angular.module('map.controllers', [])

class MapCtrl
        constructor: (@$scope, @Map) ->
                @$scope.maps = @Map.query()

                @$scope.center =
                        lat: 40.095,
                        lng: -3.823,
                        zoom: 4

                @$scope.markers =
                        Madrid:
                                lat: 40.095
                                lng: -3.823
                                message: "Drag me to your position"
                                focus: true
                                draggable: true

                @$scope.save = =>
                        @$scope.maps[0].$save(->
                                console.debug('saved')
                        )

MapCtrl.$inject = ["$scope", "Map"]


class MapNewCtrl
        constructor: (@$scope, @Map) ->
                null

MapNewCtrl.$inject = ['$scope', "Map"]


# Controller declarations
module.controller("MapCtrl", MapCtrl)
module.controller("MapNewCtrl", MapNewCtrl)
