# Methods added to this helper will be available to all templates in the admin back-office.
module AdministrationHelper
  include GetText
  def get_path_filename(img)
    return img.orig_image.url("100")
  end

  def display_money_hash(money_hash)

    str = ""
    all_currencies = Currency.find(:all)
    for currency in all_currencies

      str += "#{number_to_currency_custom(money_hash[currency.label], {:currency=>currency.label})}<br/>" if money_hash[currency.label] > 0
    end
    return str
  end

  def display_expected(garment)
    if garment.ordered_from == "Sanmar"
      business_days_future(1, garment.garments_ordered_on)
    elsif garment.ordered_from == "Technosport Ground"
      business_days_future(4, garment.garments_ordered_on)
    elsif garment.ordered_from == "Technosport Air"
      business_days_future(2, garment.garments_ordered_on)
    else
      "Unknown"
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

  def link_to_with_sort(name, sort_field, options = {}, html_options = nil)
    current_sort = params[:order].split(' ')[0] unless params[:order].nil?
    current_way = params[:order].split(' ')[1] unless params[:order].nil?
    
    if (sort_field == current_sort)
      way = (current_way == 'desc') ? 'asc' : 'desc';
      arrow = "&nbsp;#{image_tag('admin-arrow-th.gif')}"
    else
      way = 'asc'
      arrow = ''
    end

    options[:order] = sort_field + ' ' + way
    
    options[:search] = params[:search]
    options[:search_field] = params[:search_field]
    options[:page] = params[:page]
    
    "#{link_to(name, options, html_options)}#{arrow}" 
  end
  
  

  def link_to_with_sort_earnings(name, sort_field, options = {}, html_options = nil)
    current_sort = params[:order] unless params[:order].nil?
    current_way = params[:direction] unless params[:order].nil?
    
    if (sort_field == current_sort)
      way = (current_way == 'desc') ? 'asc' : 'desc';
      arrow = "&nbsp;#{image_tag('admin-arrow-th.gif')}"
    else
      way = 'desc'
      arrow = ''
    end

    options[:order] = sort_field
    options[:direction] = way
    options[:page] = params[:page] if params[:page]
    link_to(name, options, html_options) + arrow
  end
  
  def format_date(current_date)
    current_date.month.to_s  + '-' + current_date.day.to_s + '-' + current_date.year.to_s
  end
  
  def format_date_and_time(current_date)
    current_date.month.to_s  + '-' + current_date.day.to_s + '-' + current_date.year.to_s + ' ' + current_date.hour.to_s + ':' + current_date.min.to_s + ':' + current_date.sec.to_s
  end
  
  def echo_not_zero(num)
    num if num.to_f != 0.0
  end

  def bool_to_human(response, bool_true, bool_false)
    (response) ? bool_true : bool_false
  end
  
  def if_controller(controller, text_yes, text_no)
    (params[:controller] == controller) ? text_yes : text_no
  end

  def image_bank
    ["admin/frame_bank","admin/banner_bank", "admin/menu_bank"].include?(params[:controller])
  end
  
  def display_localization_tabs(loc_object)
    logger.error("INSPECTION: " + loc_object.inspect)
    languages = loc_object.map { |c| [c.language.id, c.language.name] }
    render :partial => '/admin/misc/localization_tabs', :use_full_path => true, :collection => languages
  end

  def display_locale_tabs(locales,default)    
    locales = locales.map { |locale| [locale.id, locale.long_name] }
    render :partial => '/admin/misc/locale_tabs', 
      :use_full_path => true, 
      :collection => locales, 
      :locals => {:default => default}
  end

  def display_size_type_tabs(size_types,default)    
    size_types = size_types.map { |size_type| [size_type.id, size_type.name] }
    render :partial => '/admin/misc/size_type_tabs', 
      :use_full_path => true, 
      :collection => size_types, 
      :locals => {:default => default}
  end
  
  def display_active(active, action = "active")
    if active.active 
      link_to(image_tag("admin/ico-active.png"),{:action => action, :id => active.id})
    elsif !active.active
      link_to(image_tag("admin/ico-unactive.png"),{:action => action, :id => active.id})
    end
  end
  
  def display_nodiscount(nodiscount, action = "nodiscount")
    if nodiscount.nodiscount 
      link_to(image_tag("admin/ico-active.png"),{:action => action, :id => nodiscount.id})
    elsif !nodiscount.nodiscount
      link_to(image_tag("admin/ico-unactive.png"),{:action => action, :id => nodiscount.id})
    end
  end
  
  def display_wholesale(wholesale, action = "wholesale")
    if wholesale.wholesale
      link_to(image_tag("admin/ico-active.png"),{:action => action, :id => wholesale.id})
    elsif !wholesale.wholesale
      link_to(image_tag("admin/ico-unactive.png"),{:action => action, :id => wholesale.id})
    end
  end
  
  

  def display_staff_pick(image)
    if image.staff_pick 
      link_to(image_tag("admin/ico-active.png"),{:action => 'staff_pick', :id => image.id}) 
    else
      link_to(image_tag("admin/ico-unactive.png"),{:action => 'staff_pick', :id => image.id})
    end
  end

  def display_top_product(model)
    page = params[:page] ? params[:page] : 1
    if model.top_product 
      link_to(image_tag("admin/ico-active.png"),{:action => 'top_product', :id => model.id, :page => page}) 
    else
      link_to(image_tag("admin/ico-unactive.png"),{:action => 'top_product', :id => model.id, :page => page})
    end
  end
       
  def display_categories(category,depth=0)
    ret = ""
    ret = "<tr class='#{cycle('odd', '')}'>"
    ret += "<td style='height:28px;padding-left:#{30*depth+5}px;'>#{category.local_name(session[:language_id])}</td>"
    ret += "<td>#{display_active(category)}</td>"
    if @category_type_id and @category_type_id.to_i == 4
      ret += "<td>#{display_wholesale(category)}</td>"
    end
    if @category_type_id
      ret += "<td>#{category.position} #{link_to "Up", {:action => "move_up", :id => category.id, :category_type_id => @category_type_id}} #{link_to "Down", {:action => "move_down", :id => category.id, :category_type_id => @category_type_id}}</td>"
    end

    ret += "<td>"
    ret += link_to '&nbsp;', {:action => 'edit', :id => category}, {:class => 'icoEdit icopng', :title => t(:admin_edit) }
    ret += "&nbsp;"
    ret += link_to '&nbsp;', { :action => 'destroy', :id => category }, :confirm => t(:admin_confirm), :method => :post, :class => 'icoDelete icopng', :title => t(:admin_delete)
    ret += "</td>"
    ret += '</tr>'
    category.sub_categories.each do |sub_category| 
      ret += display_categories(sub_category,depth+1)    
    end
    ret
  end
  
  def display_cities(city,depth=0)
    ret = ""
    ret = "<tr class='#{cycle('odd', '')}'>"
    ret += "<td style='height:28px;padding-left:#{30*depth+5}px;'>#{city.name}</td>"
	ret += "<td>#{city.name_en}</td>"
    ret += "<td>#{city.province.name}</td>"
    ret += "<td>#{city.url}</td>"
    
    ret += "<td>"
    ret += link_to '&nbsp;', {:action => 'edit', :id => city}, {:class => 'icoEdit icopng', :title => t(:admin_edit) }
    #ret += "&nbsp;"
    #ret += link_to '&nbsp;', { :action => 'destroy', :id => city }, :confirm => t(:admin_confirm), :method => :post, :class => 'icoDelete icopng', :title => t(:admin_delete)
    ret += "</td>"
    ret += "</tr>"
    
    ret
  end

  def display_admin_save_button(label, buttons = {})
    return link_to(label, "javascript:document.forms[0].submit();", {:class => 'textLink', :title => label }) unless (!buttons.empty? && buttons[:SAVE].nil?)
  end

  def my_display_admin_save_button(label, buttons = {})
    return link_to(label, "javascript:document.forms[1].submit();", {:class => 'textLink', :title => label }) unless (!buttons.empty? && buttons[:SAVE].nil?)
  end

  def edit_form_buttons(list_id = nil, buttons = {})
    val = ''
    val += link_to t(:admin_back), {:action => 'list', :id => list_id}, {:class => 'textLink', :title => t(:admin_back) } unless (!buttons.empty? && buttons[:BACK].nil?)
    val += ' '
    val += display_admin_save_button(t(:admin_save))
    return val
  end

  def my_edit_form_buttons(list_id = nil, buttons = {})
    val = ''
    val += link_to t(:admin_back), {:action => 'list', :id => list_id}, {:class => 'textLink', :title => t(:admin_back) } unless (!buttons.empty? && buttons[:BACK].nil?)
    val += ' '
    val += my_display_admin_save_button(t(:admin_save))
    return val
  end

  def ordered_product_zone_id(index)
	return OrderedProduct.ordered_product_zone_id(index)
  end

  # find the current letter according to all products for a given zone
  def ordered_product_zone_id_from_products(products, current_zone)
	return OrderedProduct.ordered_product_zone_id_from_products(products, current_zone)
  end
  
  
  def display_last_comment_posted_by_name(order)
    begin 
      if(order.last_comment_posted_by != nil)
        User.find(order.last_comment_posted_by).username 
      else
        ''
        end   
    rescue 
      ''
    end   
  end
  
  def display_artwork_date_required(order)
    return order.artwork_required_on
  end

  def display_bulk_order_seller(bulk_order)
    return bulk_order.seller_name
  end

   def display_quote_calculator_model_name(quote_product)
	return quote_product.model_name(session[:language_id])
  end
  
  def display_garments_changed(order)
      order.ordered_products.each do |item|
        if item.garments_changed
          return link_to(t(:_yes),{:controller => "admin/ordered_garments", :action => "show_order", :id => order.id })
        end
      end
      return t(:non)
    end
    def display_garments_ordered(order)
      if ! order.garments_ordered
        return link_to(t(:non),{:controller => "admin/ordered_garments", :action => :list, :id => order.id })
      end

      return t(:_yes)
    end

  def number_to_currency_custom(number, opt={})



    if opt[:currency]
      currency = opt[:currency]
    end

    if opt[:language]
      language = opt[:language]
    end


    format = "%u %n"

    begin
      unit = "CAD"
      unit = currency if currency 
    end

    number_to_currency(number, :unit => unit, :precision=>2, :delimiter=>" ", :separator=>".", :format => format)
  end

  def get_options_for_country_select

	countries = []

	Locale.all.each do |l|
		country_code = l.locale.split("-")[1]
		c = Country.find_by_shortname(country_code)

		if ! countries.include?(c)
			countries << c
		end
	end

    # return [["Canada", "CA"],["USA", "US"],["France", "FR"],["Australia", "AU"],["United Kingdom", "GB"], ["Europe", "EU"], ["Belgique", "BE"], ["Suisse", "CH"], ["España", "ES"], ["México", "ES"], ["Deutschland", "DE"], ["Österreich", "AT"], ]
	return countries.map{ |c| [c.name, c.shortname] }
  end

  def spinner_tag
    return image_tag('/images/spinner.gif', :class => "spinner", :id => "spinner", :style => "display:none")
  end

end
