class PastebinForm
	DebugMode = true
	Debug = 'debug'
	
	Author = 'author'
	
	PostDescription = 'postDescription'
	UnitDescription = 'unitDescription'
	
	HighlightingGroup = 'highlightingGroup'
	
	CommonHighlighting = 'commonHighlighting'
	AdvancedHighlighting = 'advancedHighlighting'
	ExpertHighlighting = 'expertHighlighting'
	
	Content = 'content'
	
	NoHighlighting = 'none'
	
	HighlightingGroupIdentifiers =
	[
		NoHighlighting,
		'common',
		'advanced',
		'expert',
	]
	
	PrivatePost = 'privatePost'
	Expiration = 'expiration'
	
	PostFields =
	[
		Author,
		
		PostDescription,
		
		HighlightingGroup,
		
		CommonHighlighting,
		AdvancedHighlighting,
		ExpertHighlighting,
		
		PrivatePost,
		Expiration,
		
		UnitDescription,
		
		Content,
	]
end
