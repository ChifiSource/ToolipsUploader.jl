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
    inp::Component = input(name, type = "file", name = "fname")
    on(c, inp, "change") do cm::ComponentModifier
        push!(cm.changes, """
        let thefile = document.getElementById("$name").files[0];
        let req = new XMLHttpRequest();
        req.open("POST", '/uploader/upload');
        var reader = new FileReader();
        req.send(thefile.name + ':' + reader.readAsBinaryString(thefile););""")
    end
    inp::Component
end

function uploadsave(dir::String, s::String)
    namebody = split(s, ":")
    name = string(namebody[1])
    body = string(namebody[2])
    touch("$dir/$name")
    open("$dir/$name", "w") do io
        write(io, body)
    end
end
export Uploader, fileinput
end # module
