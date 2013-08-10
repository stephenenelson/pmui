'use strict';

angular.module("Pmui", ['pmuiServices']).
	controller('PmuiCtrl', ['$scope', 'Entry', function ($scope, Entry) {
		$scope.entries = Entry.query();
	}]);