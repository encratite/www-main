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
	
	attr_accessor(
		:request,
		:errors,
		:author,
		:postDescription,
		:unitDescription,
		:content,
		:highlightingSelectionMode,
		:lastSelection,
		:isPrivatePost,
		:expirationIndex,
		:editUnitId,
	)
	
	def initialize(request)
		@request = request
		@errors = nil
		@author = nil
		@postDescription = nil
		@unitDescription = nil
		@content = nil
		@highlightingSelectionMode = nil
		@lastSelection = nil
		@isPrivatePost = nil
		@expirationIndex = nil
		@editUnitId = nil
	end
end
