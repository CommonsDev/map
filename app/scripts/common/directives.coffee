module = angular.module("common.directives", [])

module.directive("fileUpload", ($timeout) ->
        return {
                restrict: 'E'
                replace: true
                transclude: true

                scope:
                        bucket: '@'
                        dropzone: '@'

                template: '<form><input type="hidden" name="bucket" value="{{ bucket }}"/><input type="hidden" name="tags" value="plop"/><input class="fileupload" type="file" name="file" ></form>'

                link: ($scope, $element, $attrs) =>
                        $timeout(=>
                                $($element).fileupload(
                                        url: "http://localhost:8000/bucket/upload/"
                                        dropZone: "\##{$scope.dropzone}"
                                        dataType: 'json'
                                        done: (e, data) =>
                                                $.each(data.result, (idx, file) =>
                                                        $scope.$emit('file-uploaded', file)
                                                )
                                )
                        , 0)

                constructor: ->
                        console.debug("init fileupload")
        }

)
