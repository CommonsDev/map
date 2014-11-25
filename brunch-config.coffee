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
                                'js/vendor.js': /^bower_components/
                                'js/app.js': /^app\/scripts/
                stylesheets:
                        joinTo:
                                'css/vendor.css': /^bower_components/
                                'css/app.css': /^app\/styles/
                        order:
                                before: [
                                ]
