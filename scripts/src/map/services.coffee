services = angular.module('map.services', ['ngResource'])

class MapService
        constructor: (@$compile, @Restangular) ->
                @icon = L.icon({
                        iconUrl: '/images/pointer.png'
                        shadowUrl: null,
                        iconSize: [61, 61]
                        iconAnchor: [4, 56]
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

        getCurrentLayer: =>
                """
                Return the current map layer
                """
                return @tilelayers[Object.keys(@tilelayers)[0]] # XXX Hacky

        addMarker: (name, aMarker) =>
                """
                Given marker data, add it
                """
                console.debug("adding marker #{name}...")
                if not aMarker.options
                        aMarker.options = {}
                if not aMarker.options.icon
                        aMarker.options.icon = @icon

                @markers[name] = aMarker

        removeMarker: (name) =>
                """
                Given a name (key), remove it from the marker list
                """
                console.debug("removing marker #{name}")
                delete @markers[name]


        load: (slug, scope) =>
                @map = @Restangular.one('scout/map', slug).get().then((aMap) =>
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
                                @center =
                                        lat: aMap.center.coordinates[0]
                                        lng: aMap.center.coordinates[1]
                                        zoom: aMap.zoom

                        # Add every layer
                        for layer in aMap.tile_layers
                                @tilelayers[layer.id] =
                                        name: layer.name
                                        uri: layer.resource_uri
                                        url_template: layer.url_template
                                        attrs:
                                                zoom: 12

                                # Add its markers
                                for marker in layer.markers
                                        this.addMarker(marker.id,
                                                lat: marker.position.coordinates[0]
                                                lng: marker.position.coordinates[1]
                                                data: marker
                                        )

                )



# Services
services.factory('MapService', ['$compile', 'Restangular', ($compile, Restangular) ->
        console.debug('constructing new map srv')
        return new MapService($compile, Restangular)
])
