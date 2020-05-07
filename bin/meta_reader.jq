.[]
# Filter by package name
| select(.source_package | test($package_filter) )
# Reformat releases into a string ...
| .releases |= (
  [.] | flatten | [.[] | select( . | test($release_filter) )] | join(" ")
)
# Output the records as key="value" to be `eval`ed by the shell
| to_entries | map(.|"\(.key)=\"\(.value)\"") | join(" ")
