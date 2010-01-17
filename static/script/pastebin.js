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
		'expertHighlightingList'
	);
	
	for(var i = 1; i < ids.length; i++)
	{
		var id = ids[i];
		setElementVisibility(id, i == mode);
	}
}

function showModeSelector()
{
	var radio = document.getElementsByName('highlightingGroup');
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

function isTab(event)
{
	var code = event.keyCode;
	if(code == null)
		code = event.which;
		
	return code == 9;
}

function getEvent(event)
{
	if(!event)
		return window.event;
	return event;
}

function tabHandler(event)
{	
	var tab = '\t';
	
	event = getEvent(event);

	if(isTab(event))
	{
		//Internet Explorer/Opera
		if(document.selection)
		{
			this.focus();
			var selection = document.selection.createRange();
			selection.text = tab;
		}
		
		//Firefox
		else if(this.selectionStart || this.selectionStart == '0')
		{
			var scrollX = this.scrollLeft;
			var scrollY = this.scrollTop;

			var start = this.selectionStart;
			var end = this.selectionEnd;

			this.value = this.value.substring(0, start) + tab + this.value.substring(end, this.value.length);
			
			var offset = start + 1;

			this.focus();
			this.selectionStart = offset;
			this.selectionEnd = offset;

			this.scrollTop = scrollY;
			this.scrollLeft = scrollX;
		}
		
		//failure
		else
			return true;

		return false;
	}
}

function tabPressHandler(event)
{
	event = getEvent(event);
	
	if(isTab(event))
	{
		try
		{
			event.preventDefault();
		}
		catch(error)
		{
			error.returnValue = false;
		}
	}
}
