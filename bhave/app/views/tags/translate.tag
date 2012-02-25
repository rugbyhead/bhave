<script>
	function split(val) {
		return val.split( /,\s*/ );
	}
	function extractLast(term) {
		return split(term).pop();
	}

	function applyTranslation() {
		$('.language_input').each(function(index) {
			var element = this;

			$(element)
				.bind("keydown", function(event) {
					if (event.keyCode === $.ui.keyCode.TAB && $(this).data("autocomplete").menu.active) {
						event.preventDefault();
					}
				})
				.autocomplete({
					minLength: 1,
					source: function(request, response) {

						var terms = [];
						
						$.each(myDictionary.terms(), function(index, term) {
							terms[index] = {label: term.name(), value: term.id()};
						});
						
						response($.ui.autocomplete.filter(terms, extractLast(request.term)));
					},
					focus: function(event, ui) {
						$(element).val(ui.item.label);
						return false;
					},
					select: function(event, ui) {
						var behaviourId = $(this).attr('data-id');
						$('#syntax_input').val(behaviourId + ':' + ui.item.value);
						$('#syntax_input').change();
						$(this).val("");
						return false;
					}
			});
		});
	}

	function Translator(syntaxArray) {
		var self = this;
		var syntax = syntaxArray;
		var index = {
			'Article': 0,
			'Conjunction': 0,
			'Object.Page': 0,
			'Object.Element': 0,
			'Object.Attribute': 0,
			'Object.Value': 0,
			'Subject': 0,
			'Synonym': 0,
			'Verb': 0
		};

		self.produceCommand = function() {
			var verb = self.findNext('Verb');
			var currentCommand = self.replaceId(verb.command(), verb);
			currentCommand = self.replaceObjects(currentCommand);
			return currentCommand;
		}

		self.replaceId = function(commandString, term) {
			return commandString.replace(/~~id~~/g, term.id());
		}

		self.replaceObjects = function(commandString) {
			if (commandString.indexOf("~~page~~") != -1) {
				commandString = commandString.replace(/~~page~~/g, self.findObject('Page').value());
			}
			if (commandString.indexOf("~~element~~") != -1) {
				commandString = commandString.replace(/~~element~~/g, self.findObject('Element').value());
			}
			if (commandString.indexOf("~~attribute~~") != -1) {
				commandString = commandString.replace(/~~attribute~~/g, self.findObject('Attribute').value());
			}
			if (commandString.indexOf("~~value~~") != -1) {
				commandString = commandString.replace(/~~value~~/g, self.findObject('Value').value());
			}

			return commandString;
		}

		self.findNext = function(termType) {
			for (var i = index[termType]; i < syntax.length; i++) {
				if (syntax[i].type() == termType) {
					index[termType] = i;
					return syntax[i]; 
				}
			}
		}

		self.findObject = function(objectType) {
			for (var i = index['Object.' + objectType]; i < syntax.length; i++) {
				if (syntax[i].type() == 'Object') {
					if (syntax[i].objectType() == objectType) {
						index['Object.' + objectType] = i;
						return syntax[i]; 
					}
				}
			}
		}


	}


</script>