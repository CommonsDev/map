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
            tilelayers: "=tilelayers"
            path: "=path"
            maxZoom: "@maxzoom"

        template: '<div class="angular-leaflet-map"><div ng-transclude></div></div>'

        controller: 'LeafletController'

        link: ($scope, element, attrs, ctrl) ->
            $el = element[0]

            $scope.map = new L.Map($el)

            # Center
            if attrs.center
                console.debug("setting center to")
                $scope.map.setView([$scope.center.lat, $scope.center.lng], $scope.center.zoom)
            else
                $scope.map.setView([0, 0], 1)

            # Change callback
            $scope.$watch("center", ((center, oldValue) ->
                    $scope.map.setView([center.lat, center.lng], center.zoom)
                ), true
            )


            maxZoom = $scope.maxZoom or 12


            # Add tile layers
            if $scope.tilelayers
              for tile_name, tile_data of $scope.tilelayers
                L.tileLayer(tile_data.url_template, tile_data.attrs).addTo($scope.map)




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


            if attrs.markers isnt `undefined`
              markers_dict = []
              createAndLinkMarker = (mkey, $scope) ->
                markerData = $scope.markers[mkey]
                marker = new L.marker($scope.markers[mkey], markerData.attrs)

                if markerData.href
                  marker.on('click', =>
                    $location.path(markerData.href)
                    $scope.$apply()
                  )


                if markerData.message
                  $scope.$watch("markers." + mkey + ".message", (newValue) ->
                    marker.bindPopup(markerData.message)
                  )

                # Focus
                $scope.$watch("markers." + mkey + ".focus", (newValue) ->
                  if newValue
                    if markerData.callback
                      markerData.callback(marker, markerData)
                    else if markerData.message
                      marker.openPopup()
                )

                $scope.$watch("markers." + mkey + ".draggable", (newValue, oldValue) ->
                  if newValue is false
                    marker.dragging.disable()
                  else if newValue is true
                    marker.dragging.enable()
                )

                # Dragging events
                dragging_marker = false


                return marker

              # end of create and link marker

              # Marker watches
              $scope.$watch("markers", ((newMarkerList) ->
                # find deleted markers
                for delkey of markers_dict
                  unless $scope.markers[delkey]
                    map.removeLayer(markers_dict[delkey])
                    delete markers_dict[delkey]

                # add new markers
                for mkey of $scope.markers
                  if markers_dict[mkey] is `undefined`
                    marker = createAndLinkMarker(mkey, $scope)
                    map.addLayer(marker)
                    markers_dict[mkey] = marker
                ), true
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

        require: '^leaflet'

        link: ($scope, $elem, attrs, ctrl) ->
            # Wait for dom to render
            $timeout(->
                $scope.marker.instance.bindPopup($($elem).html())
            , 0)

    }
)