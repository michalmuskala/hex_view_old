exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/app.js",

      // To use a separate vendor.js bundle, specify two files path
      // https://github.com/brunch/brunch/blob/master/docs/config.md#files
      // joinTo: {
      //  "js/app.js": /^(js)/,
      //  "js/vendor.js": /^(vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      order: {
        before: [
          "vendor/elm.js"
        ]
      }
    },
    stylesheets: {
      joinTo: "css/app.css",
      order: {
        after: ["css/app.scss"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/,
    vendor: /(^bower_components|node_modules|vendor\/js)\//
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "elm", "css", "js", "vendor"],
    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    },
    copycat: {
      "fonts": []
    },
    sass: {
      options: {
        includePaths: ["./node_modules/"],
        precision: 8
      }
    },
    elmBrunch: {
      executablePath: './node_modules/.bin',
      mainModules: ["elm/Pages/PackageView/Main.elm"],
      outputFile: "elm.js"
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["app"]
    }
  },

  npm: {
    enabled: true,
    globals: {
    }
  }
};
