# The files the checks read although they sit in a folder left out of the verified state (docs,
# sources-art, the top-level .md files), as git pathspecs: :(glob) keeps a * from crossing a /.
# Empty by default. Dot-sourced by garde-tests.ps1, for the fingerprint of the verified state, and by
# any script that needs the same list, such as an outils/verifier.ps1 that checks that no file changed
# during a run: they all read this one list. Example, a palette that the tests read:
#   $CheckedSources = @(':(glob)sources-art/palette/*.json')
$CheckedSources = @()
