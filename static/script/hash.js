function hashGenerator()
{
	this.hash = 0x7EE3623A;
	
	this.hashData = hashData;
	this.getHash = getHash;
	
	this.hash = ~this.hash;
}

function hashData(input)
{
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
			generator.hashData('\x00');
		var argument = arguments[i];
		var data = document.getElementById(argument).value;
		generator.hashData(data);
	}
	var security = document.getElementById('security');
	security.value = generator.getHash();
}
