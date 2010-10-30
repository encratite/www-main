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
	ReplyPostId = 'post'
	
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
	
	CommonPostFields =
	[
		Author,
		
		PostDescription,
		
		HighlightingGroup,
		
		CommonHighlighting,
		AdvancedHighlighting,
		ExpertHighlighting,
		
		UnitDescription,
		
		Content,
	]
	
	CreationPostFields =
	[
		PrivatePost,
		Expiration,
	]
	
	NewSubmissionPostFields = CommonPostFields + CreationPostFields
	EditPostFields = NewSubmissionPostFields + [EditUnitId]
	ReplyPostFields = CommonPostFields + [ReplyPostId]
	EditReplyPostFields = CommonPostFields + [EditUnitId]
	
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
		:replyPostId,
		:editPost,
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
		@replyPostId = nil
		@editPost = nil
	end
end
