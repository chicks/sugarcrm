require 'helper'

class TestJson2Object < Test::Unit::TestCase
  def test_object
    json = {"string" => "value"}.to_json
    obj  = JSON.parse(json).to_obj
    assert_equal("value", obj.string)
  end
  
  def test_nested_object
    json = {"dogs" => {"retriever" => "sparky", "basset" => "jennie", "pinscher" => "carver"}}.to_json
    obj  = JSON.parse(json).to_obj
    assert_equal("sparky", obj.dogs.retriever)
  end
  
  def test_array_of_objects
    json = [{"retriever" => "sparky"}, {"basset" => "jennie"}, {"pinscher" => "carver"}].to_json
    obj  = JSON.parse(json).to_obj
    assert_equal("sparky", obj[0].retriever)
  end
  
  def test_deep_nest_mixed
    json = {"kennels" => [
            {"dallas" => [
             {"name" => "north"},
             {"name"  => "east"},
            ]},
            {"frisco" => [
             {"name" => "south"},
             {"name"  => "west"}
            ],
            "company" => "Doggie Daze"
            }
          ]}.to_json
    obj  = JSON.parse(json).to_obj
    assert_equal("west", obj.kennels[1].frisco[0].name)
  end
  
  def test_deep_nest_hash
    json = {"kennels" => {
            "kennel" => {
            "dallas" => ["north", "south"],
            "frisco" => ["east", "west"]}}
           }.to_json
    obj  = JSON.parse(json).to_obj
    assert_equal("north", obj.kennels.kennel.dallas[0])
  end
end