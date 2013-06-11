# -*- tab-width: 2 -*-
leafletDirective = angular.module("leaflet-directive", [])

leafletDirective.directive "leaflet", ["$http", "$log", "$location", ($http, $log, $location) ->
  restrict: "E"
  replace: true
  transclude: true
  scope:
    center: "=center"
    tilelayers: "=tilelayers"
    markers: "=markers"
    path: "=path"
    maxZoom: "@maxzoom"

  template: '<div class="angular-leaflet-map"></div>'

  link: ($scope, element, attrs, ctrl) ->
    $el = element[0]
    map = new L.Map($el)

    # Expose the map object, for testing purposes
    $scope.map = map if attrs.map

    # Set initial view
    map.setView([0, 0], 1)

    maxZoom = $scope.maxZoom or 12

    # Add tile layers
    if $scope.tilelayers
      for tile_name, tile_data of $scope.tilelayers
        L.tileLayer(tile_data.url_template, tile_data.attrs).addTo(map)

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

      # Center
      $scope.$watch("center", ((center, oldValue) ->
          map.setView([center.lat, center.lng], center.zoom)
        ), true
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

        marker.on("dragstart", (e) ->
          dragging_marker = true
        )

        marker.on("drag", (e) ->
          $scope.$apply((s) ->
            markerData.lat = marker.getLatLng().lat
            markerData.lng = marker.getLatLng().lng
          )
        )

        marker.on("dragend", (e) ->
          dragging_marker = false
          if markerData.message
            marker.openPopup()
        )

        # Marker changes
        $scope.$watch("markers." + mkey, (->
            marker.setLatLng($scope.markers[mkey])
          ), true
        )
        $scope.$watch("markers" + mkey + ".lng", (newValue, oldValue) ->
          return  if dragging_marker or not newValue
          marker.setLatLng(new L.LatLng(marker.getLatLng().lat, newValue))
        )

        $scope.$watch("markers" + mkey + ".lat", (newValue, oldValue) ->
          return if dragging_marker or not newValue
          marker.setLatLng(new L.LatLng(newValue, marker.getLatLng().lng))
        )
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
]
