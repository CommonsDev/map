module = angular.module('map.controllers', [])

class MapDetailCtrl
        constructor: (@$scope, @Map) ->
                icon = L.icon({
                        iconUrl: '/images/pointer.png'
                        shadowUrl: null,
                        iconSize: new L.Point(61, 61)
                        iconAnchor: new L.Point(4, 56)
                })

                @$scope.tilelayers =
                        truc:
                                url_template: 'http://tile.stamen.com/watercolor/{z}/{x}/{y}.jpg'
                                attrs:
                                        zoom: 4

                @$scope.center =
                        lat: 0
                        lng: 0
                        zoom: 1


                @$scope.markers = {}

                @$scope.map = @Map.get({mapId: 1}, (aMap, getResponseHeaders) => # FIXME: HARDCODED VALUE
                        # Locate user using HTML5 Api or use map center
                        if aMap.locate
                                navigator.geolocation.getCurrentPosition((position) =>
                                        @$scope.center =
                                                lat: position.coords.latitude
                                                lng: position.coords.longitude
                                                zoom: aMap.zoom
                                )
                        else
                                @$scope.center =
                                        lat: aMap.center.coordinates[0]
                                        lng: aMap.center.coordinates[1]
                                        zoom: aMap.zoom

                        # Add every marker (FIXME: Should handle layers)
                        for layer in aMap.tile_layers
                                @$scope.tilelayers[layer.name] =
                                                url_template: 'http://tile.stamen.com/watercolor/{z}/{x}/{y}.jpg'
                                                attrs:
                                                        zoom: 4

                                for marker in layer.markers
                                        @$scope.markers[marker.id] =
                                                href: "/marker/detail/#{ marker.id }"
                                                lat: marker.position.coordinates[0]
                                                lng: marker.position.coordinates[1]
                                                attrs:
                                                        icon: icon


                )

MapDetailCtrl.$inject = ["$scope", "Map"]


class MapNewCtrl
        constructor: (@$scope, @Map) ->
                null

MapNewCtrl.$inject = ['$scope', "Map"]


class MapMarkerDetailCtrl
        constructor: (@$scope) ->
                null

MapMarkerDetailCtrl.$inject = ['$scope']


# Controller declarations
module.controller("MapDetailCtrl", MapDetailCtrl)
module.controller("MapNewCtrl", MapNewCtrl)
module.controller("MapMarkerDetailCtrl", MapMarkerDetailCtrl)
