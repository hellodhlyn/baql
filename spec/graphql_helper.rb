module GraphQLHelpers
  def controller
    @controller ||= GraphqlController.new.tap do |ctrl|
      ctrl.set_request!(ActionDispatch::Request.new({}))
    end
  end

  def execute_graphql(query, **opts)
    BaqlSchema.execute(
      query,
      variables: opts[:variables],
      context: { controller: controller }.merge(opts[:context] || {}),
    )
  end

  def query_context
    @query_context ||= GraphQL::Query.new(BaqlSchema, "{ __typename }").context
  end
end

RSpec.configure do |config|
  config.include ::GraphQLHelpers, type: :graphql
end
