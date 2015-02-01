module UploadsHelper
  def generate_link_with_thumbnail(upload)
    # Using the same check that we use in the model to see if we need to post process
    # We see if this is an image and needs a thumbnail
    if upload.image?
      link_to '<img src="'.html_safe + home_url + upload.upload.url(:preview) + '>"'.html_safe, home_url + upload.upload.url
    else
      link_to image_tag("blank_preview.png"), home_url + upload.upload.url
    end
  end
end
