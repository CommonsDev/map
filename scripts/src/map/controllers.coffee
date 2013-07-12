module = angular.module('map.controllers', ['imageupload'])

class MapDetailCtrl
        constructor: (@$scope, @$routeParams, @MapService, @Map, @geolocation) ->
                @$scope.MapService = @MapService

                # XXX: move that
                @MapService.load("amap")


class MapNewCtrl
        constructor: (@$scope, @Map) ->
                null


class MapMarkerDetailCtrl
        constructor: (@$scope, @$routeParams, @Marker) ->
                @$scope.isLoading = true

                @$scope.marker = @Marker.get({markerId: @$routeParams.markerId}, (aMarker, getResponseHeaders) =>
                        console.debug("marker loaded")
                        @$scope.isLoading = false
                )


class MapMarkerNewCtrl
        constructor: (@$scope, @$rootScope, @debounce, @$location, @MapService, @Marker, @geolocation) ->
                width = 320
                height = 240

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

                # The new marker we'll submit if everything is OK
                @$scope.marker = new @Marker()
                @$scope.marker.position =
                        coordinates: null
                        type: "Point"

                # Preview the nextr marker
                @$scope.marker_preview =
                        draggable: true
                        attrs:
                                icon: L.icon(
                                        iconUrl: '/images/poi_localisation.png'
                                        shadowUrl: null,
                                        iconSize: new L.Point(65, 75)
                                        iconAnchor: new L.Point(4, 37)
                                )

                @MapService.addMarker('marker_preview', @$scope.marker_preview)


                # Geolocation
                # this.geolocateMarker()

                # Wizard Steps
                @$scope.wizardSteps = [
                        "category",
                        "picture",
                        "info",
                        "location"
                ]

                @$scope.wizardStep = @$scope.wizardSteps[0]

                @$scope.captureInProgress = false
                @$scope.previewInProgress = false

                # add functions and variable to scope
                @$scope.takePicture = this.takePicture
                @$scope.skipPicture  = this.skipPicture
                @$scope.grabCamera = this.grabCamera
                @$scope.cancelGrabCamera = this.cancelGrabCamera
                @$scope.submitForm = this.submitForm
                @$scope.pictureChanged = this.pictureChanged
                @$scope.pictureDelete = this.pictureDelete
                @$scope.geolocateMarker = this.geolocateMarker
                @$scope.lookupAddress = this.lookupAddress

                # Use debounce to prevent multiple calls
                @$scope.on_marker_preview_moved = @debounce(this.on_marker_preview_moved)

                # Cursor move callback
                @$scope.$watch('marker_preview.lat + marker_preview.lng', =>
                        @$scope.on_marker_preview_moved()
                )


        submitForm: =>
                """
                Submit the form to create a new point
                """
                # XXX Hacky
                @$scope.marker.tile_layer = @MapService.getCurrentLayer().uri

                @$scope.marker.$save(=>
                        console.debug("new marker saved")
                        @$location.path("/")
                )

                # XXX Need to post picture

        skipPicture: =>
                """
                Button callback for 'Skip adding picture'
                """
                @$scope.captureInProgress = false
                @$scope.previewInProgress = false

        pictureDelete: =>
                #preview = document.querySelector("#selected-photo")
                #preview.src = ""
                @$scope.marker.image = null
                @$scope.previewInProgress = false
                @$scope.marker.image = null

        pictureChanged: (field) =>
                """
                When the user picked a picture from her hardrive (or camera on Mobile devices)
                """
                file = field.files[0]

                if not file
                        console.debug("Picture now empty")
                        return

                # Make sure we have an image and the browser supports HTML5
                if typeof(FileReader) == "undefined" || not (/image/i).test(file.type)
                        console.debug("Unknown type #{file.type}")
                        return

                # Prepare preview placeholder
                preview = document.querySelector("#selected-photo")
                #preview.classList.add("obj")
                #preview.file = file

                # Read the preview from the file
                reader = new FileReader()
                reader.onload = (e) =>
                        preview.setAttribute("src", e.target.result)

                reader.readAsDataURL(file)

                console.debug("Step: preview picture")
                @$scope.previewInProgress = true
                @$scope.$apply()

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
                data = canvas.toDataURL("image/png")

                photo = document.querySelector("#selected-photo")
                photo.setAttribute("src", data)

                video = document.querySelector("#video")
                video.src = ""

                @$scope.captureInProgress = false
                @$scope.previewInProgress = true


        on_marker_preview_moved: =>
                """
                When the marker was moved
                """
                pro = @geolocation.resolveLatLng(@$scope.marker_preview.lat, @$scope.marker_preview.lng).then((address)=>
                        console.debug("Found address match: #{address.formatted_address}")
                        @$scope.marker.position.address = angular.copy(address.formatted_address)
                )


        geolocateMarker: =>
                console.debug("Getting user position...")
                p = @geolocation.position().then((pos) =>
                        console.debug("Resolving #{pos.coords.latitude}")
                        @$scope.marker.position.coordinates = [pos.coords.latitude, pos.coords.longitude]

                        # Update preview marker position
                        @$scope.marker_preview.lat = @$scope.marker.position.coordinates[0]
                        @$scope.marker_preview.lng = @$scope.marker.position.coordinates[1]

                        # Focus on new location
                        @MapService.center =
                                lat: @$scope.marker_preview.lat
                                lng: @$scope.marker_preview.lng
                                zoom: 20

                )

        lookupAddress: =>
                """
                Given an address, find lat/lng
                """
                console.debug("looking up #{@$scope.marker.position.address}")
                pos_promise = @geolocation.lookupAddress(@$scope.marker.position.address).then((coords)=>
                        console.debug("Found pos #{coords}")
                        @$scope.marker.position.coordinates = angular.copy(coords)

                        # Focus on new position
                        @MapService.center =
                                lat: @$scope.marker.position.coordinates[0]
                                lng: @$scope.marker.position.coordinates[1]
                                zoom: 15

                        # Update preview marker position
                        @$scope.marker_preview.lat = @$scope.marker.position.coordinates[0]
                        @$scope.marker_preview.lng = @$scope.marker.position.coordinates[1]
                )


# Controller declarations
module.controller("MapDetailCtrl", ['$scope', '$routeParams', 'MapService', 'Map', 'geolocation', MapDetailCtrl])
module.controller("MapNewCtrl", ['$scope', "Map", MapNewCtrl])
module.controller("MapMarkerDetailCtrl", ['$scope', '$routeParams', 'Marker', MapMarkerDetailCtrl])
module.controller("MapMarkerNewCtrl", ['$scope', '$rootScope', 'debounce', '$location', 'MapService', 'Marker', 'geolocation', MapMarkerNewCtrl])
