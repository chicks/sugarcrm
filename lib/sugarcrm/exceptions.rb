module SugarCRM
  class NoActiveSession < RuntimeError; end
  class MultipleSessions < RuntimeError; end
  class InvalidSession < RuntimeError; end
  class RetryLimitExceeded < RuntimeError; end
  class LoginError < RuntimeError; end
  class MissingCredentials < RuntimeError; end
  class ConnectionTimeoutError < RuntimeError; end
  class EmptyResponse < RuntimeError; end
  class UnhandledResponse < RuntimeError; end
  class InvalidSugarCRMUrl < RuntimeError; end
  class InvalidRequest < RuntimeError; end
  class InvalidModule <RuntimeError; end
  class AttributeParsingError < RuntimeError; end
  class RecordNotFound < RuntimeError; end
  class InvalidRecord < RuntimeError; end
  class RecordSaveFailed < RuntimeError; end
  class AssociationFailed < RuntimeError; end
  class UninitializedModule < RuntimeError; end
  class InvalidAttribute < RuntimeError; end
  class InvalidAttributeType < RuntimeError; end
  class InvalidAssociation < RuntimeError; end
end