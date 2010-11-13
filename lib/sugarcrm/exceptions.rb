module SugarCRM
  class LoginError < RuntimeError
  end

  class EmptyResponse < RuntimeError
  end

  class UnhandledResponse < RuntimeError
  end

  class InvalidSugarCRMUrl < RuntimeError
  end
  
  class InvalidRequest < RuntimeError
  end
  
  class InvalidModule <RuntimeError
  end
  
  class AttributeParsingError < RuntimeError
  end
end