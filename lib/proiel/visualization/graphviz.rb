module PROIEL
  module Visualization
    module Graphviz
      DEFAULT_GRAPHVIZ_BINARY = 'dot'.freeze
      DEFAULT_TEMPLATES = %i(classic linearized packed modern)
      SUPPORTED_OUTPUT_FORMATS = %i(png svg)

      class GraphvizError < Exception
      end

      def self.generate_to_file(template, graph, output_format, output_filename, options = {})
        raise ArgumentError, 'string expected' unless output_filename.is_a?(String)

        result = PROIEL::Visualization::Graphviz.generate(template, graph, output_format, options)

        File.open(output_filename, 'w') do |f|
          f.write(result)
        end
      end

      def self.generate(template, graph, output_format, options = {})
        raise ArgumentError, 'string or symbol expected' unless template.is_a?(String) or template.is_a?(Symbol)

        dot_code = generate_dot(template, graph, options)

        if output_format.to_sym == :dot
          dot_code
        else
          generate_image(dot_code, output_format, options)
        end
      end

      def self.template_filename(template)
        raise ArgumentError, 'string or symbol expected' unless template.is_a?(String) or template.is_a?(Symbol)
        raise ArgumentError, 'invalid template' unless DEFAULT_TEMPLATES.include?(template.to_sym)

        File.join(File.dirname(__FILE__), 'graphviz', "#{template}.dot.erb")
      end

      def self.generate_image(dot_code, output_format, options = {})
        raise ArgumentError, 'string expected' unless dot_code.is_a?(String)
        raise ArgumentError, 'string or symbol expected' unless output_format.is_a?(String) or output_format.is_a?(Symbol)
        raise ArgumentError, 'invalid output format' unless SUPPORTED_OUTPUT_FORMATS.include?(output_format.to_sym)

        graphviz_binary = options[:graphviz_binary] || DEFAULT_GRAPHVIZ_BINARY

        result, errors = nil, nil

        Open3.popen3("dot -T#{output_format}") do |dot, img, err|
          dot.write dot_code
          dot.close

          result, errors = img.read, err.read
        end

        raise GraphvizError, "graphviz exited with errors: #{errors}" unless errors.nil? or errors == ''

        result
      end

      def self.generate_dot(template, graph, options)
        raise ArgumentError, 'invalid direction' unless options[:direction].nil? or %(TD LR).include?(options[:direction])

        filename = template_filename(template)

        content = File.read(filename)

        template = ERB.new(content, nil, '-')
        template.filename = filename

        TemplateContext.new(graph, options[:direction] || 'TD').generate(template)
      end

      class TemplateContext
        def initialize(graph, direction)
          @graph = graph
          @direction = direction
        end

        def generate(template)
          template.result(binding)
        end

        protected

        # Creates a node with an identifier and a label.
        def node(identifier, label = '', options = {})
          attrs = join_attributes(options.merge(label: label))

          "#{identifier} [#{attrs}];"
        end

        # Creates an edge with a label from one identifier to another identifier.
        def edge(identifier1, identifier2, label = '', options = {})
          attrs = join_attributes(options.merge(label: label))

          "#{identifier1} -> #{identifier2} [#{attrs}];"
        end

        def join_attributes(attrs)
          attrs.map { |a, v| %|#{a}="#{v.to_s.gsub('"', '\\"')}"| }.join(',')
        end
      end
    end
  end
end
