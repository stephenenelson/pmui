angular.module('pmuiServices', ['ngResource']).
	factory('Entry', function($resource){
		return $resource('schedule/:entryId', { entryId: '@schedule_entry_id'});
	}).
	factory('Movie', function($resource){
		return $resource('movie');
	});
	