# ml-date-ranges
MarkLogic library for generating various date/time ranges

## API Documentation

See [API.md](API.md).

## Testing

- git clone git://github.com/robwhitby/xray.git
- setup an app-server mounting current dir as modules-root on localhost 8765
- ./test.sh

## Updating docs

- install xquerydoc (see https://github.com/xquery/xquerydoc)
- run: xquerydoc -f markdown
- cp xqdoc/xqdoc_ml-date-ranges_date-ranges.xqy.md API.md
- manually remove private vars (all) and functions (apply-*)
