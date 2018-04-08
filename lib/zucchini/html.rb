require 'erb'
require 'zucchini/renderer'

module Zucchini
  class HTML < Renderer
    attr :template_file, true
    attr :vars

    def initialize
      super
      @vars = {}
    end

    def type
      return 'text/html; charset=UTF-8'
    end

    def to_s
      return ERB.new(template).result(binding)
    end

    private
    def template
      raise 'テンプレートが未指定です。' unless @template_file
      return File.read(File.join(ROOT_DIR, 'views', @template_file))
    end
  end
end
