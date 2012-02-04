<script>

	function Test() {

		var myTest = this;

		myTest.syntaxInput = ko.observable();

		myTest.syntaxInput.subscribe(function(newValue) {
			if (newValue != '') {
				var bhaviourId = newValue.split(':')[0];
				var termId = newValue.split(':')[1];
	
				var getTermUrl = #{jsAction @Terms.get(':id') /}
			    $.get(getTermUrl({id: termId}), function(termData) {

			    	var term = ko.mapping.fromJS(termData);

					for (var i = 0; i<myTest.bhaviours().length; i++) {
						if (myTest.bhaviours()[i].id() == bhaviourId) {
							myTest.bhaviours()[i].syntax.push(term);
							break;
						}
					}
				});
			    myTest.syntaxInput('');
			}
		});

		myTest.removeTerm = function(termId, bhaviourId) {
			console.log(termId + ' ' + bhaviourId);
			for (var i = 0; i<myTest.bhaviours().length; i++) {
				if (myTest.bhaviours()[i].id() == bhaviourId) {
					myTest.bhaviours()[i].syntax.remove(function(item) {
						return item.id() == termId;
					});
					break;
				}
			}
		}
		
		myTest.editName = function(data, event) {
			if (event.type == 'dblclick') {
			  	myTest.editingName(true);
			}
			if (event.type == 'blur') {
				myTest.editingName(false);
			}	
			if (event.type == 'keypress') {
				if (event.keyCode == '13') {
					if (data.name() == null || data.name().trim() == '') {
						data.name('Test');
					}
					myTest.editingName(false);
				}
			}
		
			return true;
		};
		
		myTest.editingName = ko.observable(false);
		  	
		myTest.removeBhaviour = function(bhaviour) {
			myTest.bhaviours.remove(bhaviour)
		}
		myTest.addBhaviour = function(bhaviour) {
			$.getJSON("@{Bhaviours.create()}", function(bhaviourJson) {
		    	var bhaviour = ko.mapping.fromJS(bhaviourJson);
				myTest.bhaviours.push(bhaviour);
				applyTranslation();
		    });
		}
		
		myTest.run = function() {
			myTest.getDriver();
			console.log("running test");
			myTest.runBhaviours();
			myTest.updateScreenshot();
		}
		
		myTest.saveScreenshot = function(dataURI) {
			var blob = dataURItoBlob(dataURI);
			var fd = new FormData(document.forms[0]);
			var xhr = new XMLHttpRequest();
			fd.append("screenshot.source", blob);
			fd.append("screenshot.name", myTest.name() + ' - ' + new Date().toUTCString() );
			fd.append("screenshot.testId", myTest.id());
			xhr.open('POST', '@{Screenshots.saveScreenshot()}', false);
			xhr.send(fd);
			
			if (xhr.status === 200) {
				return xhr.responseText;
			} else {
				console.log('something went wrong saving screenshot')
				return '';
			}
		}
		
		myTest.deleteScreenshot = function(id) {
			console.log('deleting screenshot ' + id + ' from test ' + myTest.id());
			var deleteScreenshotUrl = #{jsAction @Screenshots.deleteScreenshot(':testId', ':id') /}
			
			$.ajax(deleteScreenshotUrl({testId: myTest.id(), id: id}), {
				type: "DELETE",
				success: function() {
					console.log("screenshot " + id + " removed");
					$('#screenshotSmall_'+id).fadeOut('slow', function() {
						console.log("screenshot " + id + " faded out");
						$('#screenshotSmall_'+id).remove();
						$('#'+id).remove();
						myTest.screenshots.remove(id);
					});
				}
			});
		}
		
		myTest.saveTest = function() {
			var mapping = {
			    'ignore': ["driverServer", "driverVersion", "driverPlatform", "driverJavascriptEnabled", "availableBrowsers", "availablePlatforms", "driverBrowserName"]
			}
		
			var unmapped = ko.mapping.toJSON(myTest, mapping);
			
			console.log(unmapped);
			$.ajax("@{Tests.save}", {
				data: unmapped,
				type: "post", contentType: "application/json",
				success: function(result) { myTest.id(result) }
			});
			
		};
		   
		myTest.getDriver = function() {
		   	myTest.client = new webdriver.http.CorsClient(myTest.driverServer());
		   	myTest.executor = new webdriver.http.Executor(myTest.client);
			myTest.driver = webdriver.WebDriver.createSession(myTest.executor, {
				'browserName': myTest.driverBrowserName(),
				'version': myTest.driverVersion(),
				'platform': myTest.driverPlatform(),
				'javascriptEnabled': myTest.driverJavascriptEnabled()
			});
		}
		
		myTest.updateScreenshot = function() {
			if (screenshot != undefined) {
				screenshot.then(function(png) {
					var screenshot = ko.mapping.fromJSON(myTest.saveScreenshot('data:image/png;base64,' + png));
					myTest.screenshots.push(screenshot.id());
				});
			}
		}
		
		myTest.runBhaviours = function() {
			var bhaviourString = "";
			for (var i = 0; i < myTest.bhaviours().length; i++) {
				bhaviourString += myTest.bhaviours()[i].command();
			}
			console.log(bhaviourString);
			var exec = new Function(bhaviourString);
			exec();
		};

	}

</script>