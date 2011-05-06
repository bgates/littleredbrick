# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
 Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
Mime::Type.register "application/vnd.oasis.opendocument.spreadsheet", :ods
Mime::Type.register "application/vnd.ms-excel", :xls, [], [:xlt, :xla]
Mime::Type.register "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", :xlsx
Mime::Type.register "application/pdf", :pdf
Mime::Type.register "image/jpg", :jpg
Mime::Type.register "image/png", :png
Mime::Type.register "application/msword", :doc, [], [:dot]

Mime::Type.register "application/vnd.openxmlformats-officedocument.wordprocessingml.document", :docx

Mime::Type.register "application/vnd.ms-powerpoint", :ppt, [], [:pot, :pps, :ppa]
Mime::Type.register "application/vnd.openxmlformats-officedocument.presentationml.presentation", :pptx

