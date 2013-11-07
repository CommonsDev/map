module = angular.module('map.controllers', ['imageupload', 'restangular'])

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
        constructor: (@$scope, @$rootScope, @$stateParams, @$location, @MapService, @geolocation) ->
                @$scope.MapService = @MapService
                @$scope.$stateParams = @$stateParams

                @$scope.isLoading = true

                @$scope.positionLocked = false

                # Load map once the page has loaded
                console.debug("loading map...")
                if @$stateParams.slug
                        @MapService.load(@$stateParams.slug, @$scope, (map) =>
                                console.debug("map loaded...")
                                @$rootScope.page_title = map.name
                                @$scope.isLoading = false
                        )

                # Bind methods
                @$scope.search = this.search
                @$scope.toggleLockPosition = this.toggleLockPosition


        toggleLockPosition: =>
                if not @$scope.positionLocked
                        @geolocation.watchPosition((position)=>
                                @$scope.$apply(=>
                                        @MapService.center =
                                                lat: position.coords.latitude
                                                lng: position.coords.longitude
                                                zoom: 25
                                )
                                console.debug("map center set to #{position.coords.latitude}, #{position.coords.longitude}")
                        )
                else
                        @geolocation.cancelWatchPosition()

                @$scope.positionLocked = not @$scope.positionLocked

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
        constructor: (@$scope, @$routeParams, @Restangular) ->
                @$scope.isLoading = true

                @Restangular.one('scout/marker', @$routeParams.markerId).get().then((marker) =>
                        console.debug("marker loaded")
                        @$scope.marker = angular.copy(marker)
                        @$scope.isLoading = false
                )


class MapSettingsCtrl
        constructor: (@$scope, @$rootScope, @$stateParams, @Restangular, @MapService) ->
                console.debug("settings initialized")
                @$scope.set_center = this.set_center

        set_center: =>
                console.debug("setting center...")
                @$rootScope.$broadcast('map.get_center', (center, zoom) =>
                        @MapService.map.center =
                                coordinates: [center.lat, center.lng]
                                type: 'Point'
                        @MapService.map.zoom = zoom
                        @MapService.map.patch()
                )

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

                @$scope.$watch('form.selected_layer', (tilelayer_idx) =>
                        if @$scope.isLoading
                                return

                        @MapService.tilelayer = @$scope.available_layers[tilelayer_idx]

                        # Save preference
                        @MapService.map.tile_layer = @$scope.available_layers[tilelayer_idx].resource_uri
                        @MapService.map.patch()
                )

                @Restangular.all("scout/tilelayer").getList().then((layers) =>
                        console.debug("layers loaded")
                        @$scope.available_layers = angular.copy(layers)
                        @$scope.isLoading = false
                )

                # Bind methods to scope
                @$scope.changeSelectedLayer = this.changeSelectedLayer

        changeSelectedLayer: (idx) =>
                @$scope.form.selected_layer = idx

class MapShareCtrl
        """
        Share config for a map
        """
        constructor: (@$scope, @$location, @$state, @Restangular, @MapService) ->
                @$scope.$state = @$state
                @$scope.$location = @$location
                @$scope.map = @MapService.map

