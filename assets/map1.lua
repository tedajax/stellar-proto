return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "0.13.1",
  orientation = "orthogonal",
  width = 72,
  height = 36,
  tilewidth = 32,
  tileheight = 32,
  nextobjectid = 5,
  properties = {},
  tilesets = {
    {
      name = "Basic",
      firstgid = 1,
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      tileoffset = {
        x = 0,
        y = 0
      },
      properties = {},
      terrains = {},
      tilecount = 1,
      tiles = {
        {
          id = 0,
          image = "tile_orange.png",
          width = 32,
          height = 32
        }
      }
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "Tile Layer 1",
      x = 0,
      y = 0,
      width = 72,
      height = 36,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "base64",
      compression = "zlib",
      data = "eJztl0EOgzAMBOH/n+61BxivjZOiekfKZd2QaIiIex7HcXrgMNfYD2M/jP0w9sPYD2M/jP0w9sPs7C1pTuX5O/rbX5yfOz/qb5VaF51+1Pc51U9mTSWjPKp1YT+M/TCr/ER3lZJRHtW6mHZ+sr3JdD/KXfvET7VPVDLKoxrNqfSgO3mjH1rffuL/PZ0o70TJKI9qNCfjyOeHHU3zk8V+mG8/6tnrGFf7uNsf7X0lld6la10lozyqPUXtj1atrWSUR7UnZPrHVesrGeVRrUqmd1zFW/1kvpcreaOf7H0yicp9O4VqPzKBnf3eP48PbBUByQ=="
    },
    {
      type = "objectgroup",
      name = "Platforms",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          id = 1,
          name = "",
          type = "platform",
          shape = "rectangle",
          x = 1600,
          y = 320,
          width = 128,
          height = 32,
          rotation = 0,
          visible = true,
          properties = {
            ["controller"] = "tween_position",
            ["endpoint_offset_x"] = "0",
            ["endpoint_offset_y"] = "672",
            ["tween_dest"] = "1",
            ["tween_duration"] = "10",
            ["tween_function"] = "sin_wave",
            ["tween_start"] = "0"
          }
        }
      }
    }
  }
}
