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
	ReplyPrivateString = 'privateString'
	
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
	PrivateReplyPostFields = CommonPostFields + [ReplyPrivateString]
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
		:editPost,
		:replyPost,
		:mode,
	)
	
	#mode may be either :new, :edit, :reply or :privateReply
	
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
		@replyPost = nil
		@editPost = nil
		@mode = nil
	end
end
