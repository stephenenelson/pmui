'use strict';

angular.module("Pmui", ['pmuiServices', 'pmuiFilters', 'ui.bootstrap']).
	controller('PmuiCtrl', ['$scope', '$timeout', 'Entry', 'Movie', function ($scope, $timeout, Entry, Movie) {
		$scope.entries = Entry.query();
		$scope.movies = Movie.query();
		$scope.delete_entry = function(entry) {
			entry.$delete({entryId: entry.schedule_entry_id},
				function() {
					$scope.entries.splice( $scope.entries.indexOf(entry), 1 );
				});
		};
		
	}]);