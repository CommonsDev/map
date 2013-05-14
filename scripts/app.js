angular.module('map', ['map.controllers', 'map.services', 'leaflet-directive']);

angular.module('gup', ['map']).config(['$locationProvider', '$routeProvider', function($locationProvider, $routeProvider){
					   $locationProvider.html5Mode(true);
					   $routeProvider
					       .when('/', {
							 templateUrl: '/views/map/list.html',
							 controller: 'MapCtrl',
						     })
					       .when('/new', {
							 templateUrl: '/views/map/new.html',
							 controller: 'MapNewCtrl'
						     })
					       .otherwise({redirectTo: '/'});
				       }
				      ])

