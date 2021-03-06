module Admin::OrderHelper

	


	def pagination_links_remote(paginator)
	  page_options = {:window_size => 1}
	  pagination_links_each(paginator, page_options) do |n|
		options = {
		  :url => {:action => 'search', :params => params.merge({:page => n, :i=>1})},
		  :update => 'listing'
		}
		html_options = {:href => url_for(:action => 'search', :params => params.merge({:page => n})), :class => 'blue bold'}
		link_to_remote(n.to_s, options, html_options)
	  end
	end 

	

  def from_value(history)
    if history.from_value == '0' && history.to_value == 'true' 
      'false'  
    elsif history.attribute == 'printer'
      display_printer_name_from_id(history.from_value)
    elsif history.attribute == 'shipping_type'
      SHIPPING_NAMES[history.from_value.to_i]
    else
      history.from_value
    end
  end

  def to_value(history)
    if history.attribute == 'printer'
      display_printer_name_from_id(history.to_value)
    elsif history.attribute == 'shipping_type'
      SHIPPING_NAMES[history.to_value.to_i]
    else
      history.to_value
    end
  end

    
    
    

		
  
  def business_days_future(num,start_date=nil)
    # takes the number of days in the past you are looking for
    # like 10 business days ago
    start_date ||= Date.today
    start_day_of_week = start_date.cwday #Date.today.cwday
    ans = 0
    # find the number of weeks
    weeks = num / 5.0
    #puts "yields #{weeks} weeks"
      
    temp_num = num > 5 ? 5 : num
    #puts "first temp num #{temp_num}"
    
    begin
      
      ans += days_to_adjust_f(start_day_of_week,temp_num)
      #puts "ans in loop #{ans}"
      
      weeks -= 1.0
      #puts "weeks in loop #{weeks}"
      
      temp_num = (weeks >= 1) ? 5 : num % 5
      #puts "temp_num after loop #{temp_num}"
    end while weeks > 0
    
    #puts "#{start_date} - #{num} - #{ans}"
    days_ago = start_date + num + ans
    
  end
  
  
  
  def days_to_adjust_f(start_day_of_week,num)
    ansr = 0
    case start_day_of_week
    when 1
      if 5 == num then ansr += 2 end
    when 2
      if (4..5).include?(num) then ansr += 2 end
    when 3
      if (3..5).include?(num) then ansr += 2 end
    when 4
      if (2..5).include?(num) then ansr += 2 end
    when 5
      if (1..5).include?(num) then ansr += 2 end
    when 6
      if (1..5).include?(num) then ansr += 1 end
    when 7
      #do nothing 
    end
    return ansr
  end


	
end
