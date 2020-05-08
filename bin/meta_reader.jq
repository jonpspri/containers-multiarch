.[]
# Filter by package name...
| select(.source_package | test($package_filter) )
# Ensure architectures is an array and save for deeper processing...
| ([.architectures]|flatten) as $architectures
# Reformat releases into a string ...
| .releases |= (
  #  Normalize string-format releases into objects...
  [.]|flatten | map( ( .|strings | { release: . } ), ( .|objects ) )
  | [
    .[] | select( .release | test($release_filter) )
    #  Releases can be specified either as strings or as objects of the form
    #  { "release": "foo", "exclude_architectures": ["bar"] }.  The array form
    #  of "exclude_architectures" is optional if it is a single architecture.
    | ([ .release, (
        #  Filter excluded architectures from the overall architecture list...
        ( $architectures - ([ .exclude_architectures? ] | flatten))
          #  Reformat and join into a comma-separated clob.
          | map(.|"linux/\(.)") | join(",")
        )
      ]) as $release_string_array
    #  Add a "release_string" for display to the record -- I suppose this
    #  could be unnecessary with some even-more-unreadable jq magic.
    | . += { release_string: $release_string_array | flatten | join(":") }
  ]
)
#  Concatenate the releases strings into a single string to display...
| (.releases | map(.release_string) | join(" ")) as $releases_string
#  Apply shell escaping for variable definitions...
| [ @sh "releases=\($releases_string)",
    @sh "source_package=\(.source_package)",
    @sh "git_repository=\(.git_repository)",
    @sh "git_ref=\(.git_ref)",
    @sh "original_tarball_url=\(.original_tarball_url)"]
#  Join into lines so the shell read/eval loop is easy to execute...
| join(" ")
