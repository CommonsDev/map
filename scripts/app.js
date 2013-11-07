config = {
    templateBaseUrl: '/views/',
}

angular.module('map', ['map.controllers', 'map.services', 'map.filters', 'leaflet-directive']);
angular.module('common', ['common.filters', 'common.controllers', 'common.services']);

app = angular.module('unisson_map', ['common', 'map', 'ui.router', 'ngAnimate', 'googleOauth']);

// Config
app.constant('moduleTemplateBaseUrl', config.templateBaseUrl + 'map/');

app.config(['TokenProvider', '$locationProvider', function(TokenProvider, $locationProvider) {
		TokenProvider.extendConfig({
					       clientId: '645581170749.apps.googleusercontent.com',
					       redirectUri: 'http://localhost:8080/oauth2callback.html',
					       scopes: ["https://www.googleapis.com/auth/userinfo.email",
							"https://www.googleapis.com/auth/userinfo.profile"],
					   });
	    }])


app.config(function(RestangularProvider) {
	       RestangularProvider.setBaseUrl("http://localhost:8000/api/v0");
	       //RestangularProvider.setBaseUrl("http://api.gup.extra-muros.coop/api/v0");

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
		    .state('index.my_maps', {
			       url: '/my_maps',
			       templateUrl: moduleTemplateBaseUrl + 'map_mymaps.html',
			   })
		    .state('map', {
			       url: '/:slug',
			       templateUrl: moduleTemplateBaseUrl + 'map_detail.html',
			       controller: 'MapDetailCtrl'
			   })
		    .state('map.welcome', {
			       url: '/welcome',
			       templateUrl: moduleTemplateBaseUrl + 'map_welcome.html'
			   })
		    .state('map.search', {
			       url: '/search',
			       templateUrl: moduleTemplateBaseUrl + 'map_search.html',
			       controller: 'MapSearchCtrl'
			   })
		    .state('map.marker_new', {
			       url: '/marker/new',
			       templateUrl: moduleTemplateBaseUrl + 'marker_new.html',
			       controller: 'MapMarkerNewCtrl'
			   })
		    .state('map.layers', {
			       url: '/layers',
			       templateUrl: moduleTemplateBaseUrl + 'map_layers.html',
			   })
		    .state('map.share', {
			       url: '/share',
			       templateUrl: moduleTemplateBaseUrl + 'map_share.html',
			   })
		    .state('map.my_maps', {
			       url: '/my_maps',
			       templateUrl: moduleTemplateBaseUrl + 'map_mymaps.html',
			   })
		    .state('map.marker_detail', {
			      url: '/marker/:markerId',
			      templateUrl: moduleTemplateBaseUrl + 'marker_detail.html',
			      controller: 'MapMarkerDetailCtrl'
			   });
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
