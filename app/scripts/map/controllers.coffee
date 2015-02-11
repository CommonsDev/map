# -*- tab-width: 2 -*-
"use strict"

module = angular.module('map.controllers', ['angularFileUpload', 'restangular', 'angularSpectrumColorpicker'])

class MapSearchCtrl
  constructor: (@$scope, @$rootScope, @$state, @MapService, @Restangular, @geolocation) ->
    @$scope.lookupAddress = this.lookupAddress
    @$scope.geolocate = this.geolocate

    @$scope.form =
      address: ""

    geolocate: =>
      p = @geolocation.position().then(
        (pos) =>
          console.debug("Resolving #{pos.coords.latitude}")

          # Focus on new location
          @MapService.center =
            lat: pos.coords.latitude
            lng: pos.coords.longitude
            zoom: 20

          @$state.go('map')

        , (reason) =>
          console.debug("error while getting position...")
    )

  lookupAddress: =>
    """
    Given an address, find lat/lng
    """
    console.debug("looking up #{@$scope.form.address}")
    pos_promise = @geolocation.lookupAddress(@$scope.form.address).then((coords)=>
      console.debug("Found pos #{coords}")

      # Focus on new position
      @MapService.center =
        lat: coords[0]
        lng: coords[1]
        zoom: 20

      @$state.go('map')
    )


class MapDetailCtrl
        """
        Base controller for interacting with a map
        """
        constructor: (@$scope, @$rootScope, @$stateParams, @$location, @MapService, @geolocation, $compile) ->
                @$scope.MapService = @MapService
                @$scope.$stateParams = @$stateParams

                @$scope.isLoading = true

                @$scope.acquiringPosition = false
                @$scope.positionLocked = false

                # Load map once the page has loaded
                console.debug("loading map...")
                if @$stateParams.slug
                        @MapService.load(@$stateParams.slug, @$scope, (map) =>
                                console.debug("map loaded...")
                                @$rootScope.page_title = map.name
                                @$scope.isLoading = false
                        )

                # Catch popup opening, format template with current data and open popup
                @$scope.$on('leafletDirectiveMarker.popupopen', (event, leafletEvent) ->
                        newScope = $scope.$new()
                        angular.extend(newScope,
                                marker: $scope.MapService.markers[leafletEvent.markerName]
                        )
                        $compile(leafletEvent.leafletEvent.popup._contentNode)(newScope)
                )

                query = @$location.search()
                # Shall we show the toolbar?
                @$scope.showToolbar = (query['toolbar'] != 'false')

                # Bind methods
                @$scope.search = this.search
                @$scope.toggleLockPosition = this.toggleLockPosition


        toggleLockPosition: =>
                if not @$scope.acquiringPosition
                        @geolocation.watchPosition((position)=>
                                @$scope.$apply(=>
                                        # Center & Zoom map
                                        @MapService.center =
                                                lat: position.coords.latitude
                                                lng: position.coords.longitude
                                                zoom: 25

                                        # Create or update geolocation marker
                                        if "geoloc_marker" in @MapService.markers
                                                marker = @MapService.markers["geoloc_marker"]
                                                marker.lat = position.coords.latitude
                                                marker.lng = position.coords.longitude
                                        else
                                                @MapService.markers['geoloc_marker'] =
                                                        lat: position.coords.latitude
                                                        lng: position.coords.longitude

                                        console.debug("map center set to #{position.coords.latitude}, #{position.coords.longitude}")

                                        @$scope.positionLocked = true
                                )

                        )
                else
                        @geolocation.cancelWatchPosition()
                        @$scope.positionLocked = false

                @$scope.acquiringPosition = not @$scope.acquiringPosition

        search: =>

                #@geolocation.position().then((position) =>
                #        @MapService.center =
                #                lat: position.coords.latitude
                #                lng: position.coords.longitude
                #                zoom: 20
                #        console.debug("map center set to #{position.coords.latitude}, #{position.coords.longitude}")
                #)


class MapNewCtrl
        """
        Create a new map
        """
        constructor: (@$scope, @$location, @cookies, @Restangular) ->
                @$scope.form =
                        name: ''
                        center:
                                coordinates: [0, 0]
                                type: 'Point'
                        tile_layer: {pk: 1}

                @$scope.create = this.create

                @$scope.$location = $location

                if @cookies.username
                        @$scope.username = @cookies.username

        create: =>
                """
                Create a new map and redirect to the newly created map url
                """
                console.debug("creating map #{@$scope.form.name}")
                @Restangular.all('scout/map').post(@$scope.form).then((map) =>
                        @$location.url("/#{map.slug}/welcome")
                )

