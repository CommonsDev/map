services = angular.module("common.services", [])
services.constant("options", {enableHighAccuracy: true})

class GeolocationService
        """
        A geolocation service to get and watch user position
        """
        constructor: (@$q, @$rootScope, @options) ->
                if not navigator.geolocation
                        console.warn("Geolocation not supported.")

                @geocoder = new google.maps.Geocoder()

                @watchId = null
                @$rootScope.position = {}

        position: =>
                deferred = @$q.defer()
                navigator.geolocation.getCurrentPosition(
                        (pos) =>
                                @$rootScope.$apply(->
                                        deferred.resolve(angular.copy(pos))
                                )
                        , (error) =>
                                @$rootScope.$apply( ->
                                        deferred.reject(error)
                                )
                        , @options
                )
                return deferred.promise

        watchPosition: =>
                """
                watch current position of user
                """
                console.debug("Watching user location...")
                @watchId = navigator.geolocation.watchPosition(
                        (pos) =>
                                @$rootScope.$apply(=>
                                        @$rootScope.position = angular.copy(pos)
                                )
                )

        cancelWatchPosition: =>
                """
                Cancel watching user position
                """
                navigator.geolocation.clearWatch(@watchId)


        lookupAddress: (location) =>
                deferred = @$q.defer()
                @geocoder.geocode({'address': location},
                        (results, status) =>
                                if status == google.maps.GeocoderStatus.OK
                                        latLong = [ results[0].geometry.location.lat(), results[0].geometry.location.lng() ]
                                        @$rootScope.$apply(->
                                                deferred.resolve(angular.copy(latLong))
                                        )
                                else
                                        @$rootScope.$apply( ->
                                                deferred.reject(status)
                                        )
                )
                return deferred.promise

        resolveLatLng: (lat, lng) =>
                deferred = @$q.defer()
                latlng = new google.maps.LatLng(lat, lng)
                @geocoder.geocode({'latLng': latlng},
                        (results, status) =>
                                if status == google.maps.GeocoderStatus.OK
                                        if results[1]
                                                @$rootScope.$apply(->
                                                        deferred.resolve(angular.copy(results[1]))
                                                )
                                else
                                        @$rootScope.$apply( ->
                                                deferred.reject(status)
                                        )
                )
                return deferred.promise





services.service("geolocation", [ "$q", "$rootScope", "options", GeolocationService])