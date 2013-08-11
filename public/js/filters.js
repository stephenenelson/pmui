'use strict';

angular.module('pmuiFilters', []).
	filter('dateformat', function() {
		return function(input) {
			var now = moment.unix(input);
			var formatted = now.format('ddd HH:mm:ss');
			return formatted;
	    }
	});	