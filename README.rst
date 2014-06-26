Unisson Map
===========

A Map front-end companion for the Unisson Data Server.

Authors:
Guillaume Libersat
Mehdi Ghilaci
Hervé Fajfer

See COPYING for the license.

Usage
=====

   sudo aptitude install ruby-compass ruby-fssm coffeescript

   git clone https://github.com/UnissonCo/map.git
   
   cd map/scripts/
   
   ./coffee_watch.sh
   
   cp config.js.sample config.js
   
   nano config.js

    config = {
        templateBaseUrl: '/views/',
        bucket_uri: 'http://localhost:8000/bucket/upload/',
        useHtml5Mode: false,
        media_uri: 'http://localhost:8000/',
        rest_uri: "http://localhost:8000/api/v0"
    }

   cd ..
   
   cd styles/
   
   compass w
   
   cd ..
   
   python -m SimpleHTTPServer 8080
