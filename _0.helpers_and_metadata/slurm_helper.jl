using Random
using UUIDs

function generate_unique_name()
    uuid = string(uuid4())
    return "db_$uuid.sqlite"
end
