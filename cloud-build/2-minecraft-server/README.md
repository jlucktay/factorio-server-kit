# Minecraft server VM image

## Remaining high-level TODO(s)

- auto-shutdown with `goppuku`

## Whitelist

Example whitelist.json file:

```json
[
    {
        "ignoresPlayerLimit": false,
        "name": "MyPlayer"
    },
    {
        "ignoresPlayerLimit": false,
        "name": "AnotherPlayer",
        "xuid": "274817248"
    }
]
```

## Notes

Below notes adapted from
[here](https://old.reddit.com/user/ProfessorValko/comments/9f438p/bedrock_dedicated_server_tutorial/).

### Bring in previous save ("world")

#### Load own world

In `/opt/minecraft/server.properties` set `level-name=oneblock` where `oneblock` is the directory name under
`/opt/minecraft/worlds/`.

> #### Use Existing World
>
> You can use existing worlds on your server that you've created or downloaded online.
>
> You cannot use the following types of worlds on your server:
>
> - Worlds purchased from the Minecraft Marketplace.
> - Worlds using Experimental Gameplay features.
>
> ##### Import World
>
> You can use an existing world for the server by placing the world save folder in the server directory's `worlds`
> folder.
> You should ensure your world is compatible with the current version of the server software.
>
> 1. Stop the server, if necessary.
> 2. Export, copy, or obtain the preferred world save folder.
> 3. Place the world save folder in the `worlds` folder located in the server directory.
> 4. Set the value of `level-name` in `server.properties` equal to the world's name.
>    - Note: The values of the world name (defined in `levelname.txt` of the world save folder), the world save folder,
>      and `level-name` in `server.properties` must all be equal.
>    - Note: The "Visible to LAN Players" toggle must have previously been enabled. You can toggle this setting in-game
>      before copying or exporting the world. Alternatively, you can set the value of `LANBroadcast` to `1` in
>      `level.dat` using an NBT editor.
> Start the server.
>
> #### Update Server
>
> Bedrock Dedicated Server (Alpha) is updated alongside the _Minecraft_ (Bedrock) client.
> You will need to manually download the updated software, and merge and/or replace files as necessary.
>
> ##### Backup current server
>
> 1. Start the server.
> 2. Use the `save hold`, `save query`, and `save resume` commands in the server console.
>     - Note: Refer to the included `bedrock_server_how_to.html` documentation for syntax and additional information.
> 3. Stop the server.
>
> ##### Download server software
>
> 1. Download the latest version of Bedrock Dedicated Server (Alpha) from
>    <https://minecraft.net/en-us/download/server/bedrock/>.
> 2. Extract (unzip) the downloaded `.zip` file.
>     - Note: You may move the extracted folder to your preferred location.
> 3. Review the included `release-notes.txt` and `bedrock_server_how_to.html` files.
>
> ##### Generate and merge files
>
> 1. Start the server to generate default and new files and directories.
> 2. Stop the server.
> 3. Copy the following server configuration files and folders from the previous server's directory, and paste them into
>    the appropriate locations in the new server's directory:
>     - `server.properties`
>     - `whitelist.json`
>     - `permissions.json`
>     - `worlds` folder
>
> ##### Restart server
>
> 1. Start the server.
>     - Note: Ensure you are using the server executable located in the new server directory.
>       Refer to the "Start Server" section of this tutorial.
