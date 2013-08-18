'use strict';

angular.module("Pmui", ['pmuiServices', 'pmuiFilters', 'ui.bootstrap']).
	controller('PmuiCtrl', ['$scope', 'Entry', 'Movie', '$dialog', function ($scope, Entry, Movie, $dialog) {
		$scope.entries = Entry.query();
		$scope.movies = Movie.query();
		$scope.delete_entry = function(entry) {
			entry.$delete({entryId: entry.schedule_entry_id},
				function() {
					$scope.entries.splice( $scope.entries.indexOf(entry), 1 );
				});
		};
		
		$scope.add_entry = function() {
			var d = $dialog.dialog({
				templateUrl: 'add_dialog.html',
				controller: 'PmuiAddDialogController',
				resolve: {
					last_entry: function() {
						var last = $scope.entries[ $scope.entries.length -1 ];
						console.log("Last is " + last.mrl);
						return last;  
					    }
					}
				}
			);
			d.open();
		};
		
	}]).
	controller('PmuiAddDialogController', ['$scope', 'dialog', 'Movie', 'Entry', 'last_entry', function( $scope, dialog, Movie, Entry, last_entry ) {
		$scope.last_entry = last_entry;
	
		$scope.close = function() {
			dialog.close();
		};
		
		$scope.save_entry = function() {
			var this_moment = moment( $scope.current_date + "T" + $scope.current_time );
			var new_entry = new Entry({ 
				mrl: $scope.current_mrl,
				start_time: this_moment.unix()
			});
			new_entry.$save(function(success) {
				dialog.close();
			})
		};
		
		var last_moment = moment.unix($scope.last_entry.schedule_entry_end.stop_time);
		$scope.current_date = last_moment.format('YYYY-MM-DD');
		$scope.current_time = last_moment.format('HH:mm:ss');
		
		$scope.movies = Movie.query();
		
  $scope.open = function() {
    $timeout(function() {
      $scope.opened = true;
    });
  };
		

	}]);