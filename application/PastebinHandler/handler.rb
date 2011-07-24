require 'SiteContainer'
require 'PastebinForm'

class PastebinHandler < SiteContainer
  def createNewPost(request)
    form = PastebinForm.new(request)
    form.mode = :new
    return @pastebinGenerator.get(['Pastebin', pastebinForm(form)], request)
  end

  def viewPosts(request)
    arguments = request.arguments
    if arguments.empty?
      page = 0
    else
      page = WWWLib.readId(arguments[0]) - 1
    end

    @database.transaction do
      postsPerPage = PastebinConfiguration::PostsPerPage
      #private_string must be NULL - only public posts may be browsed
      #reply_to must be NULL, too - we only want to see the posts which actually started a thread
      posts = @posts.where(private_string: nil, reply_to: nil)
      count = posts.count
      pageCount = count == 0 ? 1 : (Float(count) / postsPerPage).ceil
      pastebinError('Invalid page specified.', request) if page >= pageCount
      offset = [count - (page + 1) * postsPerPage, 0].max

      posts = posts.left_outer_join(:site_user, :id => :user_id)
      posts = posts.filter(pastebin_post__private_string: nil, pastebin_post__reply_to: nil)

      posts = posts.select(
                           :pastebin_post__id.as(:pastebin_post_id), :pastebin_post__user_id, :pastebin_post__author, :pastebin_post__description, :pastebin_post__creation,
                           #:site_user__name.as(:user_name),
                           :site_user__name,
                           )

      posts = posts.reverse_order(:pastebin_post__creation)
      posts = posts.limit(postsPerPage, offset)

      posts = posts.from_self(alias: :user_post)
      posts = posts.left_outer_join(:pastebin_unit, :post_id => :user_post__pastebin_post_id)

      posts = posts.select(
                           :user_post__pastebin_post_id, :user_post__user_id, :user_post__author, :user_post__description, :user_post__creation,
                           :user_post__name,
                           :pastebin_unit__paste_type,
                           'length(pastebin_unit.content)'.lit.as(:content_size)
                           )

      posts = posts.all
      parsedPosts = parsePosts(posts)
      output = listPastebinPosts(request, parsedPosts, page + 1, pageCount)
      return @pastebinGenerator.get(output, request)
    end
  end

  def viewPost(request, isPrivate, target)
    post = nil
    tree = nil
    @database.transaction do
      post = PastebinPost.new(@database)
      post.showPostQueryInitialisation(isPrivate, target, self, request)
      tree = PostTree.new(@database, post)
    end
    return showPastebinPost(request, post, tree)
  end

  def submitNewPost(request)
    return processPostSubmission(request, :new)
  end

  def download(request, unitId, privateString)
    @database.transaction do
      rows = @units.select(:post_id, :content).where(id: unitId).all
      raiseError(argumentError, request) if rows.empty?
      unit = rows.first
      postId = unit[:post_id]
      unitContent = unit[:content]
      rows = @posts.select(:private_string).where(id: postId).all
      raiseError(internalError 'Missing post', request) if rows.empty?
      post = rows.first
      postPrivateString = post[:private_string]
      argumentError if privateString != postPrivateString
      #return the actual code as plain text
      reply = WWWLib::HTTPReply.new(unitContent)
      reply.plain
      return reply
    end
  end

  def deletePost(request, isPrivate, target)
    post = PastebinPost.new(@database)
    @database.transaction do
      post.deletePostQueryInitialisation(isPrivate, target)
      writePermissionCheck(request, post)
      deletePostTree postId
    end
    return confirmPostDeletion(post, request)
  end

  def deleteUnit(request, unitId, privateString)
    post = PastebinPost.new(@database)
    deletedPost = nil
    isPrivate = privateString != nil
    @database.transaction do
      postId = post.deleteUnitQueryInitialisation(isPrivate, unitId)
      writePermissionCheck(request, post)
      @units.where(id: unitId).delete
      unitCount = @units.where(post_id: postId).count
      deletedPost = unitCount == 0
      deletePostTree postId if deletedPost
    end
    return confirmUnitDeletion(post, request, deletedPost)
  end

  def createReply(request, isPrivate, target)
    replyPost = PastebinPost.new(@database)
    replyPost.postInitialisation(isPrivate, target)
    form = PastebinForm.new(request)
    form.mode = :reply
    form.replyPost = replyPost
    return @pastebinGenerator.get(['Reply to post', pastebinForm(form)], request)
  end

  def submitReply(request)
    return processPostSubmission(request, :reply)
  end

  def editUnit(request, unitId, privateString)
    isPrivate = privateString != nil
    post = PastebinPost.new(@database)
    @database.transaction do
      post.editUnitQueryInitialisation(isPrivate, unitId)
      writePermissionCheck(request, post)
      return editUnitForm(post, request)
    end
  end

  def submitUnitModification(request)
    return processPostSubmission(request, :edit)
  end

  def addUnit(request, isPrivate, target)
    post = PastebinPost.new(@database)
    @database.transaction do
      post.postInitialisation(isPrivate, target, true)
      writePermissionCheck(request, post)
      return addUnitForm(post, request)
    end
  end

  def submitUnit(request)
    return processPostSubmission(request, :addUnit)
  end
end
