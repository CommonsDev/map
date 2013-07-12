services = angular.module('map.services', ['ngResource'])

class MapService
        constructor: (@Map) ->
                @icon = L.icon({
                        iconUrl: '/images/pointer.png'
                        shadowUrl: null,
                        iconSize: new L.Point(61, 61)
                        iconAnchor: new L.Point(4, 56)
                })

                @markers = {}
                @center =
                        lat: 1.0
                        lng: 1.0
                        zoom: 8

                @tilelayers =
                        truc:
                                url_template: 'http://tile.openstreetmap.org/{z}/{x}/{y}.png'
                                attrs:
                                        zoom: 12

        addMarker: (name, aMarker) =>
                console.debug("adding marker #{name}...")
                @markers[name] = aMarker

        load: (slug) =>
                @map = @Map.get({slug: slug}, (aMap, getResponseHeaders) => # FIXME: HARDCODED VALUE
                        # Locate user using HTML5 Api or use map center
                        if aMap.locate
                                # @geolocation.watchPosition()

                                #@geolocation.position().then((position) =>
                                #        @$scope.center =
                                #                lat: position.coords.latitude
                                #                lng: position.coords.longitude
                                #                zoom: aMap.zoom
                                #        console.debug("map center set to #{position.coords.latitude}, #{position.coords.longitude}")
                                #)
                        else
                                @center.lat = aMap.center.coordinates[0]
                                @center.lng = aMap.center.coordinates[1]
                                @center.zoom = aMap.zoom

                        # Add every marker (FIXME: Should handle layers)
                        for layer in aMap.tile_layers
                                @tilelayers[layer.name] =
                                                url_template: 'http://tile.stamen.com/watercolor/{z}/{x}/{y}.jpg'
                                                attrs:
                                                        zoom: 12

                                for marker in layer.markers
                                        this.addMarker(marker.id,
                                                href: "/marker/detail/#{ marker.id }"
                                                lat: marker.position.coordinates[0]
                                                lng: marker.position.coordinates[1]
                                                attrs:
                                                        icon: @icon
                                        )

                )



# Services
services.factory('MapService', ['Map', (Map) ->
        console.debug('constructing new map srv')
        return new MapService(Map)
])

# Models
services.factory('Map', ['$resource', '$rootScope', ($resource, $rootScope) ->
        return $resource("#{$rootScope.CONFIG.REST_URI}scout/v0/map/:slug?format=json", {slug: "@slug"})
])

services.factory('Marker', ['$resource', '$rootScope', ($resource, $rootScope) ->
        return $resource("#{$rootScope.CONFIG.REST_URI}scout/v0/marker/:markerId?format=json", {markerId: "@id"})
])