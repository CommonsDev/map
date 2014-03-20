# -*- tab-width: 4 -*-
module = angular.module("leaflet-directive", [])

class LeafletController
    constructor: (@$scope) ->
        @$scope.marker_instances = []

    addMarker: (lat, lng, options) =>
        marker = new L.marker([lat, lng], options).addTo(@$scope.map)

        return marker

    removeMarker: (aMarker) =>
        @$scope.map.removeLayer(aMarker)


module.controller("LeafletController", ['$scope', LeafletController])

module.directive("leaflet", ["$http", "$log", "$location", ($http, $log, $location) ->
    return {
        restrict: "E"
        replace: true
        transclude: true
        scope:
            center: "=center"
            tilelayer: "=tilelayer"
            path: "=path"
            maxZoom: "@maxzoom"

        template: '<div class="angular-leaflet-map"><div ng-transclude></div></div>'

        controller: 'LeafletController'

        link: ($scope, element, attrs, ctrl) ->
            $el = element[0]
            # maxBounds set to Lille area 50.59685933376767,2.9827880859375 
            sW = new L.latLng(50.59021193935192,2.96356201171875)
            nE = new L.latLng(50.66088773034316,3.1470680236816406)
            lilleBounds = new L.latLngBounds(sW, nE)
            $scope.map = new L.Map($el,
                zoomControl: true
                zoomAnimation: true
                scrollWheelZoom: false
                dragging: true
                maxBounds: lilleBounds
                maxZoom: 16 
                minZoom: 13
                # crs: L.CRS.EPSG4326
            )
            
            # Fake center, required sometimes for the plugins to work...
            $scope.map.setView([39.950041, -75.169884], 16)

            # Change callback
            $scope.$watch("center", ((center, oldValue) ->
                    console.debug("map center changed")
                    $scope.map.setView([center.lat, center.lng], center.zoom)
                ), true
            )

            # Center
            if not attrs.center
                console.debug("setting default center")
                $scope.map.setView([0, 0], 1)

            # On "get_center" signal
            $scope.$on('map.get_center', (event, callback) =>
                center = $scope.map.getCenter()
                zoom = $scope.map.getZoom()
                callback(center, zoom)
            )

            maxZoom = $scope.maxZoom or 12

            # Tile layers. XXX Should be a sub directive?
            $scope.$watch("tilelayer", (layer, oldLayer) =>
                # Remove current layers
                $scope.map.eachLayer((layer) =>
                    console.debug("removed layer #{layer._url}")
                    #$scope.map.removeLayer(layer)
                )

                # Add new ones
                if layer
                    console.debug("installing new layer #{layer.url_template}")

                    latLngGeom = []

                    lille = window.lille
                    for jump in lille.coordinates
                       for coord in jump
                            latLngGeom.push(new L.LatLng(coord[1], coord[0]))

                    layer.attrs['boundary'] = latLngGeom
                    layer.attrs['attribution'] = 'Contenu et identité graphique &copy Koan 2014' # FIXME

                    leaflayer = L.TileLayer.boundaryCanvas(layer.url_template, layer.attrs)
                    leaflayer.addTo($scope.map)

                    leaflayer.bringToBack()

            , true
            )



            # Add feature selects
            console.debug("loading features...")
            myStyle = {
                "color": "#EB2228",
                "dashArray": "5, 4",
                "lineCap": "butt",
                "lineJoin": "miter",
                "weight": 5,
                "opacity": 0.65,
                "className": "feature"
            }

            layer = L.geoJson(window.districts,
                style: myStyle
                onEachFeature: (feature, layer) ->
                    label = new L.Label({className:"label", offset:[0,-30]})
                    label.setContent(feature.name)
                    center = layer.getBounds().getCenter()
                    console.debug(" == center ==")
                    console.debug(label)
                    #label.setLatLng(center[0] - 0.1, center[1])
                    label.setLatLng(center)
                    console.debug(label)
                    #layer.bindLabel("WAZEMMES", {noHide: true}).addTo($scope.map)
                    $scope.map.showLabel(label);
                    layer.on(
                        click: (e) ->
                            $scope.map.fitBounds(e.target.getBounds())
                    )
                    layer.setStyle(
                        color: "#CCCCCC"
                        opacity: 0.9
                    )
                    layer.on(
                        mouseover: (e)->
                            layer.setStyle(
                                color: "#ff0000"
                                opacity: 0.9
                            )
                    )
                    layer.on(
                        mouseout: (e)->
                            layer.setStyle(
                                color: "#CCCCCC"
                                opacity: 0.9
                            )
                    )
            )
            fs = L.featureSelect({
                featureGroup: layer
                selectSize: [16, 16]
            })

            
            
           
           


            layer.addTo($scope.map)
            fs.addTo($scope.map)

            # Make a minimap
            miniLayer = new L.TileLayer("http://{s}.tile.stamen.com/toner/{z}/{x}/{y}.jpg", {minZoom: 0, maxZoom: 18});
            miniMap = new L.Control.MiniMap(miniLayer, {zoomLevelFixed: 12}).addTo($scope.map)


            """
            # Manage map center events
            if attrs.center and $scope.center
              if $scope.center.lat and $scope.center.lng and $scope.center.zoom
                map.setView(new L.LatLng($scope.center.lat, $scope.center.lng), $scope.center.zoom)
              else if $scope.center.autoDiscover is true
                map.locate(
                  setView: true
                  maxZoom: maxZoom
                )

              map.on("dragend", (e) ->
                $scope.$apply((s) ->
                  s.center.lat = map.getCenter().lat
                  s.center.lng = map.getCenter().lng
                )
              )

              # Zoom
              map.on("zoomend", (e) ->
                $scope.$apply((s) ->
                  s.center.zoom = map.getZoom()
                )
              )



                $scope.$watch("markers." + mkey + ".draggable", (newValue, oldValue) ->
                  if newValue is false
                    marker.dragging.disable()
                  else if newValue is true
                    marker.dragging.enable()
                )


            if attrs.path
              polyline = new L.Polyline([],
                weight: 10
                opacity: 1
              )
              map.addLayer(polyline)
              $scope.$watch("path.latlngs", ((latlngs) ->
                idx = 0
                length = latlngs.length

                while idx < length
                  if latlngs[idx] is `undefined` or latlngs[idx].lat is `undefined` or latlngs[idx].lng is `undefined`
                    $log.warn("Bad path point inn the $scope.path array ")
                    latlngs.splice(idx, 1)
                  idx++
                polyline.setLatLngs(latlngs)
              ), true
              )

              $scope.$watch("path.weight", ((weight) ->
                polyline.setStyle(weight: weight)
              ), true
              )

              $scope.$watch("path.color", ((color) ->
                polyline.setStyle(color: color)
              ), true
              )
            """
            null
    }
])


