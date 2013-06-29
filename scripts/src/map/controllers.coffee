module = angular.module('map.controllers', [])

class MapDetailCtrl
        addMarker: (name, aMarker) =>
                console.debug("creating marker #{name}...")
                @$scope.markers[name] = aMarker

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
                                        zoom: 12

                @$scope.center =
                        lat: 1.0
                        lng: 1.0
                        zoom: 8


                @$scope.$on('map:createMarker', (event, args) =>
                        this.addMarker(args.name, args.marker)
                )

                @$scope.$on('map:setCenter', (event, args) =>
                        console.debug("setting center to #{args.latitude}, #{args.longitude}, #{args.zoom}")
                        @$scope.center =
                                lat: args.latitude
                                lng: args.longitude
                                zoom: args.zoom
                )



                #.then((position) =>
                #        console.debug("User is at (#{position.coords.latitude}, #{position.coords.longitude})")
                #)

                @$scope.markers = {}

                @$scope.map = @Map.get({mapId: 1}, (aMap, getResponseHeaders) => # FIXME: HARDCODED VALUE
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
                                @$scope.center =
                                        lat: aMap.center.coordinates[0]
                                        lng: aMap.center.coordinates[1]
                                        zoom: aMap.zoom

                        # Add every marker (FIXME: Should handle layers)
                        for layer in aMap.tile_layers
                                @$scope.tilelayers[layer.name] =
                                                url_template: 'http://tile.stamen.com/watercolor/{z}/{x}/{y}.jpg'
                                                attrs:
                                                        zoom: 12

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
        constructor: (@$scope, @$rootScope, @Marker, @geolocation) ->
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

        submitForm: =>
                """
                Submit the form to create a new point
                """
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
                console.debug("Getting user position...")
                p = @geolocation.position().then((pos) =>
                        console.debug("Resolving #{pos.coords.latitude}")
                        @$scope.marker.position.coordinates = [pos.coords.latitude, pos.coords.longitude]

                        @$rootScope.$broadcast('map:setCenter',
                                latitude: pos.coords.latitude
                                longitude: pos.coords.longitude
                                zoom: 15
                        )


                        if not @map_marker
                                @map_marker =
                                        lat: @$scope.marker.position.coordinates[0]
                                        lng: @$scope.marker.position.coordinates[1]
                                        draggable: true
                                        attrs:
                                                icon: L.icon({
                                                        iconUrl: '/images/poi_localisation.png'
                                                        shadowUrl: null,
                                                        iconSize: new L.Point(65, 75)
                                                        iconAnchor: new L.Point(4, 37)
                                                        })

                                @$rootScope.$broadcast('map:createMarker',
                                        name: 'my_position'
                                        marker: @map_marker
                                )
                        else
                                @map_marker.lat = @$scope.marker.position.coordinates[0]
                                @map_marker.lng = @$scope.marker.position.coordinates[1]


                        pro = @geolocation.resolveLatLng(pos.coords.latitude, pos.coords.longitude).then((address)=>
                                @$scope.marker.position.address = angular.copy(address.formatted_address)
                        )
                )

        lookupAddress: =>
                console.debug("looking up #{@$scope.marker.position.address}")
                pos_promise = @geolocation.lookupAddress(@$scope.marker.position.address).then((coords)=>
                        console.debug("Found pos #{coords}")
                        @$scope.marker.position.coordinates = angular.copy(coords)

                        @$rootScope.$broadcast('map:setCenter',
                                latitude: @$scope.marker.position.coordinates[0]
                                longitude: @$scope.marker.position.coordinates[1]
                                zoom: 15
                        )

                        @$rootScope.$broadcast('map:createMarker',
                                name: 'my_position'
                                marker:
                                        lat: @$scope.marker.position.coordinates[0]
                                        lng: @$scope.marker.position.coordinates[1]
                                        draggable: true
                                        attrs:
                                                icon: L.icon({
                                                        iconUrl: '/images/poi_localisation.png'
                                                        shadowUrl: null,
                                                        iconSize: new L.Point(65, 75)
                                                        iconAnchor: new L.Point(4, 37)
                                                        })

                        )

                )


# Controller declarations
module.controller("MapDetailCtrl", ['$scope', 'Map', 'geolocation', MapDetailCtrl])
module.controller("MapNewCtrl", ['$scope', "Map", MapNewCtrl])
module.controller("MapMarkerDetailCtrl", ['$scope', '$routeParams', 'Marker', MapMarkerDetailCtrl])
module.controller("MapMarkerNewCtrl", ['$scope', '$rootScope', 'Marker', 'geolocation', MapMarkerNewCtrl])
