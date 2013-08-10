angular.module('pmuiServices', ['ngResource']).
	factory('Entry', function($resource){
		return $resource('schedule');
	});