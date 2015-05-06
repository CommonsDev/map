exports.config =
        plugins:
                sass:
                        mode: 'native'
                        options:
                                includePaths: ["bower_components/compass-mixins/lib/"]

        conventions:
                assets: /^app\/assets\//
        modules:
                definition: false
                wrapper: false
        paths:
            public: '_public'
        files:
                javascripts:
                        joinTo:
                                'js/vendor.js': [
                                        /^bower_components/
                                        'bower_components/leaflet.markercluster/**/*.js'
                                ]
                                'js/app.js': [
                                        'app/scripts/app.js'
                                        'app/scripts/common/**/*.coffee'
                                        'app/scripts/map/**/*.coffee'
                                ]
                                'js/config.js':[
                                        'app/scripts/config.js'
                                ]
                         order:
                                before: [
                                        'bower_components/jquery/dist/jquery.js'
                                        'bower_components/angular/angular.js'
                                        'bower_components/angularui/angular-ui.js'
                                        'bower_component/angularui/angular-ui-ieshiv.js'
                                ]
                                after: [
                                        'bower_components/leaflet.markercluster/dist/leaflet.markercluster.js'
                                ]

                stylesheets:
                        joinTo:
                                'css/vendor.css': /^bower_components/
                                'css/app.css': /^app\/styles/
                        order:
                                before: [
                                        'vendor/styles/bootstrap.less'
                                        'vendor/styles/bootstrap-responsive.less'
                                ]
