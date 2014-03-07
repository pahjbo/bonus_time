class TimesheetController < ApplicationController
  unloadable

  # figure out what objects we're looking at
  before_filter :apply_filters
  # permission filters
  before_filter :my_account_or_admin, :except => [:filter, :day]
  before_filter :can_read_this_filter, :only => [:filter, :day]

  def index
    build_filters
  	month_time
    entries_by_date
  end

  # ajax action to reload a day
  def day
    entries_by_date
  end

  # ajax action to load month data (color the calendar)
  def month
    month_time
  end

  def week
    month_time 7
    render 'month'
  end

  def filter
    build_filters
    month_time
    entries_by_date
    render 'refresh_all'
  end

  # submit time form
  def log_time
    @today = params[:time_entry][:spent_on].to_date
    if params[:time_entry_id]
      time_entry_to_save = TimeEntry.find(params[:time_entry_id])
    else
      time_entry_to_save = TimeEntry.new(:user => @user)
    end
    time_entry_to_save.project = Project.find(params[:time_entry][:project_id])
    time_entry_to_save.safe_attributes = params[:time_entry]
    call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
    time_entry_to_save.save
    puts YAML::dump(time_entry_to_save)
    entries_by_date
    month_time
    build_filters
    render 'refresh_all' # helpful view which reloads both the form and the 
  end

  def edit_log
    @is_edit = true
    @time_entry = TimeEntry.find(params[:time_entry_id])
    @today = @time_entry.spent_on
    entries_by_date
    @time_log_action = { :action => "log_time", :time_entry_id => @time_entry.id }
    render 'day'
  end

  def delete_log
    @time_entry = TimeEntry.find(params[:time_entry_id])
    @today = @time_entry.spent_on
    @time_entry.destroy
    @time_entry = nil
    entries_by_date
    month_time
    build_filters
    render 'refresh_all'
  end

  def move_log
    time_entry_to_move = TimeEntry.find(params[:time_entry_id])
    @today = time_entry_to_move.spent_on
    if params[:new_date]
      time_entry_to_move.spent_on = params[:new_date].to_date
      time_entry_to_move.save
    end
    entries_by_date
    month_time
    build_filters
    render 'refresh_all'
  end

