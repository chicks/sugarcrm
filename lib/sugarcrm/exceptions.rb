module SugarCRM
  class SugarCRMError < RuntimeError; end
  class NoActiveSession < SugarCRMError; end
  class MultipleSessions < SugarCRMError; end
  class LoginError < SugarCRMError; end
  class MissingCredentials < SugarCRMError; end
  class ConnectionError < SugarCRMError; end
  class ConnectionTimeoutError < SugarCRMError; end
  class EmptyResponse < SugarCRMError; end
  class UnhandledResponse < SugarCRMError; end
  class InvalidSugarCRMUrl < SugarCRMError; end
  class InvalidRequest < SugarCRMError; end
  class InvalidModule <SugarCRMError; end
  class AttributeParsingError < SugarCRMError; end
  class RecordNotFound < SugarCRMError; end
  class InvalidRecord < SugarCRMError; end
  class RecordSaveFailed < SugarCRMError; end
  class AssociationFailed < SugarCRMError; end
  class UninitializedModule < SugarCRMError; end
  class InvalidAttribute < SugarCRMError; end
  class InvalidAttributeType < SugarCRMError; end
  class InvalidAssociation < SugarCRMError; end
end