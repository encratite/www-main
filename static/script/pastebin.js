function setElementVisibility(id, visible)
{
	if(id == false)
		return;
	var element = document.getElementById(id);
	element.style.display = visible ? 'block' : 'none';
}

function highlightingMode(mode)
{
	var ids = new Array
	(
		false,
		'commonHighlighting',
		'advancedHighlighting',
		'expertHighlighting'
	);
	
	for(var i = 1; i < ids.length; i++)
	{
		var id = ids[i];
		setElementVisibility(id, i == mode);
	}
}

function showModeSelector()
{
	var radio = document.getElementById('highlightingGroup');
	var selection = 0;
	for(var i = 0; i < radio.length; i++)
	{
		if(radio[i].checked)
		{
			highlightingMode(i);
			return;
		}
	}
}