private
  def entries_by_date
    scope = TimeEntry.visible
    @day_users = {}
    query_filters = {
      :include => [:project, :activity, :user, {:issue => :tracker}],
      :conditions => {:spent_on => @today},
      :order => ['users.lastname', 'users.firstname', 'projects.name', :spent_on]
    }
    query_filters[:conditions][:project_id] = @project.id if @project
    query_filters[:conditions][:user_id] = @user.id unless @all_users
    day_entries = scope.all(query_filters)
    day_entries.each do |entry|
      if not @day_users[entry.user.name]
        @day_users[entry.user.name] = {:projects => {}, :user => entry.user, :hours => 0}
      end
      if not @day_users[entry.user.name][:projects][entry.project.name]
        @day_users[entry.user.name][:projects][entry.project.name] = {:issues => [], :hours => 0, :project_id => entry.project.id}
      end
      @day_users[entry.user.name][:hours] += entry.hours
      @day_users[entry.user.name][:projects][entry.project.name][:hours] += entry.hours
      @day_users[entry.user.name][:projects][entry.project.name][:issues] << entry
    end
    if not @time_entry
      @time_entry = TimeEntry.new
      last_time_entry = TimeEntry.first( :conditions => { :user_id => @user.id }, :order => 'updated_on DESC' )
      if last_time_entry
        if @project
          @time_entry.project_id = @project.id
        else
          @time_entry.project_id = last_time_entry.project_id
        end
        @time_entry.activity_id = last_time_entry.activity_id
      end
    end
    if not @time_log_action
      @time_log_action = { :controller => 'timesheet', :action => "log_time", :time_entry_id => nil }
    end
    @can_log_time = users_who_can_log_time().include?(User.current) && (!@all_users || @is_edit) && (User.current.admin? || User.current.id == @user.id)
  end

  def month_time(num_days=nil)
    start_date = @today
    unless num_days
      start_date = start_date.beginning_of_month
      end_date = start_date.end_of_month
    else
      start_date = @today
      end_date = start_date + num_days.days
    end
    scope = TimeEntry.visible.spent_between(start_date, end_date)
    query_filters = {
      :include => [:project, :activity, :user, {:issue => :tracker}],
      :order => :spent_on,
      :conditions => {}
    }
    query_filters[:conditions][:user_id] = @user.id unless @all_users
    query_filters[:conditions][:project_id] = @project.id if @project
    all_entries = scope.all(query_filters)
    @month_entries = {}
    @user_summary = {}
    @project_summary = {}
    @total_hours = 0;
    all_entries.each do |entry|
      @month_entries[entry.spent_on] ||= 0
      @project_summary[entry.project.name] ||= 0
      @user_summary[entry.user.name] ||= 0
      @month_entries[entry.spent_on] += entry.hours
      @user_summary[entry.user.name] += entry.hours
      @project_summary[entry.project.name] += entry.hours
      @total_hours += entry.hours
    end
    # round these numbers
    @month_entries.each{ |key,num| @month_entries[key] = num.round(2) }
    @project_summary.each{ |key,num| @project_summary[key] = [num.round(2), ((num / @total_hours) * 100).round(1)] }
    @user_summary.each{ |key,num| @user_summary[key] = [num.round(2), ((num / @total_hours) * 100).round(1)] }
    @total_hours = @total_hours.round(2)
  end

  def my_account_or_admin
    if @user.id != User.current.id
      require_admin
    end
    true
  end

  def can_read_this_filter
    return true if @user.id == User.current.id or User.current.allowed_to?(:view_time_entries, @project)
    require_admin
  end

  def users_who_can_log_time
    # first find roles that can log time
    Rails.cache.fetch('bonus_time_users_who_can_log2') do
      roles = Role.select('id').where(['permissions LIKE ?', '%:log_time%']).all.map(&:id)
      # then find users that have those roles on any project
      User.select('DISTINCT users.id, users.*') \
        .joins('INNER JOIN members ON members.user_id = users.id') \
        .joins('INNER JOIN member_roles ON member_roles.member_id = members.id') \
        .where("member_roles.role_id IN (?)", roles) \
        .where("users.status = 1") \
        .order("users.lastname, users.firstname")
    end
  end

  def apply_filters
    if params[:date]
      @today = params[:date].to_date
    else
      @today = Date.today
    end

    if params[:filter] != nil and params[:filter][:user] != nil and params[:filter][:user] != 'all'
      @user = User.find(params[:filter][:user])
    else
      @user = User.current
      @all_users = (params[:filter] != nil and params[:filter][:user] == 'all')
    end

    if params[:filter] != nil and params[:filter][:project] != '' and params[:filter][:project] != nil
      @project = Project.find params[:filter][:project]
    else # all projects
      @project = nil
       # only admins can see all projects and all users at once
      if User.current != @user && !User.current.admin?
        @user = User.current
      end
    end

    # if you can't log time, the default for users should be 'all'
    if !users_who_can_log_time().include?(User.current) && @user == User.current
      @all_users = true
    # if you switch to a different project, but have picked a user, and the user you picked
    # can't log time on the project you picked, reset to the current user.
    elsif @project && !@all_users && @user != User.current && !@user.allowed_to?(:log_time, @project)
      @user = User.current
    end

    rescue ActiveRecord::RecordNotFound
      render_404
  end

  def build_filters
    # if a project is selected, only show those who are assigned
    if @project && (User.current.admin? || User.current.allowed_to?(:view_time_entries, @project))
      _member_list = Member.all({
        :include => [:project, :user],
        :conditions => {:project_id => @project.id},
        :order => ['users.lastname', 'users.firstname']
      })
      @user_list = []
      _member_list.each do |member|
        @user_list << member.user if member.user and member.user.allowed_to?(:log_time, @project)
      end
    # show everyone who has the :log_time permission anywhere, if no project is selected and the user is an admin.
    elsif User.current.admin?
      @user_list = users_who_can_log_time()
    # otherwise, hide the dropdown
    else
      @user_list = []
    end

    # build project list
    if User.current.admin?
      _project_list = Project.all({:order => 'name'})
      project_hash = {'my' => [], 'other' => [], 'inactive' => []}
    else
      _project_list = Project.select('projects.*') \
        .joins('INNER JOIN members ON members.project_id = projects.id') \
        .where("members.user_id = ?", User.current.id) \
        .order("projects.name")
      project_hash = {'my' => []}
    end
    _project_list.each do |project|
      if project.status != 1 and User.current.admin?
        project_hash['inactive'] << [project.name, project.id]
      elsif User.current.allowed_to?(:view_time_entries, project) || User.current.allowed_to?(:log_time, project)
        project_hash['my'] << [project.name, project.id]
      elsif User.current.admin?
        project_hash['other'] << [project.name, project.id]
      end
    end
    # ensure alpha-sort, no empty lists
    @project_list = [['All', [['(All Projects)', '']]]]
    {'my' => 'My Projects', 'other' => 'Other Projects', 'inactive' => 'Inactive Projects'}.each do |key, label|
      if project_hash[key] and project_hash[key].length > 0
        @project_list << [label, project_hash[key]]
      end
    end
  end
end