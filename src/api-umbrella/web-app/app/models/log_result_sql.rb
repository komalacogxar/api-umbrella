class LogResultSql
  attr_reader :raw_result

  def initialize(search, raw_result)
    @search = search
    @raw_result = raw_result

    if(search.result_processors.present?)
      search.result_processors.each do |processor|
        processor.call(self)
      end
    end
  end

  def total
    raw_result["hits"]["total"]
  end

  def documents
    raw_result["hits"]["hits"]
  end

  def aggregations
    raw_result["aggregations"]
  end

  def column_indexes
    unless @column_indexes
      @column_indexes = {}
      raw_result["columnMetas"].each_with_index do |meta, index|
        @column_indexes[meta["label"].downcase] = index
      end
    end

    @column_indexes
  end

  def hits_over_time
    if(!@hits_over_time && aggregations["hits_over_time"])
      @hits_over_time = {}

      aggregations["hits_over_time"]["buckets"].each do |bucket|
        @hits_over_time[bucket["key"]] = bucket["doc_count"]
      end
    end

    @hits_over_time
  end

  def drilldown
    if(!@drilldown && aggregations["drilldown"])
      @drilldown = []

      aggregations["drilldown"]["buckets"].each do |bucket|
        depth, path = bucket["key"].split("/", 2)
        terminal = !path.end_with?("/")

        depth = depth.to_i
        descendent_depth = depth + 1
        descendent_prefix = File.join(descendent_depth.to_s, path)

        @drilldown << {
          :depth => depth,
          :path => path,
          :terminal => terminal,
          :descendent_prefix => descendent_prefix,
          :hits => bucket["doc_count"],
        }
      end
    end

    @drilldown
  end

  def map_breadcrumbs
    if(!@map_breadcrumbs && @search.region)
      @map_breadcrumbs = []

      case(@search.region)
      when /^([A-Z]{2})$/
        country = Regexp.last_match[1]

        @map_breadcrumbs = [
          { :region => "world", :name => "World" },
          { :name => Country[country].name },
        ]
      when /^(US)-([A-Z]{2})$/
        country = Regexp.last_match[1]
        state = Regexp.last_match[2]

        @map_breadcrumbs = [
          { :region => "world", :name => "World" },
          { :region => country, :name => Country[country].name },
          { :name => Country[country].states[state]["name"] },
        ]
      end
    end

    @map_breadcrumbs
  end

  def cities
    unless @cities
      @cities = {}

      @regions = aggregations["regions"]["buckets"]
      if(@search.query[:aggregations][:regions][:terms][:field] == "request_ip_city")
        @city_names = @regions.map { |bucket| bucket["key"] }
        @cities = {}

        if @city_names.any?
          query = {
            :filter => {
              :and => [],
            },
          }

          query[:filter][:and] << {
            :term => { :country => @search.country },
          }

          if @search.state
            query[:filter][:and] << {
              :term => { :region => @search.state },
            }
          end

          query[:filter][:and] << {
            :terms => { :city => @city_names },
          }

          city_results = @search.client.search({
            :index => "api-umbrella",
            :size => 500,
            :body => query,
          })

          city_results["hits"]["hits"].each do |result|
            @cities[result["_source"]["city"]] = result["_source"]["location"]
          end
        end
      end
    end

    @cities
  end
end