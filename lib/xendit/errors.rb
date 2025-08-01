module Xendit
  module Errors
    class XenditError < StandardError; end

    class ConfigurationError < XenditError; end
    class APIError < XenditError; end
    class AuthenticationError < XenditError; end
    class ForbiddenError < XenditError; end
    class NotFoundError < XenditError; end
    class BadRequestError < XenditError; end
    class ValidationError < BadRequestError; end
    class DuplicateError < BadRequestError; end
    class ConflictError < XenditError; end
    class InsufficientBalanceError < XenditError; end
    class RateLimitError < XenditError; end
    class ServerError < XenditError; end
    class TimeoutError < XenditError; end
    class ConnectionError < XenditError; end
  end
end
