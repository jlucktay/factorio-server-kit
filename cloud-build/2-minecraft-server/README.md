# Minecraft server VM image

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

## Bring in previous save ("world")

> ### Use Existing World
>
> You can use existing worlds on your server that you've created or downloaded online.
>
> You cannot use the following types of worlds on your server:
>
> - Worlds purchased from the Minecraft Marketplace.
> - Worlds using Experimental Gameplay features.
>
> #### Import World
>
> You can use an existing world for the server by placing the world save folder in the server directory's worlds folder.
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
