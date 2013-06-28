module = angular.module('map.controllers', [])

class MapDetailCtrl
        constructor: (@$scope, @Map, @geolocation) ->
                icon = L.icon({
                        iconUrl: '/images/pointer.png'
                        shadowUrl: null,
                        iconSize: new L.Point(61, 61)
                        iconAnchor: new L.Point(4, 56)
                })

                @$scope.tilelayers =
                        truc:
                                url_template: 'http://tile.openstreetmap.org/{z}/{x}/{y}.png'
                                attrs:
                                        zoom: 4

                @$scope.center =
                        lat: 0
                        lng: 0
                        zoom: 1





                #.then((position) =>
                #         @$scope.markers['my_position'] =
                #                 lat: position.coords.latitude
                #                lng: position.coords.longitude
                #        console.debug("User is at (#{position.coords.latitude}, #{position.coords.longitude})")
                #)

                @$scope.markers = {}

                @$scope.map = @Map.get({mapId: 1}, (aMap, getResponseHeaders) => # FIXME: HARDCODED VALUE
                        # Locate user using HTML5 Api or use map center
                        if aMap.locate
                                @geolocation.watchPosition()

                                #@geolocation.position().then((position) =>
                                #        @$scope.center =
                                #                lat: position.coords.latitude
                                #                lng: position.coords.longitude
                                #                zoom: aMap.zoom
                                #        console.debug("map center set to #{position.coords.latitude}, #{position.coords.longitude}")
                                #)
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
        constructor: (@$scope, @Marker, @geolocation) ->
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

                # Geolocation
                this.geolocateMarker()

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

        submitForm: =>
                """
                Submit the form to create a new point
                """
                # Position
                @$scope.marker.position = {}
                @$scope.marker.position.coordinates = [30.0, 50.0]
                @$scope.marker.position.type = "Point"

                @$scope.marker.tile_layer = "/api/scout/v0/tilelayer/1"
                @$scope.marker.created_by = "/api/account/v0/profile/1"

                @$scope.marker.$save(=>
                        console.debug("new marker saved")
                )

        skipPicture: =>
                """
                Button callback for 'Skip adding picture'
                """
                @$scope.captureInProgress = false
                @$scope.previewInProgress = false

        pictureDelete: =>
                preview = document.querySelector("#selected-photo")
                preview.src = ""
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

        geolocateMarker: =>
                pos_promise = @geolocation.lookupAddress("3 Chemin de la cluse, 62126 Wimille").then((pos)=>
                        console.debug("Found pos #{pos}")
                )

                pos_promise = @geolocation.resolveLatLng(42.2128, 71.0342).then((address)=>
                        console.debug("Resolved to: #{address.formatted_address}")
                )




# Controller declarations
module.controller("MapDetailCtrl", ['$scope', 'Map', 'geolocation', MapDetailCtrl])
module.controller("MapNewCtrl", ['$scope', "Map", MapNewCtrl])
module.controller("MapMarkerDetailCtrl", ['$scope', '$routeParams', 'Marker', MapMarkerDetailCtrl])
module.controller("MapMarkerNewCtrl", ['$scope', 'Marker', 'geolocation', MapMarkerNewCtrl])
