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
            rs["/uploader/upload"] = c::Connection -> upload_f(directory,
                                                    getpost(c)); write!(c, " ")
        end
        new(:routing, directory, f)
    end
end

function fileinput(name::String)
    inp::Component = input(name, type = "file")
    on(c, inp, "change") do cm::ComponentModifier
        push!(cm.changes, """
        let photo = document.getElementById("$name").files[0];
        let fname = document.getElementById("$name").name;
        let req = new XMLHttpRequest();
        req.open("POST", '/uploader/upload');
        req.send(fname + ':' + photo);""")
    end
    inp::Component
end

function uploadsave(dir::String, s::String)
    namebody = split(s, ":")
    name = string(namebody[1])
    body = string(namebody[2])
    touch("$dir/$name")
    open("$dir/$name") do io
        write(io, body)
    end
end

end # module
