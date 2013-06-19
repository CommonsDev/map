config = {
    templateBaseUrl: '/views/'
}

angular.module('map', ['map.controllers', 'map.services', 'leaflet-directive']);
angular.module('common', ['common.filters']);

angular.module('gup', ['common', 'map', 'http-auth-interceptor']).constant('moduleTemplateBaseUrl', config.templateBaseUrl + 'map/').config(['$locationProvider', '$routeProvider', 'moduleTemplateBaseUrl', function($locationProvider, $routeProvider, moduleTemplateBaseUrl){
					   $locationProvider.html5Mode(true);
					   $routeProvider
					       .when('/', {
							
						     })
					       .when('/new', {
							 templateUrl: moduleTemplateBaseUrl + 'new.html',
							 controller: 'MapNewCtrl'
						     })
						.when('/marker/detail/:markerId', {
							  templateUrl: moduleTemplateBaseUrl + 'marker_detail.html',
							  controller: 'MapMarkerDetailCtrl'
						      })
					       .otherwise({redirectTo: '/'});
				       }
				      ])