class MapMarkerDetailCtrl
        """
        Show the full page of a given Marker
        """
        constructor: (@$scope, @$routeParams, @$state, @Restangular) ->
                @$scope.isLoading = true

                @$scope.$state = @$state

                @Restangular.one('scout/marker', @$routeParams.markerId).get().then((marker) =>
                        console.debug("marker loaded")
                        @$scope.marker = angular.copy(marker)
                        @$scope.isLoading = false
                )

                @$scope.remove = this.remove

        remove: =>
                @Restangular.one('scout/marker', @$routeParams.markerId).remove().then(=>
                        console.debug("marker deleted")
                        @$state.go('map')
                )


class MapSettingsCtrl
        constructor: (@$scope, @$stateParams, @Restangular, @MapService) ->
                console.debug("settings initialized")
                @$scope.set_center = this.set_center

        set_center: =>
                console.debug("setting center1...")
                center = @MapService.center

                @MapService.map.center =
                        coordinates: [center.lat, center.lng]
                        type: 'Point'
                @MapService.map.zoom = center.zoom

                console.debug("setting center2...")

                @MapService.map.patch({'center': @MapService.map.center, 'zoom': @MapService.map.zoom}).then(() =>
                        $("#recadring").fadeIn('slow').delay(1000).fadeOut('slow')
                )
                console.debug("setting center3...")

class MapMyMapsCtrl
        """
        Get a list of my maps
        """
        constructor: (@$scope, @$state, @Restangular, @MapService) ->
                @$scope.isLoading = true
                @$scope.maps = []

                @Restangular.all("scout/map").getList().then((maps) =>
                        @$scope.maps = angular.copy(maps)
                        @$scope.isLoading = false
                )

class MapTileLayersCtrl
        """
        Changes the background layer of a map
        """
        constructor: (@$scope, @$stateParams, @Restangular, @MapService) ->
                @$scope.form = {}
                @$scope.isLoading = true
                @$scope.available_layers = []
                @$scope.MapService = @MapService

                # When changing tile layer
                @$scope.$watch('form.selected_layer', (tilelayer_idx) =>
                        if @$scope.isLoading
                                return

                        new_tl = @$scope.available_layers[tilelayer_idx]

                        @MapService.tiles =
                                name: new_tl.name
                                url: new_tl.url_template
                                options:
                                        attribution: new_tl.attribution

                        # Save preference to server
                        # FIXME Should use smthg liek setTiles() and saveTiles() from the service
                        @MapService.map.tile_layer = @$scope.available_layers[tilelayer_idx].resource_uri
                        @MapService.map.patch({'tile_layer': @MapService.map.tile_layer})
                )

                # Bind methods to scope
                @$scope.changeSelectedLayer = this.changeSelectedLayer


                # Get a list of available tile layers
                @Restangular.all("scout/tilelayer").getList().then((layers) =>
                        console.debug("layers loaded")
                        @$scope.available_layers = angular.copy(layers)


                        if @MapService.map
                                this.setCurrentLayer()
                        else
                                @$scope.$watch("MapService.map", =>
                                        if MapService.map == null
                                                return
                                        this.setCurrentLayer()
                                )

                        @$scope.isLoading = false

                )


        setCurrentLayer: =>
                # Check current layer
                for layer, idx in @$scope.available_layers
                        if layer.id == @MapService.map.tile_layer.id or layer.resource_uri == @MapService.map.tile_layer
                                this.changeSelectedLayer(idx)


        changeSelectedLayer: (idx) =>
                @$scope.form.selected_layer = idx

class MapShareCtrl
        """
        Share config for a map
        """
        constructor: (@$scope, @$location, @$state, @Restangular, @MapService) ->
                @$scope.$state = @$state
                @$scope.$location = @$location

                @$scope.form =
                        privacy_level: 'GROUP_RW'


                @$scope.$watch(@MapService.map, =>
                        return if @MapService.map is null
                        @$scope.map = @MapService.map
                )

                # Bind methods to scope
                @$scope.changePrivacyLevel = this.changePrivacyLevel

        changePrivacyLevel: (level) =>
                @$scope.form.privacy_level = level
                @Restangular.withConfig((RestangularConfigurer) =>
                        RestangularConfigurer.setRestangularFields(
                                id: "slug" # We need this otherwise
                                           # the URL isn't builded
                                           # correctly (it used Id
                                           # instead of slug)
                        ))
                .one('scout/map', @MapService.map.slug)
                .patch({privacy: @$scope.form.privacy_level})
                .then(->
                        console.debug("privacy changed")
                )

