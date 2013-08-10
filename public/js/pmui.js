'use strict';

angular.module("Pmui", ['pmuiServices', 'pmuiFilters']).
	controller('PmuiCtrl', ['$scope', 'Entry', 'Movie', function ($scope, Entry, Movie) {
		$scope.entries = Entry.query();
		$scope.movies = Movie.query();
	}]);