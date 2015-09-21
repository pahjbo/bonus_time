# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'timesheet', :to => 'timesheet#index'
get 'timesheet/filter', :to => 'timesheet#filter'
get 'timesheet/:time_entry_id/edit', :to => 'timesheet#edit_log'
delete 'timesheet/:time_entry_id/delete', :to => 'timesheet#delete_log'
post 'timesheet/log_time', :to => 'timesheet#log_time'
patch 'timesheet/:time_entry_id/log_time', :to => 'timesheet#log_time'
put 'timesheet/:time_entry_id/move', :to => 'timesheet#move_log'
get 'timesheet/day', :to => 'timesheet#day'
get 'timesheet/month', :to => 'timesheet#month'
get 'timesheet/week', :to => 'timesheet#week'
get 'timesheet/trackable_issues', :to => 'timesheet#trackable_issues'