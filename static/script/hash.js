function hashGenerator()
{
	this.hash = 0x7EE3623A;
	
	this.hashData = hashData;
	this.getHash = getHash;
	
	this.hash = ~this.hash;
	
	//this.debugging = false;
	this.debugging = true;
	
	if(this.debugging)
		this.content = '';
}

function hashData(input)
{
	//alert("Adding \"" + input + "\" (" + input.length + ")");
	
	if(this.debugging)
		this.content += input;
	
	var shifts = new Array(1, 4, 7, 8, 24);
	
	var hash = this.hash;
	
	var mask = 0xFFFFFFFF;
	
	for(var i = 0; i < input.length; i++)
	{
		var currentByte = input.charCodeAt(i);
		hash ^= currentByte;
		var shiftedHash = hash;
		for(var j = 0; j < shifts.length; j++)
			shiftedHash = (shiftedHash + ((hash << shifts[j]) & mask)) & mask;
		hash = shiftedHash;
	}
	
	this.hash = hash;
}

function getHash()
{
	var number = this.hash;
	if(number < 0)
		number = 0xFFFFFFFF + number + 1;
		
	return number.toString(16).toUpperCase();
}

function visualiseString(data)
{
	var replacements = new Array
	(
		"\x00", "\\\\x00",
		"\r", "\\\\r",
		"\n", "\\\\n"
	);
	
	for(var i = 0; i < replacements.length; i += 2)
	{
		var target = replacements[i];
		var replacement = replacements[i + 1];
		data = data.replace(target, replacement);
	}
	
	return data;
}

function hashFields()
{
	var arguments = hashFields.arguments;
	var generator = new hashGenerator();
	var first = true;
	for(var i = 0; i < arguments.length; i++)
	{
		if(first)
			first = false;
		else
			//generator.hashData("\x00");
			generator.hashData(':');
		var argument = arguments[i];
		var data = document.getElementById(argument);
		if(data == null)
		{
			var fields = document.getElementsByName(argument);
			if(fields == null)
			{
				alert('Missing field: ' + argument);
				return 0;
			}
			
			for(var j = 0; j < fields.length; j++)
			{
				var element = fields[j];
				if(element.checked)
				{
					data = element;
					break;
				}
			}
		}
		data = data.value;
		generator.hashData(data);
	}
	var security = document.getElementById('security');
	security.value = generator.getHash();
	
	if(generator.debugging)
	{
		var data = visualiseString(generator.content);
		//prompt('Debug output', data);
		document.getElementById('debug').value = generator.content;
	}
}
