module TrToolkit
  
  
  def self.recursive_symbolize_keys(obj)
    case obj
    when Array
      obj.inject([]){|res, val|
        res << case val
        when Hash, Array
          self.recursive_symbolize_keys(val)
        else
          val
        end
        res
      }
    when Hash
      obj.inject({}){|res, (key, val)|
        nkey = case key
        when String
          key.to_sym
        else
          key
        end
        nval = case val
        when Hash, Array
          self.recursive_symbolize_keys(val)
        else
          val
        end
        res[nkey] = nval
        res
      }
    else
      obj
    end
  end
  
  
  def self.csv_to_array(csv)
    #array = []
    #lines = csv.lines.to_a
    #header = lines.shift.strip
    #keys = header.split(',')
    #lines.each do |line|
    #  params = {}
    #  values = line.strip.split(',')
    #  keys.each_with_index do |key,i|
    #    params[key] = values[i]
    #  end
    #  array.push(params)
    #end
    #return array
    temporary_csv_file = Tempfile.new("tempcsvfile")
    temporary_csv_file.write(csv.force_encoding("UTF-8"))
    temporary_csv_file.rewind
    content = []
    lines = []
    i = 0
    j = 0
    lines_count_float = temporary_csv_file.readlines.size.to_f
    IO.foreach(temporary_csv_file) do |line|
      lines << line unless line.chomp.empty?
      if j%1000 == 0
        lines_count = lines.size
        content.push(*(CSV.parse(lines.join))) rescue next
        lines = []
        print "\r"+((j/lines_count_float)*100).round(1).to_s+"% " if i%5 == 0
        i += 1
      end
      j += 1
    end
    content.push(*(CSV.parse(lines.join)))
    temporary_csv_file.close
    temporary_csv_file.unlink
    puts "\n"
    return content
  end
  
  def self.csv_to_array_of_hashes(csv)
    array = []
    lines = csv.lines.to_a
    header = lines.shift.strip
    keys = header.split(',')
    lines.each do |line|
      params = {}
      values = line.strip.split(',')
      keys.each_with_index do |key,i|
        params[key.to_sym] = values[i]
      end
      array.push(params)
    end
    return array
  end
  
  
  def self.csv_from_objects(od_objects, replacements = {})
    csv_string = CSV.generate({:force_quotes => true}) do |csv|
      keys = od_objects.first.attributes.keys
      csv << keys
      od_objects.each do |od_object|
        actual_values = od_object.attributes.values_at(*keys)
        #puts actual_values.to_s
        if replacements.any?
          replacements.each do |value, replacement|
            actual_values.collect! { |actual_value| actual_value = (actual_value == value) ? replacement : actual_value }
            #puts actual_values.to_s
          end
        end
        #puts actual_values.to_s
        csv << actual_values
      end
    end
    return csv_string
  end
  
  
  
  def self.csv_from_array_of_hashes(array_of_hashes, replacements = {}, prefix = nil, headers = true, force_quote = true)
    return "" unless array_of_hashes.size > 0
    csv_string = CSV.generate({:force_quotes => force_quote}) do |csv|
      csv << (prefix ? (array_of_hashes.first.keys.collect { |key| prefix.to_s+key.to_s }) : array_of_hashes.first.keys) if headers
      array_of_hashes.each do |hash|
        actual_values = hash.values_at(*array_of_hashes.first.keys)
        if replacements.any?
          replacements.each do |value, replacement|
            actual_values.collect! { |actual_value| actual_value = (actual_value == value) ? replacement : actual_value }
          end
        end
        csv << actual_values
      end
    end
    return csv_string
  end
  
  # Create an auto nested hash:
  # Example: hash[:a][:b] = 3 will work even if hash[:a] doesn't exist yet.
  # Caution: YOU MUST USE has_key? method to check for key and not just check the hash directly since it will always return {} instead of nil.
  def self.auto_hash
    Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
  end
  
  # Create hash with array as default value:
  # Example: hash[:a].push "test" will work even if hash[:a] doesn't exist yet.
  def self.auto_hash_array
    Hash.new { |h, k| h[k] = [] }
  end
  

  def self.dist2sec(distance, speed = Rails.application.config.default_walking_speed)
    (distance.to_f / speed.to_f).ceil
  end
  def self.dist2min(distance, speed = Rails.application.config.default_walking_speed)
    (distance / speed.to_f / 60).ceil
  end
  def self.sec2dist(seconds, speed = Rails.application.config.default_walking_speed)
    (seconds * speed).floor
  end
  def self.min2dist(minutes, speed = Rails.application.config.default_walking_speed)
    (minutes * 60 * speed).floor
  end
  def self.sec2min(seconds)
    (seconds / 60.0).ceil
  end
  def self.min2sec(minutes)
    (minutes * 60).ceil
  end
  def self.sec2time(seconds_since_midnight)
    hour = seconds_since_midnight / 3600
    minutes = (seconds_since_midnight - hour*3600) / 60
    seconds = (seconds_since_midnight - hour*3600) % 60
    "#{hour.to_s.rjust(2,"0")}:#{minutes.to_s.rjust(2,"0")}:#{seconds.to_s.rjust(2,"0")}"
  end
  def self.sec2time_no_sec(seconds_since_midnight)
    hour = seconds_since_midnight / 3600
    minutes = ((seconds_since_midnight - hour*3600).to_f / 60).ceil
    "#{hour.to_s.rjust(2,"0")}:#{minutes.to_s.rjust(2,"0")}"
  end
  
  def self.weekdays_start_at_sunday
    ["sunday","monday","tuesday","wednesday","thursday", "friday", "saturday"]
  end
  
  def self.weekdays_start_at_monday
    ["monday","tuesday","wednesday","thursday", "friday", "saturday","sunday"]
  end
  
  def self.collection_to_hash_with_attribute(collection, attribute)
    Hash[collection.map{|o|[o.send(attribute),o]}]
  end
  
  def self.collection_to_hash_with_ids(collection)
    Hash[collection.map{|o|[o.id,o]}]
  end

  def self.collection_to_hash_with_ids_as_attribute(collection)
    Hash[collection.map{|o|[o["id"],o]}]
  end
  
  def self.collection_to_hash_with_ids_as_symbol(collection)
    Hash[collection.map{|o|[o[:id],o]}]
  end
  
end
