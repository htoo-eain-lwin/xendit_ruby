module Xendit
  module Errors
    class XenditError < StandardError; end

    # Configuration errors
    class ConfigurationError < XenditError; end

    # HTTP-based errors
    class APIError < XenditError; end
    class AuthenticationError < XenditError; end
    class ForbiddenError < XenditError; end
    class NotFoundError < XenditError; end
    class ConflictError < XenditError; end
    class RateLimitError < XenditError; end
    class ServerError < XenditError; end
    class TimeoutError < XenditError; end
    class ConnectionError < XenditError; end

    # 400-level errors
    class BadRequestError < XenditError; end
    class ValidationError < BadRequestError; end
    class DuplicateError < BadRequestError; end
    class InsufficientBalanceError < BadRequestError; end
    class IdempotencyError < BadRequestError; end

    # Xendit-specific business logic errors
    class ChannelNotActivatedError < ForbiddenError; end
    class FeatureNotActivatedError < ForbiddenError; end
    class InvalidPaymentMethodError < BadRequestError; end
    class CustomerNotFoundError < BadRequestError; end
    class MaxAmountLimitError < BadRequestError; end
    class AccountAccessBlockedError < BadRequestError; end
    class PaymentMethodAlreadyExistsError < ConflictError; end
    class MaxAccountLinkingError < BadRequestError; end
    class InvalidAccountDetailsError < BadRequestError; end
    class CustomerPaymentMethodMismatchedError < BadRequestError; end
    class PartnerChannelError < BadRequestError; end
    class PaymentExpiredError < BadRequestError; end
    class InvalidMerchantCredentialsError < AuthenticationError; end
    class ChannelUnavailableError < XenditError; end
    class OTPDeliveryError < XenditError; end
    class ExpiredOTPError < BadRequestError; end
    class InvalidOTPError < BadRequestError; end
    class MaxOTPAttemptsError < BadRequestError; end
    class PaymentRequestAlreadyFailedError < ConflictError; end
    class PaymentRequestAlreadyPendingError < ConflictError; end
    class PaymentRequestAlreadySucceededError < ConflictError; end
    class PaymentMethodAlreadyActiveError < ConflictError; end
    class PaymentMethodAlreadyFailedError < ConflictError; end
    class ProcessorConfigurationError < ServerError; end
    class ProcessorError < XenditError; end
    class ProcessorTemporarilyUnavailableError < XenditError; end
    class ProcessorTimeoutError < XenditError; end
    class AccountNotActivatedError < BadRequestError; end
    class CustomerUnreachableError < BadRequestError; end
    class IneligibleTransactionError < BadRequestError; end
    class MaximumRefundAmountReachedError < BadRequestError; end
    class PartialRefundNotSupportedError < BadRequestError; end
    class RefundNotSupportedError < BadRequestError; end
    class RefundInProgressError < BadRequestError; end
  end
end
