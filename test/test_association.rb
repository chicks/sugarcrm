#TODO: Figure out how to test this.


# That code works, but what didn't work:
# document.tasks.size
# document.associate!(task)
# document.tasks.size
# This seems to be fixed in HEAD in my repo. I haven't pushed the changes to your repo, because I don't really see why commit https://github.com/davidsulc/sugarcrm/commit/228375348c9113324370afa0aca4120eb117d3e1 fixes the issue...
# Also, I fixed this case
# document.tasks.size
# document.associate!(task)
# document.tasks.size # => 1 (correct)
# document.associate!(task)
# document.tasks.size # => 2 (incorrect: should remain 1)
# One thing we should look into is
# document.associate!(task)
# document.tasks.size # => 1
# task.documents.size # => 0 (should be 1)