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
            rs["/uploader/upload"] = upload_f
        end
        new(:routing, directory, f)
    end
end

function fileinput(c::Connection)
    inp::Component = input(name * "input", type = "file", name = "fname")
    inpform::Component = form(name, onaction = "/uploader/upload", )
    push!(inpform, inp)
    inpform
end

function uploadsave(c::Connection)
    try
        c[:Logger].log("incoming uploader")
        x = getpost(c)
        c[:Logger.log("hello!")]
    catch
        c[:Logger].log("failed to get post")
    end
end
export Uploader, fileinput
end # module
