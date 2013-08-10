angular.module('pmuiServices', ['ngResource']).
	factory('Entry', function($resource){
		return $resource('schedule');
	}).
	factory('Movie', function($resource){
		return $resource('movie');
	});
	;