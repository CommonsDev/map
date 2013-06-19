module = angular.module('common.filters', [])
module.filter('fromNow', ->
    return (dateString) ->
      return moment(new Date(dateString)).fromNow()
)