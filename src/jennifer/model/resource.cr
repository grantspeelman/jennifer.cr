require "./scoping"
require "./translation"
require "./relation_definition"
require "../macros"

module Jennifer
  module Model
    abstract class Resource
      module AbstractClassMethods
        abstract def table_name
        abstract def build(values, new_record : Bool)
        abstract def relation(name)

        abstract def actual_table_field_count
        abstract def primary_field_name
        abstract def build
        abstract def all
        abstract def superclass
        abstract def primary

        # Returns field count
        abstract def field_count

        # Returns array of field names
        abstract def field_names

        # Returns named tuple of column metadata
        abstract def columns_tuple
      end

      extend AbstractClassMethods
      include Translation
      include Scoping
      include RelationDefinition
      include Macros

      # :nodoc:
      def self.superclass; end

      alias Supportable = DBAny | self

      @@expression_builder : QueryBuilder::ExpressionBuilder?

      def inspect(io) : Nil
        io << "#<" << {{@type.name.id.stringify}} << ":0x"
        object_id.to_s(16, io)
        inspect_attributes(io)
        io << '>'
        nil
      end

      private def inspect_attributes(io) : Nil
        nil
      end

      def self.build(values : Hash(Symbol, ::Jennifer::DBAny) | NamedTuple)
        o = new(values)
        o.__after_initialize_callback
        o
      end

      def self.build(values : Hash(String, ::Jennifer::DBAny))
        o = new(values)
        o.__after_initialize_callback
        o
      end

      def self.build(**values)
        o = new(values)
        o.__after_initialize_callback
        o
      end

      # Returns adapter instance.
      def self.adapter
        Adapter.adapter
      end

      def self.context
        @@expression_builder ||= QueryBuilder::ExpressionBuilder.new(table_name)
      end

      def self.all
        {% begin %}
          QueryBuilder::ModelQuery({{@type}}).build(table_name)
        {% end %}
      end

      def self.where(&block)
        ac = all
        tree = with ac.expression_builder yield
        ac.set_tree(tree)
        ac
      end

      # Starts transaction.
      def self.transaction
        adapter.transaction do |t|
          yield(t)
        end
      end

      def self.search_by_sql(query : String, args = [] of Supportable)
        result = [] of self
        adapter.query(query, args) do |rs|
          rs.each do
            result << build(rs)
          end
        end
        result
      end

      def self.c(name : String | Symbol)
        context.c(name.to_s)
      end

      def self.c(name : String | Symbol, relation)
        ::Jennifer::QueryBuilder::Criteria.new(name.to_s, table_name, relation)
      end

      def self.star
        context.star
      end

      def self.relation(name)
        raise Jennifer::UnknownRelation.new(self, name)
      end

      def append_relation(name : String, hash)
        raise Jennifer::UnknownRelation.new(self.class, name)
      end

      def set_inverse_of(name : String, object)
        raise Jennifer::UnknownRelation.new(self.class, name)
      end

      def get_relation(name : String)
        raise Jennifer::UnknownRelation.new(self.class, name)
      end

      # Returns value of attribute *name*
      abstract def attribute(name)

      # Returns value of primary field
      abstract def primary

      # Returns hash with model attributes; keys are symbols
      abstract def to_h

      # Returns hash with model attributes; keys are strings
      abstract def to_str_h
    end
  end
end