class MapMarkerNewCtrl
        """
        Wizard to create a new marker
        """
        constructor: (@$scope, @$rootScope, @debounce, @$state, @$upload, @$location, @MapService, @Restangular, @geolocation) ->
                width = 320
                height = 240

                @$scope.marker_categories_loading = true

                video = document.querySelector("#video")
                """
                video.addEventListener("canplay", ((ev) ->
                         unless streaming
                                 height = video.videoHeight / (video.videoWidth / width)
                                 video.setAttribute("width", width)
                                 video.setAttribute("height", height)
                                 canvas.setAttribute("width", width)
                                 canvas.setAttribute("height", height)
                                 streaming = true
                         ),
                false)
                """

                # Load marker categories
                @Restangular.all("scout/marker_category").getList().then((categories) =>
                        console.debug("Marker categories loaded")
                        @$scope.marker_categories = angular.copy(categories)
                        @$scope.marker_categories_loading = false
                )

                @$scope.uploads = {}

                @$scope.MapService = @MapService

                # The new marker we'll submit if everything is OK
                @$scope.marker = {}
                @$scope.marker.position =
                        coordinates: null
                        type: "Point"

                # Preview the next marker, using a target icon
                @$scope.MapService.markers['marker_preview'] =
                        lat: @MapService.center.lat
                        lng: @MapService.center.lng
                        draggable: true
                        icon:
                                type: 'awesomeMarker'
                                icon: 'dot-circle-o'
                                markerColor: 'blue'
                                iconColor: 'white'

                @$scope.$on('$stateChangeStart', (event, toState, toParams, fromState, fromParams) =>
                        @MapService.markers = _.without(@MapService.markers, 'marker_preview')
                )

                # Wizard Steps
                @$scope.wizard =
                    step: 1

                @$scope.captureInProgress = false
                @$scope.previewInProgress = false

                # add functions and variable to scope
                @$scope.takePicture = this.takePicture
                @$scope.skipPicture  = this.skipPicture
                @$scope.grabCamera = this.grabCamera
                @$scope.cancelGrabCamera = this.cancelGrabCamera
                @$scope.submitForm = this.submitForm
                @$scope.pictureDelete = this.pictureDelete
                @$scope.geolocateMarker = this.geolocateMarker
                @$scope.lookupAddress = this.lookupAddress
                @$scope.onFileSelect = this.onFileSelect

                # Use debounce to prevent multiple calls
                @$scope.on_marker_preview_moved = @debounce(this.on_marker_preview_moved, 2)

                # Cursor move callback
                @$scope.$watch('MapService.markers["marker_preview"].lat + MapService.markers["marker_preview"].lng', =>
                        @$scope.on_marker_preview_moved()
                )

        onFileSelect: (files) =>
                @$scope.isUploading = true
                # $files: an array of files selected, each file has name, size, and type.
                for file in files
                        @$scope.upload = @$upload.upload(
                                url: @$rootScope.CONFIG.bucket_uri,
                                data: {bucket: @MapService.map.bucket.id},
                                file: file,
                        ).progress((evt) =>
                                console.log('percent: ' + parseInt(100.0 * evt.loaded / evt.total));
                        ).success((data, status, headers, config) =>
                                @$scope.marker.picture_url = data.thumbnail_url
                                @$scope.isUploading = false
                        );


        submitForm: =>
                """
                Submit the form to create a new point
                """
                # XXX Hacky, hardcoded
                @$scope.marker.data_layer = @MapService.getCurrentDataLayer().resource_uri

                # Use 'pk' for category
                # @$scope.marker.category = {'pk': @$scope.marker.category}

                # Now save the marker
                console.debug("saving...")
                console.debug(@$scope.marker)
                @$scope.isUploading = true
                @Restangular.all('scout/marker').post(@$scope.marker).then((marker) =>
                        console.debug("new marker saved")

                        # Delete temp marker
                        @MapService.removeMarker('marker_preview')

                        # Create new marker
                        @MapService.markers[marker.id] =
                                lat: marker.position.coordinates[0]
                                lng: marker.position.coordinates[1]
                                message: '<div ng-include="\'/views/map/marker_card.html\'"></div>'
                                data: angular.copy(marker)
                                icon:
                                        type: 'awesomeMarker'
                                        icon: marker.category.icon_name
                                        iconColor: marker.category.icon_color
                                        markerColor: marker.category.marker_color

                        @$scope.isUploading = false

                        # Show the newly created marker
                        @$state.go('map.marker_detail', {markerId: marker.id})
                )


        skipPicture: =>
                """
                Button callback for 'Skip adding picture'
                """
                @$scope.captureInProgress = false
                @$scope.previewInProgress = false

        pictureDelete: =>
                """
                Callback when one decide to delete the uploaded picture
                """
                @$scope.marker.picture = null
                @$scope.uploads.picture = null
                @$scope.previewInProgress = false

        grabCamera: =>
                """
                Setup and grab the camera in a canvas
                """
                console.debug("Initializing webcam...")

                video = document.querySelector("#video")
                canvas = document.querySelector("#canvas")

                navigator.getMedia = (navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia)

                navigator.getMedia(
                        video: true
                        audio: false
                        , ((stream) =>
                                if navigator.mozGetUserMedia
                                        video.mozSrcObject = stream
                                else
                                        vendorURL = window.URL or window.webkitURL
                                        video.src = vendorURL.createObjectURL(stream)
                                video.play()
                                console.debug("Webcam grab in progress...")
                                @$scope.captureInProgress = true
                                @$scope.$apply()
                        ), (err) =>
                                console.log("An error occured! " + err)
                )



        cancelGrabCamera: =>
                """
                Release handle on camera
                """
                console.debug('Disabling camera...')
                video = document.querySelector("#video")
                video.src = ""
                @$scope.captureInProgress = false

        takePicture: =>
                width = 320
                height = 240

                canvas.width = width
                canvas.height = height
                canvas.getContext("2d").drawImage(video, 0, 0, width, height)
                data = canvas.toDataURL("image/jpg")

                photo = document.querySelector("#selected-photo")
                photo.setAttribute("src", data)

                video = document.querySelector("#video")
                video.src = ""

                @$scope.captureInProgress = false
                @$scope.previewInProgress = true


        on_marker_preview_moved: =>
                """
                When the marker was moved, update position and geocode
                """
                marker_preview = @MapService.markers['marker_preview']
                if (marker_preview is undefined) or (not marker_preview.lat) or (not marker_preview.lng)
                        return

                # Update marker position
                @$scope.marker.position.coordinates = [marker_preview.lat, marker_preview.lng]
                console.debug("pos set @#{@$scope.marker.position.coordinates}")

                # Resolve lat/lng to a human readable address
                pro = @geolocation.resolveLatLng(marker_preview.lat, marker_preview.lng).then((address) =>
                        console.debug("Found address match: #{address.formatted_address}")
                        @$scope.marker.address = angular.copy(address.formatted_address)
                )


        geolocateMarker: =>
                console.debug("Getting user position...")
                p = @geolocation.position().then(
                        (pos) =>
                                console.debug("Resolving #{pos.coords.latitude}")

                                marker_preview = @MapService.markers['marker_preview']
                                marker_preview.lat = pos.coords.latitude
                                marker_preview.lng = pos.coords.longitude

                                # Focus on new location
                                @MapService.center =
                                        lat: marker_preview.lat
                                        lng: marker_preview.lng
                                        zoom: 20
                        , (reason) =>
                                console.debug("error while getting position...")
                )

        lookupAddress: =>
                """
                Given an address, find lat/lng
                """
                console.debug("looking up #{@$scope.marker.position.address}")
                pos_promise = @geolocation.lookupAddress(@$scope.marker.address).then((coords)=>
                        console.debug("Found pos #{coords}")

                        # move preview marker
                        marker_preview = @MapService.markers['marker_preview']
                        marker_preview.lat = coords[0]
                        marker_preview.lng = coords[1]

                        # Focus on new position
                        @MapService.center =
                                lat: marker_preview.lat
                                lng: marker_preview.lng
                                zoom: 15

                )

