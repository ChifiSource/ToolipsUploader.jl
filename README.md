<div align = "center"><img src = "https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipsuploader.png" href = "https://toolips.app"></img></div>

- [documentation](https://chifidocs.com/Toolips/ToolipsUploader)
- [Toolips](https://github.com/ChifiSource/Toolips.jl)

#### uploader
`ToolipsUploader` demistifies the process of uploading files from the client to the server using a simple `ToolipsSession` extension alongside the `UploadMap`. This is more of an extension to `ToolipsSession` than it is base `Toolips`, and **requires the `Session` extension** to be loaded into your server.
```julia
using Pkg

Pkg.add("ToolipsUploader")

# Latest breaking changes, sometimes broken or version mismatched
Pkg.add("ToolipsUploader", rev = "Unstable")
```
###### explanation
Uploading is handled via three functions bound to the `UploadMap` using `bind`. These are `:init`, `:progress`, and `:complete`.
```julia
upm = ToolipsUploader.UploadMap()
bind(upm, :complete) do cm::ComponentModifier
    open(upl_path, "w") do o::IOStream
        write(o, upl_data)
    end
    @info "wrote file"
    push!(cm.changes, "console.log('file written');")
end
```
This is a minimal example, the following example is a full server and includes all features:
```julia
module ToolipsUploadExample
using Toolips
using Toolips.Components
using ToolipsUploader
using ToolipsSession

main = route("/") do c::Connection
    loader = ToolipsUploader.fileinput("sampy")
    upm = ToolipsUploader.UploadMap()
    upl_path = ""
    upl_data = ""

    # init function
    function upm_init(cm::ComponentModifier, num::Int64, value::AbstractString)
        if ~(isfile(value))
            touch(value)
        end
        upl_path = value
        @info "file upload $value started"
        push!(cm.changes, "console.log('file upload started');")
    end
    # progress function
    function upmprog(cm::ComponentModifier, info::StreamFileInfo)
        upl_data = upl_data * info.data
        push!(cm.changes, "console.log('uploaded $(info.loaded) of $(info.size)');")
    end
    # complete function
    bind(upm, :complete) do cm::ComponentModifier
        open(upl_path, "w") do o::IOStream
            write(o, upl_data)
        end
        @info "wrote file"
        push!(cm.changes, "console.log('file written');")
    end
    # bind to other loader:
    bind(upm_init, upm, :init)
    bind(upm_init, upm, :upmprog)
    new_button = button("trhh", text = "UPLOAD")
    Components.bind(new_button, loader)
    Components.bind(c, loader, upm)
    write!(c, h2(text = "welcome to me uploader"))
    write!(c, loader, new_button)
end

SES = Session()

export SES, main, default_404
end # module

```
