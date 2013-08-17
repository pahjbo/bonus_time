module TimesheetHelper
    def timesheet_edit_link entry_id
        link_args = {
          :action => 'edit_log', 
          :time_entry_id => entry_id
        }
        link_args['filter[user]'] = @all_users ? 'all' : @user.id
        link_args['filter[project]'] = @project.id if @project
        link_to 'Edit', link_args, :remote => true
    end
    def timesheet_delete_link entry_id
        link_args = {
          :action => 'delete_log', 
          :time_entry_id => entry_id
        }
        link_args['filter[user]'] = @all_users ? 'all' : @user.id
        link_args['filter[project]'] = @project.id if @project
        link_to 'Delete', link_args, :confirm => 'Are you sure?', :method => :delete, :remote => true
    end
end