class MapMarkerNewCtrl
        """
        Wizard to create a new marker
        """
        constructor: (@$scope, @$rootScope, @debounce, @$state, @$location, @MapService, @Restangular, @geolocation) ->
                width = 320
                height = 240

                console.debug("Mapservice")
                console.debug(MapService)

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
                        console.debug("cat loaded!")
                        @$scope.marker_categories = angular.copy(categories)
                        @$scope.marker_categories_loading = false
                )

                @$scope.uploads = {}

                # The new marker we'll submit if everything is OK
                @$scope.marker = {}
                @$scope.marker.position =
                        coordinates: null
                        type: "Point"

                # Preview the next marker
                @$scope.marker_preview =
                        lat: @MapService.center.lat
                        lng: @MapService.center.lng
                        options:
                                draggable: true
                                icon: @MapService.icon
                @MapService.addMarker('marker_preview', @$scope.marker_preview)

                $scope.$on('$stateChangeStart', (event, toState, toParams, fromState, fromParams) =>
                        @MapService.removeMarker('marker_preview')
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

                # Use debounce to prevent multiple calls
                @$scope.on_marker_preview_moved = @debounce(this.on_marker_preview_moved, 2)

                # Cursor move callback
                @$scope.$watch('marker_preview.lat + marker_preview.lng', =>
                        @$scope.on_marker_preview_moved()
                )

                # @$rootScope.page_title = "#{@MapService.map.name} | Ajouter un POI"


        submitForm: =>
                """
                Submit the form to create a new point
                """
                # XXX Hacky, hardcoded
                console.debug(@MapService)

                console.debug(@MapService.getCurrentDataLayer())
                @$scope.marker.data_layer = @MapService.getCurrentDataLayer().resource_uri

                # Prepare file upload
                if @$scope.uploads.picture
                        console.debug(@$scope.uploads.picture)
                        @$scope.marker.picture =
                                name: @$scope.uploads.picture.file.name
                                file: @$scope.uploads.picture.dataURL.replace(/^data:image\/(png|jpg|jpeg);base64,/, "")
                                content_type: @$scope.uploads.picture.file.type

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
                        @MapService.addMarker(marker.id,
                                lat: marker.position.coordinates[0]
                                lng: marker.position.coordinates[1]
                                data: angular.copy(marker)
                                options:
                                        icon: L.AwesomeMarkers.icon({
                                                icon: marker.category.icon_name
                                                iconColor: marker.category.icon_color
                                                markerColor: marker.category.marker_color
                                        })

                        )

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
                if (not @$scope.marker_preview.lat) or (not @$scope.marker_preview.lng)
                        return

                # Update marker position
                @$scope.marker.position.coordinates = [@$scope.marker_preview.lat, @$scope.marker_preview.lng]
                console.debug("pos set @#{@$scope.marker.position.coordinates}")

                # Resolve lat/lng to a human readable address
                pro = @geolocation.resolveLatLng(@$scope.marker_preview.lat, @$scope.marker_preview.lng).then((address) =>
                        console.debug("Found address match: #{address.formatted_address}")
                        @$scope.marker.address = angular.copy(address.formatted_address)
                )


        geolocateMarker: =>
                console.debug("Getting user position...")
                p = @geolocation.position().then(
                        (pos) =>
                                console.debug("Resolving #{pos.coords.latitude}")

                                @$scope.marker_preview.lat = pos.coords.latitude
                                @$scope.marker_preview.lng = pos.coords.longitude

                                # Focus on new location
                                @MapService.center =
                                        lat: @$scope.marker_preview.lat
                                        lng: @$scope.marker_preview.lng
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
                        @$scope.marker_preview.lat = coords[0]
                        @$scope.marker_preview.lng = coords[1]

                        # Focus on new position
                        @MapService.center =
                                lat: @$scope.marker_preview.lat
                                lng: @$scope.marker_preview.lng
                                zoom: 15

                )


# Controller declarations
module.controller("MapDetailCtrl", ['$scope', '$rootScope', '$stateParams', '$location', 'MapService', 'geolocation', MapDetailCtrl])
module.controller("MapNewCtrl", ['$scope', '$location', '$cookies', 'Restangular', MapNewCtrl])
module.controller("MapMarkerDetailCtrl", ['$scope', '$stateParams', 'Restangular', MapMarkerDetailCtrl])
module.controller("MapTileLayersCtrl", ['$scope', '$stateParams', 'Restangular', 'MapService', MapTileLayersCtrl])
module.controller("MapMyMapsCtrl", ['$scope', '$state', 'Restangular', 'MapService', MapMyMapsCtrl])
module.controller("MapSettingsCtrl", ['$scope', '$rootScope', '$state', 'Restangular', 'MapService', MapSettingsCtrl])
module.controller("MapShareCtrl", ['$scope', '$location', '$state', 'Restangular', 'MapService', MapShareCtrl])
module.controller("MapMarkerNewCtrl", ['$scope', '$rootScope', 'debounce', '$state', '$location', 'MapService', 'Restangular', 'geolocation', MapMarkerNewCtrl])
module.controller("MapSearchCtrl", ['$scope', '$rootScope', '$state', 'MapService', 'Restangular', 'geolocation', MapSearchCtrl])