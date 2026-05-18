# frozen_string_literal: true
require_relative 'helper'

class RDocPluginTest < RDoc::TestCase
  class RDoc::Parser::RdocPluginTestParser < RDoc::Parser
    class << self
      attr_accessor :top_level, :content
    end
    parse_files_matching(/\.rdoc_plugin_test_ext$/)
    def scan
      self.class.top_level = @top_level
      self.class.content = @content
    end
  end

  def setup
    super
    @top_level = @store.add_file 'file.rb'
    @klass = @top_level.add_class RDoc::NormalClass, 'C'
    @module = @top_level.add_module RDoc::NormalModule, 'M'
    @inner_module = @module.add_module RDoc::NormalModule, 'N'
  end

  def construct_comment
    comment = RDoc::Comment.new('comment', @top_level)
    comment.format = 'markdown'
    comment
  end

  def test_additional_parser
    Tempfile.open(['file', '.rdoc_plugin_test_ext']) do |f|
      f.write "This is a\ntest file.\n"
      f.flush
      p f.path
      @rdoc.parse_files([f.path])
    end
    assert_instance_of RDoc::TopLevel, RDoc::Parser::RdocPluginTestParser.top_level
    assert_equal "This is a\ntest file.\n", RDoc::Parser::RdocPluginTestParser.content
  end

  def test_top_level_api_used_in_rbs_does_not_raise_error
    assert_equal 'file.rb', @top_level.relative_name
    assert_instance_of RDoc::NormalClass, @top_level.find_class_or_module('C')
    assert_instance_of RDoc::NormalModule, @top_level.find_class_or_module('M::N')
    assert_instance_of RDoc::NormalModule, @top_level.find_module_named('M::N')
  end

  def test_add_class_module_used_in_rbs_does_not_raise_error
    klass1 = @top_level.add_class(RDoc::NormalClass, 'M::C1', 'SuperClass')
    klass1.add_comment(construct_comment, @top_level)

    klass2 = @top_level.add_class(RDoc::NormalClass, 'M::C2', '::Object')
    klass2.add_comment(construct_comment, klass1)

    mod = @top_level.add_module(RDoc::NormalModule, 'M::M1')
    mod.add_comment(construct_comment, @top_level)
  end

  def test_add_const_used_in_rbs_does_not_raise_error
    const = RDoc::Constant.new('Name', 'Type', construct_comment)
    @module.add_constant(const)
  end

  def test_add_method_used_in_rbs_does_not_raise_error
    method = RDoc::AnyMethod.new(nil, 'method_name')
    method.singleton = true
    method.visibility = :public
    method.call_seq = 'method_name(arg)'
    method.start_collecting_tokens(:ruby)
    method.add_token({ line_no: 1, char_no: 1, kind: :on_comment, text: 'unused_kind' })
    method.add_token({ line_no: 1, char_no: 1, text: 'without_kind' })
    method.line = 1
    method.comment = construct_comment
    @klass.add_method(method)

    # Check if this dummy tokens can be handled without error
    assert_equal 'unused_kindwithout_kind', RDoc::TokenStream.to_html(method.token_stream)

    alias_def = RDoc::Alias.new(nil, 'method_name', 'new_name', nil, singleton: true)
    alias_def.comment = construct_comment
    @klass.add_alias(alias_def)
  end

  def test_add_attribute_used_in_rbs_does_not_raise_error
    attribute = RDoc::Attr.new(nil, 'attr', 'RW', nil, singleton: true)
    attribute.visibility = :public
    attribute.comment = construct_comment
    @klass.add_attribute(attribute)
  end

  def test_add_include_extend_used_in_rbs_does_not_raise_error
    include_decl = RDoc::Include.new('IncludedModule', nil)
    include_decl.comment = construct_comment
    @module.add_include(include_decl)

    extend_decl = RDoc::Extend.new('ExtendedModule', nil)
    extend_decl.comment = construct_comment
    @module.add_extend(extend_decl)
  end
end
