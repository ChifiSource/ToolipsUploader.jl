module ToolipsUploader
using Toolips
import Toolips: ServerExtension
using ToolipsSession

mutable struct Uploader <: ServerExtension
    type::Symbol
    directory::String
    f::Function
    function Uploader(directory::String = "public/uploads",
        upload_f::Function = uploadsave)
        f(rs::Dict{String, Function}, es::Dict{Symbol, ServerExtension}) = begin
            rs["/uploader/upload"] = none(c::Connection) = begin
                upload_f(directory, getpost(c))
                write!(c, " ")
            end
        end
        new(:routing, directory, f)
    end
end

function fileinput(c::Connection, name::String)
    inp::Component = input(name * "input", type = "file", name = "fname")
    impform = form(name, onaction = "/uploader/upload")
end

function uploadsave(dir::String, s::String)
    println()
    touch("$dir/$name")
    open("$dir/$name", "w") do io
        write(io, body)
    end
end
export Uploader, fileinput
end # module
