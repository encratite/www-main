class PastebinForm
	DebugMode = false
	Debug = 'debug'
	
	Author = 'author'
	
	PostDescription = 'postDescription'
	UnitDescription = 'unitDescription'
	
	HighlightingGroup = 'highlightingGroup'
	
	CommonHighlighting = 'commonHighlighting'
	AdvancedHighlighting = 'advancedHighlighting'
	ExpertHighlighting = 'expertHighlighting'
	
	Content = 'content'
	
	EditUnitId = 'unit'
	
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
	
	NewSubmissionPostFields =
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
	
	EditPostFields = NewSubmissionPostFields + [EditUnitId]
end
