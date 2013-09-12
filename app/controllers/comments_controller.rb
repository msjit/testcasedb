class CommentsController < ApplicationController
  # POST /comments
  # POST /comments.xml
  def create
    authorize! :create, Comment
    if params[:test_case_id]
  	  @test_case = TestCase.find(params[:test_case_id])
      @comment = @test_case.comments.build(params[:comment])
      authorize! :create, @comment
      @comment.user_id = current_user.id
      @new_comment = Comment.new(:test_case_id => @test_case.id, :comment => 'Enter a new comment')  
      respond_to do |format|
        if @comment.save
          History.create(:test_case_id => @test_case.id, :action => 7, :user_id => current_user.id)
          format.html { redirect_to( @test_case, :notice => 'Comment was successfully created.') }
          format.js
        else
          format.html { render :action => "new" }
        end
      end
    elsif params[:test_plan_id]
  	  @test_plan = TestPlan.find(params[:test_plan_id])
      @comment = @test_plan.comments.build(params[:comment])
      authorize! :create, @comment
      @comment.user_id = current_user.id
      @new_comment = Comment.new(:test_plan_id => @test_plan.id, :comment => 'Enter a new comment')    
      respond_to do |format|
        if @comment.save
          History.create(:test_plan_id => @test_plan.id, :action => 7, :user_id => current_user.id)
          format.html { redirect_to( @test_plan, :notice => 'Comment was successfully created.') }
          format.js
        else
          format.html { render :action => "new" }
        end
      end
    elsif params[:task_id]
  	  @task = Task.find(params[:task_id])
      @comment = @task.comments.build(params[:comment])
      authorize! :create, @comment
      @comment.user_id = current_user.id
      @new_comment = Comment.new(:task_id => @task.id, :comment => 'Enter a new comment')    
      respond_to do |format|
        if @comment.save
          History.create(:task_id => @task.id, :action => 7, :user_id => current_user.id)
          format.html { redirect_to( @task, :notice => 'Comment was successfully created.') }
          format.js
        else
          format.html { render :action => "new" }
        end
      end
    end  
  end
  
end
