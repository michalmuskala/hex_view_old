@moduledoc """
A schema is a keyword list which represents how to map, transform, and validate
configuration values parsed from the .conf file. The following is an explanation of
each key in the schema definition in order of appearance, and how to use them.

## Import

A list of application names (as atoms), which represent apps to load modules from
which you can then reference in your schema definition. This is how you import your
own custom Validator/Transform modules, or general utility modules for use in
validator/transform functions in the schema. For example, if you have an application
`:foo` which contains a custom Transform module, you would add it to your schema like so:

`[ import: [:foo], ..., transforms: ["myapp.some.setting": MyApp.SomeTransform]]`

## Extends

A list of application names (as atoms), which contain schemas that you want to extend
with this schema. By extending a schema, you effectively re-use definitions in the
extended schema. You may also override definitions from the extended schema by redefining them
in the extending schema. You use `:extends` like so:

`[ extends: [:foo], ... ]`

## Mappings

Mappings define how to interpret settings in the .conf when they are translated to
runtime configuration. They also define how the .conf will be generated, things like
documention, @see references, example values, etc.

See the moduledoc for `Conform.Schema.Mapping` for more details.

## Transforms

Transforms are custom functions which are executed to build the value which will be
stored at the path defined by the key. Transforms have access to the current config
state via the `Conform.Conf` module, and can use that to build complex configuration
from a combination of other config values.

See the moduledoc for `Conform.Schema.Transform` for more details and examples.

## Validators

Validators are simple functions which take two arguments, the value to be validated,
and arguments provided to the validator (used only by custom validators). A validator
checks the value, and returns `:ok` if it is valid, `{:warn, message}` if it is valid,
but should be brought to the users attention, or `{:error, message}` if it is invalid.

See the moduledoc for `Conform.Schema.Validator` for more details and examples.
"""
[
  extends: [],
  import: [],
  mappings: [
    "logger.console.format": [
      commented: false,
      datatype: :binary,
      default: """
      $time $metadata[$level] $message
      """,
      doc: "Logger format.",
      hidden: false,
      to: "logger.console.format"
    ],
    "logger.console.metadata": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :request_id
      ],
      doc: "Logger metadata.",
      hidden: false,
      to: "logger.console.metadata"
    ],
    "logger.level": [
      commented: false,
      datatype: [enum: [:info, :warn, :error]],
      default: :info,
      doc: "Logger level.",
      hidden: false,
      to: "logger.level"
    ],
    "hex_view.base_url": [
      commented: false,
      datatype: :binary,
      default: "https://repo.hex.pm",
      doc: "Hex repo endpoint.",
      hidden: false,
      to: "hex_view.Elixir.HexView.Registry.base_url"
    ],
    "hex_view.storage": [
      commented: false,
      datatype: :binary,
      default: "/var/hex_view",
      doc: "Data storage path.",
      hidden: false,
      to: "hex_view.Elixir.HexView.Registry.storage"
    ],
    "hex_view.refresh": [
      commented: false,
      datatype: :integer,
      default: 3600000,
      doc: "Registry refresh rate.",
      hidden: false,
      to: "hex_view.Elixir.HexView.Registry.refresh"
    ],
    "hex_view.download_limit": [
      commented: false,
      datatype: :integer,
      default: 10,
      doc: "Download limit during one refresh.",
      hidden: false,
      to: "hex_view.Elixir.HexView.Registry.download_limit"
    ],
    "hex_view.small_package_limit": [
      commented: false,
      datatype: :integer,
      default: 1048576,
      doc: "Maximum package size to download.",
      hidden: false,
      to: "hex_view.Elixir.HexView.Registry.small_package_limit"
    ],
    "hex_view.http.port": [
      commented: false,
      datatype: :integer,
      default: 4000,
      doc: "Port to run the endpoint on.",
      hidden: false,
      to: "hex_view.Elixir.HexView.Endpoint.http.port"
    ],
    "hex_view.url.host": [
      commented: false,
      datatype: :binary,
      default: "hexview.pm",
      doc: "URL host for path generation.",
      hidden: false,
      to: "hex_view.Elixir.HexView.Endpoint.url.host"
    ],
    "hex_view.url.port": [
      commented: false,
      datatype: :integer,
      default: 80,
      doc: "URL port for path generation.",
      hidden: false,
      to: "hex_view.Elixir.HexView.Endpoint.url.port"
    ],
    "hex_view.secret_key_base": [
      commented: false,
      datatype: :binary,
      doc: "Base for generating various secret keys",
      hidden: false,
      to: "hex_view.Elixir.HexView.Endpoint.secret_key_base"
    ]
  ],
  transforms: [],
  validators: []
]
