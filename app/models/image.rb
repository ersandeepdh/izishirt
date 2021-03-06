class Image < ActiveRecord::Base
  #validates_presence_of :name
  
  require 'RMagick'

  has_attached_file :orig_image, :whiny => false,
    :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :styles => {
      "340" => ['340x340>', :jpg],
      "popup" => ['200x200>', :jpg],
      "100" => ['100x100>', :jpg],
      "thumb" => ['60x60>', :jpg],
      "png" => ['100x100', :png],
      "png200" => ["200x200", :png],
      "png340" => ["340x340", :png]
    },
    :convert_options => {
      :all => "-strip -colorspace RGB",
      "340" => '-background white -flatten -quality 100',
      "popup" => '-background white -flatten -quality 100',
      "100" => '-background white -flatten -quality 100',
      "thumb" => '-background white -flatten -quality 100'
    }

  validates_attachment_size :orig_image, :less_than => 5.megabytes

  validates_attachment_content_type :orig_image,
    :content_type => ["image/jpg", "image/pjpeg", "image/x-png", "image/png", "image/gif", "image/png", "image/jpeg", "image/gif"]

  validate :validate_orig_image_size
  #Commented because of shitty, not localized error message
  #validates_attachment_size :contest_preview, :less_than => 100.kilobytes




  has_many :fast_tag_images, :dependent => :destroy
  has_many :fast_tags, :through => :fast_tag_images
  #belongs_to :zone
  belongs_to :category
  belongs_to :city
  belongs_to :user
  has_many :zone_artworks
  #has_many :products, :through => :zones
  has_many :ordered_zone_artworks
  has_one :top_design
  belongs_to :country
  has_many :localized_images, :dependent => :destroy
  has_many :image_files, :dependent => :destroy
  #has_many :earnings, :conditions=>['earning_type = "Image"']
  has_many :store_comments

  def validate_orig_image_size
    if orig_image.file? && orig_image.size.to_i > 5.megabytes
      errors.add_to_base(I18n.t(:error_larger_than_5MB))
    end
  end

  def validate_contest_preview_size
    if contest_preview.file? && contest_preview.size.to_i > 100.kilobytes
      errors.add_to_base(I18n.t(:error_larger_than_100KB))
    end
  end

  def self.approval_states(lang)
    [I18n.t(:admin_image_approval_state_0,:locale => lang),
     I18n.t(:admin_image_approval_state_1,:locale => lang),
     I18n.t(:admin_image_approval_state_2,:locale => lang),
     I18n.t(:admin_image_approval_state_3,:locale => lang),
     I18n.t(:admin_image_approval_state_4,:locale => lang)]
  end

	def can_be_current_contest_winner?()
		if pending_approval != DESIGN_VALIDATION_STATE_APPROVED_ID || ! is_contest || ! end_vote || is_winner
			return false
		end

		return end_vote.to_date >= (Time.now.to_date - 30.days) && end_vote.to_date < Time.now.to_date
	end

	def is_currently_contest_vote_mode?()
		if pending_approval != DESIGN_VALIDATION_STATE_APPROVED_ID || ! is_contest || ! end_vote || is_winner
			return false
		end

		return end_vote >= Time.now
	end

	def self.contest_amount_by_currency(currency_label)
		infos = {"GBP" => 600, "EUR" => 650, "CHF" => 1000, "AUD" => 1000, "MXN" => 10000}

		begin
			amount = infos[currency_label]

			if amount
				return amount
			end
		rescue
		end

		return 1000
	end

	def generate_1000_from_orig()

		if ! created_on
			raise "The orig_image has to be saved first, then call this method."
		end

		orig_file_path = orig_image.path

		self.contest = File.new(orig_file_path)
		return save
	end

	def change_contest_1000_background_color(p_background_color)
		if ! created_on
			raise "The orig_image has to be saved first, then call this method."
		end

		self.background_color = p_background_color
		self.change_background_jpg_contest = File.new(self.orig_image.path())
		self.jpg_background_color = p_background_color

		return self.save
	end

	def orig_file_extension()
		begin
			if ! orig_image
				return ""
			end

			return File.extname(orig_image.path).downcase
		rescue
		end

		return ""
	end

	def contains_transparency?()
		begin
			img = Magick::Image::read(orig_image.path).first

			cols = img.columns

			nb_rows_to_look = (img.rows.to_f * 0.01).round(0).to_i

			# thx ruby !
			rows_to_look = nb_rows_to_look.times.map{ rand(img.rows) }

			rows_to_look.each do |row|
				pixels = img.get_pixels(0, row, img.columns, 1)

				pixels.each do |p|
					# 8 bits, 16, 24, 32
					trans_values = [255, 65535, 16777215, 4294967295]

					trans_values.each do |trans_value|
						if (p.red == trans_value && p.green == trans_value && p.blue == trans_value && p.opacity == trans_value) || (p.red == 0 && p.green == 0 && p.blue == 0 && p.opacity == trans_value)
							return true
						end
					end
				end
			end
			Rails.logger.error("check transparency 5")
		rescue => e
			Rails.logger.error("ERROR => #{e}")
		end

		return false
	end

	def save_tags
	    tags = FastTagImage.find_all_by_image_id(id)

	    tags.each do |tag|
		tag.fast_tag.update_attributes(:counter_images => tag.fast_tag.counter_images - 1)
		tag.destroy
	    end

	    cpt = 0

	    alltags.each do |tag|
	      cpt += 1

	      if cpt > NB_MAX_BOUTIQUE_TAGS
		break
	      end

	      tag = tag.removeaccents if tag
	      tag = tag.strip if tag
	      tag = tag.downcase if tag

		tag = StringUtil.limit_tag(tag) if tag

		logger.error("TAGGGGGG = #{tag}")

	      #Tag.find_or_create_by_name_and_image_id(tag, @image.id)
	      begin
		FastTag.create(:name => tag)
	      rescue
	      end

	      fast_tag = FastTag.find_by_name(tag)

	      begin
		tag = FastTagImage.create(:fast_tag_id => fast_tag.id, :image_id => id)
		tag.fast_tag.update_attributes(:counter_images => tag.fast_tag.counter_images + 1)
	      rescue
	      end
	    end
	end

  def image_alt
    return "T-Shirts #{name}"
  end
  
  def image_title
    return image_alt
  end

  def background_color=(new_background_color)
    @str_background_color = new_background_color
  end

  def background_color
    return @str_background_color
  end

  def url_design_id(design)
    
    # <nom_design>-<id>

    return "#{StringUtil.pretty_escape_url(design.name)}-#{design.id}"
  end

  def url(lang, lang_id, per_page = 25)
    return "#{Language.print_force_lang(lang)}#{I18n.t(:create_shirt_url, :locale => Language.find(lang_id).shortname)}/#{url_design_id(self)}"
  end

	def info_url(lang, lang_id, per_page = 25)
		# /custom-t-shirt-design/{parent_category}-design-{name}-{id}
		parent_name, sub_name =  Category.get_parent_sub_name(category_id, lang_id)
	  
		return "#{Language.print_force_lang(lang)}#{I18n.t(:front_office_design_info_url, :locale => Language.find(lang_id).shortname)}/#{url_design_id(self)}"
	end

	def parent_category_name(lang_id)
		begin
			parent_name, sub_name =  Category.get_parent_sub_name(category_id, lang_id)

			return parent_name
		rescue
		end

		return ""
	end

  def marketplace_url(lang, lang_id, filter_by = "all", per_page = 15)
    # map.connect 't-shirt-:design_name-marketplace-:design_id', :controller => 'display', :action => 'marketplace_shop'
    # map.connect ':lang/t-shirt-:design_name-marketplace-:design_id', :controller => 'display', :action => 'marketplace_shop', :lang => lang_regexp

    if lang_id == 1
      return "#{Language.print_force_lang(lang)}t-shirt-design-marketplace/#{StringUtil.marketplace_filter_name_id(lang_id, filter_by)}/t-shirt-#{StringUtil.pretty_escape_url(name)}-#{id}"
    else
      return "#{Language.print_force_lang(lang)}t-shirt-design-marketplace/#{StringUtil.marketplace_filter_name_id(lang_id, filter_by)}/#{StringUtil.pretty_escape_url(name)}-t-shirt-#{id}"
    end
  end

	def boutique_design_url(lang, lang_id)
		return "#{Language.print_force_lang(lang)}#{I18n.t(:boutique_flash_url_id, :locale => Language.find(lang_id).shortname)}/#{StringUtil.pretty_escape_url(name)}-#{id}"
	end

  def products
    #zone_artworks
    return Product.find(:all, :conditions => ["zone_artworks.image_id = #{id}"], :include => [:zones => [:zone_artworks]])
  end  
  
  def manual_validation
    if category_id <= 0
      errors.add_to_base("No category has been selected.")
    end

    if ! name || name == ""
      errors.add_to_base("No name has been entered.")
    end
  end

  def before_create
    dimensions = Paperclip::Geometry.from_file(self.orig_image.queued_for_write[:original])
    self.errors.add(:orig_image, "Please upload a file less than 4000x4000 pixels wide") if (dimensions.width >= 4000 || dimensions.height >= 4000)

    if (dimensions.width >= 4000 || dimensions.height >= 4000)
      return false
    end



    if self.errors.length != 0
      self.is_invalid = true
      self.pending_approval = DESIGN_VALIDATION_STATE_APPROVED_ID
      self.show_in_boutique = 0
      return false
    end

    return true
	end

  def last_earning
    earning = Earning.find(:first, :conditions=>['image_id = ? and earning_type = "Image"', id], :order=>'id DESC')
  end

  def earning_count
    count = 0

    earnings.each do|e|
      count += e.ordered_zone.ordered_product.quantity
    end
    
    count
  end

  def year_created_on
    begin
    return created_on.year
    rescue
    end

  end

  def month_created_on
    begin
    return created_on.month
          rescue
    end
  end

  def day_created_on
    begin
    return created_on.day
        rescue
    end
  end
  
  def date_folder
    "#{year_created_on}/#{month_created_on}/#{day_created_on}"
  end

  def self.top_fifty_by_category(category)
    Image.find_all_by_category_id(category, :conditions => ["active = 1 and pending_approval = 1 and is_private = 0"], :order => ["sorting_rate desc"], :limit => 50)
  end
  def self.user_designs_sorted_by_sales(user_id, conditions=nil)
    user_designs = Image.find_all_by_user_id(user_id, :conditions=>conditions)
    user_designs.each { |ud| 
      ud.sorting_rate = OrderedZoneArtwork.find_all_by_image_id(ud.id).size
    }
    
    user_designs.sort! { |a,b| b.sorting_rate <=> a.sorting_rate }
  end

  def self.top_five_by_category(category)
    OrderedZoneArtwork.find(:all,
      :select => "image_id", 
      :order => "count(image_id) desc", 
      :group => "image_id", 
      :limit => 5, 
      :include => [:image], 
      :conditions => ["image_id is not null 
        and images.category_id = ? 
        and images.active = ? 
        and images.is_private = ?", category, 1, 0]).map{ |zone| 
          zone.image
        }
  end

  def self.weekly_designs(category='all')
    if category=='all'
      category_condition = ''
    else
      category_condition = "and category_id = #{category}"
    end
    designs = OrderedZoneArtwork.find(:all,
      :select => "image_id", 
      :order => "count(image_id) desc", 
      :group => "image_id", 
      :limit => 3, 
      :include => [:image], 
      :conditions => ["image_id is not null 
        and images.active = ? 
        #{category_condition}
        and ordered_zone_artworks.created_at >= ?
        and images.is_private = ?", 1, Time.now - 1.week,0]).map{ |zone| 
          {
            :path => zone.image.orig_image.url("png"),
            :id => zone.image_id
          }
        }
    if designs.size < 3 && category != 'all'
       return weekly_designs()
    elsif designs.size < 3
      designs = OrderedZoneArtwork.find(:all,
      :select => "image_id",
      :order => "count(image_id) desc",
      :group => "image_id",
      :limit => 3,
      :include => [:image],
      :conditions => ["image_id is not null
        and images.active = ?
        #{category_condition}
        and images.is_private = ?", 1,0]).map{ |zone|
          {
            :path => zone.image.orig_image.url("png"),
            :id => zone.image_id
          }
        }
        
    end
    return designs

  end

  def pending_approval=(new_pending)
	begin
		image = Image.find(id)
	rescue
		image = nil
	end

	if new_pending.to_i == DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID && is_contest && image && image.pending_approval != -1
		Rails.logger.error("CONTEST IMAGE VIOLATION FOR IMAGE #{image.id}")
		return
	end

   
    
    super
  end

  def always_private=(new_always)

    new_always = ! new_always.nil? && (new_always == 1 || new_always == "true" || new_always == true)

    super

    if new_always && id
      image = Image.find(id)
      image.update_attributes(:is_private => true)

      # enlever de la marketplace les produits ayant cette image
      prods_to_remove_from_marketplace = products()

      prods_to_remove_from_marketplace.each do |product|
        product.update_attributes(:category_id => 0)
      end
    end
  end

  def deactivate_products(mail)
    users = {}
    products.each do |product|

      if product.product_removed
        next
      end

      print "   [+] deactivating product #{product.id} of user #{product.store.user.id} (#{product.store.user.email})\n"

      product.update_attributes({:product_removed => true, :removed_reason=> "Image declined"})
      users[product.store.user] = true if product.store && product.store.user
    end

    mails_sent = false

    users.each do |user,v|
      
      if mail == "image_declined"
        mails_sent = true
        SendMail.deliver_product_removed_image_declined(user, id)
      else
        mails_sent = true
        SendMail.deliver_product_removed_image_deleted(user, id)
      end
    end

    return mails_sent
  end

  def reactivate_products
    products.each do |product|
      product.update_attributes({:product_removed => false, :removed_reason => nil})
    end
  end
  
  def alltags
   @alltags || fast_tag_images.map {|t| [t.fast_tag.name]}
  end
  
  def alltags=(p_tags)
    @alltags = p_tags.split(',')
  end
    
  def localized_meta_title(language, domain="izishirt.ca")
    category_name = category.nil? ? "" : category.localized_categories[language-1].name.to_s
    return I18n.t(:meta_title_design, :domain=>domain.capitalize, :name=>name, :category=>category_name)
  end
    
  def localized_meta_description(language)
    return I18n.t(:meta_description_design, :name=>name.to_s.capitalize)
  end
  
  def localized_meta_keywords(language)
    category_name = category.nil? ? "" : category.localized_categories[language-1].name.to_s
    return I18n.t(:meta_keywords_design, :name=>name.to_s.capitalize, :category=>category_name, :user=>user.username.capitalize)
  end

  
  
	def self.prepare_show_for_flex(designs,has_pages,base_url)
    klass = Class.new Image
    Object.const_set "Design", klass
    	  
		designs.map{ |image|
		  d = klass.new		  
	    d.write_attribute('id',image.id)
			d.write_attribute('filetype', 'png')
			d.write_attribute('category_id', image.category_id)
			d.write_attribute('thumbnail', "#{base_url}/izishirtfiles/images/#{image.date_folder}/#{image.id}/#{image.id}_thumb.jpg")
      d.write_attribute('image', "#{base_url}/create/designs/get_image/#{image.id}")
      d.write_attribute('big_image', "#{base_url}/izishirtfiles/images/#{image.date_folder}/#{image.id}/#{image.id}_340.jpg")
			d.write_attribute('name', image.name)
      d.write_attribute('created_on', image.created_on)
			d.write_attribute('lockcolor', false)
			d.write_attribute('printtype', 1)
			d.write_attribute('imagetype', 'pixel')
			d.write_attribute('minzoom', 50)
			d.write_attribute('maxzoom',150)
			d.write_attribute('defaultzoom', 100)
			d.write_attribute('rotation', 0)
      d.write_attribute('pages',designs.total_pages) if has_pages
      d.write_attribute('page',designs.current_page) if has_pages
      d
		}
	end
	def self.prepare_index_for_flex(designs,has_pages,base_url)
    klass = Class.new Image
    Object.const_set "Design", klass
    	  
		designs.map{ |image|
		  d = klass.new		  
	    d.write_attribute('id',image.id)
			d.write_attribute('category_id', image.category_id)
			d.write_attribute('thumbnail', "#{base_url}/izishirtfiles/images/#{image.date_folder}/#{image.id}/#{image.id}_thumb.jpg")
			d.write_attribute('name', image.name)
      d.write_attribute('pages',designs.total_pages) if has_pages
      d.write_attribute('page',designs.current_page) if has_pages
      d
		}
	end

  def nb_sold
    cpt = 0

    earnings.each do |earning|
      cpt += earning.ordered_zone.ordered_product.quantity if earning.ordered_zone && earning.ordered_zone.ordered_product
    end

    return cpt
  end

  def is_voted
    return true if end_vote && end_vote.to_date >= Time.now.to_date && is_contest && pending_approval == DESIGN_VALIDATION_STATE_APPROVED_ID
    return false
  end
  
  def is_pending_contest
    return true if pending_approval == DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID && is_contest
    return false
  end

  ###############################################################
  # Functions for sharing on Twitter 
  ###############################################################
  def get_twitter_post(domain, locale)
    I18n.t("myizishirt.share.share_design",
           :domain => get_link_to_flash(domain),
           :locale => locale)
  end
  def get_twitter_contest_post(domain, username, locale)
    tweet=I18n.t("myizishirt.share.share_contest_submit",
                 :locale => locale)
    tweet="#{tweet} #{get_link_to_contest(domain,username)}"
  end
  def get_twitter_vote_post(domain, username, locale)
    tweet=I18n.t("myizishirt.share.share_contest_vote",
                 :locale => locale)
    tweet="#{tweet} #{get_link_to_contest(domain,username)}"
  end
  ###############################################################
  # EO Functions for sharing on Twitter
  ###############################################################


  ###############################################################
  # Functions for sharing on facebook
  ###############################################################
  def get_link_to_boutique(domain)
    "#{user.create_my_url(domain)}/my/designs?from=#{user.username}"
  end
  def get_link_to_flash(domain)
    "#{user.create_my_url(domain)}/make-custom-t-shirt/#{id}?from=#{user.username}"
  end
  def get_link_to_contest(domain,username)
    "#{domain}/contest/tshirt_design/design_details/vote-for-#{StringUtil.pretty_escape_url(name)}-#{id}?from=#{username}"
  end
  def facebook_profile
    begin
     facebook = Facebook.find_by_user_id(user_id) 
     return facebook.facebook_profile
    rescue
      return ""
    end 
  end
  def facebook_access_token
    begin
     facebook = Facebook.find_by_user_id(user_id) 
     return facebook.access_token
    rescue
      return ""
    end 
  end
  def get_facebook_post(domain, locale)
    begin
      facebook = Facebook.find_by_user_id(user_id)
      count = facebook.facebook_posts.count(:conditions => ["post_type = ? and created_at > ?", 
                                                            "design_share",
                                                            30.minutes.ago])
      if count == 0 
        msg = I18n.t("myizishirt.share.share_design",
                     :domain => "#{domain}?from=#{user.username}", 
                     :locale => locale)
      else
        msg = I18n.t("myizishirt.share.share_designs",
                     :domain => "#{domain}?from=#{user.username}", 
                     :count => count+1, :locale => locale)
      end
    rescue
      msg = I18n.t("myizishirt.share.share_design",
                   :domain => "#{domain}?from=#{user.username}", 
                   :locale => locale)
    end
  end
  def get_facebook_contest_post(domain, locale)
    begin
      facebook = Facebook.find_by_user_id(user_id)
      count = facebook.facebook_posts.count(:conditions => ["post_type = ? and created_at > ?", 
                                                            "contest_design_share",
                                                            30.minutes.ago])
      if count == 0 
        msg = I18n.t("myizishirt.share.share_contest_submit", :domain => domain, :locale => locale)
      else
        msg = I18n.t("myizishirt.share.share_contest_submits", :domain => domain, :count => count+1, :locale => locale)
      end
    rescue
      msg = I18n.t("myizishirt.share.share_contest_submit", :domain => domain, :locale => locale)
    end
  end
  def get_facebook_vote_post(domain, locale, facebook)
    begin
      count = facebook.facebook_posts.count(:conditions => ["post_type = ? and created_at > ?", 
                                                            "vote_share",
                                                            30.minutes.ago])
      if count == 0 
        msg = I18n.t("myizishirt.share.share_contest_vote", :domain => domain, :locale => locale)
      else
        msg = I18n.t("myizishirt.share.share_contest_votes", :domain => domain, :count => count+1, :locale => locale)
      end
    rescue
      msg = I18n.t("myizishirt.share.share_contest_vote", :domain => domain, :locale => locale)
    end
  end
  def facebook_post_to_delete
    begin
      facebook = Facebook.find_by_user_id(user_id)
      count = facebook.facebook_posts.count(:conditions => ["post_type = ? and created_at > ?", 
                                                            "design_share",
                                                            30.minutes.ago])
      if count != 0 
        return facebook.facebook_posts.last.facebook_post_id
      else
        return ""
      end
    rescue
      return ""
    end
  end
  def facebook_contest_post_to_delete
    begin
      facebook = Facebook.find_by_user_id(user_id)
      count = facebook.facebook_posts.count(:conditions => ["post_type = ? and created_at > ?", 
                                                            "contest_design_share",
                                                            30.minutes.ago])
      if count != 0 
        return facebook.facebook_posts.last.facebook_post_id
      else
        return ""
      end
    rescue
      return ""
    end
  end
  def get_vote_post_to_delete(facebook)
    begin
      count = facebook.facebook_posts.count(:conditions => ["post_type = ? and created_at > ?", 
                                                            "vote_share",
                                                            30.minutes.ago])
      if count != 0 
        return facebook.facebook_posts.last.facebook_post_id
      else
        return ""
      end
    rescue
      return ""
    end
  end
  def share
    begin
      Facebook.find_by_user_id(user_id).share_designs
    rescue
      false
    end
  end
  def share_contest
    begin
      Facebook.find_by_user_id(user_id).share_contest_designs
    rescue
      false
    end
  end
  ###############################################################
  # EO Functions for sharing on facebook
  ###############################################################
  

##########
  private
##########			  	
  
end
