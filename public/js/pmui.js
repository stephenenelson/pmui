'use strict';

angular.module("Pmui", ['pmuiServices', 'pmuiFilters']).
	controller('PmuiCtrl', ['$scope', 'Entry', function ($scope, Entry) {
		$scope.entries = Entry.query();
	}]);