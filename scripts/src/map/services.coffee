services = angular.module('map.services', ['ngResource'])

services.factory('Map', ['$resource', '$rootScope', ($resource, $rootScope) ->
        return $resource("#{$rootScope.CONFIG.REST_URI}scout/v0/map/:mapId?format=json", {mapId: "@id"})
])

services.factory('Marker', ['$resource', '$rootScope', ($resource, $rootScope) ->
        return $resource("#{$rootScope.CONFIG.REST_URI}scout/v0/marker/:markerId?format=json", {markerId: "@id"})
])
