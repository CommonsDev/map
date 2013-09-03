module = angular.module('map.filters', [])

module.filter('sample_tile', =>
        return (text, length, end)=>
                return L.Util.template(text, {s: 'a', z: 15, x: 16661, y:11025})
)