module.directive("leafletMarker", ($timeout) ->
    return {
        restrict: 'E'
        require: '^leaflet'

        transclude: true
        replace: true
        template: '<div ng-transclude></div>'

        scope:
            marker: "="

        link: ($scope, $elem, attrs, ctrl) ->
            marker_instance = ctrl.addMarker($scope.marker.lat, $scope.marker.lng, $scope.marker.options)
            $scope.marker.instance = marker_instance
            marker_instance.getLatLng()

            # Marker lat/lng changes
            $scope.$watch("marker.lat", (newValue, oldValue) ->
                if $scope.marker.dragging or not newValue
                    return
                $scope.marker.instance.setLatLng(new L.LatLng(newValue, $scope.marker.instance.getLatLng().lng))
            )

            $scope.$watch("marker.lng", (newValue, oldValue) ->
                if $scope.marker.dragging or not newValue
                    return
                $scope.marker.instance.setLatLng(new L.LatLng($scope.marker.instance.getLatLng().lat, newValue))
            )


            # Dragging
            $scope.marker.instance.on("dragstart", (e) ->
                $scope.marker.dragging = true
            )

            $scope.marker.instance.on("drag", (e) ->
                $scope.$apply((s) ->
                    $scope.marker.lat = $scope.marker.instance.getLatLng().lat
                    $scope.marker.lng = $scope.marker.instance.getLatLng().lng
                )
            )

            $scope.marker.instance.on("dragend", (e) ->
                  $scope.marker.dragging = false
            )


            $scope.$on('$destroy', ->
                ctrl.removeMarker($scope.marker.instance)
            )
    }
)

module.directive("leafletPopup", ($timeout) ->
    return {
        restrict: 'CA'
        replace: false

        link: ($scope, $elem, attrs, ctrl) ->
            # Wait for dom to render
            $timeout(->
                $scope.marker.instance.bindPopup($($elem).html())
            , 0)

    }
)
