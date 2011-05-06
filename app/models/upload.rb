require 'active_model'
class Upload
  include ActiveModel::Validations
  include ActiveModel::Conversion

  validate :check_existence_and_filetype
 
  attr_reader :file, :name, :data, :grades, :filedata
  UPLOAD_PATH = "#{Rails.root}/tmp/uploads" unless defined?(UPLOAD_PATH)
  FileUtils.mkdir_p UPLOAD_PATH

  def initialize(file = nil)
    return if file.blank? 
    @file = file
    @name = set_name
    @data = []
    populate_data
  end

  def self.create(params) 
    return new unless params[:filedata].present?
    filename = "#{params[:user]}_#{params[:type]}#{File.extname(params[:filedata].original_filename)}"
    File.open("#{UPLOAD_PATH}/#{filename}", "wb") do |f|
      f.write(params[:filedata].read)
    end
    upload = open(filename)
    upload.valid?
    upload
  end

  def self.open(filename)
    path = File.join "#{UPLOAD_PATH}", filename
    File.open(path, "r") do |f|
      @file = new(f)
    end
    @file
  end

  def self.save(filename, data)
    path = File.join "#{UPLOAD_PATH}", filename
    File.open(path, "wb") do |f|
      @file = f.puts(data.read)
    end
    @file
  end

  def cleanup(filename)
    File.delete("#{UPLOAD_PATH}/#{filename}") if File.exist?("#{UPLOAD_PATH}/#{filename}")
  end

  def clean_up_data
    return if @data.empty? || @data.all?{|row|row.empty?}
    highest_row_index = @data.map{|row|row.length}.max - 1
    highest_row_index.downto(0) do |n|
      flag = false
      @data.each do |row|
        flag = true if !row[n].blank?
      end
      @data.each{|row| row.delete_at(n)} unless flag
    end
    integerize_data
  end

  def empty?
    @data.flatten.compact == []
  end

  def extension
    File.extname(name)
  end

  def integerize_data
    @data.transpose.each_with_index do |col, j|
      if col.all?{|cell| cell.to_i == cell || cell.class != Float}
        @data.each{|row| row[j] = row[j].to_i if row[j].class == Float}
      end
    end
  end

  def is_a?(type)
    return false unless name
    case type
    when 'spreadsheet'
      %w(.xls .xlsx .ods).include?(extension)
    else
      type == extension
    end
  end

  def persisted?
    false
  end

  def populate_data
    if self.is_a?('spreadsheet')
      sheet = spreadsheetify
      sheet.default_sheet ||= sheet.sheets.first
      return unless sheet.first_row
      sheet.first_row.upto(sheet.last_row) do |row_number|
        @data << sheet.row(row_number) unless sheet.row(row_number).nil?
      end
      #@data = sheet.rows.compact
      clean_up_data
    end
  end

  def save(filename)
    FileUtils.mkdir_p UPLOAD_PATH
    File.open("#{UPLOAD_PATH}/#{filename}", "wb") do |f|
      f.write(file.read)
    end
  end

  def set_name
    name = file.respond_to?(:original_filename) ? file.original_filename : file.path
    #strip path from bad ie
    name.gsub!(/^.*(\\|\/)/, '')
    # remove invalid characters
    name.gsub(/[^\w\.\-]/, '_')
  end

  def spreadsheetify
    case extension
    when '.xls'
      Excel.new(file.path)
    when '.xlsx'
      Excelx.new(file.path)
    when '.ods'
      Openoffice.new(file.path)
    end
  end

  protected
  def check_existence_and_filetype
    errors.add(:filedata, '^No file given. Please select a file to upload.') and return false unless @file
    validate_spreadsheet
    validate_non_emptiness
  end

  def validate_spreadsheet
    errors.add(:filedata, '^LittleRedBrick can upload spreadsheet data only from Excel files or OpenOffice. Could you please choose a file whose name ends in .xls, .xlsx, or .ods?') unless is_a?('spreadsheet')
  end

  def validate_non_emptiness
    errors.add(:filedata, '^That file looks empty. Could you please pick a different one?') if is_a?('spreadsheet') && empty?
  end

end

