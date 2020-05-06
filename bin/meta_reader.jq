.[]
# Filter by package name
| select(.source_package | test($package_filter) )
# Store the package information
| (.|del(.releases)) as $package
# For each release that matches the filter ...
| [.releases] | flatten | .[] | select( . | test($release_filter) )
# ... create a package object
| ( $package | del(.releases) ) + {release: .}
# Output the records as key="value" to be `eval`ed by the shell
| to_entries | map(.|"\(.key)=\"\(.value)\"") | join(" ")
