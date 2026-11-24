## Submission

This is a minor release (0.6.0 -> 0.7.0). `sc_write_csv()` now formats
times faster with less memory and writes the CSV in chunks, with a new
`chunk_size` argument. The file written is unchanged.

## R CMD check results

0 errors | 0 warnings | 0 notes

* GitHub Actions: macOS (release), Windows (release), Ubuntu (release and devel)

## Reverse dependencies

There is one reverse dependency, 'actimetrics'. It calls only
`stepcount::stepcount()`, whose output is unchanged in this release.
