module Data.Package exposing
    ( Package
    , package
    , version
    , name
    )

type alias Name = String

type alias Version = String

type Package = Package Name Version

package : Name -> Version -> Package
package name version =
    Package name version

version : Package -> Version
version (Package _ version) =
    version

name : Package -> Name
name (Package name _) =
    name
