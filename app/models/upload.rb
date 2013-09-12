class Upload < ActiveRecord::Base
  has_attached_file :upload, :url => ":class/:id/:style/:filename", :path => ':rails_root/assets/:class/:id_partition/:style_:filename', :styles => { :thumb => "75x75>" }
  
  validates_attachment_presence :upload
  validates_attachment_size :upload, :less_than => 10.megabytes
  
  before_post_process :image?
  
  
  def downloadable?(user)
    user != :guest
  end
  
  belongs_to :test_case
  belongs_to :result
  
  def image?
    supported_image_formats = ["image/jpeg", "image/png", "image/gif", "image/bmp"]
    supported_images_regex = Regexp.new('\A(' + supported_image_formats.join('|') + ')\Z')
    
    (upload_content_type =~ supported_images_regex).present?
    # ! %w(image/jpeg, image/png, image/gif, image/bmp).include?(upload_content_type)
  end
end
