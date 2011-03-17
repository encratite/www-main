require 'User'
require 'PastebinHandler'
require 'PastebinUnit'
require 'error'
require 'string'

require 'visual/highlight'

require 'www-library/SymbolTransfer'

class PastebinPost < WWWLib::SymbolTransfer
  AnonymousAuthor = 'Anonymous'
  NoDescription = 'No description'

  attr_reader(
              :userId,
              :user,
              :units,
              :author,
              :bodyAuthor,
              :noDescription,
              :bodyDescription,
              :pasteType,
              :contentSize,
              :activeUnit,
              :editAuthor,
              :children,
              )

  attr_accessor(
		:pasteTypes,
		:isPrivate,
                )

  def initialize(database)
    @bodyAuthor = ''
    @bodyDescription = ''
    #used by PostTree
    @children = []
    @database = database
  end

  def transferSymbols(input)
    super(input)
    #required for ViewPosts
    @id = @pastebinPostId if @pastebinPostId != nil
  end

  def postInitialisation(isPrivate, target, fullPostInitialisation = true)
    #just select all the fields for now, it's too much of a mess otherwise
    #the data per row are rather small anyways, the actual problem is the content within the units
    dataset = @database.post
    if target.class == String
      postData = dataset.where(private_string: target)
    else
      if isPrivate
        postData = dataset.where(id: target)
      else
        postData = dataset.where(id: target, private_string: nil)
      end
    end
    postData = postData.all
    argumentError if postData.empty?
    transferSymbols postData.first
    initialiseMembers(fullPostInitialisation)
    return
  end

  def deletePostQueryInitialisation(isPrivate, target)
    postInitialisation(isPrivate, target, false)
    return
  end

  def unitInitialisation(isPrivate, unitId, fields, fullPostInitialisation = false, fullUnitInitialisation = true)
    row = @database.unit.where(id: unitId).select(*fields).all
    argumentError if row.empty?
    unitData = row.first
    unitData[:id] = unitId
    @activeUnit = PastebinUnit.new(unitData, fullUnitInitialisation)
    postId = @activeUnit.postId
    postInitialisation(isPrivate, postId, fullPostInitialisation)
    return postId
  end

  def deleteUnitQueryInitialisation(isPrivate, unitId)
    return unitInitialisation(isPrivate, unitId, [:post_id, :description, :paste_type])
  end

  def editUnitQueryInitialisation(isPrivate, unitId)
    return unitInitialisation(isPrivate, unitId, [:post_id, :description, :content, :paste_type], true)
  end

  def editPermissionQueryInitialisation(isPrivate, unitId)
    output = unitInitialisation(isPrivate, unitId, [:post_id, :modification_counter], false, false)
    @isPrivate = @privateString != nil
    return output
  end

  def showPostQueryInitialisation(isPrivate, target, handler, request)
    dataset = @database.post

    if isPrivate
      postData = dataset.where(private_string: target)
    else
      postData = dataset.where(id: target, private_string: nil)
    end

    handler.pastebinError('You have specified an invalid post identifier.', request) if postData.empty?

    postData = postData.first
    transferSymbols postData

    if @userId != nil
      userData = @database.user.where(id: @userId)
      internalError 'Unable to retrieve the user associated with this post.' if userData.empty?
      @user = User.new(userData.first)
    end

    initialiseMembers

    unitData = @database.unit.where(post_id: @id)
    internalError 'No units are associated with this post.' if unitData.empty?
    #unit ID will be transferred from the select * query
    unitData.each { |unit| @units << PastebinUnit.new(unit) }

    return
  end

  def initialiseMembers(fullMode = true)
    if fullMode
      if @userId == nil
        @user = nil
      end

      @pasteTypes = []

      if @author == nil
        @editAuthor = nil
        if @user != nil
          @author = @user.name
        elsif @name != nil
          #name from the post listing joins
          @author = @name
        end
        @bodyAuthor = makeBold @author
      else
        #the dup is necessary because the editAuthor field would get ruined by the processDescription down there otherwise
        @editAuthor = @author.dup
        isAnonymous = @author.empty?
        processDescription(isAnonymous, @author, @bodyAuthor, AnonymousAuthor)
      end
    end

    @noDescription = @description.empty?
    processDescription(@noDescription, @description, @bodyDescription, NoDescription)

    @units = []

    @isPrivate = !@privateString.nil?

    return
  end

  def loadChildren
    #puts "Loading children of ID #{@id}"
    children = @database.post.where(reply_to: @id).all
    children.each do |child|
      childPost = PastebinPost.new(@database)
      childPost.transferSymbols(child)
      childPost.initialiseMembers
      #perform depth first search
      childPost.loadChildren
      @children << childPost
    end
    #sort the children according to their age so the oldest ones pop up first in the post tree output
    @children.sort do |a, b|
      a.creation <=> b.creation
    end

    return
  end

  def getPostPath(handler)
    if @isPrivate
      arguments = ['1', @privateString]
    else
      arguments = ['0', @id.to_s]
    end
    return handler.getPath(*arguments)
  end

  def getUnitPath(handler, unit)
    arguments = [unit.id.to_s]
    if @isPrivate
      arguments << @privateString
    end
    return handler.getPath(*arguments)
  end

  def self.publicEssentials(id)
    output = PastebinPost.new(nil)
    output.isPrivate = false
    output.id = id
    return output
  end

  def self.privateEssentials(privateString)
    output = PastebinPost.new(nil)
    output.isPrivate = true
    output.privateString = privateString
    return output
  end
end