module.controller("MapMarkerCategoriesCtrl", ($scope, MapService, Restangular) ->

  $scope.color = null

  $scope.foreground_color_options =
    color: 'white'

  $scope.background_color_options =
    showPaletteOnly: true,
    showPalette:true,
    color: 'red',
    palette: [
        "red",
        "darkred",
        "orange",
        "green",
        "darkgreen",
        "blue",
        "purple",
        "darkpurple",
        "cadetblue"
      ]

  $scope.$watch("MapService.map", (map) ->
    if map
      $scope.marker_categories = MapService.map.marker_categories
  )
)


# Controller declarations
module.controller("MapDetailCtrl", ['$scope', '$rootScope', '$stateParams', '$location', 'MapService', 'geolocation', '$compile', MapDetailCtrl])
module.controller("MapNewCtrl", ['$scope', '$location', '$cookies', 'Restangular', MapNewCtrl])
module.controller("MapMarkerDetailCtrl", ['$scope', '$stateParams', '$state', 'Restangular', MapMarkerDetailCtrl])
module.controller("MapTileLayersCtrl", ['$scope', '$stateParams', 'Restangular', 'MapService', MapTileLayersCtrl])
module.controller("MapMyMapsCtrl", ['$scope', '$state', 'Restangular', 'MapService', MapMyMapsCtrl])
module.controller("MapSettingsCtrl", ['$scope', '$state', 'Restangular', 'MapService', MapSettingsCtrl])
module.controller("MapShareCtrl", ['$scope', '$location', '$state', 'Restangular', 'MapService', MapShareCtrl])
module.controller("MapMarkerNewCtrl", ['$scope', '$rootScope', 'debounce', '$state', '$upload', '$location', 'MapService', 'Restangular', 'geolocation', MapMarkerNewCtrl])
module.controller("MapSearchCtrl", ['$scope', '$rootScope', '$state', 'MapService', 'Restangular', 'geolocation', MapSearchCtrl])
