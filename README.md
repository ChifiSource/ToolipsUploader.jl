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
