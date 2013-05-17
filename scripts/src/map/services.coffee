services = angular.module('map.services', ['ngResource'])

services.factory('Map', ($resource) ->
        return $resource('http://localhost\\:8000/api/scout/v0/map/:mapId?format=json', {mapId: "@id"})
)
