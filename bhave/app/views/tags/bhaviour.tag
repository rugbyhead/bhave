<script>

	function Bhaviour() {

		var this_ = this;

		this_.syntaxInput = ko.observable();
		
		this_.count = 0;

		this_.syntaxInput.subscribe(function(termId) {
			if (termId != '') {
			    $.get(getTermUrl({id: termId}), function(termData) {
			    	var term = ko.mapping.fromJS(termData);
			    	term.count = this_.count++;
					this_.syntax.push(term);
				});
			    this_.syntaxInput('');
			}
		});

		this_.removeTerm = function(termId) {
			this_.syntax.remove(function(item) {
				return item.id() == termId;
			});
		}

		this_.editName = function(data, event) {
			if (event.type == 'dblclick') {
			  	this_.editingName(true);
			}
			if (event.type == 'blur') {
				this_.editingName(false);
			}	
			if (event.type == 'keypress') {
				if (event.keyCode == '13') {
					if (data.name() == null || data.name().trim() == '') {
						data.name('Bhaviour');
					}
					this_.editingName(false);
				}
			}
		
			return true;
		};
		
		this_.editingName = ko.observable(false);
		  	
		this_.running = ko.observable(false);
		this_.lastSuccess = ko.observable(0);
		this_.failureMessage = ko.observable();
		
		this_.run = function() {
			this_.failedTerms([]);
			this_.passingTerms([]);
			this_.getDriver();
			this_.runBhaviours();
		}
		
		this_.saveScreenshot = function(dataURI) {
			var blob = dataURItoBlob(dataURI);
			var fd = new FormData(document.forms[0]);
			var xhr = new XMLHttpRequest();
			fd.append("screenshot.source", blob);
			fd.append("screenshot.name", this_.name() + ' - ' + new Date().toUTCString() );
			fd.append("screenshot.bhaviourId", this_.id());
			xhr.open('POST', '@{Screenshots.save()}', false);
			xhr.send(fd);
			
			if (xhr.status === 200) {
				return xhr.responseText;
			} else {
				alert('Something went wrong saving screenshot')
				return '';
			}
		}
		
		this_.deleteScreenshot = function(id) {
			$.ajax(deleteScreenshotUrl({id: id}), {
				type: "DELETE",
				success: function() {
					$('#screenshotSmall_'+id).fadeOut('slow', function() {
						$('#screenshotSmall_'+id).remove();
						$('#'+id).remove();
						this_.screenshots.remove(id);
					});
				}
			});
		}
		
		this_.saveBhaviour = function() {
			this_.saving(true);
			var mapping = {
			    'ignore': [ "isActive",
						    "definition",
						    "driverServer",
						    "driverVersion",
						    "driverPlatform",
						    "driverJavascriptEnabled",
						    "availableBrowsers",
						    "availablePlatforms",
						    "driverBrowserName",
						    "language",
						    "command"
						  ]
			}
		
			var unmapped = ko.mapping.toJSON(this_, mapping);
			
			$.ajax("@{Bhaviours.save}", {
				data: unmapped,
				type: "post", contentType: "application/json",
				success: function(result) { this_.id(result); this_.saving(false); }
			});
		};
		this_.saving = ko.observable(false);
		   
		this_.getDriver = function() {
		   	this_.client = new webdriver.http.CorsClient(this_.driverServer());
		   	this_.executor = new webdriver.http.Executor(this_.client);
			this_.driver = webdriver.WebDriver.createSession(this_.executor, {
				'browserName': this_.driverBrowserName(),
				'version': this_.driverVersion(),
				'platform': this_.driverPlatform(),
				'javascriptEnabled': this_.driverJavascriptEnabled()
			});
		}
		
		this_.runBhaviours = function() {
			var bhaviourString = "";
			bhaviourString += new Translator(this_.syntax()).produceCommand();
			var exec = new Function(bhaviourString);
			exec();
		};

		this_.failedTerms = ko.observableArray();

		this_.fail = function(termId) {
			this_.lastSuccess(BhaviourState.FAIL);
			this_.failedTerms.push(termId);
		}

		this_.passingTerms = ko.observableArray();

		this_.pass = function(termId) {
			this_.passingTerms.push(termId);
		}

		this_.language = ko.observable("");
		this_.command = ko.observable("");
		this_.isActive = ko.observable(true);
		this_.definition = {
			active: ko.observable(false),
			terms: {
				object: {
					active: ko.observable(false),
					types: {
						value: {
							value: ko.observable(""),
							active: ko.observable(false),
							add: function() {
								var term = {
										name: ko.observable(this_.language()),
										type: ko.observable('Object'),
										testCopy: ko.observable(false),
										objectType: ko.observable('Value'),
										value: ko.observable(this_.definition.terms.object.types.value.value())
									}
								this_.definition.saveTerm(term);
							}
						},
						page: {
							url: ko.observable("http://"),
							active:ko.observable(false),
							add: function() {
								var term = {
										name: ko.observable(this_.language()),
										type: ko.observable('Object'),
										testCopy: ko.observable(false),
										objectType: ko.observable('Page'),
										value: ko.observable(this_.definition.terms.object.types.page.url())
									}
								this_.definition.saveTerm(term);
							}
						},
						element: {
							active: ko.observable(false),
							defaultValue: 'bhaviour.driver.isElementPresent(webdriver.By.~~identifier~~(\'~~value~~\')).then(function(result){if(result){bhaviour.pass(~~id~~);}else{bhaviour.fail(~~id~~);}});bhaviour.driver.findElement(webdriver.By.~~identifier~~(\'~~value~~\'))',
							makeTerm: function(value) {
								return {
									name: ko.observable(this_.language()),
									type: ko.observable('Object'),
									testCopy: ko.observable(false),
									objectType: ko.observable('Element'),
									value: ko.observable(value)
								}
							},
							addTerm: function(identifier) {
								var value = this_.definition.terms.object.types.element.defaultValue.replace(/~~identifier~~/g, identifier);
								value = value.replace(/~~value~~/g, this_.definition.terms.object.types.element.identifier[identifier].value());
								var term = this_.definition.terms.object.types.element.makeTerm(value);
								this_.definition.terms.object.types.element.identifier[identifier].value(this_.definition.saveTerm(term));
							},
							makeActive: function(identifier) {
								if (this_.definition.terms.object.types.element.identifier[identifier].active()) {
									return;
								};
								this_.definition.terms.object.types.element.makeUnactive();
								this_.definition.terms.object.types.element.identifier[identifier].active(true);
							},
							makeUnactive: function() {
								for (identifier in this_.definition.terms.object.types.element.identifier) {
									this_.definition.terms.object.types.element.identifier[identifier].active(false);
								}
							},
							identifier: {
								id: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('id');
									}
								},
								name: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('name');
									}
								},
								className: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('className');
									}
								},
								css: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('css');
									}
								},
								js: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('js');
									}
								},
								linkText: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('linkText');
									}
								},
								partialLinkText: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('partialLinkText');
									}
								},
								tagName: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('tagName');
									}
								},
								xpath: {
									active: ko.observable(false),
									value: ko.observable(),
									add: function() {
										this_.definition.terms.object.types.element.addTerm('xpath');
									}
								}
							}
						},
						pageAttribute: {
							value: ko.observable(""),
							active:ko.observable(false),
							add: function() {
								var term = {
										name: ko.observable(this_.language()),
										type: ko.observable('Object'),
										testCopy: ko.observable(false),
										objectType: ko.observable('PageAttribute'),
										value: ko.observable(this_.definition.terms.object.types.pageAttribute.value())
									}
								this_.definition.saveTerm(term);
							}
						},
						elementAttribute: {
							value: ko.observable(""),
							active:ko.observable(false),
							add: function() {
								var term = {
										name: ko.observable(this_.language()),
										type: ko.observable('Object'),
										testCopy: ko.observable(false),
										objectType: ko.observable('ElementAttribute'),
										value: ko.observable(this_.definition.terms.object.types.elementAttribute.value())
									}
								this_.definition.saveTerm(term);
							}
						}
					},
					makeActive: function(type) {
						if (this_.definition.terms.object.types[type].active()) {
							return;
						};
						this_.definition.terms.object.makeUnactive();
						this_.definition.terms.object.types[type].active(true);
					},
					makeUnactive: function() {
						this_.definition.terms.object.types.element.makeUnactive();
						for (type in this_.definition.terms.object.types) {
							this_.definition.terms.object.types[type].active(false);
						}
					}
				},
				article: {
					active:ko.observable(false),
					add: function() {
						var term = {
								name: ko.observable(this_.language()),
								type: ko.observable('Article')
							}
						this_.definition.saveTerm(term);
					}
				},
				subject: {
					active:ko.observable(false),
					add: function() {
						var term = {
								name: ko.observable(this_.language()),
								type: ko.observable('Subject')
							}
						this_.definition.saveTerm(term);
					}
				},
				conjunction: {
					active: ko.observable(false),
					add: function() {
						var term = {
								name: ko.observable(this_.language()),
								type: ko.observable('Conjunction')
							}
						this_.definition.saveTerm(term);
					}
				},
				synonym: {
					active:ko.observable(false),
					terms: ko.observableArray(),
					add: function() {
						var term = {
								name: ko.observable(this_.language()),
								type: ko.observable('Synonym')
							}
						this_.definition.saveTerm(term);
					}
				}
			},
			makeActive: function(term) {
				if (this_.definition.terms[term].active()) {
					return;
				};
				this_.definition.makeUnactive();
				this_.definition.active(true);
				this_.definition.terms[term].active(true);
			},
			makeUnactive: function() {
				this_.definition.terms.object.makeUnactive();
				for (term in this_.definition.terms) {
					this_.definition.terms[term].active(false);
				}
			},
			disable: function() {
				if (!e) var e = window.event;
				var tg = (window.event) ? e.srcElement : e.target;
				if (tg.className != 'definition_tool_container') return;
				var reltg = (e.relatedTarget) ? e.relatedTarget : e.toElement;
				while (reltg != tg && reltg.nodeName != 'BODY'){
					reltg= reltg.parentNode;
					if (reltg== tg) return;
				}
				this_.definition.makeUnactive();
				this_.definition.active(false);
			},
			saveTerm: function(term) {
				if (typeof term.name != undefined && term.name != '') {
					$.ajax("@{Terms.save}", {
						data: ko.mapping.toJSON(term),
						type: "post", contentType: "application/json",
						success: function(termId) {
							term.id = ko.observable(termId);
							myDictionary.terms.push(term);
							this_.definition.makeUnactive();
							this_.definition.active(false);
							this_.isActive(true);
							return '';
						},
						failure: function(error) {
							return error;
						}
					});
				}
			}
		}	
	}
</script>