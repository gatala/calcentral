var calcentral = calcentral || {};
calcentral.Widgets = calcentral.Widgets || {};
calcentral.Widgets.myclasses = function(tuid) {

	/////////////////////////////
	// Configuration variables //
	/////////////////////////////

	var $rootel = $('#' + tuid);
	var $myclassesList = $('.cc-widget-myclasses-list', $rootel);
	// Method to filter the bspaceFavorites feed based on categories. If the value is left empty or null, will assume "All sites"
	var categoryFilter = 'Fall 2012';

	////////////////////
	// Event Handlers //
	////////////////////

	///////////////
	// Rendering //
	///////////////

	var renderClassesList = function(data) {
		if (!data.classes) {
			data.body = '{}';
		}
		calcentral.Api.Util.renderTemplate({
			'container': $myclassesList,
			'data': data,
			'template': $('#cc-widget-myclasses-list-template', $rootel)
		});
	};


	////////////
	// BSpace //
	////////////

	/**
	 * Applies a category filter on the feed of sites from /api/bspacefavorites.
	 * @param {Object} data JSON response from /api/bspacefavorites
	 * @param {String} filter category name of category to filter on.
	 */
	var filterOnCategory = function(data, filter) {
		var $sitesDeferred = $.Deferred();
		//Assume that someone wants "All Sites" if filter is falsy
		if (!filter) {
			filter = 'All sites';
		}
		var sites = $.map(data, function(value) {
			if (filter === value.category) {
				return value.sites;
			}
		});
		$sitesDeferred.resolve({
			'sites': sites
		});

		return $sitesDeferred.promise();
	};

	/**
	 * Returns a JSON Object of all the bSpace sites, in categories.
	 * @return {Array} Array of JSONObject categories of bSpace sites.
	 */
	var loadFavouritesList = function() {
		var $ajaxWrapper = $.Deferred();
		$.ajax({
			'cache': false,
			'url': '/api/bspacefavorites',
			'success': function(data) {
				//only care about the categories.
				return $ajaxWrapper.resolve(data.body.categories);
			},
			'error': $ajaxWrapper.reject
		});
		return $ajaxWrapper.promise();
	};


	////////////
	// Canvas //
	////////////

	/**
	 * Get the current user's canvas courses. If success, do some filtering on the results
	 * to only return the parts necesssary for rendering.
	 * @return {Object} Pair of 1) canvasRoot host, and 2) Array of JSON objects to pass off to the template renderer.
	*/
	var getCanvasCourses = function() {
		var $ajaxWrapper = $.Deferred();
		$.ajax({
			'url': '/api/canvas/courses',
			'success': function(data) {
				//do some translation on the results. Expecting an array of course JSON object.
				var result = $.map(data, function(value) {
					return {
						'id': value.id,
						'name': value.course_code,
						'title': value.name
					};
				});
				$ajaxWrapper.resolve({
					'host': calcentral.Data.Env.canvasRoot,
					'courses': result
				});
			},
			'error': $ajaxWrapper.reject
		});

		return $ajaxWrapper.promise();
	};

	/**
	 * Fetch users's course data from canvas.
	 * @return {Object} Deferred promise object for a Deferrred chain, with a (data) param.
	 */
	var loadCourses = function() {
		return $.when(getCanvasCourses());
	};


	////////////////////
	// Initialisation //
	////////////////////

	/**
	 * Initialise the classes widget, after functions from other widgets are resolved.
	 */
	var delayedInit = function(functionMap){
		$.when(functionMap.loadFavouritesList(), functionMap.loadCourses()).pipe(function(dataBSpace, dataCanvas) {
			return functionMap.filterOnCategory(dataBSpace, categoryFilter).pipe(function(data) {
				var $combineDataDef = $.Deferred();
				// Harmonize the bSpace and canvas data for display.
				var displayData = [];
				if (data && data.sites) {
					displayData = displayData.concat($.map(data.sites, function(value) {
						return {
							'name': value.title,
							'site_type': 'bspace',
							'title': value.title,
							'url': value.url
						};
					}));
				}
				if (dataCanvas && dataCanvas.courses && dataCanvas.host) {
					displayData = displayData.concat($.map(dataCanvas.courses, function(value) {
						return {
							'name': value.name,
							'site_type': 'canvas',
							'title': value.title,
							'url': dataCanvas.host + '/courses/' + value.id
						};
					}));
				}
				displayData = _.sortBy(displayData, function(value) { return value.title; });
				$combineDataDef.resolve({'classes': displayData});
				return $combineDataDef.promise();
			});
		}).done(renderClassesList);
	};

	var functionMap = {
		'filterOnCategory': filterOnCategory,
		'loadFavouritesList': loadFavouritesList,
		'loadCourses': loadCourses
	};
	// Start the request, with resolved functions.
	delayedInit(functionMap);
};