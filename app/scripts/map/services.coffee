services = angular.module('map.services', ['restangular'])

class MapService
        constructor: (@$compile, @$http, @Restangular) ->
                @markers = new Array()

                @center =
                        lat: 1.0
                        lng: 1.0
                        zoom: 8

                @tiles = {}

                @geojson = null

                @map = null

        getCurrentDataLayer: =>
                """
                Return the current map layer
                """
                return @map.data_layers[0] # XXX Hacky

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

                return aMarker


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

                        # Fill in markers
                        for layer in aMap.data_layers
                                console.debug("Adding data layer...")

                                # Load the geojson layer if specified
                                if layer.geojson
                                        @$http.get(layer.geojson).success((data, status) =>
                                                @geojson =
                                                        data: data
                                                        pointToLayer: (feature, latlng) ->
                                                                console.debug(feature)
                                                                return new L.Marker(latlng,
                                                                        {
                                                                                icon: L.AwesomeMarkers.icon({
                                                                                        prefix: 'fa',
                                                                                        markerColor: feature.properties['marker-color'],
                                                                                        icon: feature.properties['marker-symbol']
                                                                                });
                                                                        }
                                                                )
                                        )

                                # Add its markers
                                for marker in layer.markers
                                        @markers.push({
                                                lat: marker.position.coordinates[0]
                                                lng: marker.position.coordinates[1]
                                                message: '<div ng-include="\'/views/map/marker_card.html\'"></div>'
                                                data:
                                                        title: marker.title
                                                        subtitle: marker.subtitle
                                                        description: marker.description
                                                        picture_url: marker.picture_url
                                                        created_by: marker.created_by
                                                        address: marker.address
                                                        id: marker.id

                                                icon:
                                                        type: 'awesomeMarker'
                                                        prefix: 'fa'
                                                        icon: marker.category.icon_name
                                                        markerColor: marker.category.marker_color
                                                        iconColor: marker.category.icon_color
                                                })

                        # Add background tile layer
                        console.debug("Adding tile layer...")
                        @tiles =
                                name: aMap.tile_layer.name
                                url: aMap.tile_layer.url_template
                                options:
                                        attribution: aMap.tile_layer.attribution

                        callback(@map)
                )



# Services
services.factory('MapService', ['$compile', '$http', 'Restangular', ($compile, $http, Restangular) ->
        return new MapService($compile, $http, Restangular)
])
