services = angular.module('map.services', ['restangular'])

class MapService
        constructor: (@$rootScope, @$compile, @$http, @Restangular, @leafletEvents) ->
                @markers = new Array()

                @center =
                        lat: 1.0
                        lng: 1.0
                        zoom: 8

                @tiles = {}

                @tags = new Array()

                @events =
                        map:
                                disable: @leafletEvents.getAvailableMapEvents()
                        markers:
                                disable: @leafletEvents.getAvailableMarkerEvents()

                @layers =
                        baselayers:
                                cloudmade:
                                        name: "OSM"
                                        type: "xyz"
                                        url: "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"

                        overlays:
                                json:
                                        name: "JSON Layer"
                                        type: "markercluster"
                                        visible: true

                @geojson = null

                @map = null

        getCurrentDataLayer: =>
                """
                Return the current map layer
                """
                return @map.data_layers[0] # XXX Hacky

        readJson: (data, xpaths) =>
                if (not xpaths.object_path or not xpaths.title or not xpaths.lat or not xpaths.lng)
                        console.error("Required xpaths")
                        return

                default_xpaths =
                        object_path: "*"
                        title: "*"
                        baseline: "*"
                        description: "*"
                        lat: "*"
                        lng: "*"
                        created_by: "*"
                        created_on: "*"
                        address: "*"
                        id: "*"


                xpaths = $.extend(true, default_xpaths, xpaths)

                #snapshot = Defiant.getSnapshot(data)

                items = JSONSelect.match(xpaths.object_path, data)[0]
                for item in items
                        console.debug(item)
                        # Gather tags
                        #for tag in item.tags
                        #        if not _.where(@tags, {slug: tag.slug}).length
                        #                @tags.push({label: tag.name, slug: tag.slug, color: Please.make_color({saturation: 0.4, hue: 0.2, value: 0.7}, {from_hash: tag.slug})})
                        # Create new marker
                        @markers.push({
                                layer: "json"
                                lat: JSONSelect.match(xpaths.lat, item)[0]
                                lng: JSONSelect.match(xpaths.lng, item)[0]
                                message: '<div ng-include="\'/views/map/plugins/imagination.social/marker_card.html\'"></div>'
                                data:
                                        title: JSONSelect.match(xpaths.title, item)[0]
                                        baseline: JSONSelect.match(xpaths.baseline, item)[0]
                                        description: JSONSelect.match(xpaths.description, item)[0]
                                        # picture_url: marker.picture_url
                                        created_by: JSONSelect.match(xpaths.created_by, item)[0]
                                        created_on: JSONSelect.match(xpaths.created_on, item)[0]
                                        address: JSONSelect.match(xpaths.address, item)[0]
                                        id: JSONSelect.match(xpaths.id, item)[0]
                                icon:
                                        type: 'awesomeMarker'
                                        prefix: 'fa'
                                        # icon: marker.category.icon_name
                                        markerColor: "blue"
                                        iconColor: "white"
                        })

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
                                if layer.json_uri
                                        @$http.get(layer.json_uri).success((data, status) =>
                                                is_paths =
                                                        lat: "//location/geo/coordinates[2]"
                                                        lng: "//location/geo/coordinates[1]"
                                                        title: "//title"
                                                        baseline: "//baseline"
                                                        description: "//description"
                                                        created_on: "//created_on"
                                                        created_by: "//created_by"
                                                        address: "//location/postal_address"
                                                        id: "//id"


                                                this.readJson(data, layer.json_mapping)

                                                # @geojson =
                                                #         data: data
                                                #         pointToLayer: (feature, latlng) =>
                                                #                 # Create tags
                                                #                 if feature.properties.tags
                                                #                         for tag in feature.properties['tags']
                                                #                                 console.debug(tag)
                                                #                                 @tags.push({text: tag, weight: 13, handlers: {click: () ->
                                                #                                         console.debug("plop")
                                                #                                 }})

                                                #                 # Create real marker
                                                #                 return new L.Marker(latlng,
                                                #                         {
                                                #                                 icon: L.AwesomeMarkers.icon({
                                                #                                         prefix: 'fa',
                                                #                                         markerColor: feature.properties['marker-color'],
                                                #                                         icon: feature.properties['marker-symbol']
                                                #                                 });
                                                #                         }
                                                #                 )
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
services.factory('MapService', ['$rootScope', '$compile', '$http', 'Restangular', 'leafletEvents', ($rootScope, $compile, $http, Restangular, leafletEvents) ->
        return new MapService($rootScope, $compile, $http, Restangular, leafletEvents)
])
