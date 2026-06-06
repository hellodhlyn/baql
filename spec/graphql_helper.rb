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

  def execute_graphql_as_admin(query, **opts)
    execute_graphql(query, **opts, context: { admin: true }.merge(opts[:context] || {}))
  end

  def capture_sql
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if payload[:name] == "SCHEMA"
      next if payload[:sql].match?(/\A(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/)

      queries << payload
    end

    result = yield
    [result, queries]
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  def query_context
    @query_context ||= GraphQL::Query.new(BaqlSchema, "{ __typename }").context
  end
end

RSpec.configure do |config|
  config.include ::GraphQLHelpers, type: :graphql
end
