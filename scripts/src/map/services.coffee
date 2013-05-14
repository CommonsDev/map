services = angular.module('map.services', ['ngResource'])

services.factory('Map', ($resource) ->
        return $resource('http://localhost\\:8000/api/scout/v0/map/:id?format=json', {id: "@Id"})
)
