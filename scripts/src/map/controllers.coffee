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
                                url_template: 'http://tile.openstreetmap.org/{z}/{x}/{y}.png'
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

                @geolocation.position().then((pos)=>
                        console.debug(pos.coords)
                )

                video = document.querySelector("#video")
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

                # The possible new marker
                @$scope.marker = new @Marker()

                # Wizard Steps
                @$scope.captureInProgress = false
                @$scope.previewInProgress = false

                # add functions and variable to scope
                @$scope.takePicture = this.takePicture
                @$scope.skipPicture  = this.skipPicture
                @$scope.grabCamera = this.grabCamera
                @$scope.cancelGrabCamera = this.cancelGrabCamera
                @$scope.submitForm = this.submitForm
                @$scope.pictureChanged = this.pictureChanged
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

        pictureChanged: (field) =>
                """
                When the user picked a picture from her hardrive (or camera on Mobile devices)
                """
                console.debug(field)
                file = field
                if not file.type.match(/image.*/)
                        console.debug("Unknown type #{file.type}")
                        return

                photo = document.querySelector("#selected-photo")
                photo.setAttribute("src", data)

                photo.classList.add("obj")
                photo.file = file

                reader = new FileReader()
                reader.onload = (aImg) ->
                        return (e) ->
                                photo.src = e.target.result
                reader.readAsDataURL(file)

                @$scope.previewInProgress = true

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
                pos_promise = @geolocation.position().then(=>
                        console.debug('yo')
                )




# Controller declarations
module.controller("MapDetailCtrl", ['$scope', 'Map', MapDetailCtrl])
module.controller("MapNewCtrl", ['$scope', "Map", MapNewCtrl])
module.controller("MapMarkerDetailCtrl", ['$scope', '$routeParams', 'Marker', MapMarkerDetailCtrl])
module.controller("MapMarkerNewCtrl", ['$scope', 'Marker', 'geolocation', MapMarkerNewCtrl])
