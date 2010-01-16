function hashGenerator()
{
	this.hash = 0x7EE3623A;
	
	this.hashData = hashData;
	this.getHash = getHash;
	
	this.hash = ~this.hash;
	
	this.debugging = false;
	
	if(this.debugging)
		this.content = '';
}

function hashData(input)
{
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

function calculateHash(input1, input2)
{
	var generator = new hashGenerator();
	generator.hashData(input1 + input2);
	var hash = generator.getHash();
	document.getElementById('security2').value = hash;
}
