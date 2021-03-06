class Create::ProductsController < ApplicationController
	def show
	  @product = Product.find(params[:id])
    @product.zones.each do |oz|
      oz.txt_lines.map do |txt_line|
        txt_line.write_attribute("clean_content", "=#{txt_line.content}=")
        txt_line
      end
    end
    
    respond_to do |format|
	    format.html # index.html.erb
	    format.xml  { render :xml => @product.to_xml(
	      :only => attribute_array,
	      :include => {:zones => { :include => {:txt_lines => {}, :zone_artworks => {} } } } )}
	    format.fxml  { render :fxml => @product.to_fxml(
	      :only => attribute_array,
	      :include => {:zones => { :include => {:txt_lines => {}, :zone_artworks => {} } } } )}
	  end    
	end
  
  def attribute_array
    [ :color_id,
      :model_id,
      :price,
      :quantity,
      :size_id,
      :name,
      :commission,
      :model_background_color,
      #Zones
      :zone_type,
      :line_height,
      :line_hreflection,
	    :line_printtype,
	    :line_rotation,
	    :line_vreflection,
	    :line_width,
	    :line_x,
	    :line_y,
      #Txt Lines      
      :align,
      :bold,
      :color_id,
      :color_code,
      :cmyk_color,
      :content,
      :clean_content,
      :font,
      :height,
      :italic,
      :underlined,
      :line_position,
      :ordered_zone_id,
      :size,
      :width,
      :x,
      :y,
      #Artwork
      :uploaded_image_id,
      :image_id, 
      :artwork_vreflection,
      :artwork_hreflection,
      :artwork_rotation,
      :artwork_x,
      :artwork_y,
      :artwork_zoom
    ]
  end
  
end
