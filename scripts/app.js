config = {
    templateBaseUrl: '/views/',
}

angular.module('map', ['map.controllers', 'map.services', 'leaflet-directive']);
angular.module('common', ['common.filters', 'common.controllers', 'common.services']);

app = angular.module('unisson_map', ['common', 'map', 'ui.router']);

// Config
app.constant('moduleTemplateBaseUrl', config.templateBaseUrl + 'map/');

app.config(function(RestangularProvider) {
	       RestangularProvider.setBaseUrl("http://carpe.local:8000/api/v0");

	       /* Tastypie patch */
	       RestangularProvider.setResponseExtractor(function(response, operation, what, url) {
							    var newResponse;
							    if (operation === "getList") {
								newResponse = response.objects;
								newResponse.metadata = response.meta;
							    } else {
								newResponse = response;
							    }
							    return newResponse;
							});

	   });

app.config(['$locationProvider', '$stateProvider', '$urlRouterProvider', 'moduleTemplateBaseUrl', 
	    function($locationProvider, $stateProvider, $urlRouterProvider, moduleTemplateBaseUrl) {
		$locationProvider.html5Mode(false);
		$urlRouterProvider.otherwise("/")

		$stateProvider
		    .state('index', {
			       url: '/',
			       controller: 'MapNewCtrl',
			       page_title: 'Bienvenue',
			       templateUrl: moduleTemplateBaseUrl + 'map_new.html',
			   })
		    .state('map', {
			       url: '/:slug',
			       templateUrl: moduleTemplateBaseUrl + 'map_detail.html',
			       controller: 'MapDetailCtrl'
			   })
		    .state('map.marker_new', {
			       url: '/marker/new',
			       templateUrl: moduleTemplateBaseUrl + 'marker_new.html',
			       controller: 'MapMarkerNewCtrl'
			   })
		    .state('map.marker_detail', {
			      url: '/marker/:markerId',
			      templateUrl: moduleTemplateBaseUrl + 'marker_detail.html',
			      controller: 'MapMarkerDetailCtrl'
			   });

		/*
		$routeProvider
		    .when('/', {
			      templateUrl: moduleTemplateBaseUrl + 'map_new.html',
			      controller: 'MapNewCtrl'
			  })
		    .when('/:slug', {
			      templateUrl: moduleTemplateBaseUrl + 'map_detail.html'
			  })
		    .when('/marker/new', {
			      templateUrl: moduleTemplateBaseUrl + 'marker_new.html',
			      controller: 'MapMarkerNewCtrl'
			  })
		    .when('/marker/:markerId', {
			      templateUrl: moduleTemplateBaseUrl + 'marker_detail.html',
			      controller: 'MapMarkerDetailCtrl'
			  })
		    .otherwise({redirectTo: '/'});
		 */
	    }
	   ]);

app.run(['$rootScope', function($rootScope) {
  $rootScope.MEDIA_URI = 'http://localhost:8000';
  $rootScope.CONFIG = config;

  $rootScope.$on('$stateChangeSuccess', function (event, current, previous) {
		     if ( current.page_title )
			 $rootScope.page_title = current.page_title;
		 });

}]);
