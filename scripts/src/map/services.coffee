services = angular.module('map.services', ['restangular'])

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

                @tilelayer = null

                @map = null

        getCurrentDataLayer: =>
                """
                Return the current map layer
                """
                return @datalayers[Object.keys(@datalayers)[0]] # XXX Hacky

        addMarker: (name, aMarker) =>
                """
                Given marker data, add it
                """
                # console.debug("adding marker #{name}...")
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


        load: (slug, scope, callback) =>
                @Restangular.withConfig((RestangularConfigurer) =>
                        RestangularConfigurer.setRestangularFields(
                                id: "slug" # We need this otherwise
                                           # the URL isn't builded
                                           # correctly (it used Id
                                           # instead of slug)
                        )
                ).one('scout/map', slug).get().then((aMap) =>
                        @map = aMap

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

                        # Add every tile layer
                        console.debug("Adding tile layer...")
                        @tilelayer =
                                name: aMap.tile_layer.name
                                uri: aMap.tile_layer.resource_uri
                                url_template: aMap.tile_layer.url_template
                                attrs:
                                        zoom: 12

                        # Add data layers
                        for layer in aMap.data_layers
                                console.debug("Adding data layer...")
                                # Add its markers
                                for marker in layer.markers
                                        this.addMarker(marker.id,
                                                lat: marker.position.coordinates[0]
                                                lng: marker.position.coordinates[1]
                                                data: marker
                                        )

                        callback(@map)
                )



# Services
services.factory('MapService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])
