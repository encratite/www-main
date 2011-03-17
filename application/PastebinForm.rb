class PastebinForm
  Author = 'author'

  PostDescription = 'postDescription'
  UnitDescription = 'unitDescription'

  HighlightingGroup = 'highlightingGroup'

  CommonHighlighting = 'commonHighlighting'
  AdvancedHighlighting = 'advancedHighlighting'
  ExpertHighlighting = 'expertHighlighting'

  Content = 'content'

  EditUnitId = 'unit'
  ReplyPostId = 'replyPostId'
  AddUnitPostId = 'addUnitPostId'

  PrivateString = 'privateString'

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
  EditPostFields = CommonPostFields + [EditUnitId]
  #ReplyPostId is only specified when it's a public post - otherwise it relies on PrivateString
  ReplyPostFields = CommonPostFields
  AddUnitPostFields = CommonPostFields + [AddUnitPostId]

  attr_accessor(
		:request,
		:errors,
		:author,
		:postDescription,
		:unitDescription,
		:content,
		:highlightingSelectionMode,
		:lastSelection,
		:expirationIndex,

		:isPrivate,

		:editUnitId,

		:editPost,
		:replyPost,

		:mode,
                )

  #valid modes: :new, :edit, :reply, :addUnit

  def initialize(request)
    @request = request
    @errors = nil
    @author = nil
    @postDescription = nil
    @unitDescription = nil
    @content = nil
    @highlightingSelectionMode = nil
    @lastSelection = nil
    @expirationIndex = nil
    @editUnitId = nil
    @replyPost = nil
    @editPost = nil
    @mode = nil
  end
end
