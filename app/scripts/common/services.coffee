services = angular.module("common.services", [])
services.constant("options", {enableHighAccuracy: false, maximumAge: 60000, timeout: 5000})

class GeolocationService
        """
        A geolocation service to get and watch user position
        """
        constructor: (@$q, @$rootScope, @$window, @options) ->
                if not @$window.navigator.geolocation
                        console.warn("Geolocation not supported.")

                @geocoder = new google.maps.Geocoder()

                @watchId = null
                @$rootScope.position = {}

                @$rootScope.isGeolocating = false

        position: =>
                @$rootScope.isGeolocating = true

                deferred = @$q.defer()
                @$window.navigator.geolocation.getCurrentPosition(
                        (pos) =>
                                @$rootScope.$apply(=>
                                        @$rootScope.isGeolocating = false
                                        deferred.resolve(angular.copy(pos))
                                )
                        , (error) =>
                                @$rootScope.$apply(=>
                                        @$rootScope.isGeolocating = false
                                        deferred.reject(error)
                                )
                        , @options
                )
                return deferred.promise

        watchPosition: (callback) =>
                """
                watch current position of user
                """
                console.debug("Watching user location...")
                @watchId = @$window.navigator.geolocation.watchPosition(callback, ->
                        console.debug("error while getting position")
                ,
                        enableHighAccuracy: true,
                        maximumAge: 1000,
                        timeout: 3000
                )

        cancelWatchPosition: =>
                """
                Cancel watching user position
                """
                @$window.navigator.geolocation.clearWatch(@watchId)


        lookupAddress: (location) =>
                deferred = @$q.defer()
                @geocoder.geocode({'address': location},
                        (results, status) =>
                                if status == google.maps.GeocoderStatus.OK
                                        latLong = [ results[0].geometry.location.lat(), results[0].geometry.location.lng(), results[0].geometry.viewport ]
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

                @geocoder.geocode({'latLng': latlng}, (results, status) =>
                        if status == google.maps.GeocoderStatus.OK
                                if results[0]
                                        @$rootScope.$apply(->
                                                deferred.resolve(angular.copy(results[0]))
                                        )
                        else
                                @$rootScope.$apply( ->
                                        deferred.reject(status)
                                )
                )

                return deferred.promise




services.factory('debounce', ['$timeout', ($timeout) ->
        return (fn, timeout, apply) -> # debounce fn
            timeout = angular.isUndefined(timeout) ? 0 : timeout
            apply = angular.isUndefined(apply) ? true : apply # !!default is true! most suitable to my experience
            nthCall = 0
            return -> # intercepting fn
                that = this
                argz = arguments
                nthCall++
                later = ((version) ->
                    return ->
                        if (version is nthCall)
                            return fn.apply(that, argz)
                )(nthCall)
                return $timeout(later, timeout, apply)
])



services.service("geolocation", [ "$q", "$rootScope", "$window", "options", GeolocationService])
