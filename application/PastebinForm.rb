class PastebinForm
	Author = 'author'
	
	PostDescription = 'postDescription'
	UnitDescription = 'unitDescription'
	
	HighlightingGroup = 'highlightingGroup'
	
	CommonHighlighting = 'commonHighlighting'
	AdvancedHighlighting = 'advancedHighlighting'
	ExpertHighlighting = 'expertHighlighting'
	
	Content = 'content'
	
	HighlightingGroupIdentifiers =
	[
		'none',
		'common',
		'advanced',
		'expert'
	]
	
	PrivatePost = 'privatePost'
	Expiration = 'expiration'
	
	PostFields =
	[
		:Author,
		
		:PostDescription,
		
		:HighlightingGroup,
		
		:CommonHighlighting,
		:AdvancedHighlighting,
		:ExpertHighlighting,
		
		:PrivatePost,
		:Expiration,
		
		:UnitDescription,
		
		:Content,
	]
end
